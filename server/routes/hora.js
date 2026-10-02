const express = require('express');
const verificarToken = require('../middleware/auth');
const { fechaLimaYMD } = require('../utils/fecha');

const router = express.Router();

router.use(verificarToken);

function limaHoraHHMM(date) {
  return new Intl.DateTimeFormat('es-PE', {
    timeZone: 'America/Lima',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(date);
}

/**
 * @openapi
 * /api/hora/:
 *   get:
 *     summary: Hora oficial del servidor (display)
 *     description: Retorna UTC + fecha/hora en America/Lima sin segundos. Solo display; la hora válida de marcación es `timestamp_utc` del POST.
 *     tags: [Sistema]
 *     responses:
 *       200:
 *         description: Hora oficial
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               required: [utc, lima, lima_hora, lima_fecha]
 *               properties:
 *                 utc: { type: string, format: date-time, example: '2026-10-01T15:15:00.000Z' }
 *                 lima: { type: string, example: '2026-10-01 10:15' }
 *                 lima_hora: { type: string, example: '10:15' }
 *                 lima_fecha: { type: string, format: date, example: '2026-10-01' }
 *       401: { description: Token no proporcionado o inválido }
 */
router.get('/', (_req, res) => {
  const ahora = new Date();
  const lima_fecha = fechaLimaYMD(ahora);
  const lima_hora = limaHoraHHMM(ahora);
  res.json({
    utc: ahora.toISOString(),
    lima: `${lima_fecha} ${lima_hora}`,
    lima_hora,
    lima_fecha,
  });
});

module.exports = router;
