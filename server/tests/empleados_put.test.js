// Tests para PUT /api/empleados/:id — sin DB real (pool mockeado).
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { once } = require('node:events');

process.env.JWT_SECRET = 'test-secret';

const baseRow = () => ({
  id: 7,
  usuario_id: 5,
  codigo_empleado: 'LUM-0007',
  cargo: 'Operario',
  modalidad_laboral: 'FULL_TIME',
  tipo_horario: 'FIJO',
  sede_id: 1,
  horario_id: null,
  fecha_ingreso: '2026-01-01',
  fecha_cese: null,
  estado: 'ACTIVO',
});

const behavior = { existe: true, sedeExiste: true, horarioExiste: true, dupError: false };
let appliedRow = baseRow();

const fakePool = {
  async query(sql, params) {
    if (sql.startsWith('SELECT * FROM empleados WHERE id = ?')) {
      return [behavior.existe ? [appliedRow] : []];
    }
    if (sql.includes('FROM sedes WHERE id = ?')) {
      return [behavior.sedeExiste ? [{ id: params[0] }] : []];
    }
    if (sql.includes('FROM horarios WHERE id = ?')) {
      return [behavior.horarioExiste ? [{ id: params[0] }] : []];
    }
    if (sql.startsWith('UPDATE empleados SET')) {
      if (behavior.dupError) throw { code: 'ER_DUP_ENTRY' };
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
  behavior.sedeExiste = true;
  behavior.horarioExiste = true;
  behavior.dupError = false;
  appliedRow = baseRow();
});

const token = () => jwt.sign({ sub: 1, rol: 'ADMINISTRADOR' }, 'test-secret');
async function put(id, body, withToken = true) {
  const headers = { 'Content-Type': 'application/json' };
  if (withToken) headers.Authorization = `Bearer ${token()}`;
  const res = await fetch(`${base}/api/empleados/${id}`, {
    method: 'PUT',
    headers,
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

describe('PUT /api/empleados/:id', () => {
  it('401 sin token', async () => {
    const { status } = await put(7, { sede_id: 2 }, false);
    assert.equal(status, 401);
  });

  it('400 sin campos', async () => {
    const { status } = await put(7, {});
    assert.equal(status, 400);
  });

  it('404 inexistente', async () => {
    behavior.existe = false;
    const { status } = await put(999, { sede_id: 2 });
    assert.equal(status, 404);
  });

  it('400 listas inválidas', async () => {
    assert.equal((await put(7, { modalidad_laboral: 'X' })).status, 400);
    assert.equal((await put(7, { tipo_horario: 'X' })).status, 400);
    assert.equal((await put(7, { estado: 'X' })).status, 400);
  });

  it('400 cese anterior (nuevo y contra fecha existente)', async () => {
    assert.equal(
      (await put(7, { fecha_ingreso: '2026-09-01', fecha_cese: '2026-01-01' })).status,
      400
    );
    assert.equal((await put(7, { fecha_cese: '2025-01-01' })).status, 400);
  });

  it('404 sede y horario inexistentes', async () => {
    behavior.sedeExiste = false;
    assert.equal((await put(7, { sede_id: 999 })).status, 404);
    behavior.sedeExiste = true;
    behavior.horarioExiste = false;
    assert.equal((await put(7, { horario_id: 999 })).status, 404);
  });

  it('200 asigna sede (traslado)', async () => {
    const { status, body } = await put(7, { sede_id: 2 });
    assert.equal(status, 200);
    assert.equal(body.sede_id, 2);
  });

  it('200 asigna horario y desasigna sede', async () => {
    const { status, body } = await put(7, { horario_id: 20, sede_id: null });
    assert.equal(status, 200);
    assert.equal(body.horario_id, 20);
    assert.equal(body.sede_id, null);
  });

  it('409 codigo duplicado', async () => {
    behavior.dupError = true;
    const { status } = await put(7, { codigo_empleado: 'LUM-0001' });
    assert.equal(status, 409);
  });
});
