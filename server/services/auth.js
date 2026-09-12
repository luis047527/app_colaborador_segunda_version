// Lógica pura de autenticación (sin HTTP).
// DB entra como interfaz { query } vía models (testeable con stub).
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Usuarios = require('../models/usuarios');

function validarLoginInput(body) {
  if (!body.email || !body.password) {
    return 'email y password son obligatorios';
  }
  return null;
}

// { status, data } | { status, error }. Lanza si falla la DB (ruta => 500).
async function autenticar(db, { email, password }, { jwtSecret }) {
  const usuario = await Usuarios.buscarPorEmail(db, email);
  if (!usuario || !(await bcrypt.compare(password, usuario.password_hash))) {
    return { status: 401, error: 'Credenciales inválidas' };
  }
  if (usuario.estado !== 'ACTIVO') {
    return { status: 403, error: `Usuario ${usuario.estado.toLowerCase()}` };
  }
  await Usuarios.registrarAcceso(db, usuario.id);
  const token = jwt.sign(
    { sub: usuario.id, email: usuario.email, rol: usuario.rol },
    jwtSecret,
    { expiresIn: '8h' }
  );
  const { password_hash, ...safe } = usuario;
  return { status: 200, data: { token, usuario: safe } };
}

module.exports = { validarLoginInput, autenticar };
