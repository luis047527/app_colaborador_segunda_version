// Unit tests del servicio de auth: stub de DB, bcrypt/jwt reales.
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { validarLoginInput, autenticar } = require('../services/auth');

const SEED_HASH = '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C';

const baseUser = () => ({
  id: 1,
  nombre: 'Luis',
  email: 'admin@lumibell.com',
  password_hash: SEED_HASH,
  rol: 'ADMINISTRADOR',
  estado: 'ACTIVO',
});

let fila = baseUser();
let accesos = 0;
const SECRET = 'test-secret';

const dbStub = {
  async query(sql) {
    if (sql.startsWith('SELECT * FROM usuarios WHERE email = ?')) {
      return [fila ? [fila] : []];
    }
    if (sql.startsWith('UPDATE usuarios SET ultimo_acceso')) {
      accesos += 1;
      return [{ affectedRows: 1 }];
    }
    throw new Error(`query no mockeada: ${sql}`);
  },
};

const login = (body) => autenticar(dbStub, body, { jwtSecret: SECRET });

describe('services/auth', () => {
  it('validarLoginInput', async () => {
    assert.equal(validarLoginInput({}), 'email y password son obligatorios');
    assert.equal(validarLoginInput({ email: 'a@x.com' }), 'email y password son obligatorios');
    assert.equal(
      validarLoginInput({ email: 'a@x.com', password: 'p' }),
      null
    );
  });

  it('401 usuario inexistente o password mala', async () => {
    fila = null;
    assert.equal((await login({ email: 'x@y.com', password: 'p' })).status, 401);
    fila = baseUser();
    const r = await login({ email: 'admin@lumibell.com', password: 'Wrong2026' });
    assert.equal(r.status, 401);
    assert.equal(r.error, 'Credenciales inválidas');
  });

  it('403 inactivo con mensaje en minúsculas', async () => {
    fila = { ...baseUser(), estado: 'BLOQUEADO' };
    const r = await login({ email: 'admin@lumibell.com', password: 'Lumibell2026' });
    assert.equal(r.status, 403);
    assert.equal(r.error, 'Usuario bloqueado');
    fila = baseUser();
  });

  it('200 token + sin hash + registra acceso', async () => {
    accesos = 0;
    const r = await login({ email: 'admin@lumibell.com', password: 'Lumibell2026' });
    assert.equal(r.status, 200);
    assert.ok(r.data.token);
    assert.equal(r.data.usuario.email, 'admin@lumibell.com');
    assert.ok(!('password_hash' in r.data.usuario));
    assert.equal(accesos, 1);
  });

  it('propaga error de DB (ruta => 500)', async () => {
    const rota = {
      async query() {
        throw new Error('down');
      },
    };
    await assert.rejects(autenticar(rota, { email: 'a', password: 'b' }, { jwtSecret: SECRET }));
  });
});
