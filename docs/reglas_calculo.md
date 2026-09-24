# Reglas de Cálculo — App Colaborador (Lumibell MVP)

Documento canónico de cómo el backend interpreta horarios y marcaciones para
determinar tardanzas, horas y balances. Fuente: decisiones de `notes-david-sep-9.md`.
Todo lo numérico vive en el motor de cálculo (API, Semana 3); la base de datos
solo guarda datos crudos + validaciones estructurales.

---

## 1. Hora oficial y fecha de jornada

- **Hora oficial = reloj del servidor, en UTC.** `marcaciones.timestamp_utc` se genera
  en el backend al recibir la marcación (`CURRENT_TIMESTAMP`). Nunca se acepta la
  hora del teléfono (puede estar manipulada o desincronizada).
- **Fecha de jornada = día calendario en America/Lima** derivado en API desde el
  timestamp UTC. Ejemplo: `2026-09-09T04:55:00Z` (UTC) = `2026-09-08 23:55` en Lima
  → pertenece a la jornada del **08**, no del 09.
- El lookup del horario del día usa esa fecha Lima:
  `dia_semana = WEEKDAY(fecha_lima) + 1` (1=Lun … 7=Dom, ISO).
  No usar `DAYOFWEEK()` (convención USA 1=Dom, causa off-by-one).

## 2. Jornada programada (qué se espera cada día)

- Cada empleado tiene **un horario** (`empleados.horario_id`) con **7 filas** en
  `horario_dias` (una por `dia_semana`, aunque se repitan los horarios).
- Cada fila: `entrada | ref_inicio | ref_fin | salida | es_descanso`.
  - Turno partido (full-time `10:00–13:00 + 14:00–19:00`) se expresa con el
    refrigerio: `entrada 10:00, ref_ini 13:00, ref_fin 14:00, salida 19:00`.
  - Día simple (part-time `15:00–19:00`): refs en `NULL` → jornada de 2 marcaciones.
  - Flexible = distintas horas por fila (ej. miércoles `10–14`, sábado
    `10–12:30 + 14:30–19`). Misma estructura, solo cambian los datos.
  - `es_descanso = 1` (típico domingo): horas en `NULL`, requeridas = 0.
- **Horas requeridas NO se almacenan** (varían por día en flexible). Se calculan:
  - Con refrigerio: `(salida − entrada) − (ref_fin − ref_ini)`.
    Ej. full-time: `(19−10) − (14−13)` = **8h**. Sábado flexible:
    `(12:30−10) + (19−14:30)` = **7h**.
  - Sin refrigerio: `salida − entrada`. Ej. part-time: **4h**.
- MVP: **`salida > entrada` siempre** (sin turnos nocturnos 23→07). Si
  `salida <= entrada` el API rechaza con 400. Habilitar nocturnos después no
  requiere cambio de esquema, solo regla `+24h` en el motor.

## 3. Tolerancia y calificación de llegada

- `horarios.tolerancia_minutos` (default 10) es **política por horario**, no por día.
- Solo aplica a la llegada (`ENTRADA`, y `REG_REF` si se decide):
  - `real < programada` → **anticipada** (minutos = programada − real).
  - `programada ≤ real ≤ programada + tolerancia` → **dentro de tolerancia** (tardanza 0).
  - `real > programada + tolerancia` → **tarde** (tardanza = real − programada).
- Ejemplo base Lun `10:00`, tol 10: `09:55` anticipada · `10:05` en hora ·
  `10:15` tarde 15m.
- **Clamp anti-gaming:** la llegada anticipada se registra (auditoría) pero **no
  suma balance**. Trabajadas cuentan desde la `programada`.
  Ej. marcación `09:45` vs `10:00`: aceptada, `anticipada 15m`, pero el cálculo
  parte de las `10:00` → balance `±0`, no `+15m`. Llegar antes no autoriza salir antes.

## 4. Horas trabajadas y balance

- **Trabajadas** = suma de intervalos reales entre pares de marcaciones:
  - Con refrigerio: `(SAL_REF − ENTRADA) + (SALIDA − REG_REF)`.
  - Simple: `SALIDA − ENTRADA` (con clamp de anticipada, §3).
- **Balance = trabajadas − requeridas** (§5.7 MVP). Positivo = a favor,
  negativo = en contra. Ejemplo: 8h20 − 8h = **+20m**.
- Sin jornada completa (falta alguna marcación) **no hay balance**: estado
  `INCOMPLETA`, pendiente de corrección/admin.

## 5. Secuencia de marcaciones y estados de jornada

- Orden válido con refrigerio: `ENTRADA → SAL_REF → REG_REF → SALIDA`.
  Sin refrigerio: `ENTRADA → SALIDA`.
- El registro de vacaciones debe seguir la siguiente lógica, inicialmente asignar una cantidad de días por año, luego tener la posibilidad de ir distribuyendo esos días de vacaciones en el año, para lo que debemos de tener la posibilidad de asignar periodos flexibles de vacaciones.
- **Estados de jornada** (§5.5): `NO INICIADA · EN CURSO · COMPLETA · INCOMPLETA ·
  VACACIONES · DESCANSO`. La app muestra la próxima marcación disponible.
- Día `DESCANSO` o `VACACIONES`: requeridas = 0, no genera balance negativo;
  marcar se rechaza (o registra `DESCANSO`).

## 6. GPS y QR (piloto)

- **GPS flexible:** Flutter envía lat/lon; el backend calcula haversine contra la
  sede (`latitud, longitud, radio_permitido_metros`). Fuera de radio o sin
  coordenadas → se **acepta** con `fuera_radio = 1` / motivo informativo. No se
  rechaza en el piloto (emuladores e interiores).
- **QR estático en MVP:** payload `LUMIBELL-SEDE-{id}` debe coincidir con la sede
  enviada. QR dinámico con token temporal = TODO posterior.

## 7. Ejemplos completos

Base: Lun full-time `10:00 | 13:00 | 14:00 | 19:00`, tol 10, req 8h.

**A — puntual.** `10:02 · 13:00 · 14:00 · 19:00` → en hora.
Trabajadas `(13:00−10:02)+(19:00−14:00)` = 7:58. Balance **−2m**. `COMPLETA`.

**B — tarde.** `10:25 · 13:05 · 14:02 · 19:10` → tarde 15m.
Trabajadas `(13:05−10:25)+(19:10−14:02)` = 7:48. Balance **−12m**.

**C — incompleta.** `10:00 · 13:00 · (falta REG_REF) · 19:00` → secuencia rota,
`INCOMPLETA`, sin balance.

**Flexible.** Miércoles `10–14`: `10:03 … 14:00` → en hora, 3:57 vs 4h req = −3m.
Sábado `10–12:30 + 14:30–19`: `10:12 · 12:30 · 14:35 · 19:00` → entrada en
tolerancia, trabajadas 6:43 vs 7h req = −17m.
