const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol } = require('../middleware/roles');
const Horarios = require('../models/horarios');
const Sedes = require('../models/sedes');
const {
  validarCreate,
  validarUpdate,
  crearEmpleado,
  actualizarEmpleado,
  horarioHoy,
} = require('../services/empleados');

const router = express.Router();

router.use(verificarToken);

/**
 * @openapi
 * /api/empleados/:
 *   get:
 *     summary: Listar empleados (ADMIN/SUPERVISOR)
 *     description: Lista operativa para gestión de colaboradores y home Admin. Requiere ADMIN o SUPERVISOR. Incluye datos de usuario, sede y horario vía LEFT JOIN.
 *     tags: [Empleados]
 *     responses:
 *       200:
 *         description: Lista de empleados con datos de usuario/sede/horario
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/Empleado' }
 *       401:
 *         description: Token no proporcionado o inválido
 *       403:
 *         description: Rol no autorizado (COLABORADOR)
 */
router.get('/', requerirRol('ADMINISTRADOR', 'SUPERVISOR'), async (_req, res) => {
  try {
    const [rows] = await pool.query(`SELECT e.*, u.nombre, u.apellido, u.email, u.rol,
      s.nombre AS sede_nombre, h.nombre AS horario_nombre
      FROM empleados e JOIN usuarios u ON u.id = e.usuario_id
      LEFT JOIN sedes s ON s.id = e.sede_id LEFT JOIN horarios h ON h.id = e.horario_id
      ORDER BY u.nombre, u.apellido`);
    res.json(rows);
  } catch (err) { console.error('GET /api/empleados error:', err); res.status(500).json({ error: 'Error interno del servidor' }); }
});

// Helpers reutilizables para REST-pure + aliases legacy
async function handleGetMe(req, res) {
  try {
    const [rows] = await pool.query(
      `SELECT e.*, u.nombre, u.apellido, u.email, u.foto_url, u.rol,
        s.nombre AS sede_nombre, s.direccion AS sede_direccion,
        h.nombre AS horario_nombre, h.tolerancia_minutos
       FROM empleados e
       JOIN usuarios u ON u.id = e.usuario_id
       LEFT JOIN sedes s ON s.id = e.sede_id
       LEFT JOIN horarios h ON h.id = e.horario_id
       WHERE e.usuario_id = ?`,
      [req.usuario.sub]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Usuario sin perfil de colaborador' });
    res.json(rows[0]);
  } catch (_) { res.status(500).json({ error: 'Error interno del servidor' }); }
}

async function handleGetMeHorario(req, res) {
  try {
    const [rows] = await pool.query(
      'SELECT horario_id FROM empleados WHERE usuario_id = ?',
      [req.usuario.sub]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Usuario sin perfil de colaborador' });
    if (!rows[0].horario_id) return res.status(404).json({ error: 'Colaborador sin horario asignado' });
    const horario = await Horarios.buscarPorId(pool, rows[0].horario_id);
    if (!horario) return res.status(404).json({ error: 'Horario no encontrado' });
    const dias = await Horarios.listarDias(pool, rows[0].horario_id);
    res.json({ ...horario, dias });
  } catch (_) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}

async function handleGetHorarioById(req, res) {
  try {
    const [emp] = await pool.query(
      'SELECT id, usuario_id, horario_id FROM empleados WHERE id = ?',
      [req.params.id]
    );
    if (emp.length === 0) {
      return res.status(404).json({ error: 'Empleado no encontrado' });
    }
    if (req.usuario.rol === 'COLABORADOR' && emp[0].usuario_id !== req.usuario.sub) {
      return res.status(403).json({ error: 'No autorizado' });
    }
    // REST-pure: ?fecha=YYYY-MM-DD (o ?date=), default hoy Lima
    const rawFecha = req.query.fecha || req.query.date;
    let hoy;
    if (rawFecha) {
      const parsed = new Date(rawFecha + 'T12:00:00');
      if (isNaN(parsed.getTime())) return res.status(400).json({ error: 'fecha inválida, use YYYY-MM-DD' });
      hoy = parsed;
    }
    const r = await horarioHoy(pool, req.params.id, hoy);
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}

/**
 * @openapi
 * /api/empleados/me:
 *   get:
 *     summary: Perfil del colaborador autenticado
 *     description: Retorna el empleado vinculado a `req.usuario.sub`.
 *     tags: [Empleados]
 *     responses:
 *       200:
 *         description: Empleado encontrado
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Empleado' }
 *       401: { description: Token no proporcionado o inválido }
 *       404: { description: Usuario sin perfil de colaborador }
 */
router.get('/me', handleGetMe);

/**
 * @openapi
 * /api/empleados/me/horario:
 *   get:
 *     summary: Horario semanal del colaborador autenticado
 *     description: Retorna cabecera `horarios` + `horario_dias` (7 filas).
 *     tags: [Empleados]
 *     responses:
 *       200: { description: Horario con dias }
 *       401: { description: Token no proporcionado o inválido }
 *       404: { description: Usuario sin perfil, sin horario asignado u horario no encontrado }
 */
router.get('/me/horario', handleGetMeHorario);

async function handleGetMeSede(req, res) {
  try {
    const [emps] = await pool.query(
      'SELECT id, sede_id, estado FROM empleados WHERE usuario_id = ?',
      [req.usuario.sub]
    );
    if (!emps[0]) return res.status(404).json({ error: 'Usuario sin perfil de colaborador' });
    if (emps[0].estado !== 'ACTIVO') return res.status(403).json({ error: 'Colaborador no activo' });
    if (!emps[0].sede_id) return res.status(404).json({ error: 'Colaborador sin sede asignada' });
    const sede = await Sedes.buscarFila(pool, emps[0].sede_id);
    if (!sede || sede.estado !== 'ACTIVA') return res.status(404).json({ error: 'Sede no disponible' });
    res.json({
      id: sede.id,
      nombre: sede.nombre,
      latitud: Number(sede.latitud),
      longitud: Number(sede.longitud),
      radio_permitido_metros: Number(sede.radio_permitido_metros),
    });
  } catch (_) { res.status(500).json({ error: 'Error interno del servidor' }); }
}

/**
 * @openapi
 * /api/empleados/me/sede:
 *   get:
 *     summary: Sede asignada al usuario autenticado (sin secreto QR)
 *     description: Retorna coords y radio para pre-validación GPS en cliente. Nunca expone `qr_valor`.
 *     tags: [Empleados]
 *     responses:
 *       200:
 *         description: Sede asignada
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               required: [id, nombre, latitud, longitud, radio_permitido_metros]
 *               properties:
 *                 id: { type: integer }
 *                 nombre: { type: string }
 *                 latitud: { type: number }
 *                 longitud: { type: number }
 *                 radio_permitido_metros: { type: number }
 *       401: { description: Token no proporcionado o inválido }
 *       403: { description: Colaborador no activo }
 *       404: { description: Sin perfil, sin sede asignada o sede no disponible }
 */
router.get('/me/sede', handleGetMeSede);

// Horario del día para el colaborador (criterio de éxito #5 MVP).
// COLABORADOR solo ve el suyo; ADMIN/SUPERVISOR cualquiera.
/**
 * @openapi
 * /api/empleados/{id}/horario:
 *   get:
 *     summary: Horario del día del empleado
 *     description: Acepta `?fecha=YYYY-MM-DD` (ó `?date=`), default hoy en zona Lima. Retorna fecha, fila del día y minutos requeridos.
 *     tags: [Empleados]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *       - in: query
 *         name: fecha
 *         schema: { type: string, format: date }
 *         description: Fecha en Lima (YYYY-MM-DD), default hoy
 *       - in: query
 *         name: date
 *         schema: { type: string, format: date }
 *         description: Alias de fecha
 *     responses:
 *       200: { description: Fecha, fila del día y minutos requeridos }
 *       400: { description: fecha inválida }
 *       403: { description: Colaborador ajeno }
 *       404: { description: Empleado/horario/detalle inexistente }
 */
router.get('/:id/horario', handleGetHorarioById);

// EDITABLES queda en ruta (filtro HTTP de campos permitidos).
const EDITABLES = [
  'codigo_empleado',
  'cargo',
  'modalidad_laboral',
  'tipo_horario',
  'sede_id',
  'horario_id',
  'fecha_ingreso',
  'fecha_cese',
  'estado',
];

/**
 * @openapi
 * /api/empleados/:
 *   post:
 *     summary: Crear empleado (vincula usuario + sede/horario opcionales)
 *     tags: [Empleados]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/EmpleadoInput' }
 *     responses:
 *       201:
 *         description: Creado
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Empleado' }
 *       400:
 *         description: Campos faltantes o valor inválido
 *       404:
 *         description: Usuario/sede/horario inexistente
 *       409:
 *         description: Usuario ya asignado o código duplicado
 */
router.post('/', requerirRol('ADMINISTRADOR'), async (req, res) => {
  const errCreate = validarCreate(req.body || {});
  if (errCreate) return res.status(400).json({ error: errCreate });
  try {
    const r = await crearEmpleado(pool, req.body);
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.status(r.status).json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * @openapi
 * /api/empleados/{id}:
 *   put:
 *     summary: Actualizar empleado (traslado sede, asignar horario, etc.)
 *     tags: [Empleados]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               codigo_empleado: { type: string }
 *               cargo: { type: string }
 *               modalidad_laboral: { type: string, enum: [FULL_TIME, PART_TIME] }
 *               tipo_horario: { type: string, enum: [FIJO, FLEXIBLE, ROTATIVO, PERSONALIZADO] }
 *               sede_id: { type: integer, nullable: true }
 *               horario_id: { type: integer, nullable: true }
 *               fecha_ingreso: { type: string, format: date }
 *               fecha_cese: { type: string, format: date, nullable: true }
 *               estado: { type: string, enum: [ACTIVO, INACTIVO] }
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Empleado' }
 *       400:
 *         description: Sin campos o valor inválido
 *       404:
 *         description: Empleado/sede/horario inexistente
 *       409:
 *         description: Código duplicado
 */
router.put('/:id', requerirRol('ADMINISTRADOR'), async (req, res) => {
  const cambios = {};
  for (const campo of EDITABLES) {
    if (req.body?.[campo] !== undefined) cambios[campo] = req.body[campo];
  }
  if (Object.keys(cambios).length === 0) {
    return res.status(400).json({ error: 'No hay campos para actualizar' });
  }

  try {
    const [actual] = await pool.query('SELECT * FROM empleados WHERE id = ?', [req.params.id]);
    if (actual.length === 0) {
      return res.status(404).json({ error: 'Empleado no encontrado' });
    }
    const errUpdate = validarUpdate(actual[0], cambios);
    if (errUpdate) return res.status(400).json({ error: errUpdate });
    const r = await actualizarEmpleado(pool, req.params.id, cambios);
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
