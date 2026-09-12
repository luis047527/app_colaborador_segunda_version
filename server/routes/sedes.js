const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol } = require('../middleware/roles');
const Sedes = require('../models/sedes');
const { ESTADOS_VALIDOS, validarGeo, crearSede, actualizarSede } = require('../services/sedes');

const router = express.Router();

router.use(verificarToken);

const EDITABLES = ['nombre', 'direccion', 'latitud', 'longitud', 'radio_permitido_metros', 'estado'];

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
    res.json(await Sedes.listar(pool));
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
    const fila = await Sedes.buscarFila(pool, req.params.id);
    if (!fila) {
      return res.status(404).json({ error: 'Sede no encontrada' });
    }
    res.json(fila);
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
  if (!ESTADOS_VALIDOS.includes(estado || 'ACTIVA')) {
    return res.status(400).json({ error: 'estado inválido' });
  }
  try {
    const r = await crearSede(pool, req.body);
    res.status(r.status).json(r.data);
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
    const r = await actualizarSede(pool, req.params.id, cambios);
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.delete('/:id', requerirRol('ADMINISTRADOR'), async (req, res) => {
  try {
    const affected = await Sedes.desactivar(pool, req.params.id);
    if (affected === 0) {
      return res.status(404).json({ error: 'Sede no encontrada' });
    }
    res.json({ mensaje: 'Sede desactivada (borrado lógico)' });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
