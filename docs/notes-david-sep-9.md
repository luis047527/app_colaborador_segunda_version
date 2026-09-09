# Notes

- Database is created 
- Tables: usuarios, sedes, empleados (./server/sql/01_schema_login.sql)
- no table to horario
- constraints in database for usuarios: rol, estado
- constraints in database for sedes: estado
- constraints in database for empleados: tipo_horario
- constraints in database for empleados: estado
- will remove database constraints to allow evolve
- API endpoints created (grouped by routes): 
  - /health (check database connection)
  - /api/auth/login
  - GET /api/auth/usuarios/ 
  - POST /api/auth/usuarios/ 
  - GET /api/auth/usuarios/:id 
  - PUT /api/auth/usuarios/:id 
  - DELETE /api/auth/usuarios/:id 
- no endpoints to create usuarios
- POST /api/empleados/ (create empleado: usuario_id, codigo, cargo, modalidad, tipo_horario, sede_id?, horario_id?, fechas; validaciones en API)
- no endpoints to create sedes
- POST /api/horarios/ (header + 7 dias transaccional) + GET /api/horarios/:id; validaciones MVP en API (7 dias 1-7, salida>entrada, orden refs)
- no endpoints to assign usuario to sede
- no endpoints to assign usuario to horario
- API call directly to SQL, no controller, service, model layers

## Progress
- removed database constraints to allow evolve. Will handle validations in API
- kept mandatory only: PKs, NOT NULLs, uq_usuarios_email, uq_empleados_usuario/codigo, fk_empleados_usuario/sede RESTRICT, chk_empleados_fechas
- run `docker compose down -v` and `docker compose up --build` to get new database
- added Tests (`server/tests/`, `npm test`, pool mockeado): POST /api/auth/login, /api/usuarios, POST /api/empleados
- added Horarios endpoint  (/api/horarios/)
- added method to re-assign sede to empleado (PUT /api/empleados/)

## Horarios design (chat sep-9)
- Decision: 2 tables `horarios` (header) + `horario_dias` (7 rows per horario).
- Assignment: `empleados.horario_id FK NULL -> horarios.id`. One column = one horario per empleado. NULL allows empleado to exist before assignment. Many empleados can share one horario (3 templates); no UNIQUE on horario_id to allow reuse.
- `horario_dias.dia_semana TINYINT 1=Lun..7=Dom (ISO)`, `UNIQUE(horario_id, dia_semana)`. Lookup per marcacion: `WHERE horario_id=:id AND dia_semana=WEEKDAY(:fecha)+1`. Avoid DAYOFWEEK (US 1=Dom).
- One row per dia even if times repeat (dia 1,2 = 2 rows). 7 explicit rows simplifies query + per-day override.
- Split shift via `entrada | ref_ini | ref_fin | salida`. refs NULL = 2-marcacion day (part-time). Full-time / part-time / flexible are just different data, no schema change. Rotativo = N `horarios` rows with `vigencia_desde/hasta`, same detail shape.
- `horas_requeridas` NOT stored (varies per day in flexible). Computed: `(salida-entrada)-(ref_fin-ref_ini)`.
- `tolerancia_minutos SMALLINT` on `horarios` header. Rule: `real<entrada`=anticipada; `entrada<=real<=entrada+tol`=on-time; `real>entrada+tol`=tarde. Applies to ENTRADA (+REG_REF if wanted).
- Early arrival (ej. 09:45 vs 10:00 tol 10): accepted, llegada=anticipada 15m, store raw in marcaciones, clamp calc to 10:00 so balance ignores early minutes (no gaming).
- `marcaciones` (pending table): ENTRADA->SAL_REF->REG_REF->SALIDA with hora oficial server. Missing step = INCOMPLETA, no balance. descanso=1 => req 0 / estado DESCANSO.
- Overnight 23->07: convention salida<=entrada means +1 day in calc engine.
- Next: replace `empleados.tipo_horario VARCHAR` with `horario_id FK` when tables are created.

### Examples (horario_dias rows as dia | entrada | ref_ini | ref_fin | salida | descanso)
- Full-time Lun-Sab 10:00-13:00 + 14:00-19:00 (req 8h):
  - dias 1-6: `10:00 | 13:00 | 14:00 | 19:00 | 0` (6 rows, same times)
  - dia 7: `NULL | NULL | NULL | NULL | 1`
- Part-time Lun-Sab 15:00-19:00 (req 4h, no refrigerio):
  - dias 1-6: `15:00 | NULL | NULL | 19:00 | 0`
  - dia 7: `NULL | NULL | NULL | NULL | 1`
- Flexible (README): Lun-Mar 15-19, Mie 10-14, Jue-Vie 15-19, Sab 10-12:30+14:30-19:
  - dias 1,2: `15:00 | NULL | NULL | 19:00 | 0` (2 rows)
  - dia 3: `10:00 | NULL | NULL | 14:00 | 0` (req 4h)
  - dias 4,5: `15:00 | NULL | NULL | 19:00 | 0`
  - dia 6: `10:00 | 12:30 | 14:30 | 19:00 | 0` (req 7h = (12:30-10)+(19-14:30))
  - dia 7: descanso. Req varies per day, so never store single horas_requeridas on header.
- Rotativo Ene manana 07-15 / Feb tarde 15-23 / Mar noche 23-07:
  - 3 `horarios` rows same empleado, vigencia 2026-01-01->01-31, 02-01->02-28, 03-01->03-31.
  - each with its own 7 dias rows (dias 1-6 with that month's times).
  - API picks `WHERE hoy BETWEEN vigencia_desde AND vigencia_hasta`. Noche 23->07 uses overnight convention (+24h in calc).

### Tolerancia + marcacion examples (base Lun 10:00 | 13:00 | 14:00 | 19:00, tol 10, req 8h)
- Rule: limite=entrada+tol. real<entrada=anticipada; entrada<=real<=limite=on-time (tardanza 0); real>limite=tarde (tardanza=real-entrada). Store raw timestamp, clamp early minutes to programada for balance.
- Caso A puntual `10:02 ENTRADA | 13:00 SAL_REF | 14:00 REG_REF | 19:00 SALIDA`: on-time, trabajadas=(13:00-10:02)+(19:00-14:00)=7:58, balance -2m, jornada COMPLETA.
- Caso B tarde `10:25 ENTRADA | 13:05 SAL_REF | 14:02 REG_REF | 19:10 SALIDA`: tarde 15m, trabajadas=(13:05-10:25)+(19:10-14:02)=7:48, balance -12m.
- Caso C incompleta `10:00 ENTRADA | 13:00 SAL_REF | (falta REG_REF) | 19:00 SALIDA`: secuencia rota -> INCOMPLETA, sin balance, requiere correccion/admin.
- Early 09:45 vs 10:00 tol 10: aceptada, llegada=anticipada 15m, trabajadas se clampean a 10:00 -> balance ±0 (no gaming). Mismo criterio para Mie flexible (10:00) y Sab (10:00).
- Dia descanso (dia 7): marcacion se rechaza o marca estado DESCANSO, req=0, no genera balance negativo.

### MVP scope cut: no overnight
- Decision: `salida > entrada` always (same calendar day). Night shift 23->07 NOT supported in MVP.
- Enforcement: API-only (no DB CHECK per evolve decision). `POST/PUT /horarios` validates `salida > entrada` and `entrada <= ref_ini < ref_fin <= salida`, else 400. Calc engine assumes same-day, no +24h logic, no open-prev-day lookup.
- Consequence: rotativo Mar noche 23-07 unrepresentable for now (posterior, like §6 rotativos avanzados). Revisit = drop validation + add +24h convention, zero schema change.

