// Tests para POST /api/sedes/:id/qr (plan-semana-2 actividad 4) — pool mockeado.
// 201 primera vez, 200 al rotar (invalida el valor anterior).
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { installPool, bootApp, token } = require('./helpers');

const sedesPorId = {
  1: { id: 1, qr_valor: null, estado: 'ACTIVA' },
  2: { id: 2, qr_valor: 'LUMIBELL-SEDE-2-VIEJO123', estado: 'ACTIVA' },
  3: { id: 3, qr_valor: 'LUMIBELL-SEDE-3-QQQQ9999', estado: 'ACTIVA' },
  4: { id: 4, qr_valor: null, estado: 'ACTIVA' },
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

const getQr = async (id, payload, { query = '', ...headers } = {}) => {
  const h = { ...headers };
  if (payload !== false) h.Authorization = `Bearer ${token(payload)}`;
  const res = await fetch(`${base}/api/sedes/${id}/qr${query}`, { headers: h });
  const contentType = res.headers.get('content-type') || '';
  if (contentType.includes('image/png')) {
    return { status: res.status, contentType, bytes: Buffer.from(await res.arrayBuffer()) };
  }
  return { status: res.status, contentType, body: await res.json().catch(() => null) };
};

describe('GET /api/sedes/:id/qr', () => {
  it('401 sin token y 403 colaborador', async () => {
    assert.equal((await getQr(3, false)).status, 401);
    assert.equal((await getQr(3, { sub: 5, rol: 'COLABORADOR' })).status, 403);
  });

  it('404 inexistente y sin QR generado', async () => {
    assert.equal((await getQr(999, ADMIN)).status, 404);
    const sinQr = await getQr(4, ADMIN);
    assert.equal(sinQr.status, 404);
    assert.match(sinQr.body.error, /sin QR/);
  });

  it('200 JSON con las 3 claves (admin y supervisor)', async () => {
    for (const payload of [ADMIN, { sub: 2, rol: 'SUPERVISOR' }]) {
      const { status, body } = await getQr(3, payload);
      assert.equal(status, 200);
      assert.equal(body.sede_id, 3);
      assert.equal(body.qr_valor, 'LUMIBELL-SEDE-3-QQQQ9999');
      assert.equal(body.qr_png_url, '/api/sedes/3/qr?formato=png');
    }
  });

  it('200 PNG con ?formato=png y con Accept: image/png', async () => {
    for (const headers of [{ query: '?formato=png' }, { Accept: 'image/png' }]) {
      const r = await getQr(3, ADMIN, headers);
      assert.equal(r.status, 200);
      assert.match(r.contentType, /image\/png/);
      assert.deepEqual([...r.bytes.subarray(0, 4)], [0x89, 0x50, 0x4e, 0x47]);
      assert.ok(r.bytes.length > 100);
    }
  });
});
