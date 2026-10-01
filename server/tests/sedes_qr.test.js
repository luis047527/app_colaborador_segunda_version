// Tests para POST /api/sedes/:id/qr (plan-semana-2 actividad 4) — pool mockeado.
// 201 primera vez, 200 al rotar (invalida el valor anterior).
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { installPool, bootApp, token } = require('./helpers');

const sedesPorId = {
  1: { id: 1, qr_valor: null, estado: 'ACTIVA' },
  2: { id: 2, qr_valor: 'LUMIBELL-SEDE-2-VIEJO123', estado: 'ACTIVA' },
};
let ultimoUpdate = null;

installPool(async (sql, params) => {
  if (sql.startsWith('SELECT * FROM sedes WHERE id = ?')) {
    const sede = sedesPorId[params[0]];
    return [sede ? [{ ...sede }] : []];
  }
  if (sql.startsWith('UPDATE sedes SET')) {
    ultimoUpdate = { sql, params };
    sedesPorId[params[1]].qr_valor = params[0];
    return [{ affectedRows: 1 }];
  }
  throw new Error(`query no mockeada: ${sql.slice(0, 120)} | params=${JSON.stringify(params)}`);
});

let server;
let base;
before(async () => {
  ({ server, base } = await bootApp());
});
after(() => server.close());

const post = async (id, payload) => {
  const headers = {};
  if (payload !== false) headers.Authorization = `Bearer ${token(payload)}`;
  const res = await fetch(`${base}/api/sedes/${id}/qr`, { method: 'POST', headers });
  return { status: res.status, body: await res.json().catch(() => null) };
};

const ADMIN = { sub: 1, rol: 'ADMINISTRADOR' };

describe('POST /api/sedes/:id/qr', () => {
  it('401 sin token', async () => {
    const { status } = await post(1, false);
    assert.equal(status, 401);
  });

  it('403 no administrador', async () => {
    for (const payload of [
      { sub: 2, rol: 'SUPERVISOR' },
      { sub: 5, rol: 'COLABORADOR' },
    ]) {
      const { status } = await post(1, payload);
      assert.equal(status, 403);
    }
  });

  it('404 sede inexistente', async () => {
    const { status, body } = await post(999, ADMIN);
    assert.equal(status, 404);
    assert.equal(body.error, 'Sede no encontrada');
  });

  it('201 genera con formato y qr_png_url', async () => {
    const { status, body } = await post(1, ADMIN);
    assert.equal(status, 201);
    assert.equal(body.sede_id, 1);
    assert.match(body.qr_valor, /^LUMIBELL-SEDE-1-[0-9A-F]{8}$/);
    assert.equal(body.qr_png_url, '/api/sedes/1/qr?formato=png');
    assert.equal(ultimoUpdate.params[0], body.qr_valor);
  });

  it('200 rota y cambia el valor anterior', async () => {
    const antes = sedesPorId[2].qr_valor;
    const { status, body } = await post(2, ADMIN);
    assert.equal(status, 200);
    assert.match(body.qr_valor, /^LUMIBELL-SEDE-2-[0-9A-F]{8}$/);
    assert.notEqual(body.qr_valor, antes);
  });
});
