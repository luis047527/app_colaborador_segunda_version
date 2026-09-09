// Acceso a datos de horarios: solo SQL, sin decisiones.
async function buscarPorId(db, id) {
  const [rows] = await db.query('SELECT * FROM horarios WHERE id = ?', [id]);
  return rows[0] || null;
}

async function existe(db, id) {
  const [rows] = await db.query('SELECT id FROM horarios WHERE id = ?', [id]);
  return rows.length > 0;
}

async function buscarDia(db, horarioId, diaSemana) {
  const [rows] = await db.query(
    'SELECT dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso FROM horario_dias WHERE horario_id = ? AND dia_semana = ?',
    [horarioId, diaSemana]
  );
  return rows[0] || null;
}

async function listarDias(db, horarioId) {
  const [rows] = await db.query(
    'SELECT dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso FROM horario_dias WHERE horario_id = ? ORDER BY dia_semana',
    [horarioId]
  );
  return rows;
}

async function insertar(conn, { nombre, descripcion, tolerancia, vigencia_desde, vigencia_hasta }) {
  const [r] = await conn.query(
    `INSERT INTO horarios (nombre, descripcion, tolerancia_minutos, vigencia_desde, vigencia_hasta)
     VALUES (?, ?, ?, ?, ?)`,
    [nombre, descripcion, tolerancia, vigencia_desde, vigencia_hasta]
  );
  return r.insertId;
}

async function insertarDia(conn, { horarioId, dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso }) {
  await conn.query(
    `INSERT INTO horario_dias (horario_id, dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [horarioId, dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso]
  );
}

module.exports = { buscarPorId, existe, buscarDia, listarDias, insertar, insertarDia };
