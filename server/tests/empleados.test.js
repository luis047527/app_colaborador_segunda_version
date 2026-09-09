// Tests para POST /api/empleados/ — runner built-in (node --test), sin dependencias.
// Se mockea ../db.js (pool mysql) vía require.cache antes de cargar la app,
// así no se necesita MySQL corriendo. Ejecutar: npm test
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { once } = require('node:events');

process.env.JWT_SECRET = 'test-secret';

// --- Mock del pool -----------------------------------------------------------
const dbBehavior = {
  usuarioExiste: true,
  empleadoExistente: false,
  sedeExiste: true,
  horarioExiste: true,
  insertError: null,
};
let lastInsert = null;

const fakePool = {
  async query(sql, params) {
    if (sql.includes('FROM usuarios WHERE id = ?')) {
      return [dbBehavior.usuarioExiste ? [{ id: params[0] }] : []];
    }
    if (sql.includes('FROM empleados WHERE usuario_id = ?')) {
      return [dbBehavior.empleadoExistente ? [{ id: 7 }] : []];
    }
    if (sql.includes('FROM sedes WHERE id = ?')) {
      return [dbBehavior.sedeExiste ? [{ id: params[0] }] : []];
    }
    if (sql.includes('FROM horarios WHERE id = ?')) {
      return [dbBehavior.horarioExiste ? [{ id: params[0] }] : []];
    }
    if (sql.startsWith('INSERT INTO empleados')) {
      if (dbBehavior.insertError) throw dbBehavior.insertError;
      lastInsert = params;
      return [{ insertId: 99 }];
    }
    if (sql.includes('FROM empleados WHERE id = ?')) {
      const [
        usuario_id,
        codigo_empleado,
        cargo,
        modalidad_laboral,
        tipo_horario,
        sede_id,
        horario_id,
        fecha_ingreso,
        fecha_cese,
        estado,
      ] = lastInsert;
      return [
        [
          {
            id: 99,
            usuario_id,
            codigo_empleado,
            cargo,
            modalidad_laboral,
            tipo_horario,
            sede_id,
            horario_id,
            fecha_ingreso,
            fecha_cese,
            estado,
          },
        ],
      ];
    }
    throw new Error(`query no mockeada: ${sql}`);
  },
};

const dbPath = path.join(__dirname, '..', 'db.js');
require.cache[dbPath] = { id: dbPath, filename: dbPath, loaded: true, exports: fakePool };

const jwt = require('jsonwebtoken');
const app = require('../index.js');

// --- Servidor efímero ---------------------------------------------------------
let server;
let base;
before(async () => {
  server = app.listen(0);
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

beforeEach(() => {
  dbBehavior.usuarioExiste = true;
  dbBehavior.empleadoExistente = false;
  dbBehavior.sedeExiste = true;
  dbBehavior.horarioExiste = true;
  dbBehavior.insertError = null;
  lastInsert = null;
});

const token = () => jwt.sign({ sub: 1, rol: 'ADMINISTRADOR' }, 'test-secret');

async function postEmpleado(body, withToken = true) {
  const headers = { 'Content-Type': 'application/json' };
  if (withToken) headers.Authorization = `Bearer ${token()}`;
  const res = await fetch(`${base}/api/empleados/`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

const valido = () => ({
  usuario_id: 5,
  codigo_empleado: 'LUM-0004',
  cargo: 'Operario',
  modalidad_laboral: 'FULL_TIME',
  tipo_horario: 'FIJO',
  fecha_ingreso: '2026-09-09',
});

// --- Tests --------------------------------------------------------------------
describe('POST /api/empleados/', () => {
  it('401 sin token', async () => {
    const { status, body } = await postEmpleado(valido(), false);
    assert.equal(status, 401);
    assert.equal(body.error, 'Token no proporcionado');
  });

  it('400 si faltan campos obligatorios', async () => {
    const { status } = await postEmpleado({ nombre: 'x' });
    assert.equal(status, 400);
  });

  it('400 modalidad_laboral inválida', async () => {
    const { status, body } = await postEmpleado({ ...valido(), modalidad_laboral: 'NOCTURNO' });
    assert.equal(status, 400);
    assert.match(body.error, /modalidad_laboral/);
  });

  it('400 tipo_horario inválido', async () => {
    const { status } = await postEmpleado({ ...valido(), tipo_horario: 'LIBRE' });
    assert.equal(status, 400);
  });

  it('400 fecha_cese anterior a fecha_ingreso', async () => {
    const { status } = await postEmpleado({
      ...valido(),
      fecha_ingreso: '2026-09-09',
      fecha_cese: '2026-01-01',
    });
    assert.equal(status, 400);
  });

  it('404 usuario inexistente', async () => {
    dbBehavior.usuarioExiste = false;
    const { status, body } = await postEmpleado(valido());
    assert.equal(status, 404);
    assert.equal(body.error, 'Usuario no encontrado');
  });

  it('409 usuario ya tiene empleado', async () => {
    dbBehavior.empleadoExistente = true;
    const { status } = await postEmpleado(valido());
    assert.equal(status, 409);
  });

  it('404 sede inexistente', async () => {
    dbBehavior.sedeExiste = false;
    const { status } = await postEmpleado({ ...valido(), sede_id: 999 });
    assert.equal(status, 404);
  });

  it('404 horario inexistente', async () => {
    dbBehavior.horarioExiste = false;
    const { status } = await postEmpleado({ ...valido(), horario_id: 999 });
    assert.equal(status, 404);
  });

  it('201 crea con defaults (estado ACTIVO, sede/horario null)', async () => {
    const { status, body } = await postEmpleado(valido());
    assert.equal(status, 201);
    assert.equal(body.id, 99);
    assert.equal(body.codigo_empleado, 'LUM-0004');
    assert.equal(body.estado, 'ACTIVO');
    assert.equal(body.sede_id, null);
    assert.equal(body.horario_id, null);
    assert.equal(body.fecha_cese, null);
  });

  it('201 crea con sede, horario y cese', async () => {
    const { status, body } = await postEmpleado({
      ...valido(),
      sede_id: 1,
      horario_id: 20,
      fecha_cese: '2026-12-31',
      estado: 'INACTIVO',
    });
    assert.equal(status, 201);
    assert.equal(body.sede_id, 1);
    assert.equal(body.horario_id, 20);
    assert.equal(body.fecha_cese, '2026-12-31');
    assert.equal(body.estado, 'INACTIVO');
  });

  it('409 codigo duplicado (carrera contra UNIQUE)', async () => {
    dbBehavior.insertError = { code: 'ER_DUP_ENTRY' };
    const { status } = await postEmpleado(valido());
    assert.equal(status, 409);
  });
});
