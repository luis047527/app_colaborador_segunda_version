const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');

const router = express.Router();

router.post('/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'email y password son obligatorios' });
  }
  try {
    const [rows] = await pool.query('SELECT * FROM usuarios WHERE email = ?', [email]);
    const usuario = rows[0];
    if (!usuario || !(await bcrypt.compare(password, usuario.password_hash))) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }
    if (usuario.estado !== 'ACTIVO') {
      return res.status(403).json({ error: `Usuario ${usuario.estado.toLowerCase()}` });
    }
    await pool.query('UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = ?', [usuario.id]);
    const token = jwt.sign(
      { sub: usuario.id, email: usuario.email, rol: usuario.rol },
      process.env.JWT_SECRET || 'dev-secret',
      { expiresIn: '8h' }
    );
    const { password_hash, ...safe } = usuario;
    res.json({ token, usuario: safe });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
