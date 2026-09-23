# AGENTS.md — Guide for Coding Agents (Lumibell App Colaborador)

> **For humans and AI agents** fixing issues like *endpoint nomenclature* (`mio` → `me`, `horario-hoy` → `?fecha`) as done in `docs/notes-david-sep-22.md:47`.

## 1. Project Stack & Commands

* **Stack:** Flutter 3.29 (`lib/`) → Node 20 + Express (`server/`) → MySQL 8 (`sql/00..05`, `Dockerfile.db`) → Docker Compose (`docker-compose.yml`).
* **Fresh dev DB:** `npm run db:reset` (`server/package.json:5` → `bash ../scripts/reset-db.sh`) == `docker compose down -v && up --build -d` + health checks. Incremental: `npm run db:apply` / `bash ../scripts/apply-db-scripts.sh`. Never edit `mysql_data` directly.
* **API:** JWT (`Authorization: Bearer`), roles `ADMINISTRADOR > SUPERVISOR > COLABORADOR` (`server/middleware/roles.js:3`), `server/index.js:67` mounts `/api/auth`, `/api/usuarios`, `/api/empleados`, `/api/horarios`, `/api/sedes`, `/api/marcaciones`. Swagger UI `GET /api-docs`, spec `GET /api-docs.json` (`server/docs/swagger.js:22`).
* **Tests:** `docker exec node_server npm test` (or `docker-compose build server && up -d && npm test`) — `node --test` (no extra deps), now `124` pass. Flutter: `flutter analyze` (no errors, 10 `info` deprecated `value` allowed).
* **Coverage:** `coverage/` is gitignored (` .gitignore:49`); don’t commit `lcov.info`.

## 2. Semana Cadence (source of truth)

`docs/Alcance_Funcional_Lumibell_MVP_1_mes.md:54`:
* **Semana 1 — Base técnica:** gestión usuarios, horarios personalizados, reglas/estados. Completed via `GET /api/empleados` (`home`), `GET /api/horarios`, `POST /horarios`, etc.
* **Semana 2 — Marcación:** `POST /marcaciones/qr/sede/:id`, `GET /marcaciones/mio`, `POST /marcaciones` (QR `LUMIBELL-SEDE-{id}` static, GPS `fuera_radio`, secuencia — see `docs/reglas_calculo.md:66`).
* **Semana 3-4:** cálculo/historial/balance, vacaciones.

Complete Semana N before N+1. Mark `docs/notes-david-sep-22.md` audit + TODOs.

## 3. REST API Guidelines (fixing nomenclature)

**Rule: nouns, plural, hierarchy, query for filters/qualifiers.**

| Bad (fixed) | Good | Why |
|---|---|---|
| `GET /api/empleados/mio` (pronoun) | `GET /api/empleados/me` (`server/routes/empleados.js:115`) | Standard alias `me`/`self` for current `JWT` user; pronouns like `mio` are non-standard, order-dependent (`mio` before `:id` or shadowing). Even Spanish APIs use `me`. |
| `GET /api/empleados/mio/horario-semanal` | `GET /api/empleados/me/horario` | `horario` resource, not `horario-semanal` qualifier-in-path. Weekly is default for `me/horario`; if needed `?view=semanal`. |
| `GET /api/empleados/:id/horario-hoy` | `GET /api/empleados/:id/horario?fecha=YYYY-MM-DD` (`&date=` alias, default `hoy` Lima) (`server/routes/empleados.js:179`) | Qualifier `hoy` belongs in query, not path. Allows `?fecha=2026-01-05` for tests (`400` on invalid), cacheable per date. |
| `GET /api/horarios` list mixed singular/plural | Keep plural `horarios` for collection, singular `horario` for sub-resource under `empleados` is intentional hierarchical (`horario` belongs to `empleado`). Don’t mix `horarios` vs `horario` at same level. |
| Verb in path | Never `POST /crearEmpleado`; use `POST /api/empleados/` | Use HTTP methods. |

**Checklist for any endpoint change:**

1. **Audit:** `grep -r "/api/" server/routes lib/ docs/` + `docker exec node_server node -e "require('./docs/swagger')" | Object.keys(paths)` vs `server/tests/docs.test.js:23` `ESPERADAS`.
2. **Propose:** If non-canonical, propose REST-pure `me`/`?fecha` alternative; decide deprecation vs breaking. For breaking after FE migrated (as with `mio` → `me` now unused), **remove** legacy aliases (see `f76b87a`).
3. **Implement:** Edit `server/routes/<resource>.js` — extract handlers (`handleGetMe`, `handleGetMeHorario`, `handleGetHorarioById`) for reuse if keeping aliases, or remove aliases entirely. Order static `me` before `:id` in Express. Validate `?fecha` (`new Date(fecha+'T12:00:00')`, `400` if `NaN`).
4. **OpenAPI:** Add `/** @openapi */` above route (see `empleados.js:115` for `GET /me`). For removed aliases, drop `@openapi` so spec shrinks. Verify via `docker-compose build server && curl /api-docs.json`.
5. **Flutter:** `grep -r "/api/empleados" lib/` — update all call sites (`perfil_colaborador_screen.dart:27`, `asistencia_screen.dart:27,30`, `mi_horario_screen.dart:23`). Keep no legacy references.
6. **Tests:** Add `server/tests/<resource>_*.test.js` — mock `pool` via `require.cache[../db.js]`, test `401`/`403`/`404`/`200` + alias parity or `400` for bad `fecha`, update `docs.test.js` `ESPERADAS`. Mock must match SQL strings (`LEFT JOIN horarios h ON...`, `WHERE e.usuario_id = ?`). Run `docker exec node_server npm test` (expect `124`+).
7. **Docs:** Update `docs/notes-david-sep-22.md` with Follow-up section (why necessary for Semana N per `Alcance:54`, commits, file:line refs, verification `curl` commands). Update `README.md` if dev workflow changes.
8. **Verify:** `docker-compose down -v && up --build -d` → `SHOW TABLES`, `curl` new endpoint `200`, `curl` old alias `404` (if removed), `flutter analyze`.

## 4. Handling Legacy Aliases

* **Before FE migrated:** keep both, mark `deprecated: true` in `@openapi` (as done with `mio` in `3417a69`), so `GET /api-docs.json` shows both.
* **After `grep` shows zero FE hits:** remove route, `@openapi`, and `docs.test` expectation in one commit (`f76b87a` removed `mio`/`horario-hoy` → `124` pass, spec clean). Don’t leave dead `deprecated` spec if unused — it confuses agents.

## 5. Common Fixes (register of issues solved)

* **Home `500` → `200`:** `GET /api/empleados` `LEFT JOIN horarios` threw `ER_NO_SUCH_TABLE` due to stale `mysql_data` (only `01..04` copied, `horario_id` missing) — fixed via `sql/00_init-db.sql` + `Dockerfile.db:11` + `reset-db.sh` (`docs/notes-david-sep-22.md:5`). Always use `npm run db:reset` for schema changes.
* **Missing `GET /api/empleados` docs/tests:** added `empleados.js:19` OpenAPI + `empleados_get.test.js` (`5c3dd62`).
* **Pronoun/qualifier:** `mio` → `me`, `horario-hoy` → `?fecha` (`3417a69` → `f76b87a`).
* **Undocumented `GET /api/horarios/` list:** added `horarios.js:64` OpenAPI (`7169fa6`), still needs `GET` list test (`TODO`).
* **Untested marcaciones (Semana 2):** `POST /qr/sede/:id`, `GET /mio`, `POST /` lack `@openapi` + `marcaciones.test.js` — next task (`notes-david-sep-22.md:57` audit).

## 6. When to Ask

* If Semana N scope unclear → re-read `Alcance §4` table `342` (`Gestión de usuarios`, etc.) before adding endpoint.
* If unsure to keep legacy alias → `grep -r "oldPath" lib/ server/tests` — zero hits + spec deprecated → remove; otherwise keep `deprecated: true` one commit.

## 7. Commit Style (for agents)

* `fix(data): ...`, `feat(empleados): ...`, `docs: ...`, `chore: ...`, `refactor(empleados): ...` with file:line refs (`server/routes/empleados.js:115`) and verification commands (`docker exec node_server npm test`, `curl /api-docs.json`).

— End of `AGENTS.md` (see also `docs/REST_API_GUIDELINES.md` if exists, and `docs/notes-david-sep-22.md` for latest audit). Update this file when conventions evolve.
