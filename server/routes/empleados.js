const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol } = require('../middleware/roles');
const {
  validarCreate,
  validarUpdate,
  crearEmpleado,
  actualizarEmpleado,
  horarioHoy,
} = require('../services/empleados');

const router = express.Router();

router.use(verificarToken);

// Horario del día para el colaborador (criterio de éxito #5 MVP).
// COLABORADOR solo ve el suyo; ADMIN/SUPERVISOR cualquiera.
/**
 * @openapi
 * /api/empleados/{id}/horario-hoy:
 *   get:
 *     summary: Horario del día del empleado (fecha Lima + requeridas)
 *     tags: [Empleados]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Fecha, fila del día y minutos requeridos
 *       403:
 *         description: Colaborador ajeno
 *       404:
 *         description: Empleado/horario/detalle inexistente
 */
router.get('/:id/horario-hoy', async (req, res) => {
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
    const r = await horarioHoy(pool, req.params.id);
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

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
