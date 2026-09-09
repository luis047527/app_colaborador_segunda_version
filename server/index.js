const express = require('express');
const pool = require('./db');
const authRoutes = require('./routes/auth');
const usuarioRoutes = require('./routes/usuarios');
const empleadoRoutes = require('./routes/empleados');
const horarioRoutes = require('./routes/horarios');
const sedeRoutes = require('./routes/sedes');

const app = express();
const port = process.env.PORT || 3000;

const configuredOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

function isAllowedOrigin(origin) {
  // Flutter Web usa un puerto local variable en desarrollo.
  const isLocalFlutterWeb = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
  return isLocalFlutterWeb || configuredOrigins.includes(origin);
}

app.use((req, res, next) => {
  const origin = req.get('origin');

  if (origin && isAllowedOrigin(origin)) {
    res.set({
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      Vary: 'Origin',
    });
  }

  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }

  next();
});

app.use(express.json());

app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'up' });
  } catch (err) {
    res.status(500).json({ status: 'ok', db: 'down' });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/usuarios', usuarioRoutes);
app.use('/api/empleados', empleadoRoutes);
app.use('/api/horarios', horarioRoutes);
app.use('/api/sedes', sedeRoutes);

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
  });
}

module.exports = app;
