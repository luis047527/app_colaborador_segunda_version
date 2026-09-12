// Tests para /api/sedes — sin DB real (pool mockeado).
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { once } = require('node:events');

process.env.JWT_SECRET = 'test-secret';

const baseRow = () => ({
  id: 1,
  nombre: 'Sede Principal Lima',
  direccion: 'Av. Principal 123, Lima',
  latitud: '-12.0463740',
  longitud: '-77.0427930',
  radio_permitido_metros: '100.00',
  estado: 'ACTIVA',
  created_at: '2026-01-01 00:00:00',
  updated_at: '2026-01-01 00:00:00',
});

const behavior = { existe: true, lista: [baseRow()], affectedRows: 1 };
let appliedRow = baseRow();

const fakePool = {
  async query(sql, params) {
    if (sql.includes('ORDER BY id')) return [behavior.lista];
    if (sql.startsWith('INSERT INTO sedes')) return [{ insertId: 5 }];
    if (sql.startsWith('SELECT * FROM sedes WHERE id = ?')) {
      return [behavior.existe ? [appliedRow] : []];
    }
    if (sql === 'SELECT id FROM sedes WHERE id = ?') {
      return [behavior.existe ? [{ id: params[0] }] : []];
    }
    if (sql.startsWith('UPDATE sedes SET estado =')) {
      return [{ affectedRows: behavior.affectedRows }];
    }
    if (sql.startsWith('UPDATE sedes SET')) {
      const setPart = sql.split('SET ')[1].split(' WHERE id')[0];
      const cols = setPart.split(',').map((s) => s.trim().split(' ')[0]);
      cols.forEach((c, i) => {
        appliedRow[c] = params[i];
      });
      return [{ affectedRows: 1 }];
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
  behavior.existe = true;
  behavior.lista = [baseRow()];
  behavior.affectedRows = 1;
  appliedRow = baseRow();
});

const token = () => jwt.sign({ sub: 1, rol: 'ADMINISTRADOR' }, 'test-secret');
async function call(method, url, body, withToken = true) {
  const headers = {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (withToken) headers.Authorization = `Bearer ${token()}`;
  const res = await fetch(`${base}${url}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

const nueva = () => ({
  nombre: 'Sede Norte',
  direccion: 'Av. Norte 456',
  latitud: -12.05,
  longitud: -77.04,
  radio_permitido_metros: 150,
});

describe('/api/sedes', () => {
  it('401 sin token', async () => {
    const { status } = await call('GET', '/api/sedes/', undefined, false);
    assert.equal(status, 401);
  });

  it('200 lista', async () => {
    const { status, body } = await call('GET', '/api/sedes/');
    assert.equal(status, 200);
    assert.equal(body.length, 1);
  });

  it('200 una + 404 inexistente', async () => {
    assert.equal((await call('GET', '/api/sedes/1')).status, 200);
    behavior.existe = false;
    assert.equal((await call('GET', '/api/sedes/999')).status, 404);
  });

  it('400 faltantes', async () => {
    const { status } = await call('POST', '/api/sedes/', { nombre: 'X' });
    assert.equal(status, 400);
  });

  it('400 geo inválida', async () => {
    assert.match(
      (await call('POST', '/api/sedes/', { ...nueva(), latitud: 95 })).body.error,
      /latitud/
    );
    assert.match(
      (await call('POST', '/api/sedes/', { ...nueva(), longitud: -200 })).body.error,
      /longitud/
    );
    assert.match(
      (await call('POST', '/api/sedes/', { ...nueva(), radio_permitido_metros: 0 })).body.error,
      /radio/
    );
    assert.equal(
      (await call('POST', '/api/sedes/', { ...nueva(), estado: 'X' })).status,
      400
    );
  });

  it('201 crea con estado ACTIVA', async () => {
    const { status, body } = await call('POST', '/api/sedes/', nueva());
    assert.equal(status, 201);
    assert.equal(body.estado, 'ACTIVA');
  });

  it('PUT 400/404/200', async () => {
    assert.equal((await call('PUT', '/api/sedes/1', {})).status, 400);
    assert.equal((await call('PUT', '/api/sedes/1', { latitud: 100 })).status, 400);
    behavior.existe = false;
    assert.equal((await call('PUT', '/api/sedes/999', { nombre: 'X' })).status, 404);
    behavior.existe = true;
    const { status, body } = await call('PUT', '/api/sedes/1', {
      nombre: 'Sede Sur',
      estado: 'INACTIVA',
    });
    assert.equal(status, 200);
    assert.equal(body.nombre, 'Sede Sur');
    assert.equal(body.estado, 'INACTIVA');
  });

  it('DELETE 200 lógico + 404', async () => {
    const { status, body } = await call('DELETE', '/api/sedes/1');
    assert.equal(status, 200);
    assert.match(body.mensaje, /desactivada/);
    behavior.affectedRows = 0;
    assert.equal((await call('DELETE', '/api/sedes/999')).status, 404);
  });
});
