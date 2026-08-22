const express = require('express');
const pool = require('./db');
const authRoutes = require('./routes/auth');
const usuarioRoutes = require('./routes/usuarios');

const app = express();
const port = process.env.PORT || 3000;

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

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
