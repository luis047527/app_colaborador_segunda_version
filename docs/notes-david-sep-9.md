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

