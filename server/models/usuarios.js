// Acceso a datos de usuarios: solo SQL, sin decisiones.
// Recibe `db` ({ query }) para no acoplarse al pool real.
async function buscarPorEmail(db, email) {
  const [rows] = await db.query('SELECT * FROM usuarios WHERE email = ?', [email]);
  return rows[0] || null;
}

async function registrarAcceso(db, id) {
  await db.query('UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = ?', [id]);
}

async function listar(db) {
  const [rows] = await db.query(
    'SELECT id, nombre, apellido, email, foto_url, rol, estado, ultimo_acceso, created_at, updated_at FROM usuarios ORDER BY id'
  );
  return rows;
}

async function buscarPorId(db, id) {
  const [rows] = await db.query('SELECT * FROM usuarios WHERE id = ?', [id]);
  return rows[0] || null;
}

async function existeEmail(db, email, excluirId = null) {
  const [rows] =
    excluirId === null
      ? await db.query('SELECT id FROM usuarios WHERE email = ?', [email])
      : await db.query('SELECT id FROM usuarios WHERE email = ? AND id <> ?', [email, excluirId]);
  return rows.length > 0;
}

async function insertar(db, { nombre, apellido, email, passwordHash, fotoUrl, rol }) {
  const [r] = await db.query(
    'INSERT INTO usuarios (nombre, apellido, email, password_hash, foto_url, rol) VALUES (?, ?, ?, ?, ?, ?)',
    [nombre, apellido, email, passwordHash, fotoUrl, rol]
  );
  return r.insertId;
}

async function actualizar(db, id, cambios) {
  const setSql = Object.keys(cambios)
    .map((c) => `${c} = ?`)
    .join(', ');
  await db.query(`UPDATE usuarios SET ${setSql} WHERE id = ?`, [...Object.values(cambios), id]);
}

async function actualizarPassword(db, id, hash) {
  await db.query('UPDATE usuarios SET password_hash = ? WHERE id = ?', [hash, id]);
}

async function desactivar(db, id) {
  const [r] = await db.query("UPDATE usuarios SET estado = 'INACTIVO' WHERE id = ?", [id]);
  return r.affectedRows;
}

module.exports = {
  buscarPorEmail,
  registrarAcceso,
  listar,
  buscarPorId,
  existeEmail,
  insertar,
  actualizar,
  actualizarPassword,
  desactivar,
};
