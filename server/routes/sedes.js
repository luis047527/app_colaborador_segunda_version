const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol } = require('../middleware/roles');

const router = express.Router();

router.use(verificarToken);

// Lista válida solo en API (sin CHECKs en DB por decisión de evolve).
const ESTADOS_VALIDOS = ['ACTIVA', 'INACTIVA'];
const EDITABLES = ['nombre', 'direccion', 'latitud', 'longitud', 'radio_permitido_metros', 'estado'];

function validarGeo({ latitud, longitud, radio_permitido_metros }) {
  if (latitud !== undefined) {
    const lat = Number(latitud);
    if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
      return 'latitud debe ser número entre -90 y 90';
    }
  }
  if (longitud !== undefined) {
    const lon = Number(longitud);
    if (!Number.isFinite(lon) || lon < -180 || lon > 180) {
      return 'longitud debe ser número entre -180 y 180';
    }
  }
  if (radio_permitido_metros !== undefined) {
    const radio = Number(radio_permitido_metros);
    if (!Number.isFinite(radio) || radio <= 0) {
      return 'radio_permitido_metros debe ser número mayor a 0';
    }
  }
  return null;
}

/**
 * @openapi
 * /api/sedes/:
 *   get:
 *     summary: Listar sedes
 *     tags: [Sedes]
 *     responses:
 *       200:
 *         description: Lista
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/Sede' }
 *   post:
 *     summary: Crear sede
 *     tags: [Sedes]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/SedeInput' }
 *     responses:
 *       201:
 *         description: Creada (estado default ACTIVA)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Sede' }
 *       400:
 *         description: Campos faltantes o geo/estado inválido
 */
router.get('/', async (_req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM sedes ORDER BY id');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * @openapi
 * /api/sedes/{id}:
 *   get:
 *     summary: Obtener sede
 *     tags: [Sedes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Sede' }
 *       404:
 *         description: No encontrada
 *   put:
 *     summary: Actualizar sede
 *     tags: [Sedes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/SedeInput' }
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Sede' }
 *       400:
 *         description: Sin campos o valor inválido
 *       404:
 *         description: No encontrada
 *   delete:
 *     summary: Desactivar sede (borrado lógico a INACTIVA)
 *     tags: [Sedes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Desactivada
 *       404:
 *         description: No encontrada
 */
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM sedes WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Sede no encontrada' });
    }
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.post('/', requerirRol('ADMINISTRADOR'), async (req, res) => {
  const { nombre, direccion, latitud, longitud, radio_permitido_metros, estado } = req.body || {};
  if (!nombre || !direccion || latitud === undefined || longitud === undefined || radio_permitido_metros === undefined) {
    return res.status(400).json({
      error: 'nombre, direccion, latitud, longitud y radio_permitido_metros son obligatorios',
    });
  }
  const errGeo = validarGeo({ latitud, longitud, radio_permitido_metros });
  if (errGeo) return res.status(400).json({ error: errGeo });
  const estadoFinal = estado || 'ACTIVA';
  if (!ESTADOS_VALIDOS.includes(estadoFinal)) {
    return res.status(400).json({ error: 'estado inválido' });
  }
  try {
    const [result] = await pool.query(
      `INSERT INTO sedes (nombre, direccion, latitud, longitud, radio_permitido_metros, estado)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [nombre, direccion, latitud, longitud, radio_permitido_metros, estadoFinal]
    );
    const [rows] = await pool.query('SELECT * FROM sedes WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.put('/:id', requerirRol('ADMINISTRADOR'), async (req, res) => {
  const cambios = {};
  for (const campo of EDITABLES) {
    if (req.body?.[campo] !== undefined) cambios[campo] = req.body[campo];
  }
  if (Object.keys(cambios).length === 0) {
    return res.status(400).json({ error: 'No hay campos para actualizar' });
  }
  const errGeo = validarGeo(cambios);
  if (errGeo) return res.status(400).json({ error: errGeo });
  if (cambios.estado && !ESTADOS_VALIDOS.includes(cambios.estado)) {
    return res.status(400).json({ error: 'estado inválido' });
  }
  try {
    const [existe] = await pool.query('SELECT id FROM sedes WHERE id = ?', [req.params.id]);
    if (existe.length === 0) {
      return res.status(404).json({ error: 'Sede no encontrada' });
    }
    const setSql = Object.keys(cambios)
      .map((c) => `${c} = ?`)
      .join(', ');
    await pool.query(`UPDATE sedes SET ${setSql} WHERE id = ?`, [
      ...Object.values(cambios),
      req.params.id,
    ]);
    const [rows] = await pool.query('SELECT * FROM sedes WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.delete('/:id', requerirRol('ADMINISTRADOR'), async (req, res) => {
  try {
    const [result] = await pool.query("UPDATE sedes SET estado = 'INACTIVA' WHERE id = ?", [
      req.params.id,
    ]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Sede no encontrada' });
    }
    res.json({ mensaje: 'Sede desactivada (borrado lógico)' });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
