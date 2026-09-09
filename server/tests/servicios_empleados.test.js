// Unit tests de orquestación de empleados: stub de DB, fecha fija.
const { describe, it, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const svc = require('../services/empleados');
const { diaSemanaLima } = require('../utils/fecha');

const flags = {
  usuarioExiste: true,
  asignado: false,
  sedeExiste: true,
  horarioExiste: true,
  dupInsert: false,
  dupUpdate: false,
  empRow: null,
  asignacion: { id: 7, usuario_id: 5, horario_id: 20 },
  header: { id: 20, nombre: 'FULL_TIME' },
  dia: {
    dia_semana: 3,
    entrada: '10:00:00',
    ref_inicio: '13:00:00',
    ref_fin: '14:00:00',
    salida: '19:00:00',
    es_descanso: 0,
  },
};

const dbStub = {
  async query(sql, params) {
    if (sql.startsWith('SELECT id, usuario_id, horario_id FROM empleados WHERE id = ?')) {
      return [flags.asignacion ? [flags.asignacion] : []];
    }
    if (sql === 'SELECT id FROM empleados WHERE usuario_id = ?') {
      return [flags.asignado ? [{ id: 7 }] : []];
    }
    if (sql === 'SELECT id FROM sedes WHERE id = ?') {
      return [flags.sedeExiste ? [{ id: params[0] }] : []];
    }
    if (sql === 'SELECT id FROM horarios WHERE id = ?') {
      return [flags.horarioExiste ? [{ id: params[0] }] : []];
    }
    if (sql.startsWith('INSERT INTO empleados')) {
      if (flags.dupInsert) throw { code: 'ER_DUP_ENTRY' };
      return [{ insertId: 42 }];
    }
    if (sql === 'SELECT * FROM empleados WHERE id = ?') {
      return [flags.empRow ? [{ ...flags.empRow, id: params[0] }] : []];
    }
    if (sql.startsWith('UPDATE empleados SET')) {
      if (flags.dupUpdate) throw { code: 'ER_DUP_ENTRY' };
      return [{ affectedRows: 1 }];
    }
    if (sql === 'SELECT * FROM usuarios WHERE id = ?') {
      return [flags.usuarioExiste ? [{ id: params[0] }] : []];
    }
    if (sql.startsWith('SELECT * FROM horarios WHERE id = ?')) {
      return [flags.header ? [flags.header] : []];
    }
    if (sql.includes('FROM horario_dias WHERE horario_id = ?')) {
      return [flags.dia ? [flags.dia] : []];
    }
    throw new Error(`query no mockeada: ${sql}`);
  },
};

const reset = () => {
  flags.usuarioExiste = true;
  flags.asignado = false;
  flags.sedeExiste = true;
  flags.horarioExiste = true;
  flags.dupInsert = false;
  flags.dupUpdate = false;
  flags.empRow = { id: 7, usuario_id: 5, codigo_empleado: 'LUM-0007', estado: 'ACTIVO' };
  flags.asignacion = { id: 7, usuario_id: 5, horario_id: 20 };
  flags.header = { id: 20, nombre: 'FULL_TIME' };
  flags.dia = {
    dia_semana: 3,
    entrada: '10:00:00',
    ref_inicio: '13:00:00',
    ref_fin: '14:00:00',
    salida: '19:00:00',
    es_descanso: 0,
  };
};

const HOY = new Date('2026-09-09T15:00:00Z'); // 10:00 Lima
const NUEVO = {
  usuario_id: 5,
  codigo_empleado: 'LUM-0042',
  cargo: 'Operario',
  modalidad_laboral: 'FULL_TIME',
  tipo_horario: 'FIJO',
  fecha_ingreso: '2026-09-09',
};

describe('services/empleados crearEmpleado', () => {
  beforeEach(reset);

  it('404 usuario, 409 asignado, 404 sede/horario', async () => {
    flags.usuarioExiste = false;
    assert.equal((await svc.crearEmpleado(dbStub, NUEVO)).status, 404);
    flags.usuarioExiste = true;

    flags.asignado = true;
    assert.equal((await svc.crearEmpleado(dbStub, NUEVO)).status, 409);
    flags.asignado = false;

    flags.sedeExiste = false;
    assert.equal((await svc.crearEmpleado(dbStub, { ...NUEVO, sede_id: 9 })).status, 404);
    flags.sedeExiste = true;

    flags.horarioExiste = false;
    assert.equal((await svc.crearEmpleado(dbStub, { ...NUEVO, horario_id: 9 })).status, 404);
    flags.horarioExiste = true;
  });

  it('201 con defaults y 409 en carrera', async () => {
    const r = await svc.crearEmpleado(dbStub, NUEVO);
    assert.equal(r.status, 201);
    assert.equal(r.data.id, 42);

    flags.dupInsert = true;
    assert.equal((await svc.crearEmpleado(dbStub, NUEVO)).status, 409);
  });
});

describe('services/empleados actualizarEmpleado', () => {
  beforeEach(reset);

  it('404, 404 horario y 409 duplicado', async () => {
    flags.empRow = null;
    assert.equal((await svc.actualizarEmpleado(dbStub, 999, { cargo: 'X' })).status, 404);
    flags.empRow = { id: 7 };

    flags.horarioExiste = false;
    assert.equal((await svc.actualizarEmpleado(dbStub, 7, { horario_id: 9 })).status, 404);
    flags.horarioExiste = true;

    flags.dupUpdate = true;
    assert.equal((await svc.actualizarEmpleado(dbStub, 7, { codigo_empleado: 'X' })).status, 409);
  });

  it('200 devuelve fila', async () => {
    const r = await svc.actualizarEmpleado(dbStub, 7, { sede_id: 2 });
    assert.equal(r.status, 200);
    assert.equal(r.data.id, 7);
  });
});

describe('services/empleados horarioHoy', () => {
  beforeEach(reset);

  it('404 sin empleado, sin horario y sin detalle', async () => {
    flags.asignacion = null;
    assert.equal((await svc.horarioHoy(dbStub, 999, HOY)).status, 404);
    flags.asignacion = { id: 7, usuario_id: 5, horario_id: null };
    assert.match((await svc.horarioHoy(dbStub, 7, HOY)).error, /sin horario/);
    flags.asignacion = { id: 7, usuario_id: 5, horario_id: 20 };
    flags.dia = null;
    assert.match((await svc.horarioHoy(dbStub, 7, HOY)).error, /detalle/);
  });

  it('200 con requeridas según día', async () => {
    const r = await svc.horarioHoy(dbStub, 7, HOY);
    assert.equal(r.status, 200);
    assert.equal(r.data.fecha, '2026-09-09');
    assert.equal(r.data.dia_semana, diaSemanaLima(HOY));
    assert.equal(r.data.horas_requeridas_min, 480);

    flags.dia = { ...flags.dia, entrada: null, ref_inicio: null, ref_fin: null, salida: null, es_descanso: 1 };
    assert.equal((await svc.horarioHoy(dbStub, 7, HOY)).data.horas_requeridas_min, 0);
  });
});
