const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');

const router = express.Router();

router.use(verificarToken);

// Reglas MVP (API-only, sin CHECKs en DB — ver docs/notes-david-sep-9.md):
// - dias: exactamente 7 filas, dia_semana 1=Lun..7=Dom sin repetir.
// - salida > entrada siempre (sin overnight en MVP).
// - refs: ambas NULL (jornada simple) o entrada <= ref_ini < ref_fin <= salida.
// - descanso => horas NULL y req 0.
// - llegada anticipada se clampeada a programada en el motor de cálculo (no aquí).
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

/**
 * @openapi
 * /api/horarios/:
 *   post:
 *     summary: Crear horario con sus 7 días (transaccional)
 *     tags: [Horarios]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema: { $ref: '#/components/schemas/HorarioInput' }
 *     responses:
 *       201:
 *         description: Creado con dias normalizados HH:MM:SS
 *       400:
 *         description: Días incompletos, overnight, refs u horas inválidas
 */
router.post('/', async (req, res) => {
  const { nombre, descripcion, tolerancia_minutos, vigencia_desde, vigencia_hasta, dias } =
    req.body || {};

  if (!nombre || !vigencia_desde) {
    return res.status(400).json({ error: 'nombre y vigencia_desde son obligatorios' });
  }
  const tolerancia = tolerancia_minutos === undefined ? 10 : tolerancia_minutos;
  if (!Number.isInteger(tolerancia) || tolerancia < TOL_MIN || tolerancia > TOL_MAX) {
    return res.status(400).json({
      error: `tolerancia_minutos debe ser entero ${TOL_MIN}-${TOL_MAX}`,
    });
  }
  // YYYY-MM-DD compara lexicográficamente.
  if (vigencia_hasta && vigencia_hasta < vigencia_desde) {
    return res.status(400).json({ error: 'vigencia_hasta no puede ser anterior a vigencia_desde' });
  }
  const errDias = validarDias(dias);
  if (errDias) return res.status(400).json({ error: errDias });

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [cab] = await conn.query(
      `INSERT INTO horarios (nombre, descripcion, tolerancia_minutos, vigencia_desde, vigencia_hasta)
       VALUES (?, ?, ?, ?, ?)`,
      [nombre, descripcion || null, tolerancia, vigencia_desde, vigencia_hasta || null]
    );
    const horarioId = cab.insertId;
    for (const d of dias) {
      await conn.query(
        `INSERT INTO horario_dias (horario_id, dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          horarioId,
          d.dia_semana,
          d._norm.entrada,
          d._norm.ref_inicio,
          d._norm.ref_fin,
          d._norm.salida,
          d._norm.es_descanso,
        ]
      );
    }
    await conn.commit();
    res.status(201).json({
      id: horarioId,
      nombre,
      descripcion: descripcion || null,
      tolerancia_minutos: tolerancia,
      vigencia_desde,
      vigencia_hasta: vigencia_hasta || null,
      dias: dias.map((d) => ({ dia_semana: d.dia_semana, ...d._norm })),
    });
  } catch (err) {
    await conn.rollback();
    res.status(500).json({ error: 'Error interno del servidor' });
  } finally {
    conn.release();
  }
});

/**
 * @openapi
 * /api/horarios/{id}:
 *   get:
 *     summary: Obtener horario con sus días
 *     tags: [Horarios]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Header + dias ordenados
 *       404:
 *         description: No encontrado
 */
router.get('/:id', async (req, res) => {
  try {
    const [cab] = await pool.query('SELECT * FROM horarios WHERE id = ?', [req.params.id]);
    if (cab.length === 0) {
      return res.status(404).json({ error: 'Horario no encontrado' });
    }
    const [dias] = await pool.query(
      'SELECT dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso FROM horario_dias WHERE horario_id = ? ORDER BY dia_semana',
      [req.params.id]
    );
    res.json({ ...cab[0], dias });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
