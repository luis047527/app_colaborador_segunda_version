const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');
const verificarToken = require('../middleware/auth');

const router = express.Router();

const sinHash = ({ password_hash, ...resto }) => resto;
const ROLES_VALIDOS = ['ADMINISTRADOR', 'SUPERVISOR', 'COLABORADOR'];

router.use(verificarToken);

router.get('/', async (_req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, nombre, apellido, email, foto_url, rol, estado, ultimo_acceso, created_at, updated_at FROM usuarios ORDER BY id'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, nombre, apellido, email, foto_url, rol, estado, ultimo_acceso, created_at, updated_at FROM usuarios WHERE id = ?',
      [req.params.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.post('/', async (req, res) => {
  const { nombre, apellido, email, password, rol, foto_url } = req.body || {};
  if (!nombre || !apellido || !email || !password || !rol) {
    return res.status(400).json({ error: 'nombre, apellido, email, password y rol son obligatorios' });
  }
  if (!ROLES_VALIDOS.includes(rol)) {
    return res.status(400).json({ error: `rol debe ser uno de: ${ROLES_VALIDOS.join(', ')}` });
  }
  try {
    const [dup] = await pool.query('SELECT id FROM usuarios WHERE email = ?', [email]);
    if (dup.length > 0) {
      return res.status(409).json({ error: 'El email ya está registrado' });
    }
    const hash = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      'INSERT INTO usuarios (nombre, apellido, email, password_hash, foto_url, rol) VALUES (?, ?, ?, ?, ?, ?)',
      [nombre, apellido, email, hash, foto_url || null, rol]
    );
    const [rows] = await pool.query('SELECT * FROM usuarios WHERE id = ?', [result.insertId]);
    res.status(201).json(sinHash(rows[0]));
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.put('/:id', async (req, res) => {
  const permitidos = ['nombre', 'apellido', 'email', 'foto_url', 'rol', 'estado'];
  const cambios = {};
  for (const campo of permitidos) {
    if (req.body?.[campo] !== undefined) cambios[campo] = req.body[campo];
  }
  if (Object.keys(cambios).length === 0 && req.body?.password === undefined) {
    return res.status(400).json({ error: 'No hay campos para actualizar' });
  }
  try {
    const [existe] = await pool.query('SELECT id FROM usuarios WHERE id = ?', [req.params.id]);
    if (existe.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    if (cambios.rol && !ROLES_VALIDOS.includes(cambios.rol)) {
      return res.status(400).json({ error: `rol debe ser uno de: ${ROLES_VALIDOS.join(', ')}` });
    }
    if (cambios.estado && !['ACTIVO', 'INACTIVO', 'BLOQUEADO'].includes(cambios.estado)) {
      return res.status(400).json({ error: 'estado inválido' });
    }
    if (cambios.email) {
      const [dup] = await pool.query('SELECT id FROM usuarios WHERE email = ? AND id <> ?', [
        cambios.email,
        req.params.id,
      ]);
      if (dup.length > 0) {
        return res.status(409).json({ error: 'El email ya está registrado' });
      }
    }
    let sql;
    const valores = Object.values(cambios);
    if (req.body.password !== undefined) {
      sql = await bcrypt.hash(req.body.password, 10);
    }
    if (Object.keys(cambios).length > 0) {
      const setSql = Object.keys(cambios).map((c) => `${c} = ?`).join(', ');
      await pool.query(`UPDATE usuarios SET ${setSql} WHERE id = ?`, [...valores, req.params.id]);
    }
    if (sql !== undefined) {
      await pool.query('UPDATE usuarios SET password_hash = ? WHERE id = ?', [sql, req.params.id]);
    }
    const [rows] = await pool.query('SELECT * FROM usuarios WHERE id = ?', [req.params.id]);
    res.json(sinHash(rows[0]));
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const [result] = await pool.query("UPDATE usuarios SET estado = 'INACTIVO' WHERE id = ?", [
      req.params.id,
    ]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    res.json({ mensaje: 'Usuario desactivado (borrado lógico)' });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
