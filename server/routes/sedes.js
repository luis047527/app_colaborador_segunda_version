const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol } = require('../middleware/roles');
const Sedes = require('../models/sedes');
const { ESTADOS_VALIDOS, validarGeo, crearSede, actualizarSede, generarQr } = require('../services/sedes');

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

/**
 * @openapi
 * /api/sedes/{id}/qr:
 *   post:
 *     summary: Generar o rotar QR estático de la sede
 *     description: Crea `sedes.qr_valor` la primera vez (201) o lo sobrescribe al rotar (200, invalida impresiones anteriores).
 *     tags: [Sedes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       201:
 *         description: QR generado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               required: [sede_id, qr_valor, qr_png_url]
 *               properties:
 *                 sede_id: { type: integer }
 *                 qr_valor: { type: string, example: 'LUMIBELL-SEDE-1-A1B2C3D4' }
 *                 qr_png_url: { type: string, example: '/api/sedes/1/qr?formato=png' }
 *       200:
 *         description: QR rotado (misma forma que 201)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               required: [sede_id, qr_valor, qr_png_url]
 *               properties:
 *                 sede_id: { type: integer }
 *                 qr_valor: { type: string }
 *                 qr_png_url: { type: string }
 *       401: { description: Token no proporcionado o inválido }
 *       403: { description: Rol no autorizado (solo ADMINISTRADOR) }
 *       404: { description: Sede no encontrada }
 */
router.post('/:id/qr', requerirRol('ADMINISTRADOR'), async (req, res) => {
  try {
    const r = await generarQr(pool, req.params.id);
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.status(r.status).json(r.data);
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
