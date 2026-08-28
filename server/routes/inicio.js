const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');

const router = express.Router();

router.use(verificarToken);

function proximaAccion(ultimoTipo) {
  if (!ultimoTipo) return 'ENTRADA';
  const mapa = {
    ENTRADA: 'SALIDA_ALMUERZO',
    SALIDA_ALMUERZO: 'REGRESO_ALMUERZO',
    REGRESO_ALMUERZO: 'SALIDA',
    SALIDA_PERMISO: 'REGRESO_PERMISO',
    REGRESO_PERMISO: 'SALIDA',
    SALIDA: null,
  };
  return mapa[ultimoTipo] ?? 'ENTRADA';
}

router.get('/resumen', async (req, res) => {
  const usuarioId = req.usuario?.sub;
  if (!usuarioId) {
    return res.status(401).json({ error: 'Token inválido' });
  }
  try {
    const [usuarios] = await pool.query(
      'SELECT id, nombre, apellido, email, foto_url, rol, estado, ultimo_acceso, created_at FROM usuarios WHERE id = ?',
      [usuarioId]
    );
    const usuario = usuarios[0];
    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const [empleados] = await pool.query(
      'SELECT e.*, s.nombre AS sede_nombre, s.direccion AS sede_direccion, s.latitud AS sede_latitud, s.longitud AS sede_longitud, s.radio_permitido_metros AS sede_radio FROM empleados e LEFT JOIN sedes s ON s.id = e.sede_id WHERE e.usuario_id = ?',
      [usuarioId]
    );
    const empleado = empleados[0] || null;

    let marcacionesHoy = [];
    let balanceHoy = null;
    if (empleado) {
      const [rowsMarc] = await pool.query(
        "SELECT id, empleado_id, fecha_hora, tipo_marcacion, metodo_marcacion, sede_id, estado FROM marcaciones WHERE empleado_id = ? AND DATE(fecha_hora) = CURDATE() ORDER BY fecha_hora ASC",
        [empleado.id]
      );
      marcacionesHoy = rowsMarc;

      const [rowsBal] = await pool.query(
        'SELECT * FROM balances_diarios WHERE empleado_id = ? AND fecha = CURDATE()',
        [empleado.id]
      );
      balanceHoy = rowsBal[0] || null;
    }

    const [notifs] = await pool.query(
      'SELECT id, tipo, titulo, mensaje, leida, created_at FROM notificaciones WHERE usuario_id = ? ORDER BY created_at DESC LIMIT 5',
      [usuarioId]
    );
    const [countNoLeidas] = await pool.query(
      'SELECT COUNT(*) AS total FROM notificaciones WHERE usuario_id = ? AND leida = 0',
      [usuarioId]
    );

    const ultimoTipo = marcacionesHoy.length ? marcacionesHoy[marcacionesHoy.length - 1].tipo_marcacion : null;
    const siguiente = proximaAccion(ultimoTipo);

    res.json({
      usuario,
      empleado,
      hoy: {
        fecha: new Date().toISOString().slice(0, 10),
        marcaciones: marcacionesHoy,
        balance: balanceHoy,
        proxima_accion: siguiente,
        jornada_completa: siguiente === null,
      },
      notificaciones: {
        no_leidas: countNoLeidas[0].total,
        ultimas: notifs,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;
