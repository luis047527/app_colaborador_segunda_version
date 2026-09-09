const express = require('express');
const pool = require('../db');
const { validarLoginInput, autenticar } = require('../services/auth');

const router = express.Router();

/**
 * @openapi
 * /api/auth/login:
 *   post:
 *     summary: Iniciar sesión (JWT 8h)
 *     tags: [Auth]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/LoginInput' }
 *     responses:
 *       200:
 *         description: Token + usuario (sin hash)
 *       400:
 *         description: Faltan email/password
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       401:
 *         description: Credenciales inválidas
 *       403:
 *         description: Usuario no activo
 */
router.post('/login', async (req, res) => {
  const errInput = validarLoginInput(req.body || {});
  if (errInput) {
    return res.status(400).json({ error: errInput });
  }
  try {
    const r = await autenticar(pool, req.body, {
      jwtSecret: process.env.JWT_SECRET || 'dev-secret',
    });
    if (r.error) {
      return res.status(r.status).json({ error: r.error });
    }
    res.json(r.data);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
