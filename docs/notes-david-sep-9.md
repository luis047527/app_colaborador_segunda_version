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
- /api/sedes CRUD (GET/POST/PUT/DELETE lógico a INACTIVA; valida geo + estado en API)
- POST /api/horarios/ (header + 7 dias transaccional) + GET /api/horarios/:id; validaciones MVP en API (7 dias 1-7, salida>entrada, orden refs)
- PUT /api/empleados/:id (traslado sede / asignar horario / editar campos; validaciones en API)
- GET /api/empleados/:id/horario-hoy (horario del día: fecha Lima, fila del dia, horas_requeridas_min; COLABORADOR solo el suyo)
- API call directly to SQL, no controller, service, model layers

## Progress
- DB constraints: removed enum CHECKs, validations moved to API. Kept mandatory only: PKs, NOT NULLs, uq_usuarios_email, uq_empleados_usuario/codigo, fk_empleados_usuario/sede RESTRICT, chk_empleados_fechas (`sql/01_schema_login.sql`)
- New tables `horarios` + `horario_dias` (`sql/03_horarios.sql`, wired in `Dockerfile.db`); `empleados.horario_id FK NULL` (one horario per empleado, NULL = unassigned)
- Fresh rebuild applied via `docker compose down -v && docker compose up --build` (no migration needed, DB was fresh)
- API: POST /api/empleados + PUT /api/empleados/:id (sede/horario assignment, traslado) + GET /api/empleados/:id/horario-hoy, /api/sedes CRUD (DELETE lógico a INACTIVA), POST /api/horarios (header + 7 dias transaccional) + GET /api/horarios/:id
- Marcaciones tabla `04_marcaciones.sql` wired en `Dockerfile.db`, rebuild aplicado (6 tablas + seeds OK)
- Tests (`server/tests/`, `npm test`, pool mockeado, sin DB ni deps nuevas): 74/74 — login (6), usuarios (16), empleados POST (12) + PUT (9), horarios (12), sedes (8), horario-hoy (9), docs (2)
- Docs OpenAPI (JSDoc en rutas + swagger-ui): UI en /api-docs, JSON en /api-docs.json; tests verifican las 17 rutas
- MVP cuts (detalle abajo): sin overnight (`salida > entrada`), llegada anticipada se clampeada a programada, `horas_requeridas` calculadas por dia (no almacenadas)
- **Frontend Semana 1** (`feature/semana-1-frontend-test` 60cae68): scaffold `HomeScreen` (Inicio/Horario/Perfil + `Admin` role-based), `Inicio/ Horario/ Perfil` placeholders, `AuthService` `http.Client` injection; tests `test/` 21/21 (usuario 2, auth 6, app_config 1, login 5, home 3, inicio/perfil 3, app 1) + `flutter analyze` clean. Ver §5.
- **Frontend admin CRUD** (361f9a5): `usuario/sede/empleado/horario` services (`lib/services/*_service.dart`) + 5 admin screens (`lib/screens/admin/` create_usuario/sede/empleado/horario + assign_horario + menu) + `Home` Admin tab (ADMIN 4 tabs). Tests 32/32 (services 7 + admin_menu 4 + previos 21). Ver §6.
- **Cómo testear frontend (completo):** `export PATH="/usr/local/flutter/bin:$PATH" && flutter pub get && flutter analyze && flutter test --reporter expanded && flutter test --coverage` (esperado 32 passed, lcov 100% core). Smoke admin: `docker compose up --build -d` + `flutter run --dart-define=API_BASE_URL=http://localhost:3000` (web) / `10.0.2.2` (emulador) loguear `admin@lumibell.com / Lumibell2026` → `Admin` → crear flujo `Sede → Horario (7 dias) → Usuario → Empleado → Asignar` → verificar `horario-hoy`.

## TODO
- Supervisor (§5.2/§5.12): modelar (propuesta self-FK `empleados.supervisor_id`), endpoints asignar/consultar
- Role guards: middleware solo-ADMIN en escrituras (hoy cualquier logueado puede crear); SUPERVISOR lectura + COLABORADOR solo lo suyo (horario-hoy ya lo aplica)
- Marcaciones endpoints (Semana 2): POST/GET /api/marcaciones sobre tabla 04 (diseño en "Marcaciones decisions")
- Seeds: 3 horarios template (full/part/flexible) para piloto
- QR dinámico con token temporal (hoy estático `LUMIBELL-SEDE-{id}`)

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

## Marcaciones decisions (chat sep-9)
- Table `marcaciones` (`sql/04_marcaciones.sql`): empleado_id FK, fecha DATE (jornada Lima), tipo (API list), timestamp_utc DATETIME (hora oficial), sede_id FK, lat/lon, distancia_metros, fuera_radio flag, resultado ACEPTADA/RECHAZADA + motivo. Index (empleado_id, fecha); NO unique (empleado, fecha, tipo) a propósito.
- Hora oficial: UTC en DB (`timestamp_utc DEFAULT CURRENT_TIMESTAMP`, contenedor sin TZ fija). `fecha` Lima se deriva en API (Intl America/Lima). Conversión Lima↔UTC vive en el motor de cálculo (Semana 3), no en SQL.
- QR estático en MVP: payload `LUMIBELL-SEDE-{id}` debe coincidir con `sede_id` enviado; backend valida formato + sede existe. QR dinámico (token temporal por sede) = TODO posterior (§5.4).
- GPS flexible: Flutter envía lat/lon; backend calcula haversine vs sede (lat/lon + radio_permitido_metros). Fuera de radio o sin coords => se ACEPTA con `fuera_radio=1` / motivo info (auditoría). No se rechaza en piloto (emuladores/interiores).
- Rechazos se guardan: secuencia rota, QR inválido, usuario/empleado inactivo, día descanso, duplicada => fila RECHAZADA + motivo, respuesta 4xx con la fila incluida. Sin empleado (JWT sin empleado) => 404 sin fila (FK lo impide).
- Secuencia esperada (sobre aceptadas del día): sin horario o día sin refs => ENTRADA->SALIDA (2 pasos); con refs => ENTRADA->SAL_REF->REG_REF->SALIDA. Día descanso => todo se rechaza. Tipo ya aceptado => 409 duplicada; otro tipo fuera de orden => 422.
- Endpoints: POST /api/marcaciones (empleado sale del JWT, nunca del body) + GET /api/marcaciones?empleado_id&desde&hasta (COLABORADOR solo ve las suyas).

## Frontend testing — Semana 1 (simple)

> Alcance frontend Semana 1 = solo **Login** (`lib/screens/login/login_screen.dart` + `lib/services/auth_service.dart` + `lib/models/usuario.dart` + `lib/config/app_config.dart` + `lib/main.dart` Provider). Sin dashboards ni marcaciones. Objetivo: verificar que el login renderiza, valida, llama a la API y maneja errores.

### 1. Pre-requisitos (sin deps nuevas)

```bash
# Flutter en esta maquina esta en /usr/local/flutter/bin
export PATH="/usr/local/flutter/bin:$PATH"
flutter --version  # 3.47.2 / Dart 3.13.2
flutter pub get
```

`pubspec.yaml` ya trae `flutter_test` + `flutter_lints`; no se agrega `mockito` para el simple — se usa `http` mock via `http/testing` (incluido en `http`) y `Provider` fake.

### 2. Tests automatizados (unit + widget)

Estructura sugerida (crear si no existe):

```
test/
  unit/
    usuario_test.dart          # Usuario.fromJson + nombreCompleto
    auth_service_test.dart     # AuthService.login con MockClient
  widget/
    login_screen_test.dart     # LoginScreen render + validacion + estados
```

#### 2.1 Unit — `AuthService` (`lib/services/auth_service.dart:20`)

Usar `http/testing.dart` → `MockClient`:

```dart
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import '../lib/services/auth_service.dart'; // ajustar import relativo

// 200 OK -> token + usuario parseado, isAuthenticated true
// 401 -> throw AuthException('Credenciales inválidas')
// 403 -> throw AuthException('Usuario inactivo o bloqueado')
// 400/falta campo -> 400 con error generico
// Exception de red -> 'No se pudo conectar con el servidor' (mapeado en LoginScreen:58)
```

Comando:

```bash
export PATH="/usr/local/flutter/bin:$PATH"
flutter test test/unit/auth_service_test.dart
flutter test test/unit/usuario_test.dart
```

#### 2.2 Widget — `LoginScreen` (`lib/screens/login/login_screen.dart:5`)

Casos mínimos Semana 1:

- renderiza 2 `TextFormField` (Usuario + Contraseña), boton Ingresar, link "¿Olvidaste...?" y footer Asistencia Lumibell
- validacion vacio: "Ingresa tu usuario" / "Ingresa tu contraseña" (validadores linea 165, 198)
- toggle visibilidad contraseña (linea 189 `_obscurePassword`)
- `_isLoading` muestra `CircularProgressIndicator` y deshabilita boton (linea 210)
- error de `AuthException` se muestra en `_errorMessage` (linea 285)
- tap "Olvidaste" abre `AlertDialog` pendiente (linea 65)
- on success muestra `SnackBar` Bienvenido (linea 53) y `notifyListeners` cambia a `HomePlaceholder` (`lib/main.dart:25`)

Ejemplo pump:

```dart
testWidgets('login form valida vacios', (tester) async {
  final auth = AuthService();
  await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: auth)));
  await tester.tap(find.text('Ingresar'));
  await tester.pump();
  expect(find.text('Ingresa tu usuario'), findsOneWidget);
});
```

Comando:

```bash
export PATH="/usr/local/flutter/bin:$PATH"
flutter test test/widget/login_screen_test.dart
# o todo el frontend
flutter test
flutter analyze  # debe pasar sin issues (analysis_options.yaml ya excluye build/**)
```

### 3. Smoke manual (con backend real) — recomendado para Semana 1

```bash
# 1. levantar DB + API (desde raiz)
docker compose down -v && docker compose up --build -d
docker compose ps
curl http://localhost:3000/health            # -> {status:"ok"}
curl http://localhost:3000/api-docs.json | head  # 17 rutas documentadas

# 2. correr Flutter (web/desktop por defecto localhost:3000)
export PATH="/usr/local/flutter/bin:$PATH"
flutter run --dart-define=API_BASE_URL=http://localhost:3000          # web/windows
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Android emulador -> 10.0.2.2, fisico -> IP LAN del host
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

Credenciales seed (`sql/02_seed_login.sql`, pass todos: `Lumibell2026`):

- `admin@lumibell.com` / `Lumibell2026` (ADMINISTRADOR)
- `supervisor@lumibell.com` / `Lumibell2026` (SUPERVISOR)
- `colaborador@lumibell.com` / `Lumibell2026` (COLABORADOR)

Checks manuales:

1. campos vacios → mensajes validacion inline
2. pass <4 chars → "Ingresa una contraseña válida"
3. credenciales malas → banner rojo "Credenciales inválidas" (`AuthService:43`)
4. usuario ACTIVO → SnackBar Bienvenido + navega a `HomePlaceholder` Bienvenido, nombreCompleto + logout
5. `AppConfig.apiBaseUrl` (`lib/config/app_config.dart:12`) respeta `--dart-define` sin recompilar codigo

### 4. Criterio OK Semana 1 frontend

- `flutter analyze` sin errores
- `flutter test` verde (unit + widget login)
- login manual con los 3 usuarios seed funciona en chrome/web y/o device elegido, usando `API_BASE_URL` correcto

### 5. Frontend scaffold Semana 1 — commit 2026-09-09 (feature/semana-1-frontend-test)

**Branch:** `feature/semana-1-frontend-test` (alias `semana-1-frontend-test`) desde `feature/semana-1-backend` (4bf09d0).

**Cambios incluidos:**

- `lib/screens/home/home_screen.dart` — `HomeScreen` con `NavigationBar` 3 tabs (Inicio/Horario/Perfil) + `AppBar` dinámico + logout (`lib/main.dart:25` usa `HomeScreen` si `isAuthenticated`, mantiene `HomePlaceholder` legacy).
- `lib/screens/inicio/inicio_screen.dart` — bienvenida con `nombreCompleto`/`rol` + card Semana 1.
- `lib/screens/horario/horario_screen.dart` — placeholder `GET /api/empleados/:id/horario-hoy` + cards Horario/Horas requeridas.
- `lib/screens/perfil/perfil_screen.dart` — avatar, email, rol/estado, sede/supervisor TODO.
- `lib/services/auth_service.dart:14` — inyección `http.Client` (`AuthService({client})`) para testabilidad con `MockClient`; default `http.Client()` preserva prod.
- `analysis_options.yaml` — `exclude: build/** android/** ios/** web/**` para `flutter analyze` limpio.
- Tests `test/` (21/21 verde, `export PATH="/usr/local/flutter/bin:$PATH"`):
  - `test/unit/usuario_test.dart` (2) — `Usuario.fromJson` + `nombreCompleto` (`lib/models/usuario.dart:10`).
  - `test/unit/auth_service_test.dart` (6) — 200 OK + notify, 401/403/400 errores, network exception, logout (`lib/services/auth_service.dart:20`).
  - `test/unit/app_config_test.dart` (1) — default `http://localhost:3000` (`lib/config/app_config.dart:12`).
  - `test/widget/login_screen_test.dart` (5) — render, validación vacíos (2 widgets hint+error), toggle visibilidad, dialog recuperación, pass corta.
  - `test/widget/home_screen_test.dart` (3) — NavigationBar 3 destinations, navegación Inicio↔Horario↔Perfil, AppBar title.
  - `test/widget/inicio_perfil_test.dart` (3) — Inicio bienvenida, Perfil datos, Horario placeholder.
  - `test/widget/app_test.dart` (1) — `MainApp` default muestra Login.
- Verificación: `flutter analyze` → `No issues found!` (8s), `flutter test --coverage` → 21 passed, `lcov` 100% en `usuario.dart`/`auth_service.dart`.

**Comando reproducir:**

```bash
export PATH="/usr/local/flutter/bin:$PATH"
flutter pub get && flutter analyze && flutter test --reporter expanded && flutter test --coverage
```

**Próximo:** Semana 2 — marcaciones (QR+GPS), historial y cálculo, sobre `04_marcaciones.sql` + `POST/GET /api/marcaciones`.

### 6. Frontend admin CRUD — create usuario/sede/empleado/horario + assign (2026-09-09)

**Objetivo pedido:** `create usuario, create empleado, create sede, create horario, assign horario` — flujo admin completo Semana 1.

**Branch:** `feature/semana-1-frontend-test` continúa (commit pendiente 32 tests).

**Servicios nuevos (`lib/services/`):**

- `usuario_service.dart` — `POST /api/usuarios` (nombre, apellido, email, password, rol) + `GET /api/usuarios`, `ApiException(status)` con `Bearer token`.
- `sede_service.dart` — `POST /api/sedes` (nombre, direccion, latitud -90..90, longitud -180..180, radio>0) + `GET /api/sedes`, valida geo igual que `server/routes/sedes.js:13`.
- `empleado_service.dart` — `POST /api/empleados` (usuario_id, codigo, cargo, modalidad FULL/PART, tipo FIJO/FLEX/ROT/PERS, fecha_ingreso YYYY-MM-DD, sede_id? horario_id?) + `PUT /api/empleados/:id` (assign) + `GET /api/empleados/:id/horario-hoy`, validaciones espejo `server/routes/empleados.js:81`.
- `horario_service.dart` — `POST /api/horarios` (nombre, vigencia_desde, tolerancia 0-180, 7 dias transaccional) + `GET /api/horarios/:id`, repro `server/routes/horarios.js:31` (salida>entrada, refs juntos o nulos).

**Screens (`lib/screens/admin/`):**

- `create_usuario_screen.dart` — Form nombre/apellido/email/password/rol dropdown, `UsuarioService.crearUsuario`, muestra `id` + SnackBar, hint `POST /api/usuarios`.
- `create_sede_screen.dart` — Form nombre/direccion/lat/lon/radio con defaults Sede Principal Lima, `SedeService.crearSede`, geo validation.
- `create_empleado_screen.dart` — Form usuario_id/codigo/cargo/modalidad/tipo/fecha_ingreso + sede_id? horario_id? opcionales, `EmpleadoService.crearEmpleado`.
- `create_horario_screen.dart` — Form nombre/vigencia/tolerancia + 7 cards `dia_semana 1-7` con entrada/salida/ref_ini/ref_fin + checkbox descanso (Dom default descanso), construye `dias` array y llama `HorarioService.crearHorario` (transaccional 7 filas, valida `salida>entrada`).
- `assign_horario_screen.dart` — Form empleado_id + horario_id? + sede_id? → `PUT /api/empleados/:id` (`actualizarEmpleado`), tip para verificar con `horario-hoy`.
- `admin_menu_screen.dart` — Lista 5 tiles con `Navigator.push` a cada create, subtitle indica endpoint.
- `lib/screens/home/home_screen.dart` — role-based: `ADMINISTRADOR` ve 4 tabs `[Inicio, Admin, Horario, Perfil]` con `Admin` → `AdminMenuScreen`; otros roles 3 tabs (oculta Admin). `watch<AuthService>` para reactividad rol.

**Tests añadidos (32/32 verde):**

- `test/unit/services_test.dart` (7) — Usuario 201/409, Sede 201, Empleado 201 + assign PUT 200, Horario 201/400 con `MockClient`.
- `test/widget/admin_menu_test.dart` (4) — Admin ve 4 tabs vs Colab 3, AdminMenu 5 tiles, navega a Crear Usuario/Sede forms.
- Previos 21 se mantienen; nuevos totales 32. `flutter analyze` → `No issues found!`.

**Cómo probar (con backend):**

```bash
export PATH="/usr/local/flutter/bin:$PATH"
flutter test --reporter expanded # 32 passed
# manual admin flow (logueado como admin@lumibell.com / Lumibell2026):
# Home → Admin → Crear Sede → Crear Horario → Crear Usuario → Crear Empleado (usuario_id del paso anterior) → Asignar Horario/Sede → Inicio/Horario verifica horario-hoy
```

**Próximo:** validar con `docker compose up` + token real, y Semana 2 marcaciones QR/GPS + historial (balance) sobre `04_marcaciones.sql`.

## Instructions to test client (Flutter) — quick copy-paste (Semana 1)

**Branch:** `feature/semana-1-frontend-test` (also `semana-1-frontend-test`), 32 tests verde.

### A. Automated (no backend needed)

```bash
# Flutter está en /usr/local/flutter/bin en esta máquina
export PATH="/usr/local/flutter/bin:$PATH"
flutter --version          # 3.47.2 / Dart 3.13.2
flutter pub get
flutter analyze            # → No issues found!
flutter test --reporter expanded   # → 32 passed (unit 10 + widget 22)
flutter test --coverage    # → coverage/lcov.info 100% en usuario.dart/auth_service.dart
# solo login
flutter test test/widget/login_screen_test.dart
flutter test test/unit/auth_service_test.dart
```

**Qué valida:** `lib/models/usuario.dart:20` fromJson/nombreCompleto, `lib/services/auth_service.dart:20` login 200/401/403/400 + logout, `lib/services/*_service.dart` MockClient 201/4xx, `lib/screens/login/login_screen.dart:165` validadores + `lib/screens/home/home_screen.dart:14` role-based Admin tab, `lib/screens/admin/*` forms.

### B. Manual with backend (admin CRUD flow)

```bash
# 1. Backend (raíz del repo)
docker compose down -v && docker compose up --build -d
docker compose ps
curl http://localhost:3000/health            # {status:"ok"}
curl http://localhost:3000/api-docs.json | head  # 17 rutas

# 2. Client
export PATH="/usr/local/flutter/bin:$PATH"
# web/chrome (default http://localhost:3000)
flutter run --dart-define=API_BASE_URL=http://localhost:3000
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
# emulador Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
# físico (IP LAN del host)
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000
```

**Seed login** (`sql/02_seed_login.sql` pass `Lumibell2026`): `admin@lumibell.com` (ADMIN), `supervisor@lumibell.com`, `colaborador@lumibell.com`.

**Config:** `lib/config/app_config.dart:12` `apiBaseUrl` default `http://localhost:3000`, override con `--dart-define=API_BASE_URL=...` sin editar código.

### B.1 Manual step-by-step: crear usuario, sede, empleado, horario, assign (happy + unhappy)

> Pre-condición: logueado como **ADMIN** `admin@lumibell.com / Lumibell2026`. Todas las pantallas requieren `Authorization: Bearer <token>` (`lib/services/*_service.dart` inyecta `AuthService.token`). Si el token falta/expiró → 401 `No autorizado` (middleware `server/middleware/auth.js`).

#### 0) Login (base)

1. Happy: email `admin@lumibell.com` + pass `Lumibell2026` → `POST /api/auth/login` 200, `Home` 4 tabs. Ver `Inicio` muestra `Bienvenido, Luis Bello`.
2. Unhappy vacío → validador inline `Ingresa tu usuario` / `Ingresa tu contraseña` (`lib/screens/login/login_screen.dart:165,198`).
3. Unhappy pass `123` → `Ingresa una contraseña válida` (len<4).
4. Unhappy creds `admin@lumibell.com / wrong` → banner rojo `Credenciales inválidas` (`lib/services/auth_service.dart:43` mapea 401).
5. Unhappy inactivo: si `estado!=ACTIVO` → `Usuario inactivo o bloqueado` (403).

#### 1) Crear Sede — `POST /api/sedes` — `lib/screens/admin/create_sede_screen.dart:1` (`SedeService` `server/routes/sedes.js:140`)

1. **Happy:** `Home → Admin → Crear Sede` → Nombre `Sede Test 2`, Dirección `Av Test 456`, Lat `-12.05`, Lon `-77.03`, Radio `150` → Tap `Crear sede` → 201 `Sede #2 creada` + SnackBar. Verifica `GET /api/sedes` lista la nueva (prueba `curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/sedes`).
2. **Unhappy geo lat** → Lat `100` (>90) → client validator `Entre -90 y 90` antes de API; si se bypass → API 400 `latitud debe ser número entre -90 y 90` (`server/routes/sedes.js:13`).
3. **Unhappy geo lon** → Lon `200` → `Entre -180 y 180` / API 400 `longitud ...`.
4. **Unhappy radio** → Radio `0` → client `>0` / API 400 `radio_permitido_metros debe ser número mayor a 0`.
5. **Unhappy vacío** → dejar Nombre vacío → `Requerido` inline, no llama API.
6. **Happy alternativo:** crear `Sede Principal Lima` ya existe (seed id 1); crear segunda valida que no hay UNIQUE conflict (nombre puede repetir, solo PK).

#### 2) Crear Usuario — `POST /api/usuarios` — `lib/screens/admin/create_usuario_screen.dart:1` (`UsuarioService` `server/routes/usuarios.js:136`)

1. **Happy:** `Admin → Crear Usuario` → Nombre `Ana`, Apellido `Test`, Email `ana.test@lumibell.com`, Password `Lumibell2026`, Rol `COLABORADOR` → 201 `Creado usuario #4 ana.test@lumibell.com`. Anota `id=4` para empleado.
2. **Unhappy email duplicado** → mismo email `ana.test@lumibell.com` → API 409 `El email ya está registrado` (muestra en banner rojo `_msg`). Client no bloquea porque email válido, pero API rechaza.
3. **Unhappy email inválido** → `ana@` sin `@` → client `Email inválido` inline (no llama API).
4. **Unhappy pass corto** → `123` → client `Mín 4 chars`.
5. **Unhappy rol inválido** → si se manipula request a `ROL_X` → API 400 `rol debe ser uno de: ADMINISTRADOR, SUPERVISOR, COLABORADOR` (`server/routes/usuarios.js:141`).
6. **Unhappy vacío** → Nombre vacío → `Requerido`.

#### 3) Crear Horario — `POST /api/horarios` (transaccional 7 días) — `lib/screens/admin/create_horario_screen.dart:1` (`HorarioService` `server/routes/horarios.js:91`)

> Form defaults: `Horario Full-time`, `vigencia 2026-01-01`, tol `10`, Lun-Sáb `10:00/19:00` con refs `13:00-14:00`, Dom `descanso`.

1. **Happy:** dejar defaults → `Crear horario (transaccional 7 días)` → 201 `Horario #2 creado` (7 filas `horario_dias`). Verifica `GET /api/horarios/2` trae `dias` ordenados 1..7.
2. **Unhappy tolerancia** → Tol `200` → client `0-180` / API 400 `tolerancia_minutos debe ser entero 0-180`.
3. **Unhappy vigencia** → `vigencia_desde` vacío → client `Requerido` / API 400 `nombre y vigencia_desde son obligatorios`.
4. **Unhappy salida>entrada (MVP nocturno)** → Lun `entrada 23:00 + salida 07:00` (overnight) → API 400 `dia 1: salida debe ser mayor a entrada (turno nocturno no soportado en MVP)` (`server/routes/horarios.js:60`).
5. **Unhappy refs orden** → `entrada 10:00, ref_ini 14:00, ref_fin 13:00, salida 19:00` (ref_fin < ref_ini) → API 400 `dia 1: orden inválido, debe ser entrada <= ref_inicio < ref_fin <= salida`.
6. **Unhappy refs solos** → solo `ref_ini 13:00` sin `ref_fin` → API 400 `ref_inicio y ref_fin deben ir juntos o ambos nulos`.
7. **Happy flexible:** editar Mié `10:00-14:00` sin refs, Sáb `10:00-12:30 + 14:30-19:00` (doble turno) → 201 ok (flexible es solo data distinta, ver `docs/notes-david-sep-9.md:64`).
8. **Happy descanso:** marcar Dom `Descanso` checked → envía `es_descanso:true` con horas null, API acepta (req 0).

#### 4) Crear Empleado — `POST /api/empleados` — `lib/screens/admin/create_empleado_screen.dart:1` (`EmpleadoService` `server/routes/empleados.js:120`)

1. **Happy:** `Admin → Crear Empleado` → `usuario_id=4` (Ana), `codigo LUM-0004`, `cargo Asistente`, `modalidad FULL_TIME`, `tipo FIJO`, `fecha_ingreso 2024-04-01`, `sede_id=2` (Sede Test), `horario_id=2` (horario creado) → 201 `Empleado #4 creado`.
2. **Unhappy usuario duplicado** → mismo `usuario_id=4` → API 409 `El usuario ya tiene un empleado asignado` (`server/routes/empleados.js:174`).
3. **Unhappy usuario inexistente** → `usuario_id=9999` → API 404 `Usuario no encontrado`.
4. **Unhappy código duplicado** → `codigo LUM-0001` (seed) → API 409 `codigo_empleado duplicado o usuario ya asignado`.
5. **Unhappy modalidad** → `modalidad XYZ` (si se bypass dropdown) → API 400 `modalidad_laboral debe ser una de: FULL_TIME, PART_TIME`.
6. **Unhappy fecha** → `fecha_cese 2023-01-01 < fecha_ingreso 2024-01-01` → API 400 `fecha_cese no puede ser anterior a fecha_ingreso`.
7. **Happy sin sede/horario:** dejar `sede_id` y `horario_id` vacíos → crea empleado `horario_id=NULL` (permite asignar después via assign screen) → 201 ok, luego `GET /api/empleados/:id/horario-hoy` → 404 `Empleado sin horario asignado`.

#### 5) Asignar Horario/Sede — `PUT /api/empleados/:id` — `lib/screens/admin/assign_horario_screen.dart:1` (`EmpleadoService.actualizarEmpleado` `server/routes/empleados.js:261`)

1. **Happy asignar horario:** `Admin → Asignar Horario/Sede` → `empleado_id=4`, `horario_id=2`, dejar `sede_id` vacío → `Asignar` → 200 `Empleado #4 actualizado → horario 2`. Verifica `GET /api/empleados/4/horario-hoy` con token admin → 200 con `horas_requeridas_min` calculado (ej. 480 para 8h).
2. **Happy traslado sede:** `empleado_id=4`, `sede_id=1` → 200 `sede 1`.
3. **Unhappy empleado inexistente** → `empleado_id=9999` → API 404 `Empleado no encontrado`.
4. **Unhappy horario inexistente** → `horario_id=9999` → API 404 `Horario no encontrado`.
5. **Unhappy sede inexistente** → `sede_id=9999` → API 404 `Sede no encontrada`.
6. **Unhappy sin campos** → dejar ambos vacíos → client `Ingresa horario_id o sede_id` (no llama API) / API 400 `No hay campos para actualizar`.
7. **Happy verificar COLABORADOR solo su horario:** loguear como `ana.test@lumibell.com` (si se crea token) → `GET /api/empleados/3/horario-hoy` (otro empleado) → 403 `No autorizado`; `GET /api/empleados/4/horario-hoy` propio → 200.

#### 6) Verificación final Semana 1 (post-assign)

1. `Horario` tab (con token de Ana si se implementa login como Ana, o admin viendo `empleado_id=4`) debe mostrar `horas_requeridas_min` = `(salida-entrada)-(ref_fin-ref_ini)` (ej. `(19:00-10:00)-(14:00-13:00)=480`).
2. `Inicio/Perfil` siguen mostrando `nombreCompleto/rol/sede` (perfil ahora placeholder, próximamente `GET /api/empleados` con `sede` join).

**Limpieza:** `docker compose down -v` resetea DB a seeds; `flutter test` sigue 32/32 sin DB.

