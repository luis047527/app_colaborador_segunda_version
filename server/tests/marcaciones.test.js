// Tests para POST /api/marcaciones (plan-semana-2 actividad 3) — pool mockeado.
// Contrato: QR estático por igualdad contra sedes.qr_valor; fuera de radio -> 403.
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { installPool, bootApp, token } = require('./helpers');

const QR = 'LUMIBELL-SEDE-1-AAAA1111';
const SEDE_LAT = -12.0464;
const SEDE_LON = -77.0428;

const empleadosPorUsuario = {
  5: { id: 3, usuario_id: 5, sede_id: 1, horario_id: 1, estado: 'ACTIVO' },
  7: { id: 7, usuario_id: 7, sede_id: null, horario_id: 1, estado: 'ACTIVO' },
  8: { id: 8, usuario_id: 8, sede_id: 1, horario_id: 1, estado: 'INACTIVO' },
  9: { id: 9, usuario_id: 9, sede_id: 3, horario_id: 1, estado: 'ACTIVO' },
  10: { id: 10, usuario_id: 10, sede_id: 99, horario_id: 1, estado: 'ACTIVO' },
  11: { id: 11, usuario_id: 11, sede_id: 4, horario_id: 1, estado: 'ACTIVO' },
  12: { id: 12, usuario_id: 12, sede_id: 1, horario_id: 1, estado: 'ACTIVO' },
};

const sedesPorId = {
  1: {
    id: 1, nombre: 'Sede Principal Lima', latitud: SEDE_LAT, longitud: SEDE_LON,
    radio_permitido_metros: 100, estado: 'ACTIVA', qr_valor: QR,
  },
  3: {
    id: 3, nombre: 'Sede Cerrada', latitud: SEDE_LAT, longitud: SEDE_LON,
    radio_permitido_metros: 100, estado: 'INACTIVA', qr_valor: 'LUMIBELL-SEDE-3-X',
  },
  4: {
    id: 4, nombre: 'Sede Sin QR', latitud: SEDE_LAT, longitud: SEDE_LON,
    radio_permitido_metros: 100, estado: 'ACTIVA', qr_valor: null,
  },
};

const TIPOS_COMPLETOS = ['ENTRADA', 'SALIDA_REFRIGERIO', 'REGRESO_REFRIGERIO', 'SALIDA'];

installPool(async (sql, params) => {
  if (sql.startsWith('SELECT id, usuario_id, sede_id, horario_id, estado FROM empleados WHERE usuario_id = ?')) {
    const row = empleadosPorUsuario[params[0]];
    return [row ? [row] : []];
  }
  if (sql.startsWith("SELECT tipo FROM marcaciones WHERE empleado_id = ?")) {
    if (params[0] === 12) return [TIPOS_COMPLETOS.map((tipo) => ({ tipo }))];
    return [[]];
  }
  if (sql.startsWith('SELECT * FROM sedes WHERE id = ?')) {
    const sede = sedesPorId[params[0]];
    return [sede ? [sede] : []];
  }
  if (sql.startsWith('INSERT INTO marcaciones')) {
    return [{ insertId: 101 }];
  }
  if (sql.startsWith('SELECT * FROM marcaciones WHERE id = ?')) {
    return [[{ id: 101, empleado_id: 3, tipo: 'ENTRADA', fuera_radio: 0, resultado: 'ACEPTADA' }]];
  }
  throw new Error(`query no mockeada: ${sql.slice(0, 120)} | params=${JSON.stringify(params)}`);
});

let server;
let base;
before(async () => {
  ({ server, base } = await bootApp());
});
after(() => server.close());

const post = async (payload, body) => {
  const headers = { 'Content-Type': 'application/json' };
  if (payload !== false) headers.Authorization = `Bearer ${token(payload)}`;
  const res = await fetch(`${base}/api/marcaciones`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body || {}),
  });
  return { status: res.status, body: await res.json().catch(() => null) };
};

const baseBody = () => ({ qr_token: QR, latitud: SEDE_LAT, longitud: SEDE_LON });
const COLAB = { sub: 5, rol: 'COLABORADOR' };

describe('POST /api/marcaciones', () => {
  it('401 sin token', async () => {
    const { status } = await post(false, baseBody());
    assert.equal(status, 401);
  });

  it('403 rol no colaborador', async () => {
    const { status } = await post({ sub: 1, rol: 'ADMINISTRADOR' }, baseBody());
    assert.equal(status, 403);
  });

  it('403 usuario sin perfil', async () => {
    const { status } = await post({ sub: 999, rol: 'COLABORADOR' }, baseBody());
    assert.equal(status, 403);
  });

  it('403 empleado inactivo', async () => {
    const { status } = await post({ sub: 8, rol: 'COLABORADOR' }, baseBody());
    assert.equal(status, 403);
  });

  it('400 sin sede asignada', async () => {
    const { status } = await post({ sub: 7, rol: 'COLABORADOR' }, baseBody());
    assert.equal(status, 400);
  });

  it('400 sede inactiva o inexistente', async () => {
    for (const sub of [9, 10]) {
      const { status } = await post({ sub, rol: 'COLABORADOR' }, baseBody());
      assert.equal(status, 400);
    }
  });

  it('400 sede sin QR generado', async () => {
    const { status, body } = await post({ sub: 11, rol: 'COLABORADOR' }, baseBody());
    assert.equal(status, 400);
    assert.match(body.error, /sin QR/);
  });

  it('400 QR inválido o ausente', async () => {
    for (const qr_token of [undefined, 'LUMIBELL-SEDE-1-OTRO', 'LUMIBELL-SEDE-2-AAAA1111']) {
      const { status } = await post(COLAB, { ...baseBody(), qr_token });
      assert.equal(status, 400);
    }
  });

  it('400 GPS inválido', async () => {
    const { status } = await post(COLAB, { qr_token: QR, latitud: 'x', longitud: SEDE_LON });
    assert.equal(status, 400);
  });

  it('403 fuera del radio permitido', async () => {
    const { status, body } = await post(COLAB, { qr_token: QR, latitud: -12.0, longitud: -77.0 });
    assert.equal(status, 403);
    assert.match(body.error, /radio/);
  });

  it('409 jornada completa', async () => {
    const { status } = await post({ sub: 12, rol: 'COLABORADOR' }, baseBody());
    assert.equal(status, 409);
  });

  it('201 QR + GPS ok: ENTRADA y siguiente SALIDA_REFRIGERIO', async () => {
    const { status, body } = await post(COLAB, baseBody());
    assert.equal(status, 201);
    assert.equal(body.marcacion.tipo, 'ENTRADA');
    assert.equal(body.marcacion.fuera_radio, 0);
    assert.equal(body.siguiente_marcacion, 'SALIDA_REFRIGERIO');
  });
});
