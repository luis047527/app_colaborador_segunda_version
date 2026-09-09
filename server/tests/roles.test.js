// Tests de autorización por rol — pool mockeado.
// Política: escrituras ADMIN; lecturas ADMIN/SUPERVISOR (+ dueño); sedes lectura abierta.
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { once } = require('node:events');

process.env.JWT_SECRET = 'test-secret';

const filaUsuario = (id) => ({
  id,
  nombre: 'A',
  apellido: 'B',
  email: 'a@x.com',
  foto_url: null,
  rol: 'COLABORADOR',
  estado: 'ACTIVO',
  ultimo_acceso: null,
  created_at: '2026-01-01 00:00:00',
  updated_at: '2026-01-01 00:00:00',
});

const fakePool = {
  async query(sql, params) {
    if (sql.includes('ORDER BY id') && sql.includes('FROM usuarios')) return [[filaUsuario(1)]];
    if (sql === 'SELECT id FROM usuarios WHERE email = ?') return [[]];
    if (sql.startsWith('INSERT INTO usuarios')) return [{ insertId: 9 }];
    if (sql.includes('FROM usuarios WHERE id = ?')) return [[filaUsuario(params[0])]];
    if (sql.startsWith('UPDATE usuarios SET')) return [{ affectedRows: 1 }];
    if (sql.includes('FROM sedes ORDER BY')) {
      return [[{ id: 1, nombre: 'S', estado: 'ACTIVA' }]];
    }
    if (sql.startsWith('SELECT * FROM horarios WHERE id = ?')) {
      return [[{ id: params[0], nombre: 'H' }]];
    }
    if (sql.includes('FROM horario_dias WHERE horario_id = ?')) {
      return [[{ dia_semana: 1, es_descanso: 0 }]];
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

const ADMIN = { sub: 1, rol: 'ADMINISTRADOR' };
const SUP = { sub: 2, rol: 'SUPERVISOR' };
const COLAB = { sub: 5, rol: 'COLABORADOR' };

async function call(method, url, body, payload) {
  const headers = {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (payload) headers.Authorization = `Bearer ${jwt.sign(payload, 'test-secret')}`;
  const res = await fetch(`${base}${url}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

const NUEVO = {
  nombre: 'A',
  apellido: 'B',
  email: 'n@x.com',
  password: 'Secreta123',
  rol: 'COLABORADOR',
};

describe('autorización', () => {
  it('GET /api/usuarios: COLAB 403, SUP 200', async () => {
    assert.equal((await call('GET', '/api/usuarios/', undefined, COLAB)).status, 403);
    assert.equal((await call('GET', '/api/usuarios/', undefined, SUP)).status, 200);
  });

  it('GET /api/usuarios/:id: dueño 200, ajeno 403', async () => {
    assert.equal((await call('GET', '/api/usuarios/5', undefined, COLAB)).status, 200);
    assert.equal((await call('GET', '/api/usuarios/9', undefined, COLAB)).status, 403);
  });

  it('POST /api/usuarios: solo ADMIN', async () => {
    assert.equal((await call('POST', '/api/usuarios/', NUEVO, COLAB)).status, 403);
    assert.equal((await call('POST', '/api/usuarios/', NUEVO, SUP)).status, 403);
    assert.equal((await call('POST', '/api/usuarios/', NUEVO, ADMIN)).status, 201);
  });

  it('PUT propio: nombre 200, rol/estado/email 403; ajeno 403', async () => {
    assert.equal((await call('PUT', '/api/usuarios/5', { nombre: 'N' }, COLAB)).status, 200);
    assert.equal((await call('PUT', '/api/usuarios/5', { rol: 'ADMINISTRADOR' }, COLAB)).status, 403);
    assert.equal((await call('PUT', '/api/usuarios/5', { estado: 'X' }, COLAB)).status, 403);
    assert.equal((await call('PUT', '/api/usuarios/5', { email: 'x@x.com' }, COLAB)).status, 403);
    assert.equal((await call('PUT', '/api/usuarios/9', { nombre: 'N' }, COLAB)).status, 403);
  });

  it('DELETE /api/usuarios: solo ADMIN', async () => {
    assert.equal((await call('DELETE', '/api/usuarios/5', undefined, COLAB)).status, 403);
    assert.equal((await call('DELETE', '/api/usuarios/5', undefined, SUP)).status, 403);
  });

  it('empleados: escritura solo ADMIN', async () => {
    assert.equal((await call('POST', '/api/empleados/', {}, COLAB)).status, 403);
    assert.equal((await call('PUT', '/api/empleados/7', { sede_id: 2 }, COLAB)).status, 403);
    assert.equal((await call('PUT', '/api/empleados/7', { sede_id: 2 }, SUP)).status, 403);
  });

  it('sedes: lectura abierta, escritura ADMIN', async () => {
    assert.equal((await call('GET', '/api/sedes/', undefined, COLAB)).status, 200);
    assert.equal((await call('POST', '/api/sedes/', {}, COLAB)).status, 403);
    assert.equal((await call('DELETE', '/api/sedes/1', undefined, SUP)).status, 403);
  });

  it('horarios: POST ADMIN, GET admin/sup; COLAB 403', async () => {
    assert.equal((await call('POST', '/api/horarios/', {}, COLAB)).status, 403);
    assert.equal((await call('GET', '/api/horarios/1', undefined, COLAB)).status, 403);
    assert.equal((await call('GET', '/api/horarios/1', undefined, SUP)).status, 200);
  });
});
