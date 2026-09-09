// Acceso a datos de empleados: solo SQL, sin decisiones.
async function buscarPorId(db, id) {
  const [rows] = await db.query('SELECT * FROM empleados WHERE id = ?', [id]);
  return rows[0] || null;
}

async function buscarAsignacion(db, id) {
  const [rows] = await db.query('SELECT id, usuario_id, horario_id FROM empleados WHERE id = ?', [
    id,
  ]);
  return rows[0] || null;
}

async function existeParaUsuario(db, usuarioId) {
  const [rows] = await db.query('SELECT id FROM empleados WHERE usuario_id = ?', [usuarioId]);
  return rows.length > 0;
}

async function insertar(db, c) {
  const [r] = await db.query(
    `INSERT INTO empleados
       (usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario, sede_id, horario_id, fecha_ingreso, fecha_cese, estado)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      c.usuario_id,
      c.codigo_empleado,
      c.cargo,
      c.modalidad_laboral,
      c.tipo_horario,
      c.sede_id,
      c.horario_id,
      c.fecha_ingreso,
      c.fecha_cese,
      c.estado,
    ]
  );
  return r.insertId;
}

async function actualizar(db, id, cambios) {
  const setSql = Object.keys(cambios)
    .map((c) => `${c} = ?`)
    .join(', ');
  await db.query(`UPDATE empleados SET ${setSql} WHERE id = ?`, [...Object.values(cambios), id]);
}

module.exports = { buscarPorId, buscarAsignacion, existeParaUsuario, insertar, actualizar };
