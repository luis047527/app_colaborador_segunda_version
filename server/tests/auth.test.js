// Tests para POST /api/auth/login/ — sin DB real (pool mockeado).
// El hash es el real del seed (password: Lumibell2026, bcrypt cost 10).
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { installPool, bootApp, req } = require('./helpers');

const SEED_HASH = '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C';

const baseUser = () => ({
  id: 1,
  nombre: 'Luis',
  apellido: 'Bello',
  email: 'admin@lumibell.com',
  password_hash: SEED_HASH,
  foto_url: null,
  rol: 'ADMINISTRADOR',
  estado: 'ACTIVO',
  ultimo_acceso: null,
  created_at: '2026-01-01 00:00:00',
  updated_at: '2026-01-01 00:00:00',
});

// Control por test: qué devuelve el SELECT de login.
let loginRow = baseUser();
let updatedAcceso = 0;

installPool(async (sql) => {
  if (sql.startsWith('SELECT * FROM usuarios WHERE email = ?')) {
    return [loginRow ? [loginRow] : []];
  }
  if (sql.startsWith('UPDATE usuarios SET ultimo_acceso')) {
    updatedAcceso += 1;
    return [{ affectedRows: 1 }];
  }
  throw new Error(`query no mockeada: ${sql}`);
});

let server;
let base;
before(async () => {
  ({ server, base } = await bootApp());
});
after(() => server.close());

const login = (body) => req(base, 'POST', '/api/auth/login', body, false);

describe('POST /api/auth/login', () => {
  it('400 sin email ni password', async () => {
    const { status } = await login({});
    assert.equal(status, 400);
  });

  it('400 sin password', async () => {
    const { status } = await login({ email: 'admin@lumibell.com' });
    assert.equal(status, 400);
  });

  it('401 email inexistente', async () => {
    loginRow = null;
    const { status, body } = await login({ email: 'nadie@x.com', password: 'y' });
    assert.equal(status, 401);
    assert.equal(body.error, 'Credenciales inválidas');
    loginRow = baseUser();
  });

  it('401 password incorrecta', async () => {
    const { status } = await login({ email: 'admin@lumibell.com', password: 'Wrong2026' });
    assert.equal(status, 401);
  });

  it('403 usuario INACTIVO', async () => {
    loginRow = { ...baseUser(), estado: 'INACTIVO' };
    const { status, body } = await login({
      email: 'admin@lumibell.com',
      password: 'Lumibell2026',
    });
    assert.equal(status, 403);
    assert.equal(body.error, 'Usuario inactivo');
    loginRow = baseUser();
  });

  it('200 éxito: token, sin password_hash, registra acceso', async () => {
    updatedAcceso = 0;
    const { status, body } = await login({
      email: 'admin@lumibell.com',
      password: 'Lumibell2026',
    });
    assert.equal(status, 200);
    assert.ok(body.token);
    assert.equal(body.usuario.email, 'admin@lumibell.com');
    assert.ok(!('password_hash' in body.usuario));
    assert.equal(updatedAcceso, 1);
  });
});
