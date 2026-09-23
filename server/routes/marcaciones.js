const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol } = require('../middleware/roles');
const Sedes = require('../models/sedes');
const { crearQr, registrar } = require('../services/marcaciones');

const router = express.Router();
router.use(verificarToken);

// El administrador muestra este valor como QR en la sede. Vence en dos minutos.
router.post('/qr/sede/:sedeId', requerirRol('ADMINISTRADOR', 'SUPERVISOR'), async (req, res) => {
  try {
    const sede = await Sedes.buscarFila(pool, req.params.sedeId);
    if (!sede || sede.estado !== 'ACTIVA') return res.status(404).json({ error: 'Sede no encontrada o inactiva' });
    res.json({ sede_id: sede.id, ...crearQr(sede.id, process.env.QR_SECRET || 'qr-dev-secret') });
  } catch (_) { res.status(500).json({ error: 'Error interno del servidor' }); }
});

router.get('/mio', requerirRol('COLABORADOR'), async (req, res) => {
  const hasta = /^\d{4}-\d{2}-\d{2}$/.test(req.query.hasta || '')
    ? req.query.hasta
    : new Date().toISOString().slice(0, 10);
  const desdeDefault = new Date(`${hasta}T12:00:00Z`);
  desdeDefault.setUTCDate(desdeDefault.getUTCDate() - 30);
  const desde = /^\d{4}-\d{2}-\d{2}$/.test(req.query.desde || '')
    ? req.query.desde
    : desdeDefault.toISOString().slice(0, 10);
  if (desde > hasta) return res.status(400).json({ error: 'desde no puede ser posterior a hasta' });
  try {
    const [employees] = await pool.query(
      'SELECT id FROM empleados WHERE usuario_id = ?',
      [req.usuario.sub]
    );
    if (!employees[0]) return res.status(404).json({ error: 'Usuario sin perfil de colaborador' });
    const [rows] = await pool.query(
      `SELECT m.id, m.fecha, m.tipo, m.timestamp_utc, m.resultado, m.motivo,
        m.fuera_radio, m.distancia_metros, s.nombre AS sede_nombre
       FROM marcaciones m
       LEFT JOIN sedes s ON s.id = m.sede_id
       WHERE m.empleado_id = ? AND m.fecha BETWEEN ? AND ?
       ORDER BY m.fecha DESC, m.timestamp_utc ASC`,
      [employees[0].id, desde, hasta]
    );
    res.json({ desde, hasta, marcaciones: rows });
  } catch (_) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

router.post('/', requerirRol('COLABORADOR'), async (req, res) => {
  try {
    const r = await registrar(pool, req.usuario.sub, req.body || {});
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.status(r.status).json(r.data);
  } catch (_) { res.status(500).json({ error: 'Error interno del servidor' }); }
});
module.exports = router;
