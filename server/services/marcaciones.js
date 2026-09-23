const crypto = require('crypto');
const Marcaciones = require('../models/marcaciones');
const Sedes = require('../models/sedes');
const { fechaLimaYMD } = require('../utils/fecha');

const TIPOS = ['ENTRADA', 'SALIDA_REFRIGERIO', 'REGRESO_REFRIGERIO', 'SALIDA'];

function distanciaMetros(lat1, lon1, lat2, lon2) {
  const r = 6371000;
  const rad = (v) => (v * Math.PI) / 180;
  const dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * r * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function siguienteTipo(tipos) { return TIPOS[tipos.length] || null; }

function crearQr(sedeId, secreto) {
  const expiraEn = Date.now() + 2 * 60 * 1000;
  const nonce = crypto.randomBytes(12).toString('hex');
  const payload = `${sedeId}.${expiraEn}.${nonce}`;
  const firma = crypto.createHmac('sha256', secreto).update(payload).digest('hex');
  return { token: Buffer.from(`${payload}.${firma}`).toString('base64url'), expira_en: new Date(expiraEn).toISOString() };
}

function validarQr(token, sedeId, secreto) {
  try {
    const [tokenSede, expiraEn, nonce, firma] = Buffer.from(token, 'base64url').toString().split('.');
    const payload = `${tokenSede}.${expiraEn}.${nonce}`;
    const esperada = crypto.createHmac('sha256', secreto).update(payload).digest('hex');
    return Number(tokenSede) === Number(sedeId) && Number(expiraEn) >= Date.now() &&
      crypto.timingSafeEqual(Buffer.from(firma), Buffer.from(esperada));
  } catch (_) { return false; }
}

async function registrar(db, usuarioId, data, ahora = new Date()) {
  const empleado = await Marcaciones.buscarEmpleadoPorUsuario(db, usuarioId);
  if (!empleado || empleado.estado !== 'ACTIVO') return { status: 403, error: 'Colaborador no activo' };
  if (!empleado.sede_id) return { status: 400, error: 'Colaborador sin sede asignada' };
  if (!data.qr_token || !validarQr(data.qr_token, empleado.sede_id, process.env.QR_SECRET || 'qr-dev-secret')) {
    return { status: 400, error: 'QR inválido o vencido' };
  }
  if (!Number.isFinite(data.latitud) || !Number.isFinite(data.longitud)) return { status: 400, error: 'Ubicación GPS inválida' };
  const fecha = fechaLimaYMD(ahora);
  const tipos = await Marcaciones.tiposAceptadosHoy(db, empleado.id, fecha);
  const tipo = siguienteTipo(tipos);
  if (!tipo) return { status: 409, error: 'La jornada ya está completa' };
  const sede = await Sedes.buscarFila(db, empleado.sede_id);
  if (!sede || sede.estado !== 'ACTIVA') return { status: 400, error: 'Sede no disponible' };
  const distancia = distanciaMetros(Number(data.latitud), Number(data.longitud), Number(sede.latitud), Number(sede.longitud));
  const fila = await Marcaciones.insertar(db, {
    empleadoId: empleado.id, fecha, tipo, sedeId: sede.id, latitud: data.latitud, longitud: data.longitud,
    distancia, fueraRadio: distancia > Number(sede.radio_permitido_metros) ? 1 : 0,
    resultado: 'ACEPTADA', motivo: null,
  });
  return { status: 201, data: { marcacion: fila, siguiente_marcacion: siguienteTipo([...tipos, tipo]) } };
}

module.exports = { TIPOS, distanciaMetros, crearQr, validarQr, registrar };
