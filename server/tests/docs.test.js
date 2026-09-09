// Tests de documentación OpenAPI: el spec debe exponer todas las rutas.
// No toca DB (solo sirve el JSON generado en require-time).
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');

const app = require('../index.js');

let server;
let base;
before(async () => {
  server = app.listen(0);
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

const ESPERADAS = {
  '/health': ['get'],
  '/api/auth/login': ['post'],
  '/api/usuarios/': ['get', 'post'],
  '/api/usuarios/{id}': ['get', 'put', 'delete'],
  '/api/empleados/': ['post'],
  '/api/empleados/{id}': ['put'],
  '/api/empleados/{id}/horario-hoy': ['get'],
  '/api/sedes/': ['get', 'post'],
  '/api/sedes/{id}': ['get', 'put', 'delete'],
  '/api/horarios/': ['post'],
  '/api/horarios/{id}': ['get'],
};

describe('OpenAPI', () => {
  it('GET /api-docs.json expone el spec completo', async () => {
    const res = await fetch(`${base}/api-docs.json`);
    assert.equal(res.status, 200);
    const spec = await res.json();
    assert.equal(spec.openapi, '3.0.0');
    assert.ok(spec.components.securitySchemes.bearerAuth);
    for (const [ruta, metodos] of Object.entries(ESPERADAS)) {
      assert.ok(spec.paths[ruta], `falta ruta ${ruta}`);
      for (const m of metodos) {
        assert.ok(spec.paths[ruta][m], `falta ${m.toUpperCase()} ${ruta}`);
      }
    }
  });

  it('GET /api-docs/ sirve la UI', async () => {
    const res = await fetch(`${base}/api-docs/`);
    assert.equal(res.status, 200);
    assert.match(res.headers.get('content-type'), /html/);
  });
});
