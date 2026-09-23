// Tests para GET /api/empleados (home Admin), /me y /me/horario (REST-pure) — pool mockeado.
// Semana 1: base técnica debe exponer home (lista operativa) y perfil/horario semanal del colaborador.
// Cubre regresión del 500 por JOIN horarios (horario_id) y autorización por rol.
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { once } = require('node:events');

process.env.JWT_SECRET = 'test-secret';

// --- Estado mockeado ---------------------------------------------------------
const empleadosRows = [
  {
    id: 4,
    usuario_id: 4,
    codigo_empleado: 'LUM-0004',
    cargo: 'Asistente',
    modalidad_laboral: 'FULL_TIME',
    tipo_horario: 'FIJO',
    sede_id: 1,
    horario_id: 1,
    estado: 'ACTIVO',
    nombre: 'Ana',
    apellido: 'Torres',
    email: 'ana@x.com',
    rol: 'COLABORADOR',
    sede_nombre: 'Sede Principal Lima',
    horario_nombre: 'Horario Oficina 08:00 - 17:00',
  },
  {
    id: 1,
    usuario_id: 1,
    codigo_empleado: 'LUM-0001',
    cargo: 'Admin',
    modalidad_laboral: 'FULL_TIME',
    tipo_horario: 'FIJO',
    sede_id: 1,
    horario_id: null,
    estado: 'ACTIVO',
    nombre: 'Luis',
    apellido: 'Bello',
    email: 'admin@x.com',
    rol: 'ADMINISTRADOR',
    sede_nombre: 'Sede Principal Lima',
    horario_nombre: null,
  },
];

let mioRow = {
  id: 3,
  usuario_id: 5,
  codigo_empleado: 'LUM-0003',
  cargo: 'Operario',
  modalidad_laboral: 'PART_TIME',
  tipo_horario: 'FLEXIBLE',
  sede_id: 1,
  horario_id: 2,
  estado: 'ACTIVO',
  nombre: 'Carlos',
  apellido: 'Colaborador',
  email: 'colaborador@x.com',
  foto_url: null,
  rol: 'COLABORADOR',
  sede_nombre: 'Sede Principal Lima',
  sede_direccion: 'Av. Principal 123',
  horario_nombre: 'Part Time',
  tolerancia_minutos: 5,
};

let horarioSemanal = {
  horario: { id: 2, nombre: 'Part Time', tolerancia_minutos: 5 },
  dias: [
    { dia_semana: 1, entrada: '09:00:00', salida: '14:00:00', es_descanso: 0 },
    { dia_semana: 7, entrada: null, salida: null, es_descanso: 1 },
  ],
};

let empleadoHorarioId = { horario_id: 2 };

const fakePool = {
  async query(sql, params) {
    // GET /api/empleados (list) — must contain LEFT JOIN horarios h ON h.id = e.horario_id
    if (sql.includes('FROM empleados e JOIN usuarios u') && sql.includes('LEFT JOIN horarios h')) {
      return [empleadosRows];
    }
    // GET /mio — WHERE e.usuario_id = ?
    if (sql.includes('WHERE e.usuario_id = ?') && sql.includes('foto_url')) {
      if (params[0] === 999) return [[]];
      return [[mioRow]];
    }
    // GET /mio/horario-semanal — SELECT horario_id FROM empleados WHERE usuario_id = ?
    if (sql.includes('SELECT horario_id FROM empleados WHERE usuario_id = ?')) {
      if (params[0] === 999) return [[]];
      if (params[0] === 998) return [[{ horario_id: null }]];
      return [[empleadoHorarioId]];
    }
    // Horarios.buscarPorId / listarDias via models/horarios
    if (sql.startsWith('SELECT * FROM horarios WHERE id = ?')) {
      if (params[0] === 999) return [[]];
      return [[horarioSemanal.horario]];
    }
    if (sql.includes('FROM horario_dias WHERE horario_id = ?')) {
      return [horarioSemanal.dias];
    }
    throw new Error(`query no mockeada: ${sql.slice(0, 120)} | params=${JSON.stringify(params)}`);
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
  mioRow = {
    id: 3,
    usuario_id: 5,
    codigo_empleado: 'LUM-0003',
    cargo: 'Operario',
    modalidad_laboral: 'PART_TIME',
    tipo_horario: 'FLEXIBLE',
    sede_id: 1,
    horario_id: 2,
    estado: 'ACTIVO',
    nombre: 'Carlos',
    apellido: 'Colaborador',
    email: 'colaborador@x.com',
    foto_url: null,
    rol: 'COLABORADOR',
    sede_nombre: 'Sede Principal Lima',
    sede_direccion: 'Av. Principal 123',
    horario_nombre: 'Part Time',
    tolerancia_minutos: 5,
  };
  empleadoHorarioId = { horario_id: 2 };
  horarioSemanal = {
    horario: { id: 2, nombre: 'Part Time', tolerancia_minutos: 5 },
    dias: [
      { dia_semana: 1, entrada: '09:00:00', salida: '14:00:00', es_descanso: 0 },
      { dia_semana: 7, entrada: null, salida: null, es_descanso: 1 },
    ],
  };
});

const token = (payload = { sub: 1, rol: 'ADMINISTRADOR' }) => jwt.sign(payload, 'test-secret');
async function get(url, payload) {
  const headers = {};
  if (payload !== false) headers.Authorization = `Bearer ${token(payload)}`;
  const res = await fetch(`${base}${url}`, { headers });
  return { status: res.status, body: await res.json().catch(() => null) };
}

// --- Tests -------------------------------------------------------------------
describe('GET /api/empleados (home Admin/Supervisor)', () => {
  it('401 sin token', async () => {
    const { status, body } = await get('/api/empleados/', false);
    assert.equal(status, 401);
    assert.equal(body.error, 'Token no proporcionado');
  });

  it('403 COLABORADOR no autorizado', async () => {
    const { status, body } = await get('/api/empleados/', { sub: 5, rol: 'COLABORADOR' });
    assert.equal(status, 403);
    assert.match(body.error, /No autorizado/);
  });

  it('200 ADMIN lista con sede_nombre/horario_nombre (regresión JOIN horarios)', async () => {
    const { status, body } = await get('/api/empleados/', { sub: 1, rol: 'ADMINISTRADOR' });
    assert.equal(status, 200);
    assert.ok(Array.isArray(body));
    assert.equal(body.length, 2);
    assert.equal(body[0].sede_nombre, 'Sede Principal Lima');
    assert.equal(body[0].horario_nombre, 'Horario Oficina 08:00 - 17:00');
    // segundo sin horario debe venir con null, no 500
    assert.equal(body[1].horario_nombre, null);
  });

  it('200 SUPERVISOR también autorizado', async () => {
    const { status } = await get('/api/empleados/', { sub: 2, rol: 'SUPERVISOR' });
    assert.equal(status, 200);
  });
});

describe('GET /api/empleados/me', () => {
  it('401 sin token', async () => {
    const { status } = await get('/api/empleados/me', false);
    assert.equal(status, 401);
  });

  it('404 usuario sin perfil', async () => {
    const { status, body } = await get('/api/empleados/me', { sub: 999, rol: 'COLABORADOR' });
    assert.equal(status, 404);
    assert.equal(body.error, 'Usuario sin perfil de colaborador');
  });

  it('200 retorna empleado del JWT con sede y horario', async () => {
    const { status, body } = await get('/api/empleados/me', { sub: 5, rol: 'COLABORADOR' });
    assert.equal(status, 200);
    assert.equal(body.codigo_empleado, 'LUM-0003');
    assert.equal(body.sede_nombre, 'Sede Principal Lima');
    assert.equal(body.horario_nombre, 'Part Time');
  });
});

describe('GET /api/empleados/me/horario', () => {
  it('401 sin token', async () => {
    const { status } = await get('/api/empleados/me/horario', false);
    assert.equal(status, 401);
  });

  it('404 sin perfil', async () => {
    const { status } = await get('/api/empleados/me/horario', { sub: 999, rol: 'COLABORADOR' });
    assert.equal(status, 404);
  });

  it('404 sin horario asignado', async () => {
    const { status, body } = await get('/api/empleados/me/horario', { sub: 998, rol: 'COLABORADOR' });
    assert.equal(status, 404);
    assert.match(body.error, /sin horario/);
  });

  it('200 horario con dias', async () => {
    const { status, body } = await get('/api/empleados/me/horario', { sub: 5, rol: 'COLABORADOR' });
    assert.equal(status, 200);
    assert.equal(body.id, 2);
    assert.ok(Array.isArray(body.dias));
    assert.ok(body.dias.length >= 2);
  });
});
