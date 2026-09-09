const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');

const router = express.Router();

router.use(verificarToken);

// Listas válidas solo en API (sin CHECKs en DB por decisión de evolve).
// Deben mantenerse en sync con seeds y docs si cambian.
const ESTADOS_VALIDOS = ['ACTIVO', 'INACTIVO'];
const MODALIDADES_VALIDAS = ['FULL_TIME', 'PART_TIME'];
const TIPOS_HORARIO_VALIDOS = ['FIJO', 'FLEXIBLE', 'ROTATIVO', 'PERSONALIZADO'];

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

module.exports = router;
