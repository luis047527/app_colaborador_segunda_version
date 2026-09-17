const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol } = require('../middleware/roles');
const { TOL_MIN, TOL_MAX, validarDias, crearHorario } = require('../services/horarios');
const Horarios = require('../models/horarios');

const router = express.Router();

router.use(verificarToken);

/**
 * @openapi
 * /api/horarios/:
 *   post:
 *     summary: Crear horario con sus 7 días (transaccional)
 *     tags: [Horarios]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/HorarioInput' }
 *     responses:
 *       201:
 *         description: Creado con dias normalizados HH:MM:SS
 *       400:
 *         description: Días incompletos, overnight, refs u horas inválidas
 */
router.post('/', requerirRol('ADMINISTRADOR'), async (req, res) => {
  const { nombre, descripcion, tolerancia_minutos, vigencia_desde, vigencia_hasta, dias } =
    req.body || {};

  if (!nombre || !vigencia_desde) {
    return res.status(400).json({ error: 'nombre y vigencia_desde son obligatorios' });
  }
  const tolerancia = tolerancia_minutos === undefined ? 10 : tolerancia_minutos;
  if (!Number.isInteger(tolerancia) || tolerancia < TOL_MIN || tolerancia > TOL_MAX) {
    return res.status(400).json({
      error: `tolerancia_minutos debe ser entero ${TOL_MIN}-${TOL_MAX}`,
    });
  }
  // YYYY-MM-DD compara lexicográficamente.
  if (vigencia_hasta && vigencia_hasta < vigencia_desde) {
    return res.status(400).json({ error: 'vigencia_hasta no puede ser anterior a vigencia_desde' });
  }
  const errDias = validarDias(dias);
  if (errDias) return res.status(400).json({ error: errDias });

  try {
    const r = await crearHorario(pool, {
      nombre,
      descripcion,
      tolerancia,
      vigencia_desde,
      vigencia_hasta,
      dias,
    });
    res.status(r.status).json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.get('/', requerirRol('ADMINISTRADOR', 'SUPERVISOR'), async (_req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM horarios ORDER BY id DESC');
    res.json(rows);
  } catch (_) { res.status(500).json({ error: 'Error interno del servidor' }); }
});

/**
 * @openapi
 * /api/horarios/{id}:
 *   get:
 *     summary: Obtener horario con sus días
 *     tags: [Horarios]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Header + dias ordenados
 *       404:
 *         description: No encontrado
 */
router.get('/:id', requerirRol('ADMINISTRADOR', 'SUPERVISOR'), async (req, res) => {
  try {
    const cab = await Horarios.buscarPorId(pool, req.params.id);
    if (!cab) {
      return res.status(404).json({ error: 'Horario no encontrado' });
    }
    const dias = await Horarios.listarDias(pool, req.params.id);
    res.json({ ...cab, dias });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
