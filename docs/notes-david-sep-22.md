# Notes — 2026-09-22 (home 500 + fresh dev DB)

## Current status (before fix)
- `AdminHomeScreen` (`lib/screens/inicio/admin_home_screen.dart:25` → `GET /api/empleados`) returned `500 {"error":"Error interno del servidor"}`. Curl with valid `ADMIN` JWT reproduced it.
- Root cause: stale volume `mysql_data` prevented `docker-entrypoint-initdb.d` re-run. `Dockerfile.db:10` only copied `01..04` (missing `05`); lexical order was `01..05` then `init-db.sql` (root) last (`'0' < 'i'`), so init ran late. Live DB had only `usuarios, sedes, empleados` without `empleados.horario_id` and without tables `horarios/horario_dias/marcaciones` → `server/routes/empleados.js:19` query `LEFT JOIN horarios h ON h.id = e.horario_id` threw `ER_NO_SUCH_TABLE`/`ER_BAD_FIELD_ERROR` swallowed by `catch (_)` → generic 500 (`server/index.js:69`).
- `sql/02_seed_login.sql:5` was non-idempotent (`INSERT VALUES`) — second apply via scripts failed on `uq_usuarios_email`/`uq_empleados_codigo`.
- `scripts/apply-db-scripts.sh:19` / `.ps1:17` only handled `01`+`02`, not `03..05`.

## Fix applied (commit `30fa4ac` `fix(data): ensure fresh dev DB follows schema...`)

### 1. Init ordering & fresh build
- Renamed `init-db.sql` → `sql/00_init-db.sql:1` and deleted root `init-db.sql`. `Dockerfile.db:11` now `COPY sql/00_init-db.sql sql/01_schema_login.sql sql/02_seed_login.sql sql/03_horarios.sql sql/04_marcaciones.sql sql/05_seed_demo_colaboradores_horarios.sql /docker-entrypoint-initdb.d/` — lexical `00..05` guarantees deterministic init. Verified `docker exec mysql_db ls -1 /docker-entrypoint-initdb.d` → `00..05` and `docker-compose down -v && up --build` creates 6 tables + `horario_id` column.
- Verified `SHOW TABLES` → `empleados, horario_dias, horarios, marcaciones, sedes, usuarios`; `DESCRIBE empleados` has `horario_id` FK; seed counts `5 usuarios / 5 empleados / 2 horarios / 14 horario_dias`.

### 2. Idempotent seeds (why old dates kept fixed)
- `sql/02_seed_login.sql:5` rewritten to `INSERT ... SELECT ... WHERE NOT EXISTS (SELECT 1 FROM sedes WHERE nombre=...)` / `WHERE email=...` / `WHERE codigo_empleado=...` and resolves `sede_id`/`usuario_id` dynamically via sub-select. Fixed historical hire dates `2024-01-15`, `2024-02-01`, `2024-03-10` **kept as-is** because they are past tenure data — stable for sorting/tenure tests and `chk_empleados_fechas`. Making them `CURRENT_DATE` would make every reset produce moving dates and flaky snapshots. This was confirmed with user: “old dates can be fixed. they are test data so it's not important.”
- `sql/05_seed_demo_colaboradores_horarios.sql:6` stays `CURRENT_DATE` / `DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY)` for demo vigencia/marcaciones — intentionally relative to today so historial shows “ayer/anteayer” after each reset.

### 3. Incremental apply scripts
- `scripts/apply-db-scripts.sh:15` / `scripts/apply-db-scripts.ps1:14` now handle `00..05`: `has_table()` / `Has-Table()` + `has_column()` checks against `information_schema`, `00+01` only if `usuarios` missing, `02` always (idempotent), `03` if `horarios` missing or `empleados.horario_id` missing (covers stale volumes), `04` if `marcaciones` missing, `05` always. Verified idempotent — two consecutive runs keep counts `5/5/2` and `GET /api/empleados` stays `200`.

### 4. Deterministic dev reset helpers
- Added `scripts/reset-db.sh:1` / `scripts/reset-db.ps1:1` (`chmod +x`) — `docker compose down -v && up --build -d` + `mysqladmin ping` wait + `SHOW TABLES` + `curl /health` check. Handles `docker compose` vs `docker-compose` fallback. Documented in `README.md:103`.

### 5. Docs & observability
- `README.md:82` Option 2 now references `sql/00_init-db.sql → 05_*`; `README.md:103` Option 3 and `## Datos frescos en dev` explain `down` (keeps data) vs `down -v` (fresh) and `reset-db.sh/ps1` vs incremental `apply-db-scripts`.
- `server/routes/empleados.js:27` changed `catch (_) {500}` → `catch (err) { console.error('GET /api/empleados error:', err); 500 }` so next `ER_*` surfaces in `docker logs node_server`.

## Verification
```bash
docker-compose down -v && docker-compose up --build -d
# wait healthy, then
docker exec mysql_db mysql -uappuser -papppassword -e "SHOW TABLES; DESCRIBE empleados;" appdb
curl -s http://localhost:3000/health            # {"status":"ok","db":"up"}
TOKEN=$(docker exec node_server node -e "console.log(require('jsonwebtoken').sign({sub:1,rol:'ADMINISTRADOR'},process.env.JWT_SECRET))")
curl -s http://localhost:3000/api/empleados -H "Authorization: Bearer $TOKEN" # 200, 5 rows
# incremental idempotency
./scripts/apply-db-scripts.sh && ./scripts/apply-db-scripts.sh
```
Also tested `GET /api/empleados/mio`, `/mio/horario-semanal`, `/:id/horario-hoy` for `COLABORADOR` after fix — all `200`.

## Follow-up 1 — Semana 1 home docs/tests (commit `5c3dd62`) — endpoint `/api/empleados` was Semana 1
- **Why necessary for Semana 1:** per `docs/Alcance_Funcional_Lumibell_MVP_1_mes.md:54` Semana 1 = “Gestión de usuarios colaboradores” + “base técnica preparada”. `GET /api/empleados/` (`server/routes/empleados.js:38` `requerirRol('ADMINISTRADOR','SUPERVISOR')` + `LEFT JOIN sede/horario`) is the lista operativa for `AdminHomeScreen` (`lib/screens/inicio/admin_home_screen.dart:25` → resumen equipo + `ColaboradoresScreen`). Without it Semana 1 cannot show home “Resumen del equipo” nor validate `horario_id` FK fix. Criterio audit: Semana 1 must be completable before Semana 2 marcaciones — we verified `docs/Alcance_Funcional_Lumibell_MVP_1_mes.md:342` `Gestión de usuarios ☐ → ☑` depends on this list.
- Checked Semana 1: `GET /api/empleados` lacked `@openapi` and tests (while `POST /api/empleados` already had). Also `GET /mio` + `/mio/horario-semanal` lacked docs for perfil/horario flows but were pre-existing for Semana 1.
- Added `server/routes/empleados.js:19` `GET /` OpenAPI (`ADMIN/SUPERVISOR`, `LEFT JOIN horarios`), and retained `server/routes/empleados.js:30`/`48` for `/mio` + `/mio/horario-semanal` (now deprecated aliases, see Follow-up 2).
- Created `server/tests/empleados_get.test.js:1` (11 tests: `401`/`403`/`200` + JOIN `horario_id` regression for `/`) and updated `server/tests/docs.test.js:23` (`/api/empleados/` `get`+`post`, `/mio`, `/mio/horario-semanal`). Tests `109→120` pass, spec exposes new paths. This completes Semana 1 base técnica for home.

## Follow-up 2 — REST-pure refactor `me`/`horario` (commit `3417a69`)
- Audited `GET /api/empleados/mio` (`:30`) and `/:id/horario-hoy` (`:138`) against REST: pronoun `mio` non-standard (should be `me`), qualifier-in-path `horario-hoy` should be `?fecha`, `horario-semanal` hyphen + nesting `mio/horario-semanal` order-dependent (`mio` before `:id` or shadowing), singular/plural `horario` vs `horarios` collection.
- Implemented REST-pure with backward `deprecated: true` aliases:
  - `GET /api/empleados/me` (`server/routes/empleados.js:115` → `handleGetMe`) replaces `/mio` (`:133` alias)
  - `GET /api/empleados/me/horario` (`:148` → `handleGetMeHorario`) replaces `/mio/horario-semanal` (`:162` alias)
  - `GET /api/empleados/:id/horario` (`:179` → `handleGetHorarioById` with `?fecha`/`?date` default today Lima, `400` on invalid) replaces `/:id/horario-hoy` (`:207` alias), adds ownership `COLABORADOR` check + date injection into `services/empleados.horarioHoy(pool,id,hoy)`
- Updated Flutter to new endpoints: `lib/screens/perfil/perfil_colaborador_screen.dart:27` `/me`, `lib/screens/asistencia/asistencia_screen.dart:27,30` `/me` + `/:id/horario`, `lib/screens/horarios/mi_horario_screen.dart:23,24,31` similarly.
- Tests: extended `server/tests/empleados_get.test.js:24` with `GET /me` and `GET /me/horario` parity checks, `server/tests/horario_hoy.test.js:1` added suite `GET /:id/horario` (`?fecha`, `?date`, `400`, `403`); `server/tests/docs.test.js:23` now expects `/me`, `/me/horario`, `/{id}/horario` plus legacy. `120→130` pass, `GET /api-docs.json` lists both new and deprecated, `curl` verified `200` for `ADMIN`/`COLABORADOR` and `500` regression fixed, `flutter analyze` clean (`analysis_options.yaml` exclude added).

## Follow-up 3 — `GET /api/horarios/` docs gap (commit `7169fa6`)
- **Why it existed but was unchecked:** `GET /api/horarios/` (`server/routes/horarios.js:64` `requerirRol('ADMINISTRADOR','SUPERVISOR')` + `SELECT * ORDER BY id DESC`) is required for Semana 1 assignment UI (`HorariosScreen` lists horarios to assign), yet only `POST /api/horarios/` (`:29`) and `GET /api/horarios/:id` (`:88`) had `@openapi`. `server/tests/horarios.test.js:125` covered `POST` + `GET/:id`, `server/tests/docs.test.js:23` `ESPERADAS` omitted `GET /api/horarios/`, so `GET /api-docs.json` lacked `get` for `/api/horarios/`.
- Added `server/routes/horarios.js:64` `@openapi` `GET /api/horarios/` (`ADMIN/SUPERVISOR`, `200` array of horario headers). Verified `docker exec node_server node -e "require('./docs/swagger')"` lists `get` for `/api/horarios/` and `curl /api-docs.json` now shows it; rebuilt `server` image and confirmed `GET /api/horarios/` works via existing `horarios.test` coverage (no new test yet — TODO below).

## Follow-up 4 — `npm run db:reset` + remove unused legacy aliases (commit `f76b87a`)
- **Why `npm run db:reset`:** `README.md:103` documented `./scripts/reset-db.sh` but no npm alias. Semana 1 asked to add `npm run db:reset` for coding agents/devs. Added `server/package.json:5` `scripts: { "db:reset": "bash ../scripts/reset-db.sh", "db:apply": "bash ../scripts/apply-db-scripts.sh" }` — now `npm run db:reset` (from `server/`) == `docker compose down -v && up --build` with health checks.
- **Why remove unused endpoints:** after `3417a69` REST-pure migration, Flutter now uses only `GET /api/empleados/me` (`lib/screens/perfil/perfil_colaborador_screen.dart:27`), `GET /me/horario` (`mi_horario_screen.dart:31`), `GET /:id/horario` (`mi_horario_screen.dart:24`, `asistencia_screen.dart:30`). Legacy aliases `GET /mio` (`server/routes/empleados.js:133`), `GET /mio/horario-semanal` (`:162`), `GET /:id/horario-hoy` (`:207`) became unused — verified via `grep -r "/api/empleados" lib/` returns zero hits for `mio`/`horario-hoy`. Removed them (`server/routes/empleados.js:62` deletions) to keep API surface REST-pure and avoid confusion for agents.
- **Tests/docs cleanup:** updated `server/tests/docs.test.js:23` `ESPERADAS` to drop `mio`/`horario-hoy` (now expects `/me`, `/me/horario`, `/{id}/horario` only), and `server/tests/empleados_get.test.js:1` + `server/tests/horario_hoy.test.js:1` to drop legacy `mio` alias suites — `130→124` pass, `GET /api-docs.json` no longer lists `mio`/`horario-hoy`, `docker-compose build server && npm test` still green. Rebuilt image and `curl` verified new endpoints still `200`.

## Endpoint audit 2026-09-22 — pending Semana 2 (update f76b87a)
- **Semana 1 fully checked** (via `server/index.js:67` + `swagger` + `tests`): `/health`, `POST /api/auth/login`, `/api/usuarios/` (+`/{id}`), `/api/empleados/` (+`/me`/`/me/horario`), `/api/sedes/`, `/api/horarios/` (`GET` + `POST` + `GET /{id}`) — all have `@openapi` and `node --test` (`124` pass after legacy removal; `GET /api/horarios/` docs added `7169fa6`, dedicated list test still to add — see TODO).
- **Semana 2 to be checked (marcaciones, per `docs/Alcance_Funcional_Lumibell_MVP_1_mes.md:66` Semana 2 — QR dinámico/GPS/validación/secuencia):** endpoints exist but **unchecked** (no `@openapi`, no `server/tests/marcaciones.test.js`):
  - `POST /api/marcaciones/qr/sede/:sedeId` (`server/routes/marcaciones.js:12` `requerirRol('ADMINISTRADOR','SUPERVISOR')` → `Sedes.buscarFila` + `crearQr`)
  - `GET /api/marcaciones/mio?desde&hasta` (`:20` `requerirRol('COLABORADOR')`, default `hasta=today`, `desde=hasta-30d`, `400` if `desde>hasta`)
  - `POST /api/marcaciones` (`:51` `requerirRol('COLABORADOR')` → `registrar(pool, req.usuario.sub)`)
  - Need for Semana 2: add `@openapi` (security, `qr_token`/`latitud`/`longitud`, responses `201`/`400`/`403`/`404`), add `server/tests/marcaciones.test.js` mocking `pool` + `Marcaciones` model (QR `LUMIBELL-SEDE-{id}` static, GPS `fuera_radio`, secuencia `ENTRADA`→`SALIDA_REFRIGERIO`→`REGRESO`→`SALIDA`) per `docs/reglas_calculo.md:66` and `docs/notes-david-sep-9.md:35`, and extend `server/tests/docs.test.js:23` `ESPERADAS` + `roles.test.js:118` for marcaciones.

## Follow-up 5 — coding agents doc (question from user 2026-09-22)
- User asked: “we're using coding agents. should we add a document for agents to solve issues like endpoints nomenclature that we fixed recently ?” — added `AGENTS.md:1` (`1da7ea7`) per approval 2026-09-22, committed.

## Pending — evidence for approval from Luis about calcs for Semana 1
- **Semana 1 calcs in scope:** per `docs/Alcance_Funcional_Lumibell_MVP_1_mes.md:54` + `docs/reglas_calculo.md:66` — base técnica defines `horario` model (`horarios` + `horario_dias`, `empleados.horario_id`), tolerancia, `horas requeridas = salida-entrada - (ref_fin-ref_inicio)`, `horas trabajadas`/`balance` placeholders, and `GET /api/empleados/:id/horario?fecha` calculation in `server/services/empleados.js:131` `horarioHoy` + `server/models/horarios.js`. These were not yet formally approved by Luis (Product Owner).
- **Evidence needed:** written sign-off from Luis (comment in PR `frontend-mvp-usuarios-horarios-marcacion`, or email/Slack thread, or approval comment on `docs/reglas_calculo.md` / `docs/notes-david-sep-9.md:5`). Until then Semana 1 cannot be marked *approved* even though `124` tests pass. Track as blocker.
- **Next step:** request Luis review of `docs/reglas_calculo.md` + `GET /api/empleados/:id/horario` sample payload (`fecha`, `horas_requeridas_min`, `tolerancia_minutos`) and capture screenshot/link in this note.

## TO DO — Semana 1 (remaining to close Semana 1)
- [x] Fix data script and config to have fresh data when re-building containers
- [x] Semana 1 home endpoints documented & tested
- [x] REST-pure `me`/`horario` with deprecated aliases; FE migrated → then aliases removed (`f76b87a`)
- [x] `coverage/` removed & added to `.gitignore:49` (`6bb687a`)
- [x] `GET /api/horarios/` OpenAPI added (`7169fa6`); remaining: add dedicated `GET /api/horarios/` test (list `200`/`401`/`403`)
- [x] `npm run db:reset` alias added (`server/package.json:5` `f76b87a`)
- [x] Remove unused legacy empleados aliases (`f76b87a`, spec now clean)
- [x] Agents doc added (`AGENTS.md:1` — `1da7ea7`, per user approval 2026-09-22)
- [ ] Pending evidence from Luis about calcs for Semana 1 (see above) — blocker to mark Semana 1 approved
- [ ] `GET /api/horarios/` list test (last Semana 1 gap)

## Next iteration — Semana 2 (after Semana 1 approved)
> Not a TODO for current Semana 1. Track here per `Alcance §4 Semana 2 — Marcación` to start only after Semana 1 is approved.

- Semana 2: check `marcaciones` endpoints audited above (`POST /api/marcaciones/qr/sede/:sedeId`, `GET /api/marcaciones/mio`, `POST /api/marcaciones`) — add `@openapi` + `server/tests/marcaciones.test.js` + `docs.test.js`/`roles.test.js` asserts per `docs/reglas_calculo.md:66`.

