async function buscarEmpleadoPorUsuario(db, usuarioId) {
  const [rows] = await db.query(
    'SELECT id, usuario_id, sede_id, horario_id, estado FROM empleados WHERE usuario_id = ?',
    [usuarioId]
  );
  return rows[0] || null;
}

async function tiposAceptadosHoy(db, empleadoId, fecha) {
  const [rows] = await db.query(
    "SELECT tipo FROM marcaciones WHERE empleado_id = ? AND fecha = ? AND resultado = 'ACEPTADA' ORDER BY id",
    [empleadoId, fecha]
  );
  return rows.map((row) => row.tipo);
}

async function insertar(db, data) {
  const [result] = await db.query(
    `INSERT INTO marcaciones
      (empleado_id, fecha, tipo, sede_id, latitud, longitud, distancia_metros, fuera_radio, resultado, motivo)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [data.empleadoId, data.fecha, data.tipo, data.sedeId, data.latitud, data.longitud,
      data.distancia, data.fueraRadio, data.resultado, data.motivo]
  );
  const [rows] = await db.query('SELECT * FROM marcaciones WHERE id = ?', [result.insertId]);
  return rows[0];
}

module.exports = { buscarEmpleadoPorUsuario, tiposAceptadosHoy, insertar };
