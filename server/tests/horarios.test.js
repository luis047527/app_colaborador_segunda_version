// Tests para /api/horarios — sin DB real (pool + conexión mockeados).
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { once } = require('node:events');

process.env.JWT_SECRET = 'test-secret';

const tx = { begun: false, committed: false, rolledBack: false, released: false };
let diasInserts = 0;
let failDiasAt = -1;
let lastDias = [];

const behavior = {
  horario: {
    id: 50,
    nombre: 'FULL_TIME',
    descripcion: null,
    tolerancia_minutos: 10,
    vigencia_desde: '2026-01-01',
    vigencia_hasta: null,
  },
  dias: [],
};

const fakeConn = {
  async beginTransaction() {
    tx.begun = true;
  },
  async commit() {
    tx.committed = true;
  },
  async rollback() {
    tx.rolledBack = true;
  },
  async release() {
    tx.released = true;
  },
  async query(sql, params) {
    if (sql.startsWith('INSERT INTO horarios')) return [{ insertId: 50 }];
    if (sql.startsWith('INSERT INTO horario_dias')) {
      diasInserts += 1;
      if (diasInserts === failDiasAt) throw new Error('boom');
      lastDias.push(params);
      return [{ insertId: 100 + diasInserts }];
    }
    throw new Error(`conn query no mockeada: ${sql}`);
  },
};

const fakePool = {
  async getConnection() {
    return fakeConn;
  },
  async query(sql) {
    if (sql.startsWith('SELECT * FROM horarios WHERE id = ?')) {
      return [behavior.horario ? [behavior.horario] : []];
    }
    if (sql.includes('FROM horario_dias WHERE horario_id = ?')) {
      return [behavior.dias];
    }
    throw new Error(`pool query no mockeada: ${sql}`);
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
  tx.begun = tx.committed = tx.rolledBack = tx.released = false;
  diasInserts = 0;
  failDiasAt = -1;
  lastDias = [];
  behavior.horario = {
    id: 50,
    nombre: 'FULL_TIME',
    descripcion: null,
    tolerancia_minutos: 10,
    vigencia_desde: '2026-01-01',
    vigencia_hasta: null,
  };
  behavior.dias = [];
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

const dia = (dia_semana, entrada = '10:00', refI = '13:00', refF = '14:00', salida = '19:00') => ({
  dia_semana,
  entrada,
  ref_inicio: refI,
  ref_fin: refF,
  salida,
  es_descanso: 0,
});
const semanaFull = () => [
  ...[1, 2, 3, 4, 5, 6].map((d) => dia(d)),
  { dia_semana: 7, entrada: null, ref_inicio: null, ref_fin: null, salida: null, es_descanso: 1 },
];
const valido = () => ({ nombre: 'FULL_TIME', vigencia_desde: '2026-01-01', dias: semanaFull() });
const post = (body, withToken = true) => call('POST', '/api/horarios/', body, withToken);

describe('POST /api/horarios', () => {
  it('401 sin token', async () => {
    const { status } = await post(valido(), false);
    assert.equal(status, 401);
  });

  it('400 sin nombre ni vigencia', async () => {
    assert.equal((await post({ dias: semanaFull() })).status, 400);
    assert.equal((await post({ nombre: 'X', dias: semanaFull() })).status, 400);
  });

  it('400 dias incompletos', async () => {
    const dias = semanaFull().slice(0, 6);
    assert.equal((await post({ ...valido(), dias })).status, 400);
  });

  it('400 dia duplicado y fuera de rango', async () => {
    const dias = semanaFull();
    dias[1] = { ...dias[1], dia_semana: 1 };
    assert.match((await post({ ...valido(), dias })).body.error, /duplicado/);
    const dias2 = semanaFull();
    dias2[0] = { ...dias2[0], dia_semana: 8 };
    assert.equal((await post({ ...valido(), dias: dias2 })).status, 400);
  });

  it('400 overnight (salida <= entrada)', async () => {
    const dias = semanaFull();
    dias[0] = dia(1, '23:00', null, null, '07:00');
    const { status, body } = await post({ ...valido(), dias });
    assert.equal(status, 400);
    assert.match(body.error, /nocturno/);
  });

  it('400 refs incompletos o desordenados', async () => {
    const dias = semanaFull();
    dias[0] = dia(1, '10:00', '13:00', null, '19:00');
    assert.equal((await post({ ...valido(), dias })).status, 400);
    const dias2 = semanaFull();
    dias2[0] = dia(1, '10:00', '15:00', '14:00', '19:00');
    assert.match((await post({ ...valido(), dias: dias2 })).body.error, /orden/);
  });

  it('400 hora y tolerancia inválidas', async () => {
    const dias = semanaFull();
    dias[0] = dia(1, 'abc', null, null, '19:00');
    assert.equal((await post({ ...valido(), dias })).status, 400);
    assert.equal((await post({ ...valido(), tolerancia_minutos: -5 })).status, 400);
    assert.equal((await post({ ...valido(), tolerancia_minutos: 181 })).status, 400);
  });

  it('400 vigencia_hasta anterior', async () => {
    const { status } = await post({
      ...valido(),
      vigencia_desde: '2026-02-01',
      vigencia_hasta: '2026-01-01',
    });
    assert.equal(status, 400);
  });

  it('201 crea header + 7 dias en transacción', async () => {
    const dias = semanaFull();
    dias[0] = dia(1, '9:05', null, null, '19:00'); // formato corto -> normaliza
    const { status, body } = await post({ ...valido(), dias });
    assert.equal(status, 201);
    assert.equal(body.id, 50);
    assert.equal(body.dias.length, 7);
    assert.equal(body.dias[0].entrada, '09:05:00');
    assert.equal(body.dias[6].es_descanso, 1);
    assert.equal(tx.begun, true);
    assert.equal(tx.committed, true);
    assert.equal(tx.rolledBack, false);
    assert.equal(tx.released, true);
    assert.equal(diasInserts, 7);
  });

  it('500 con rollback si falla un dia', async () => {
    failDiasAt = 3;
    const { status } = await post(valido());
    assert.equal(status, 500);
    assert.equal(tx.committed, false);
    assert.equal(tx.rolledBack, true);
    assert.equal(tx.released, true);
  });
});

describe('GET /api/horarios/:id', () => {
  it('200 con dias', async () => {
    behavior.dias = semanaFull().map((d) => ({ ...d, es_descanso: d.es_descanso }));
    const { status, body } = await call('GET', '/api/horarios/50');
    assert.equal(status, 200);
    assert.equal(body.id, 50);
    assert.equal(body.dias.length, 7);
  });

  it('404 inexistente', async () => {
    behavior.horario = null;
    const { status } = await call('GET', '/api/horarios/999');
    assert.equal(status, 404);
  });
});
