// Lógica pura de sedes (sin HTTP; DB como interfaz vía models).
const Sedes = require('../models/sedes');
const ESTADOS_VALIDOS = ['ACTIVA', 'INACTIVA'];

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

module.exports = { ESTADOS_VALIDOS, validarGeo, crearSede, actualizarSede };

async function crearSede(db, { nombre, direccion, latitud, longitud, radio_permitido_metros, estado }) {
  const id = await Sedes.insertar(db, {
    nombre,
    direccion,
    latitud,
    longitud,
    radio: radio_permitido_metros,
    estado: estado || 'ACTIVA',
  });
  return { status: 201, data: await Sedes.buscarFila(db, id) };
}

async function actualizarSede(db, id, cambios) {
  if (!(await Sedes.buscarPorId(db, id))) {
    return { status: 404, error: 'Sede no encontrada' };
  }
  await Sedes.actualizar(db, id, cambios);
  return { status: 200, data: await Sedes.buscarFila(db, id) };
}
