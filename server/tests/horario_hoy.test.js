// Tests para GET /api/empleados/:id/horario-hoy — pool mockeado.
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { once } = require('node:events');

process.env.JWT_SECRET = 'test-secret';

const behavior = {
  emp: { id: 7, usuario_id: 5, horario_id: 20 },
  header: { id: 20, nombre: 'FULL_TIME', tolerancia_minutos: 10 },
  dia: {
    dia_semana: 3,
    entrada: '10:00:00',
    ref_inicio: '13:00:00',
    ref_fin: '14:00:00',
    salida: '19:00:00',
    es_descanso: 0,
  },
};

const fakePool = {
  async query(sql) {
    if (sql.startsWith('SELECT id, usuario_id, horario_id FROM empleados WHERE id = ?')) {
      return [behavior.emp ? [behavior.emp] : []];
    }
    if (sql.startsWith('SELECT * FROM horarios WHERE id = ?')) {
      return [behavior.header ? [behavior.header] : []];
    }
    if (sql.includes('FROM horario_dias WHERE horario_id = ?')) {
      return [behavior.dia ? [behavior.dia] : []];
    }
    throw new Error(`query no mockeada: ${sql}`);
  },
};

const dbPath = path.join(__dirname, '..', 'db.js');
require.cache[dbPath] = { id: dbPath, filename: dbPath, loaded: true, exports: fakePool };

const jwt = require('jsonwebtoken');
const app = require('../index.js');

let server;
let base;
before(async () => {
  server = app.listen(0);
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

beforeEach(() => {
  behavior.emp = { id: 7, usuario_id: 5, horario_id: 20 };
  behavior.header = { id: 20, nombre: 'FULL_TIME', tolerancia_minutos: 10 };
  behavior.dia = {
    dia_semana: 3,
    entrada: '10:00:00',
    ref_inicio: '13:00:00',
    ref_fin: '14:00:00',
    salida: '19:00:00',
    es_descanso: 0,
  };
});

const token = (payload = { sub: 1, rol: 'ADMINISTRADOR' }) => jwt.sign(payload, 'test-secret');
async function get(url, payload) {
  const headers = {};
  if (payload !== false) headers.Authorization = `Bearer ${token(payload)}`;
  const res = await fetch(`${base}${url}`, { headers });
  return { status: res.status, body: await res.json() };
}

describe('GET /api/empleados/:id/horario-hoy', () => {
  it('401 sin token', async () => {
    const { status } = await get('/api/empleados/7/horario-hoy', false);
    assert.equal(status, 401);
  });

  it('404 empleado inexistente', async () => {
    behavior.emp = null;
    const { status } = await get('/api/empleados/999/horario-hoy');
    assert.equal(status, 404);
  });

  it('403 colaborador ve horario ajeno', async () => {
    const { status } = await get('/api/empleados/7/horario-hoy', { sub: 9, rol: 'COLABORADOR' });
    assert.equal(status, 403);
  });

  it('200 colaborador ve el suyo', async () => {
    const { status, body } = await get('/api/empleados/7/horario-hoy', {
      sub: 5,
      rol: 'COLABORADOR',
    });
    assert.equal(status, 200);
    assert.equal(body.horas_requeridas_min, 480);
  });

  it('404 sin horario asignado', async () => {
    behavior.emp = { id: 7, usuario_id: 5, horario_id: null };
    const { status } = await get('/api/empleados/7/horario-hoy');
    assert.equal(status, 404);
  });

  it('404 horario borrado', async () => {
    behavior.header = null;
    const { status } = await get('/api/empleados/7/horario-hoy');
    assert.equal(status, 404);
  });

  it('200 full-time req 480', async () => {
    const { status, body } = await get('/api/empleados/7/horario-hoy');
    assert.equal(status, 200);
    assert.ok(body.fecha);
    assert.ok(body.dia_semana >= 1 && body.dia_semana <= 7);
    assert.equal(body.horas_requeridas_min, 480);
  });

  it('200 descanso req 0', async () => {
    behavior.dia = {
      dia_semana: 7,
      entrada: null,
      ref_inicio: null,
      ref_fin: null,
      salida: null,
      es_descanso: 1,
    };
    const { status, body } = await get('/api/empleados/7/horario-hoy');
    assert.equal(status, 200);
    assert.equal(body.horas_requeridas_min, 0);
  });

  it('200 part-time sin refs req 240', async () => {
    behavior.dia = {
      dia_semana: 3,
      entrada: '15:00:00',
      ref_inicio: null,
      ref_fin: null,
      salida: '19:00:00',
      es_descanso: 0,
    };
    const { status, body } = await get('/api/empleados/7/horario-hoy');
    assert.equal(status, 200);
    assert.equal(body.horas_requeridas_min, 240);
  });
});
