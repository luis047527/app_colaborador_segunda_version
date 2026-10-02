// Tests para GET /api/hora/ — hora oficial display, sin DB.
// No toca pool: si alguna query se ejecuta, el test falla.
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { installPool, bootApp, req, token } = require('./helpers');

installPool(async (sql) => {
  throw new Error(`GET /hora no debe tocar DB, query: ${sql}`);
});

let server;
let base;
before(async () => {
  ({ server, base } = await bootApp());
});
after(() => server.close());

describe('GET /api/hora/', () => {
  it('401 sin token', async () => {
    const res = await fetch(`${base}/api/hora/`);
    assert.equal(res.status, 401);
  });

  it('401 token inválido', async () => {
    const res = await fetch(`${base}/api/hora/`, {
      headers: { Authorization: 'Bearer invalido' },
    });
    assert.equal(res.status, 401);
  });

  it('200 con JWT: forma utc + lima sin segundos', async () => {
    const { status, body } = await req(base, 'GET', '/api/hora/');
    assert.equal(status, 200);
    assert.match(body.utc, /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
    assert.match(body.lima_fecha, /^\d{4}-\d{2}-\d{2}$/);
    assert.match(body.lima_hora, /^\d{2}:\d{2}$/);
    assert.equal(body.lima, `${body.lima_fecha} ${body.lima_hora}`);
    assert.ok(!isNaN(Date.parse(body.utc)));
  });

  it('200 para rol COLABORADOR (cualquier rol autenticado)', async () => {
    const res = await fetch(`${base}/api/hora/`, {
      headers: {
        Authorization: `Bearer ${token({ sub: 9, rol: 'COLABORADOR' })}`,
      },
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.match(body.lima_hora, /^\d{2}:\d{2}$/);
  });
});
