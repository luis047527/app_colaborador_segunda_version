// Harness compartido: mock del pool mysql + app en puerto efímero + JWT.
// Cada archivo *.test.js corre en su propio proceso, así que no hay fugas
// de require.cache entre suites.
const path = require('node:path');
const { once } = require('node:events');

process.env.JWT_SECRET = 'test-secret';

function installPool(handler) {
  const dbPath = path.join(__dirname, '..', 'db.js');
  require.cache[dbPath] = {
    id: dbPath,
    filename: dbPath,
    loaded: true,
    exports: { query: handler },
  };
}

async function bootApp() {
  const app = require('../index.js');
  const server = app.listen(0);
  await once(server, 'listening');
  return { server, base: `http://127.0.0.1:${server.address().port}` };
}

const jwt = require('jsonwebtoken');
const token = (payload = { sub: 1, rol: 'ADMINISTRADOR' }) =>
  jwt.sign(payload, 'test-secret');

async function req(base, method, url, body, withToken = true) {
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

module.exports = { installPool, bootApp, token, req };
