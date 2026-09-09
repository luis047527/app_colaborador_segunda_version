// Lógica pura de empleados (sin HTTP; DB como interfaz vía models).
// Listas válidas solo en API (sin CHECKs en DB por decisión de evolve).
const Usuarios = require('../models/usuarios');
const Empleados = require('../models/empleados');
const Sedes = require('../models/sedes');
const Horarios = require('../models/horarios');
const { fechaLimaYMD, diaSemanaLima, minutosDesdeHora } = require('../utils/fecha');
const ESTADOS_VALIDOS = ['ACTIVO', 'INACTIVO'];
const MODALIDADES_VALIDAS = ['FULL_TIME', 'PART_TIME'];
const TIPOS_HORARIO_VALIDOS = ['FIJO', 'FLEXIBLE', 'ROTATIVO', 'PERSONALIZADO'];

function validarCreate(d) {
  if (
    !d.usuario_id ||
    !d.codigo_empleado ||
    !d.cargo ||
    !d.modalidad_laboral ||
    !d.tipo_horario ||
    !d.fecha_ingreso
  ) {
    return 'usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario y fecha_ingreso son obligatorios';
  }
  if (!MODALIDADES_VALIDAS.includes(d.modalidad_laboral)) {
    return `modalidad_laboral debe ser una de: ${MODALIDADES_VALIDAS.join(', ')}`;
  }
  if (!TIPOS_HORARIO_VALIDOS.includes(d.tipo_horario)) {
    return `tipo_horario debe ser uno de: ${TIPOS_HORARIO_VALIDOS.join(', ')}`;
  }
  if (!ESTADOS_VALIDOS.includes(d.estado || 'ACTIVO')) {
    return 'estado inválido';
  }
  // Comparación lexicográfica válida para fechas YYYY-MM-DD.
  if (d.fecha_cese && d.fecha_cese < d.fecha_ingreso) {
    return 'fecha_cese no puede ser anterior a fecha_ingreso';
  }
  return null;
}

// Valida cambios contra valores efectivos (fila actual + cambios).
function validarUpdate(filaActual, cambios) {
  if (cambios.modalidad_laboral && !MODALIDADES_VALIDAS.includes(cambios.modalidad_laboral)) {
    return `modalidad_laboral debe ser una de: ${MODALIDADES_VALIDAS.join(', ')}`;
  }
  if (cambios.tipo_horario && !TIPOS_HORARIO_VALIDOS.includes(cambios.tipo_horario)) {
    return `tipo_horario debe ser uno de: ${TIPOS_HORARIO_VALIDOS.join(', ')}`;
  }
  if (cambios.estado && !ESTADOS_VALIDOS.includes(cambios.estado)) {
    return 'estado inválido';
  }
  const ingreso = cambios.fecha_ingreso ?? filaActual.fecha_ingreso;
  const cese = cambios.fecha_cese ?? filaActual.fecha_cese;
  if (cese && cese < ingreso) {
    return 'fecha_cese no puede ser anterior a fecha_ingreso';
  }
  return null;
}

module.exports = {
  ESTADOS_VALIDOS,
  MODALIDADES_VALIDAS,
  TIPOS_HORARIO_VALIDOS,
  validarCreate,
  validarUpdate,
  crearEmpleado,
  actualizarEmpleado,
  horarioHoy,
};

async function crearEmpleado(db, datos) {
  const estadoFinal = datos.estado || 'ACTIVO';
  if (!(await Usuarios.buscarPorId(db, datos.usuario_id))) {
    return { status: 404, error: 'Usuario no encontrado' };
  }
  if (await Empleados.existeParaUsuario(db, datos.usuario_id)) {
    return { status: 409, error: 'El usuario ya tiene un empleado asignado' };
  }
  if (datos.sede_id !== undefined && datos.sede_id !== null) {
    if (!(await Sedes.buscarPorId(db, datos.sede_id))) {
      return { status: 404, error: 'Sede no encontrada' };
    }
  }
  if (datos.horario_id !== undefined && datos.horario_id !== null) {
    if (!(await Horarios.existe(db, datos.horario_id))) {
      return { status: 404, error: 'Horario no encontrado' };
    }
  }
  try {
    const id = await Empleados.insertar(db, {
      ...datos,
      sede_id: datos.sede_id ?? null,
      horario_id: datos.horario_id ?? null,
      fecha_cese: datos.fecha_cese ?? null,
      estado: estadoFinal,
    });
    return { status: 201, data: await Empleados.buscarPorId(db, id) };
  } catch (err) {
    // UNIQUEs (uq_empleados_usuario/codigo) como red ante carreras.
    if (err.code === 'ER_DUP_ENTRY') {
      return { status: 409, error: 'codigo_empleado duplicado o usuario ya asignado' };
    }
    throw err;
  }
}

async function actualizarEmpleado(db, id, cambios) {
  const actual = await Empleados.buscarPorId(db, id);
  if (!actual) {
    return { status: 404, error: 'Empleado no encontrado' };
  }
  if (cambios.sede_id !== undefined && cambios.sede_id !== null) {
    if (!(await Sedes.buscarPorId(db, cambios.sede_id))) {
      return { status: 404, error: 'Sede no encontrada' };
    }
  }
  if (cambios.horario_id !== undefined && cambios.horario_id !== null) {
    if (!(await Horarios.existe(db, cambios.horario_id))) {
      return { status: 404, error: 'Horario no encontrado' };
    }
  }
  try {
    await Empleados.actualizar(db, id, cambios);
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return { status: 409, error: 'codigo_empleado duplicado' };
    }
    throw err;
  }
  return { status: 200, data: await Empleados.buscarPorId(db, id) };
}

// Horario del día (criterio #5). Ownership (colaborador propio) queda en ruta.
// `hoy` inyectable para tests (default: ahora).
async function horarioHoy(db, empleadoId, hoy = new Date()) {
  const emp = await Empleados.buscarAsignacion(db, empleadoId);
  if (!emp) {
    return { status: 404, error: 'Empleado no encontrado' };
  }
  if (!emp.horario_id) {
    return { status: 404, error: 'Empleado sin horario asignado' };
  }
  const fecha = fechaLimaYMD(hoy);
  const diaSemana = diaSemanaLima(hoy);
  const cab = await Horarios.buscarPorId(db, emp.horario_id);
  if (!cab) {
    return { status: 404, error: 'Horario no encontrado' };
  }
  const dia = await Horarios.buscarDia(db, emp.horario_id, diaSemana);
  if (!dia) {
    return { status: 404, error: 'Horario sin detalle para hoy' };
  }
  let requeridasMin = 0;
  if (!dia.es_descanso) {
    requeridasMin = minutosDesdeHora(dia.salida) - minutosDesdeHora(dia.entrada);
    if (dia.ref_inicio && dia.ref_fin) {
      requeridasMin -= minutosDesdeHora(dia.ref_fin) - minutosDesdeHora(dia.ref_inicio);
    }
  }
  return { status: 200, data: { fecha, dia_semana: diaSemana, horario: cab, dia, horas_requeridas_min: requeridasMin } };
}
