# Notes (sep-9)

## 1. Análisis inicial (estado encontrado)

### Base de datos
- Database creada; tablas `usuarios, sedes, empleados` (`sql/01_schema_login.sql`)
- Sin tabla de horario
- Constraints enum en DB: `usuarios(rol, estado)`, `sedes(estado)`, `empleados(tipo_horario, estado)`
- Decisión temprana: remover constraints enum para permitir evolve (solo mandatorios en DB)

### API encontrada (`server/routes/`)
- `GET /health`, `POST /api/auth/login`
- Usuarios CRUD en `/api/auth/usuarios/` (GET lista, POST, GET/PUT/DELETE `/:id`)
- Llamadas directas a SQL, sin capas controller/service/model
- Sin tests

### Gaps detectados
- Sin endpoints: crear empleado, sedes, horario, asignar sede/horario
- Sin validación de rol en rutas (cualquier logueado podía crear)
- Sin docs OpenAPI, sin versionado, listas sin paginar

## 2. Progress
- DB constraints: removidos CHECKs enum, validaciones en API. Mandatorios: PKs, NOT NULLs, `uq_usuarios_email`, `uq_empleados_usuario/codigo`, `fk_empleados_usuario/sede` RESTRICT, `chk_empleados_fechas`
- Nuevas tablas `horarios` + `horario_dias` (`sql/03_horarios.sql`); `empleados.horario_id FK NULL` (uno por empleado, compartible); `marcaciones` (`sql/04_marcaciones.sql`, índice empleado+fecha, sin UNIQUE a propósito)
- Rebuilds frescos vía `docker compose down -v && docker compose up --build` (6 tablas + seeds OK)
- API: `POST /api/empleados` + `PUT /api/empleados/:id` (traslado/asignar) + `GET …/horario-hoy`, `/api/sedes` CRUD (baja a INACTIVA), `POST /api/horarios` (header + 7 días transaccional) + `GET /api/horarios/:id`
- AuthZ: `server/middleware/roles.js` (escrituras ADMIN; lectura ADMIN/SUPERVISOR; COLABORADOR propio en GET/PUT usuarios + horario-hoy; sedes lectura abierta)
- Capas: `server/services/` (auth, horarios, sedes, empleados, usuarios) + `server/models/` (las 4 entidades); lecturas ruta→modelo, escrituras ruta→servicio→modelo; privilegio queda en ruta
- Tests (`npm test`, pool mockeado, sin DB ni deps nuevas): 109/109 — login (6), usuarios (16), empleados POST (12) + PUT (9), horarios (12), sedes (8), horario-hoy (9), docs (2), roles (8), servicios unit (27)
- Docs OpenAPI (JSDoc + swagger-ui): `/api-docs` y `/api-docs.json`; tests verifican 17 rutas
- MVP cuts (detalle: `docs/reglas_calculo.md`): sin overnight, anticipada clampeada, requeridas calculadas por día

## 3. TODO
- Supervisor (§5.2/§5.12): modelar (propuesta self-FK `empleados.supervisor_id`), endpoints asignar/consultar
- Marcaciones endpoints (Semana 2): POST/GET `/api/marcaciones` (diseño §5 + reglas en `docs/reglas_calculo.md`)
- Seeds: 3 horarios template (full/part/flexible) para piloto
- QR dinámico con token temporal (hoy estático `LUMIBELL-SEDE-{id}`)
- Versionado `/api/v1` antes de integrar Flutter; paginación en listados; rate-limit en login

## 4. Branch / release (PR #2 → main)
- PR #2 open, MERGEABLE/CLEAN, sin reviews: `feature/semana-1-backend` — falta review de Luis + merge
- Post-merge: tag anotado en `main` (`git tag -a v0.1.0 -m "..." && git push origin v0.1.0`), opcional Release como baseline del piloto
- Limpieza: borrar rama tras merge (local + remote); stale sin diff vs main: `feature/backend-node-mysql`, `feature/modulo-2-inicio`
- Siguiente rama desde `main` fresco: `feature/semana-2-marcaciones`

## 5. Decisiones técnicas

### Constraints: DB vs API
- CHECKs enum fuera (evolución = migration costosa con entrypoint de un solo uso); validan en API con listas versionadas en código; UNIQUEs/FKs/`chk_fechas` quedan (integridad no negociable)

### Esquema horario/marcación (cálculo: `docs/reglas_calculo.md`)
- `horario_dias`: `UNIQUE(horario_id, dia_semana)`, lookup `dia_semana=WEEKDAY(fecha Lima)+1` (no `DAYOFWEEK`)
- Sin overnight en MVP: `POST/PUT /horarios` valida `salida > entrada` (API-only); habilitar nocturnos = regla `+24h`, cero cambio de esquema
- Marcaciones: rechazos guardados con motivo (salvo JWT sin empleado — FK lo impide); POST toma empleado del JWT, nunca del body

### Capas y authz
- Servicios puros con `db` inyectada (testeables con stub); modelos SQL delgado; ownership/privilegio junto al middleware, no en servicios
- `horario-hoy`: doble lookup PK aceptado (ruta chequea ownership, servicio autocontenido testeable)
