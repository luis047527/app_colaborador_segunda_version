const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol, permitirPropio } = require('../middleware/roles');
const Usuarios = require('../models/usuarios');
const {
  sinHash,
  validarCreate,
  validarUpdate,
  crearUsuario,
  actualizarUsuario,
} = require('../services/usuarios');

const router = express.Router();

router.use(verificarToken);

/**
 * @openapi
 * /api/usuarios/:
 *   get:
 *     summary: Listar usuarios
 *     tags: [Usuarios]
 *     responses:
 *       200:
 *         description: Lista sin password_hash
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/Usuario' }
 *   post:
 *     summary: Crear usuario
 *     tags: [Usuarios]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/UsuarioInput' }
 *     responses:
 *       201:
 *         description: Creado (sin hash)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Usuario' }
 *       400:
 *         description: Campos faltantes o rol inválido
 *       409:
 *         description: Email duplicado
 */
router.get('/', requerirRol('ADMINISTRADOR', 'SUPERVISOR'), async (_req, res) => {
  try {
    res.json(await Usuarios.listar(pool));
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

/**
 * @openapi
 * /api/usuarios/{id}:
 *   get:
 *     summary: Obtener usuario
 *     tags: [Usuarios]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Usuario' }
 *       404:
 *         description: No encontrado
 *   put:
 *     summary: Actualizar usuario (incluye password y estado)
 *     tags: [Usuarios]
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
 *               nombre: { type: string }
 *               apellido: { type: string }
 *               email: { type: string }
 *               foto_url: { type: string }
 *               password: { type: string }
 *               rol: { type: string, enum: [ADMINISTRADOR, SUPERVISOR, COLABORADOR] }
 *               estado: { type: string, enum: [ACTIVO, INACTIVO, BLOQUEADO] }
 *     responses:
 *       200:
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Usuario' }
 *       400:
 *         description: Sin campos o valor inválido
 *       404:
 *         description: No encontrado
 *       409:
 *         description: Email duplicado
 *   delete:
 *     summary: Desactivar usuario (borrado lógico a INACTIVO)
 *     tags: [Usuarios]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Desactivado
 *       404:
 *         description: No encontrado
 */
router.get('/:id', permitirPropio('ADMINISTRADOR', 'SUPERVISOR'), async (req, res) => {
  try {
    const fila = await Usuarios.buscarPorId(pool, req.params.id);
    if (!fila) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    res.json(sinHash(fila));
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.post('/', requerirRol('ADMINISTRADOR'), async (req, res) => {
  const errCreate = validarCreate(req.body || {});
  if (errCreate) return res.status(400).json({ error: errCreate });
  try {
    const r = await crearUsuario(pool, req.body);
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.status(r.status).json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.put('/:id', permitirPropio('ADMINISTRADOR'), async (req, res) => {
  const permitidos = ['nombre', 'apellido', 'email', 'foto_url', 'rol', 'estado'];
  const cambios = {};
  for (const campo of permitidos) {
    if (req.body?.[campo] !== undefined) cambios[campo] = req.body[campo];
  }
  if (Object.keys(cambios).length === 0 && req.body?.password === undefined) {
    return res.status(400).json({ error: 'No hay campos para actualizar' });
  }
  // No-admin solo edita su perfil básico; rol/estado/email son privilegio ADMIN.
  if (
    req.usuario.rol !== 'ADMINISTRADOR' &&
    (cambios.rol !== undefined || cambios.estado !== undefined || cambios.email !== undefined)
  ) {
    return res.status(403).json({ error: 'No autorizado' });
  }
  try {
    const errUpdate = validarUpdate(cambios);
    if (errUpdate) return res.status(400).json({ error: errUpdate });
    const r = await actualizarUsuario(pool, req.params.id, cambios, req.body.password);
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.delete('/:id', requerirRol('ADMINISTRADOR'), async (req, res) => {
  try {
    const affected = await Usuarios.desactivar(pool, req.params.id);
    if (affected === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    res.json({ mensaje: 'Usuario desactivado (borrado lógico)' });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
