# Plan Semana 2 — Marcación QR + GPS

## 1. Objetivo
Permitir al colaborador registrar sus 4 marcaciones diarias (`Entrada → Inicio refrigerio → Fin refrigerio → Salida`) de forma confiable, validando **ubicación GPS + QR de sede + hora oficial del servidor**.

Resultado esperado: marcación funcional de extremo a extremo.

## 2. Flujo colaborador — pantalla de marcación

Al abrir la pantalla:
- La app pide al servidor los datos de la sede asignada: `nombre, latitud, longitud, radio_permitido`.
- La app pide la hora oficial al servidor y la refresca **cada 60 segundos**. No se usa la hora del celular.
- El usuario elige el tipo de marcación según su horario.

Validación de ubicación (bajo demanda):
- La app muestra el botón `Validar mi ubicación`. Solo al presionarlo se lee el GPS una vez. No hay rastreo continuo.
- Si el GPS está apagado → mostrar: `"El GPS del dispositivo no está habilitado"`.
- Si está fuera del radio → mostrar: `"La ubicación actual no se encuentra dentro del área permitida"`.
- Si es válida → mostrar `"Ubicación lista para registrar — [Nombre Sede]"` y habilitar el botón `Escanear QR`.

Registro con QR:
- Al presionar `Escanear QR` se abre la cámara.
- Se compara el valor leído con el valor esperado de la sede.
- Si no coincide → mostrar `"El código QR no es válido"` y no guardar nada.
- Si coincide y el GPS es válido → enviar `POST /api/marcaciones`.

## 3. Flujo administrador — QR
- El QR es **estático** en este MVP: formato `LUMIBELL-SEDE-{id}`.
- El administrador puede generarlo, regenerarlo y descargarlo para imprimirlo en sede.
- Deuda conocida: el alcance original pedía QR dinámico temporal. Se pospone.

## 4. Reglas actuales
- Solo las marcaciones exitosas se guardan en la BD. Fallos de GPS o QR no generan fila.
- Cada marcación guarda: `usuario, sede, tipo, timestamp del servidor, lat/lon`.

## 5. Pendiente de definir — validación de la marcación en el servidor
Aún falta definir cómo el backend validará cada `POST /api/marcaciones` antes de guardar.

Puntos abiertos:
- Orden de validaciones (usuario activo, sede, QR, GPS/radio, secuencia, duplicados, día descanso/vacaciones).
- Qué se rechaza con `400/403/404` y qué se acepta con marca informativa (`fuera_radio`).
- Si los intentos rechazados se guardan para trazabilidad o se descartan.
- Cómo se valida la secuencia `ENTRADA -> SAL_REF -> REG_REF -> SALIDA` y duplicados por tipo/día.
- Cómo se usa la hora oficial del servidor (`timestamp_utc`) como única fuente de verdad.

## 6. Criterios de aceptación
- [ ] Con GPS apagado, muestra el mensaje correcto y no habilita QR.
- [ ] Fuera de radio, muestra el mensaje correcto y no habilita QR.
- [ ] Dentro de radio, muestra el nombre de la sede y habilita `Escanear QR`.
- [ ] QR incorrecto muestra error y no crea fila.
- [ ] QR + GPS correctos crean 1 fila con hora del servidor.
- [ ] Hora en pantalla se actualiza cada minuto.
- [ ] Administrador puede generar / regenerar / descargar QR.

## 7. Fuera de alcance
QR dinámico, modo offline, cálculo de tardanza/balance (Semana 3), vacaciones (Semana 4).

## Aclaraciones necesarias (resueltas 2026-10-01)

1. `La hora se refresca cada cierto tiempo` — solo display, sin segundos, sin offset.
   - El cliente pide la hora al servidor cada 60 s solo mientras la pantalla de marcaciones está visible (`init` + `Timer.periodic(60s)`, cancela en `dispose`). Muestra `HH:MM` Lima, sin segundos ni tick local.
   - Nuevo `GET /api/hora → { utc, lima, lima_hora: "HH:MM", lima_fecha }` (reusa `server/utils/fecha.js` + `America/Lima`). Si falla (sin red), se mantiene última hora + aviso "sin conexión".
   - La hora mostrada es referencial. La hora válida es `timestamp_utc` que pone el servidor en `POST /api/marcaciones`. Cumple `CA-06`.
   - UX: icono "i" junto a la hora con texto: "Hora oficial del servidor (Lima). No depende de la hora de tu celular. Tu marcación se guarda con esta hora."

2. `Validar mi ubicación` — la hace el cliente, bajo demanda.
   - Solo al presionar `Validar mi ubicación` el cliente lee el GPS una vez (sin rastreo continuo) y lo compara con los datos de la sede (`latitud, longitud, radio_permitido_metros`) obtenidos del servidor vía `GET /api/empleados/me/sede`. Cálculo haversine en Flutter.
   - GPS apagado → `"El GPS del dispositivo no está habilitado"`. Fuera de radio → `"La ubicación actual no se encuentra dentro del área permitida"` y no habilita `Escanear QR`. Dentro → `"Ubicación lista — [Nombre Sede]"` y habilita QR.
   - El backend re-valida lo mismo en `POST /api/marcaciones` como autoridad (`Alcance §5.4`, `server/services/marcaciones.js:50`). El cliente pre-valida para UX/bloqueo de botón (`CA-04`); el servidor rechaza definitivo `403` si `fuera_radio`. Nota: cambiar `docs/reglas_calculo.md §6` (piloto flexible `fuera_radio=1` aceptado) a rechazo para cumplir `CA-04`.

3. `El administrador puede descargar el QR` — QR estático, valor guardado + PNG al vuelo.
   - Decisión: QR estático (revierte QR dinámico 2 min actual de `server/services/marcaciones.js:18`). Formato `LUMIBELL-SEDE-{id}-{random}` guardado en nueva columna `sedes.qr_valor`.
   - `POST /api/sedes/:id/qr → { sede_id, qr_valor }` genera/rota el valor (admin). `GET /api/sedes/:id/qr.png → image/png` genera la imagen al vuelo desde `qr_valor` (no se almacena imagen, solo el valor).
   - `GET /api/sedes/:id` (admin) incluye `qr_valor + qr_png_url`. `GET /api/empleados/me/sede` (colaborador) solo incluye `lat/lon/radio/nombre`, sin `qr_valor` (llega por cámara y el server lo compara en `POST /marcaciones`).

## Actividades Backend (derivado de Aclaraciones 2026-10-01)

1. `GET /api/hora` — hora oficial display (Aclaración 1).
   - Auth: JWT cualquier rol. Sin DB. Reusa `server/utils/fecha.js:3` + `Intl America/Lima`.
   - Responde `200 { utc, lima: "YYYY-MM-DD HH:MM", lima_hora: "HH:MM", lima_fecha: "YYYY-MM-DD" }` (sin segundos).
   - Implementar en `server/routes/hora.js` (nuevo) + montar en `server/index.js`, `@openapi` + `server/tests/hora.test.js` (200 con JWT, forma `HH:MM`).

2. `GET /api/empleados/me/sede` — sede asignada sin secreto (Aclaración 2).
   - Auth: `COLABORADOR`. Lookup `empleados WHERE usuario_id = ?` (`server/models/marcaciones.js:1`) + `sedes WHERE id = ?`. `404` si sin perfil/sede, `403` si `INACTIVO/BLOQUEADO`.
   - Responde `200 { id, nombre, latitud, longitud, radio_permitido_metros }`. NO incluye `qr_valor`.
   - Implementar en `server/routes/empleados.js` (estático `me/sede` antes de `:id`), `@openapi` + test `401/403/404/200`.

3. `POST /api/marcaciones` — ajustar a QR estático + rechazo estricto (Aclaraciones 2 y 3).
   - Mantiene ruta y body `{ qr_token, latitud, longitud }` (contrato real con Flutter `asistencia_screen.dart:50`). Cambia validación en `server/services/marcaciones.js:registrar`: comparar `qr_token` contra `sedes.qr_valor` (igualdad exacta, `400 "QR inválido"` si difiere, `400 "Sede sin QR generado"` si null); `crearQr/validarQr` dinámico 2 min queda solo para la ruta legacy deprecated.
   - Orden: usuario activo → sede asignada y `ACTIVA` → QR → GPS numérico → haversine (`distanciaMetros`) → si `distancia > radio` rechaza `403 "fuera de radio"` (ya no acepta con `fuera_radio=1`; actualiza `docs/reglas_calculo.md §6`) → secuencia `TIPOS` + `tiposAceptadosHoy` → `409` jornada completa → inserta con `timestamp_utc = NOW()` servidor.
   - Intentos rechazados no generan fila (según §4). `@openapi` faltante + `server/tests/marcaciones.test.js` (`400` QR, `403` fuera radio, `409` duplicada, `201` ok).

4. Migración + `POST /api/sedes/:id/qr` — generar/rotar QR estático (Aclaración 3).
   - Nueva migración `sql/06_qr_estatico.sql`: `ALTER TABLE sedes ADD qr_valor VARCHAR(100) NULL UNIQUE` + backfill `LUMIBELL-SEDE-{id}-{8 hex}` para filas existentes. Incluir en `sql/00_init-db.sql` y `Dockerfile.db`.
   - Auth: `ADMINISTRADOR`. Genera `LUMIBELL-SEDE-{id}-{randomHex8}`, `UPDATE sedes SET qr_valor`, responde `{ sede_id, qr_valor, qr_png_url: "/api/sedes/:id/qr?formato=png" }` con `201` primera vez y `200` al rotar (sobrescribe).
   - Implementar en `server/routes/sedes.js` + `server/services/sedes.js`, `@openapi` + test (`403` colaborador, `404` sede inexistente, `201` genera / `200` rota).

5. `GET /api/sedes/:id/qr` + `?formato=png` — consultar/descargar (Aclaración 3, REST-puro: formato en query, no `.png` en path).
   - Auth: `ADMINISTRADOR, SUPERVISOR`. Lee `sedes.qr_valor`; `404` si sede inexistente o aún sin generar (indicar llamar a `POST .../qr` primero).
   - Sin query → `200 JSON { sede_id, qr_valor, qr_png_url }`. Con `?formato=png` (o `Accept: image/png`) → `200 image/png` generado al vuelo desde `qr_valor` (lib `qrcode`, `Cache-Control: no-store` pues rota). No guarda archivos. Permite `<img src=".../qr?formato=png">` y descarga directa.
   - `@openapi` (ambas representaciones) + test (JSON ok, content-type png, 404 sin qr). `GET /api/sedes/:id` (admin) además expone `qr_valor + qr_png_url`.

6. Transversal.
   - `server/tests/docs.test.js`: agregar `ESPERADAS` (`/api/hora`, `/me/sede`, `/sedes/{id}/qr`) y quitar `/qr/sede/:sedeId` dinámico.
   - Verificar: `npm run db:reset`, `docker exec node_server npm test`, `curl /api-docs.json`.
