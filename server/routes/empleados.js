const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { fechaLimaYMD, diaSemanaLima, minutosDesdeHora } = require('../utils/fecha');

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
    if (!emp[0].horario_id) {
      return res.status(404).json({ error: 'Empleado sin horario asignado' });
    }
    const fecha = fechaLimaYMD();
    const diaSemana = diaSemanaLima();
    const [cab] = await pool.query('SELECT * FROM horarios WHERE id = ?', [emp[0].horario_id]);
    if (cab.length === 0) {
      return res.status(404).json({ error: 'Horario no encontrado' });
    }
    const [dias] = await pool.query(
      'SELECT dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso FROM horario_dias WHERE horario_id = ? AND dia_semana = ?',
      [emp[0].horario_id, diaSemana]
    );
    if (dias.length === 0) {
      return res.status(404).json({ error: 'Horario sin detalle para hoy' });
    }
    const d = dias[0];
    let requeridasMin = 0;
    if (!d.es_descanso) {
      requeridasMin = minutosDesdeHora(d.salida) - minutosDesdeHora(d.entrada);
      if (d.ref_inicio && d.ref_fin) {
        requeridasMin -= minutosDesdeHora(d.ref_fin) - minutosDesdeHora(d.ref_inicio);
      }
    }
    res.json({
      fecha,
      dia_semana: diaSemana,
      horario: cab[0],
      dia: d,
      horas_requeridas_min: requeridasMin,
    });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Listas válidas solo en API (sin CHECKs en DB por decisión de evolve).
// Deben mantenerse en sync con seeds y docs si cambian.
const ESTADOS_VALIDOS = ['ACTIVO', 'INACTIVO'];
const MODALIDADES_VALIDAS = ['FULL_TIME', 'PART_TIME'];
const TIPOS_HORARIO_VALIDOS = ['FIJO', 'FLEXIBLE', 'ROTATIVO', 'PERSONALIZADO'];
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
router.post('/', async (req, res) => {
  const {
    usuario_id,
    codigo_empleado,
    cargo,
    modalidad_laboral,
    tipo_horario,
    sede_id,
    horario_id,
    fecha_ingreso,
    fecha_cese,
    estado,
  } = req.body || {};

  if (
    !usuario_id ||
    !codigo_empleado ||
    !cargo ||
    !modalidad_laboral ||
    !tipo_horario ||
    !fecha_ingreso
  ) {
    return res.status(400).json({
      error:
        'usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario y fecha_ingreso son obligatorios',
    });
  }
  if (!MODALIDADES_VALIDAS.includes(modalidad_laboral)) {
    return res.status(400).json({
      error: `modalidad_laboral debe ser una de: ${MODALIDADES_VALIDAS.join(', ')}`,
    });
  }
  if (!TIPOS_HORARIO_VALIDOS.includes(tipo_horario)) {
    return res.status(400).json({
      error: `tipo_horario debe ser uno de: ${TIPOS_HORARIO_VALIDOS.join(', ')}`,
    });
  }
  const estadoFinal = estado || 'ACTIVO';
  if (!ESTADOS_VALIDOS.includes(estadoFinal)) {
    return res.status(400).json({ error: 'estado inválido' });
  }
  // Comparación lexicográfica válida para fechas YYYY-MM-DD.
  if (fecha_cese && fecha_cese < fecha_ingreso) {
    return res.status(400).json({ error: 'fecha_cese no puede ser anterior a fecha_ingreso' });
  }

  try {
    const [usuarios] = await pool.query('SELECT id FROM usuarios WHERE id = ?', [usuario_id]);
    if (usuarios.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    const [existente] = await pool.query('SELECT id FROM empleados WHERE usuario_id = ?', [
      usuario_id,
    ]);
    if (existente.length > 0) {
      return res.status(409).json({ error: 'El usuario ya tiene un empleado asignado' });
    }
    if (sede_id !== undefined && sede_id !== null) {
      const [sedes] = await pool.query('SELECT id FROM sedes WHERE id = ?', [sede_id]);
      if (sedes.length === 0) {
        return res.status(404).json({ error: 'Sede no encontrada' });
      }
    }
    if (horario_id !== undefined && horario_id !== null) {
      const [horarios] = await pool.query('SELECT id FROM horarios WHERE id = ?', [horario_id]);
      if (horarios.length === 0) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }
    }

    let result;
    try {
      [result] = await pool.query(
        `INSERT INTO empleados
           (usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario, sede_id, horario_id, fecha_ingreso, fecha_cese, estado)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          usuario_id,
          codigo_empleado,
          cargo,
          modalidad_laboral,
          tipo_horario,
          sede_id ?? null,
          horario_id ?? null,
          fecha_ingreso,
          fecha_cese ?? null,
          estadoFinal,
        ]
      );
    } catch (err) {
      // UNIQUEs (uq_empleados_usuario/codigo) como red de seguridad ante carreras.
      if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ error: 'codigo_empleado duplicado o usuario ya asignado' });
      }
      throw err;
    }
    const [rows] = await pool.query('SELECT * FROM empleados WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
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
router.put('/:id', async (req, res) => {
  const cambios = {};
  for (const campo of EDITABLES) {
    if (req.body?.[campo] !== undefined) cambios[campo] = req.body[campo];
  }
  if (Object.keys(cambios).length === 0) {
    return res.status(400).json({ error: 'No hay campos para actualizar' });
  }
  if (cambios.modalidad_laboral && !MODALIDADES_VALIDAS.includes(cambios.modalidad_laboral)) {
    return res.status(400).json({
      error: `modalidad_laboral debe ser una de: ${MODALIDADES_VALIDAS.join(', ')}`,
    });
  }
  if (cambios.tipo_horario && !TIPOS_HORARIO_VALIDOS.includes(cambios.tipo_horario)) {
    return res.status(400).json({
      error: `tipo_horario debe ser uno de: ${TIPOS_HORARIO_VALIDOS.join(', ')}`,
    });
  }
  if (cambios.estado && !ESTADOS_VALIDOS.includes(cambios.estado)) {
    return res.status(400).json({ error: 'estado inválido' });
  }

  try {
    const [actual] = await pool.query('SELECT * FROM empleados WHERE id = ?', [req.params.id]);
    if (actual.length === 0) {
      return res.status(404).json({ error: 'Empleado no encontrado' });
    }
    // Regla de fechas sobre valores efectivos (fila actual + cambios).
    const ingreso = cambios.fecha_ingreso ?? actual[0].fecha_ingreso;
    const cese = cambios.fecha_cese ?? actual[0].fecha_cese;
    if (cese && cese < ingreso) {
      return res.status(400).json({ error: 'fecha_cese no puede ser anterior a fecha_ingreso' });
    }
    if (cambios.sede_id !== undefined && cambios.sede_id !== null) {
      const [sedes] = await pool.query('SELECT id FROM sedes WHERE id = ?', [cambios.sede_id]);
      if (sedes.length === 0) {
        return res.status(404).json({ error: 'Sede no encontrada' });
      }
    }
    if (cambios.horario_id !== undefined && cambios.horario_id !== null) {
      const [horarios] = await pool.query('SELECT id FROM horarios WHERE id = ?', [
        cambios.horario_id,
      ]);
      if (horarios.length === 0) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }
    }

    const setSql = Object.keys(cambios)
      .map((c) => `${c} = ?`)
      .join(', ');
    try {
      await pool.query(`UPDATE empleados SET ${setSql} WHERE id = ?`, [
        ...Object.values(cambios),
        req.params.id,
      ]);
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ error: 'codigo_empleado duplicado' });
      }
      throw err;
    }
    const [rows] = await pool.query('SELECT * FROM empleados WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
