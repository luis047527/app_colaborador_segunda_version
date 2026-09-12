// Tests para /api/usuarios — sin DB real (pool mockeado).
// bcrypt es real; los hash/compare cuestan ~100ms por caso que los usa.
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { installPool, bootApp, req } = require('./helpers');

const SEED_HASH = '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C';

const filaLista = (id, email) => ({
  id,
  nombre: 'N',
  apellido: 'A',
  email,
  foto_url: null,
  rol: 'COLABORADOR',
  estado: 'ACTIVO',
  ultimo_acceso: null,
  created_at: '2026-01-01 00:00:00',
  updated_at: '2026-01-01 00:00:00',
});

const behavior = {
  lista: [filaLista(1, 'a@x.com'), filaLista(2, 'b@x.com')],
  porId: filaLista(1, 'a@x.com'),
  dupEmail: false,
  affectedRows: 1,
  overrides: null, // mezcla sobre SELECT * (POST/PUT responden la fila creada)
  lastInsert: null,
};

const filaCompleta = () => ({
  ...(behavior.porId || filaLista(99, 'nuevo@x.com')),
  password_hash: SEED_HASH,
  ...(behavior.overrides || {}),
});

installPool(async (sql, params) => {
  if (sql.includes('ORDER BY id')) return [behavior.lista];
  if (sql === 'SELECT id FROM usuarios WHERE email = ?') {
    return [behavior.dupEmail ? [{ id: 9 }] : []];
  }
  if (sql.includes('AND id <> ?')) {
    return [behavior.dupEmail ? [{ id: 9 }] : []];
  }
  if (sql.startsWith('INSERT INTO usuarios')) {
    behavior.lastInsert = params;
    return [{ insertId: 99 }];
  }
  if (sql.includes('FROM usuarios WHERE id = ?')) {
    return [behavior.porId ? [filaCompleta()] : []];
  }
  if (sql.startsWith('UPDATE usuarios SET')) {
    return [{ affectedRows: behavior.affectedRows }];
  }
  throw new Error(`query no mockeada: ${sql}`);
});

let server;
let base;
before(async () => {
  ({ server, base } = await bootApp());
});
after(() => server.close());

beforeEach(() => {
  behavior.lista = [filaLista(1, 'a@x.com'), filaLista(2, 'b@x.com')];
  behavior.porId = filaLista(1, 'a@x.com');
  behavior.dupEmail = false;
  behavior.affectedRows = 1;
  behavior.overrides = null;
  behavior.lastInsert = null;
});

const get = (url, withToken = true) => req(base, 'GET', url, undefined, withToken);
const post = (body) => req(base, 'POST', '/api/usuarios/', body);
const put = (id, body) => req(base, 'PUT', `/api/usuarios/${id}`, body);
const del = (id) => req(base, 'DELETE', `/api/usuarios/${id}`, undefined);

describe('GET /api/usuarios', () => {
  it('401 sin token', async () => {
    const { status } = await get('/api/usuarios/', false);
    assert.equal(status, 401);
  });

  it('200 lista usuarios sin hash', async () => {
    const { status, body } = await get('/api/usuarios/');
    assert.equal(status, 200);
    assert.equal(body.length, 2);
    assert.ok(body.every((u) => !('password_hash' in u)));
  });

  it('200 un usuario', async () => {
    const { status, body } = await get('/api/usuarios/1');
    assert.equal(status, 200);
    assert.equal(body.id, 1);
  });

  it('404 usuario inexistente', async () => {
    behavior.porId = null;
    const { status } = await get('/api/usuarios/999');
    assert.equal(status, 404);
  });
});

describe('POST /api/usuarios', () => {
  const nuevo = () => ({
    nombre: 'Ana',
    apellido: 'Rios',
    email: 'ana@x.com',
    password: 'Secreta123',
    rol: 'COLABORADOR',
  });

  it('400 campos faltantes', async () => {
    const { status } = await post({ email: 'a@x.com' });
    assert.equal(status, 400);
  });

  it('400 rol inválido', async () => {
    const { status } = await post({ ...nuevo(), rol: 'JEFE' });
    assert.equal(status, 400);
  });

  it('409 email duplicado', async () => {
    behavior.dupEmail = true;
    const { status } = await post(nuevo());
    assert.equal(status, 409);
  });

  it('201 crea y oculta hash', async () => {
    const { status, body } = await post(nuevo());
    assert.equal(status, 201);
    assert.equal(body.email, 'a@x.com'); // fila mockeada por SELECT *
    assert.ok(!('password_hash' in body));
    // bcrypt real: se guardó un hash, no el plano
    assert.match(behavior.lastInsert[3], /^\$2[aby]\$/);
  });
});

describe('PUT /api/usuarios/:id', () => {
  it('400 sin campos', async () => {
    const { status } = await put(1, {});
    assert.equal(status, 400);
  });

  it('404 inexistente', async () => {
    behavior.porId = null;
    const { status } = await put(999, { nombre: 'X' });
    assert.equal(status, 404);
  });

  it('400 rol y estado inválidos', async () => {
    assert.equal((await put(1, { rol: 'X' })).status, 400);
    assert.equal((await put(1, { estado: 'X' })).status, 400);
  });

  it('409 email duplicado', async () => {
    behavior.dupEmail = true;
    const { status } = await put(1, { email: 'b@x.com' });
    assert.equal(status, 409);
  });

  it('200 actualiza y oculta hash', async () => {
    behavior.overrides = { nombre: 'Nuevo' };
    const { status, body } = await put(1, { nombre: 'Nuevo' });
    assert.equal(status, 200);
    assert.equal(body.nombre, 'Nuevo');
    assert.ok(!('password_hash' in body));
  });

  it('200 actualiza password (hash real)', async () => {
    behavior.overrides = {};
    const { status, body } = await put(1, { password: 'Nueva123' });
    assert.equal(status, 200);
    assert.ok(!('password_hash' in body));
  });
});

describe('DELETE /api/usuarios/:id', () => {
  it('200 borrado lógico', async () => {
    const { status, body } = await del(1);
    assert.equal(status, 200);
    assert.match(body.mensaje, /desactivado/);
  });

  it('404 inexistente', async () => {
    behavior.affectedRows = 0;
    const { status } = await del(999);
    assert.equal(status, 404);
  });
});
