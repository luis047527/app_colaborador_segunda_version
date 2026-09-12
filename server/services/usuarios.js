// Lógica pura de usuarios (sin HTTP; DB como interfaz vía models).
// Solo validación de valores; el privilegio (quién puede cambiar rol/estado/email)
// vive en la ruta junto al middleware de roles.
const bcrypt = require('bcryptjs');
const Usuarios = require('../models/usuarios');
const ROLES_VALIDOS = ['ADMINISTRADOR', 'SUPERVISOR', 'COLABORADOR'];
const ESTADOS_VALIDOS = ['ACTIVO', 'INACTIVO', 'BLOQUEADO'];

function validarCreate(body) {
  if (!body.nombre || !body.apellido || !body.email || !body.password || !body.rol) {
    return 'nombre, apellido, email, password y rol son obligatorios';
  }
  if (!ROLES_VALIDOS.includes(body.rol)) {
    return `rol debe ser uno de: ${ROLES_VALIDOS.join(', ')}`;
  }
  return null;
}

function validarUpdate(cambios) {
  if (cambios.rol && !ROLES_VALIDOS.includes(cambios.rol)) {
    return `rol debe ser uno de: ${ROLES_VALIDOS.join(', ')}`;
  }
  if (cambios.estado && !ESTADOS_VALIDOS.includes(cambios.estado)) {
    return 'estado inválido';
  }
  return null;
}

const sinHash = ({ password_hash, ...resto }) => resto;

async function crearUsuario(db, { nombre, apellido, email, password, rol, foto_url }) {
  if (await Usuarios.existeEmail(db, email)) {
    return { status: 409, error: 'El email ya está registrado' };
  }
  const id = await Usuarios.insertar(db, {
    nombre,
    apellido,
    email,
    passwordHash: await bcrypt.hash(password, 10),
    fotoUrl: foto_url || null,
    rol,
  });
  return { status: 201, data: sinHash(await Usuarios.buscarPorId(db, id)) };
}

async function actualizarUsuario(db, id, cambios, password) {
  const fila = await Usuarios.buscarPorId(db, id);
  if (!fila) {
    return { status: 404, error: 'Usuario no encontrado' };
  }
  if (cambios.email && (await Usuarios.existeEmail(db, cambios.email, id))) {
    return { status: 409, error: 'El email ya está registrado' };
  }
  if (Object.keys(cambios).length > 0) {
    await Usuarios.actualizar(db, id, cambios);
  }
  if (password !== undefined) {
    await Usuarios.actualizarPassword(db, id, await bcrypt.hash(password, 10));
  }
  return { status: 200, data: sinHash(await Usuarios.buscarPorId(db, id)) };
}

module.exports = {
  ROLES_VALIDOS,
  ESTADOS_VALIDOS,
  sinHash,
  validarCreate,
  validarUpdate,
  crearUsuario,
  actualizarUsuario,
};
