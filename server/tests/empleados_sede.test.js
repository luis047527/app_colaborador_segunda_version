// Tests para GET /api/empleados/me/sede (plan-semana-2 actividad 2) — pool mockeado.
// Contrato: coords + radio, nunca qr_valor; sede INACTIVA -> 404.
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { installPool, bootApp, token } = require('./helpers');

const empleadosPorUsuario = {
  5: { id: 3, sede_id: 1, estado: 'ACTIVO' }, // colaborador
  1: { id: 1, sede_id: 1, estado: 'ACTIVO' }, // admin (todos los roles)
  7: { id: 7, sede_id: null, estado: 'ACTIVO' }, // sin sede
  8: { id: 8, sede_id: 1, estado: 'INACTIVO' }, // inactivo
  9: { id: 9, sede_id: 3, estado: 'ACTIVO' }, // sede inactiva
  10: { id: 10, sede_id: 99, estado: 'ACTIVO' }, // sede inexistente
};

const sedesPorId = {
  1: {
    id: 1,
    nombre: 'Sede Principal Lima',
    latitud: '-12.0464000',
    longitud: '-77.0428000',
    radio_permitido_metros: '100.00',
    estado: 'ACTIVA',
    qr_valor: 'LUMIBELL-SEDE-1-AAAA1111',
  },
  3: {
    id: 3,
    nombre: 'Sede Cerrada',
    latitud: '-12.0000000',
    longitud: '-77.0000000',
    radio_permitido_metros: '50.00',
    estado: 'INACTIVA',
    qr_valor: 'LUMIBELL-SEDE-3-BBBB2222',
  },
};

installPool(async (sql, params) => {
  if (sql.startsWith('SELECT id, sede_id, estado FROM empleados WHERE usuario_id = ?')) {
    const row = empleadosPorUsuario[params[0]];
    return [row ? [row] : []];
  }
  if (sql.startsWith('SELECT * FROM sedes WHERE id = ?')) {
    const sede = sedesPorId[params[0]];
    return [sede ? [sede] : []];
  }
  throw new Error(`query no mockeada: ${sql.slice(0, 120)} | params=${JSON.stringify(params)}`);
});

let server;
let base;
before(async () => {
  ({ server, base } = await bootApp());
});
after(() => server.close());

const get = async (payload) => {
  const headers = {};
  if (payload !== false) headers.Authorization = `Bearer ${token(payload)}`;
  const res = await fetch(`${base}/api/empleados/me/sede`, { headers });
  return { status: res.status, body: await res.json().catch(() => null) };
};

describe('GET /api/empleados/me/sede', () => {
  it('401 sin token', async () => {
    const { status } = await get(false);
    assert.equal(status, 401);
  });

  it('404 usuario sin perfil', async () => {
    const { status, body } = await get({ sub: 999, rol: 'COLABORADOR' });
    assert.equal(status, 404);
    assert.equal(body.error, 'Usuario sin perfil de colaborador');
  });

  it('403 empleado inactivo', async () => {
    const { status } = await get({ sub: 8, rol: 'COLABORADOR' });
    assert.equal(status, 403);
  });

  it('404 sin sede asignada', async () => {
    const { status, body } = await get({ sub: 7, rol: 'COLABORADOR' });
    assert.equal(status, 404);
    assert.equal(body.error, 'Colaborador sin sede asignada');
  });

  it('404 sede inactiva', async () => {
    const { status, body } = await get({ sub: 9, rol: 'COLABORADOR' });
    assert.equal(status, 404);
    assert.equal(body.error, 'Sede no disponible');
  });

  it('404 sede inexistente', async () => {
    const { status } = await get({ sub: 10, rol: 'COLABORADOR' });
    assert.equal(status, 404);
  });

  it('200 colaborador: coords numéricas y sin qr_valor', async () => {
    const { status, body } = await get({ sub: 5, rol: 'COLABORADOR' });
    assert.equal(status, 200);
    assert.deepEqual(Object.keys(body).sort(), [
      'id',
      'latitud',
      'longitud',
      'nombre',
      'radio_permitido_metros',
    ]);
    assert.equal(body.nombre, 'Sede Principal Lima');
    assert.equal(typeof body.latitud, 'number');
    assert.equal(typeof body.longitud, 'number');
    assert.equal(typeof body.radio_permitido_metros, 'number');
    assert.ok(!('qr_valor' in body));
  });

  it('200 admin también autorizado (todos los roles)', async () => {
    const { status, body } = await get({ sub: 1, rol: 'ADMINISTRADOR' });
    assert.equal(status, 200);
    assert.equal(body.id, 1);
  });
});
