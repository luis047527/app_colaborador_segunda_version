// Lógica de horarios (sin HTTP).
// validación/normalización puras + orquestación transaccional (conn inyectada vía pool).
const Horarios = require('../models/horarios');
const TOL_MIN = 0;
const TOL_MAX = 180;

// 'H:MM' o 'HH:MM:SS' -> 'HH:MM:SS'. null/'' -> null. Otro formato -> undefined.
function normalizarHora(v) {
  if (v === null || v === undefined || v === '') return null;
  const m = /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/.exec(String(v).trim());
  if (!m) return undefined;
  const h = Number(m[1]);
  const mi = Number(m[2]);
  const s = m[3] === undefined ? 0 : Number(m[3]);
  if (h > 23 || mi > 59 || s > 59) return undefined;
  const p = (n) => String(n).padStart(2, '0');
  return `${p(h)}:${p(mi)}:${p(s)}`;
}

// Valida el arreglo de 7 días. null = OK (y deja fila normalizada en d._norm).
// Reglas: 7 filas dia 1-7 sin repetir; salida > entrada (sin overnight MVP);
// refs ambas null o entrada <= ref_ini < ref_fin <= salida; descanso => todo null.
function validarDias(dias) {
  if (!Array.isArray(dias) || dias.length !== 7) {
    return 'dias debe ser un arreglo con 7 filas (una por dia_semana 1-7)';
  }
  const vistos = new Set();
  for (const d of dias) {
    if (!Number.isInteger(d.dia_semana) || d.dia_semana < 1 || d.dia_semana > 7) {
      return 'dia_semana debe ser entero 1-7';
    }
    if (vistos.has(d.dia_semana)) return 'dia_semana duplicado';
    vistos.add(d.dia_semana);

    const dia = d.dia_semana;
    const entrada = normalizarHora(d.entrada);
    const refIni = normalizarHora(d.ref_inicio);
    const refFin = normalizarHora(d.ref_fin);
    const salida = normalizarHora(d.salida);
    if (entrada === undefined || refIni === undefined || refFin === undefined || salida === undefined) {
      return `hora inválida en dia ${dia} (formato HH:MM)`;
    }

    if (d.es_descanso) {
      d._norm = { entrada: null, ref_inicio: null, ref_fin: null, salida: null, es_descanso: 1 };
      continue;
    }
    if (!entrada || !salida) {
      return `entrada y salida son obligatorias en dia ${dia} (o márcalo descanso)`;
    }
    // Comparación lexicográfica válida en HH:MM:SS.
    if (salida <= entrada) {
      return `dia ${dia}: salida debe ser mayor a entrada (turno nocturno no soportado en MVP)`;
    }
    if ((refIni === null) !== (refFin === null)) {
      return `dia ${dia}: ref_inicio y ref_fin deben ir juntos o ambos nulos`;
    }
    if (refIni !== null && !(entrada <= refIni && refIni < refFin && refFin <= salida)) {
      return `dia ${dia}: orden inválido, debe ser entrada <= ref_inicio < ref_fin <= salida`;
    }
    d._norm = { entrada, ref_inicio: refIni, ref_fin: refFin, salida, es_descanso: 0 };
  }
  return null;
}

module.exports = { TOL_MIN, TOL_MAX, normalizarHora, validarDias, crearHorario };

// Crea header + 7 días atómicamente. Recibe pool (solo usa getConnection).
// `datos.dias` ya validados por validarDias (usan d._norm). Lanza si falla (ruta => 500).
async function crearHorario(pool, datos) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const horarioId = await Horarios.insertar(conn, {
      nombre: datos.nombre,
      descripcion: datos.descripcion || null,
      tolerancia: datos.tolerancia,
      vigencia_desde: datos.vigencia_desde,
      vigencia_hasta: datos.vigencia_hasta || null,
    });
    for (const d of datos.dias) {
      await Horarios.insertarDia(conn, { horarioId, dia_semana: d.dia_semana, ...d._norm });
    }
    await conn.commit();
    return {
      status: 201,
      data: {
        id: horarioId,
        nombre: datos.nombre,
        descripcion: datos.descripcion || null,
        tolerancia_minutos: datos.tolerancia,
        vigencia_desde: datos.vigencia_desde,
        vigencia_hasta: datos.vigencia_hasta || null,
        dias: datos.dias.map((d) => ({ dia_semana: d.dia_semana, ...d._norm })),
      },
    };
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}
