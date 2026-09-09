// Acceso a datos de sedes: solo SQL, sin decisiones.
async function buscarPorId(db, id) {
  const [rows] = await db.query('SELECT id FROM sedes WHERE id = ?', [id]);
  return rows[0] || null;
}

async function listar(db) {
  const [rows] = await db.query('SELECT * FROM sedes ORDER BY id');
  return rows;
}

async function buscarFila(db, id) {
  const [rows] = await db.query('SELECT * FROM sedes WHERE id = ?', [id]);
  return rows[0] || null;
}

async function insertar(db, { nombre, direccion, latitud, longitud, radio, estado }) {
  const [r] = await db.query(
    `INSERT INTO sedes (nombre, direccion, latitud, longitud, radio_permitido_metros, estado)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [nombre, direccion, latitud, longitud, radio, estado]
  );
  return r.insertId;
}

async function actualizar(db, id, cambios) {
  const setSql = Object.keys(cambios)
    .map((c) => `${c} = ?`)
    .join(', ');
  await db.query(`UPDATE sedes SET ${setSql} WHERE id = ?`, [...Object.values(cambios), id]);
}

async function desactivar(db, id) {
  const [r] = await db.query("UPDATE sedes SET estado = 'INACTIVA' WHERE id = ?", [id]);
  return r.affectedRows;
}

module.exports = { buscarPorId, listar, buscarFila, insertar, actualizar, desactivar };
