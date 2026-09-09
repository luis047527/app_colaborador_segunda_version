// Unit tests de servicios de validación: funciones puras, sin app ni DB.
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { validarGeo } = require('../services/sedes');
const sedSvc = require('../services/sedes');
const emp = require('../services/empleados');
const usr = require('../services/usuarios');

describe('services/sedes validarGeo', () => {
  it('acepta geo válida y campos ausentes', async () => {
    assert.equal(validarGeo({ latitud: -12.05, longitud: -77.04, radio_permitido_metros: 100 }), null);
    assert.equal(validarGeo({}), null);
  });

  it('rechaza rangos', async () => {
    assert.match(validarGeo({ latitud: 95 }), /latitud/);
    assert.match(validarGeo({ latitud: 'x' }), /latitud/);
    assert.match(validarGeo({ longitud: -200 }), /longitud/);
    assert.match(validarGeo({ radio_permitido_metros: 0 }), /radio/);
    assert.match(validarGeo({ radio_permitido_metros: -5 }), /radio/);
  });
});

describe('services/sedes orquestación', () => {
  const fila = (id) => ({
    id,
    nombre: 'Sede Norte',
    direccion: 'Av. Norte 456',
    latitud: -12.05,
    longitud: -77.04,
    radio_permitido_metros: 150,
    estado: 'ACTIVA',
  });

  let existe = true;
  const dbStub = {
    async query(sql, params) {
      if (sql.startsWith('INSERT INTO sedes')) return [{ insertId: 5 }];
      if (sql === 'SELECT * FROM sedes WHERE id = ?') return [existe ? [fila(params[0])] : []];
      if (sql === 'SELECT id FROM sedes WHERE id = ?') {
        return [existe ? [{ id: params[0] }] : []];
      }
      if (sql.startsWith('UPDATE sedes SET')) return [{ affectedRows: 1 }];
      throw new Error(`query no mockeada: ${sql}`);
    },
  };

  const NUEVA = {
    nombre: 'Sede Norte',
    direccion: 'Av. Norte 456',
    latitud: -12.05,
    longitud: -77.04,
    radio_permitido_metros: 150,
  };

  it('crearSede 201 con default ACTIVA', async () => {
    const r = await sedSvc.crearSede(dbStub, NUEVA);
    assert.equal(r.status, 201);
    assert.equal(r.data.id, 5);
    assert.equal(r.data.estado, 'ACTIVA');
  });

  it('actualizarSede 404 y 200', async () => {
    existe = false;
    assert.equal((await sedSvc.actualizarSede(dbStub, 999, { nombre: 'X' })).status, 404);
    existe = true;
    const r = await sedSvc.actualizarSede(dbStub, 1, { nombre: 'Sede Sur' });
    assert.equal(r.status, 200);
    assert.equal(r.data.id, 1);
  });
});

describe('services/empleados', () => {
  const base = () => ({
    usuario_id: 5,
    codigo_empleado: 'LUM-0004',
    cargo: 'Operario',
    modalidad_laboral: 'FULL_TIME',
    tipo_horario: 'FIJO',
    fecha_ingreso: '2026-09-09',
  });

  it('validarCreate ok y faltantes', async () => {
    assert.equal(emp.validarCreate(base()), null);
    assert.match(emp.validarCreate({}), /obligatorios/);
    assert.match(emp.validarCreate({ ...base(), modalidad_laboral: 'X' }), /modalidad/);
    assert.match(emp.validarCreate({ ...base(), tipo_horario: 'X' }), /tipo_horario/);
    assert.match(emp.validarCreate({ ...base(), estado: 'X' }), /estado/);
    assert.match(
      emp.validarCreate({ ...base(), fecha_ingreso: '2026-09-09', fecha_cese: '2026-01-01' }),
      /fecha_cese/
    );
  });

  it('validarUpdate usa valores efectivos', async () => {
    const fila = { fecha_ingreso: '2026-01-01', fecha_cese: null };
    assert.equal(emp.validarUpdate(fila, { cargo: 'Y' }), null);
    assert.match(emp.validarUpdate(fila, { modalidad_laboral: 'X' }), /modalidad/);
    assert.match(emp.validarUpdate(fila, { estado: 'X' }), /estado/);
    // cese nuevo vs ingreso existente
    assert.match(emp.validarUpdate(fila, { fecha_cese: '2025-01-01' }), /fecha_cese/);
    // ambos nuevos
    assert.match(
      emp.validarUpdate(fila, { fecha_ingreso: '2026-09-01', fecha_cese: '2026-01-01' }),
      /fecha_cese/
    );
  });
});

describe('services/usuarios', () => {
  it('validarCreate', async () => {
    const ok = { nombre: 'A', apellido: 'B', email: 'a@x.com', password: 'p', rol: 'COLABORADOR' };
    assert.equal(usr.validarCreate(ok), null);
    assert.match(usr.validarCreate({}), /obligatorios/);
    assert.match(usr.validarCreate({ ...ok, rol: 'JEFE' }), /rol/);
  });

  it('validarUpdate solo valores (privilegio vive en ruta)', async () => {
    assert.equal(usr.validarUpdate({ nombre: 'N' }), null);
    assert.match(usr.validarUpdate({ rol: 'X' }), /rol/);
    assert.match(usr.validarUpdate({ estado: 'X' }), /estado/);
  });
});

describe('services/usuarios orquestación', () => {
  const fila = () => ({
    id: 9,
    nombre: 'Ana',
    apellido: 'Rios',
    email: 'ana@x.com',
    password_hash: 'HASH',
    foto_url: null,
    rol: 'COLABORADOR',
    estado: 'ACTIVO',
  });

  let dup = false;
  let existe = true;
  let passActualizada = false;

  const dbStub = {
    async query(sql, params) {
      if (sql.includes('AND id <> ?')) return [dup ? [{ id: 3 }] : []];
      if (sql === 'SELECT id FROM usuarios WHERE email = ?') return [dup ? [{ id: 3 }] : []];
      if (sql.startsWith('INSERT INTO usuarios')) return [{ insertId: 9 }];
      if (sql.includes('FROM usuarios WHERE id = ?')) return [existe ? [fila()] : []];
      if (sql.startsWith('UPDATE usuarios SET password_hash')) {
        passActualizada = true;
        return [{ affectedRows: 1 }];
      }
      if (sql.startsWith('UPDATE usuarios SET')) return [{ affectedRows: 1 }];
      throw new Error(`query no mockeada: ${sql}`);
    },
  };

  it('crearUsuario 409 y 201 con hash', async () => {
    dup = true;
    const c409 = await usr.crearUsuario(dbStub, { email: 'a@x.com' });
    assert.equal(c409.status, 409);

    dup = false;
    const datos = {
      nombre: 'Ana',
      apellido: 'Rios',
      email: 'ana@x.com',
      password: 'Secreta123',
      rol: 'COLABORADOR',
    };
    const c201 = await usr.crearUsuario(dbStub, datos);
    assert.equal(c201.status, 201);
    assert.equal(c201.data.email, 'ana@x.com');
    assert.ok(!('password_hash' in c201.data));
  });

  it('actualizarUsuario 404, 409 y 200 + password', async () => {
    existe = false;
    assert.equal((await usr.actualizarUsuario(dbStub, 999, { nombre: 'X' })).status, 404);
    existe = true;

    dup = true;
    assert.equal((await usr.actualizarUsuario(dbStub, 9, { email: 'b@x.com' })).status, 409);
    dup = false;

    passActualizada = false;
    const r = await usr.actualizarUsuario(dbStub, 9, { nombre: 'N' }, 'Nueva123');
    assert.equal(r.status, 200);
    assert.ok(!('password_hash' in r.data));
    assert.equal(passActualizada, true);
  });
});
