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
