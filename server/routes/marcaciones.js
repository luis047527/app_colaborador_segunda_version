const express = require('express');
const pool = require('../db');
const verificarToken = require('../middleware/auth');
const { requerirRol } = require('../middleware/roles');
const Sedes = require('../models/sedes');
const { crearQr, registrar } = require('../services/marcaciones');

const router = express.Router();
router.use(verificarToken);

/**
 * @openapi
 * /api/marcaciones/qr/sede/{sedeId}:
 *   post:
 *     summary: (DEPRECATED) Generar QR dinámico temporal
 *     description: Reemplazado por QR estático (`POST /api/sedes/{id}/qr`). El QR dinámico ya no valida marcaciones. Se conserva hasta migrar la pantalla admin.
 *     deprecated: true
 *     tags: [Marcaciones]
 *     parameters:
 *       - in: path
 *         name: sedeId
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200: { description: QR dinámico (ya no válido para marcar) }
 *       404: { description: Sede no encontrada o inactiva }
 */
// El administrador muestra este valor como QR en la sede. Vence en dos minutos.
router.post('/qr/sede/:sedeId', requerirRol('ADMINISTRADOR', 'SUPERVISOR'), async (req, res) => {
  try {
    const sede = await Sedes.buscarFila(pool, req.params.sedeId);
    if (!sede || sede.estado !== 'ACTIVA') return res.status(404).json({ error: 'Sede no encontrada o inactiva' });
    res.json({ sede_id: sede.id, ...crearQr(sede.id, process.env.QR_SECRET || 'qr-dev-secret') });
  } catch (_) { res.status(500).json({ error: 'Error interno del servidor' }); }
});

/**
 * @openapi
 * /api/marcaciones/mio:
 *   get:
 *     summary: Historial de marcaciones del colaborador autenticado
 *     tags: [Marcaciones]
 *     parameters:
 *       - in: query
 *         name: desde
 *         schema: { type: string, format: date }
 *         description: Fecha inicial (YYYY-MM-DD), default 30 días antes de `hasta`
 *       - in: query
 *         name: hasta
 *         schema: { type: string, format: date }
 *         description: Fecha final (YYYY-MM-DD), default hoy
 *     responses:
 *       200: { description: Rango + lista de marcaciones con sede }
 *       400: { description: desde posterior a hasta }
 *       404: { description: Usuario sin perfil de colaborador }
 */
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

/**
 * @openapi
 * /api/marcaciones/:
 *   post:
 *     summary: Registrar marcación (QR estático + GPS)
 *     description: Valida QR por igualdad contra `sedes.qr_valor` y ubicación por haversine. Fuera de radio se rechaza con 403. Solo COLABORADOR.
 *     tags: [Marcaciones]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [qr_token, latitud, longitud]
 *             properties:
 *               qr_token: { type: string, example: 'LUMIBELL-SEDE-1-A1B2C3D4' }
 *               latitud: { type: number }
 *               longitud: { type: number }
 *     responses:
 *       201: { description: Marcación creada + siguiente tipo esperado }
 *       400: { description: Sin sede, sede no disponible/sin QR, QR inválido o GPS inválido }
 *       401: { description: Token no proporcionado o inválido }
 *       403: { description: Colaborador no activo o fuera del radio permitido }
 *       409: { description: Jornada ya completa }
 */
router.post('/', requerirRol('COLABORADOR'), async (req, res) => {
  try {
    const r = await registrar(pool, req.usuario.sub, req.body || {});
    if (r.error) return res.status(r.status).json({ error: r.error });
    res.status(r.status).json(r.data);
  } catch (_) { res.status(500).json({ error: 'Error interno del servidor' }); }
});
module.exports = router;
