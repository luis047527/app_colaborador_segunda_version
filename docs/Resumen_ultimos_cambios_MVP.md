# Resumen de los últimos cambios del MVP

## Objetivo general

Los cambios recientes amplían el MVP de la aplicación Lumibell para incorporar la gestión operativa de colaboradores y horarios, además del registro de asistencia mediante códigos QR y validación de ubicación GPS.

## 1. Gestión de colaboradores

Se agregó una nueva interfaz administrativa que permite:

- Consultar la lista de colaboradores registrados.
- Visualizar el cargo, la sede y el horario asignado a cada colaborador.
- Crear un colaborador con sus datos personales y laborales.
- Crear automáticamente su usuario con el rol `COLABORADOR`.
- Asignar una sede durante el registro.
- Desactivar colaboradores desde la lista.
- Actualizar la información mediante recarga manual de la pantalla.

En el backend se incorporó un endpoint para listar empleados con la información relacionada de usuario, sede y horario. También se agregó un endpoint para que el usuario autenticado obtenga su propio perfil de empleado.

## 2. Gestión de horarios

Se implementó una nueva sección para administrar horarios personalizados. Esta permite:

- Consultar los horarios existentes.
- Crear un horario indicando nombre, entrada, inicio y fin del refrigerio y hora de salida.
- Aplicar inicialmente el horario de lunes a viernes.
- Registrar sábado y domingo como días de descanso.
- Configurar una tolerancia predeterminada de 10 minutos.
- Asignar un horario existente a un colaborador.

El backend ahora dispone de un endpoint para listar horarios, accesible para los roles `ADMINISTRADOR` y `SUPERVISOR`.

## 3. Registro de asistencia con QR

Se agregó el flujo de marcación de asistencia mediante QR:

- El administrador o supervisor selecciona una sede y genera un código QR temporal.
- El colaborador consulta la jornada y el horario que le corresponden en el día actual.
- El colaborador escanea el QR de la sede con la cámara del dispositivo.
- La aplicación solicita la ubicación GPS y la envía junto con el token del QR.
- Al completarse el registro, la aplicación informa qué tipo de marcación fue guardado.

La secuencia contemplada para una jornada es:

1. `ENTRADA`
2. `SALIDA_REFRIGERIO`
3. `REGRESO_REFRIGERIO`
4. `SALIDA`

## 4. Validaciones de la marcación

El nuevo servicio del backend valida:

- Que el usuario tenga un perfil de colaborador activo.
- Que el colaborador tenga una sede asignada.
- Que el QR corresponda a esa sede.
- Que el QR tenga una firma válida y no haya vencido.
- Que se hayan enviado coordenadas GPS válidas.
- Que la sede se encuentre activa.
- Que la distancia entre el colaborador y la sede esté dentro del radio configurado.
- Que las marcaciones respeten el orden de la jornada.
- Que no se registre una quinta marcación cuando la jornada ya esté completa.

Los QR se generan con una vigencia de dos minutos y una firma HMAC SHA-256. La distancia con la sede se calcula en metros y se registra si la marcación fue realizada fuera del radio permitido.

## 5. Navegación según el rol

Se actualizó el flujo posterior al inicio de sesión:

- Los usuarios con rol `ADMINISTRADOR` ingresan al inicio administrativo.
- Desde el inicio administrativo ya se puede navegar a Colaboradores, Horarios y Asistencias.
- Los usuarios que no son administradores ingresan directamente a la pantalla de su jornada y marcación de asistencia.
- El token de autenticación se comparte con las pantallas administrativas para realizar solicitudes protegidas al backend.

La opción de Reportes continúa marcada como funcionalidad pendiente.

## 6. Servicio de comunicación con la API

Se creó un servicio común en Flutter para centralizar las solicitudes autenticadas al backend. El servicio:

- Incluye automáticamente el token Bearer.
- Envía y recibe información en formato JSON.
- Soporta solicitudes `GET`, `POST`, `PUT` y `DELETE`.
- Convierte las respuestas de error del backend en excepciones que pueden mostrarse en la interfaz.

## 7. Nuevas rutas y componentes del backend

Se incorporaron componentes específicos para marcaciones:

- Modelo de acceso a datos de marcaciones.
- Servicio con la lógica de generación y validación del QR.
- Ruta para generar un QR por sede.
- Ruta para registrar una marcación.
- Registro de `/api/marcaciones` en la aplicación principal del servidor.

También se ampliaron las rutas de empleados y horarios para soportar las nuevas pantallas del frontend.

## 8. Permisos y dependencias

En Android se agregaron los permisos para:

- Acceder a la cámara.
- Obtener la ubicación precisa del dispositivo.

En Flutter se incorporaron las siguientes dependencias:

- `geolocator`: obtención y autorización de la ubicación GPS.
- `mobile_scanner`: lectura de códigos QR con la cámara.
- `qr_flutter`: generación visual de códigos QR.

Los archivos generados de plugins para macOS y Windows también fueron actualizados como consecuencia de estas dependencias.

## 9. Estado actual y observaciones

- Los cambios descritos se encuentran actualmente como modificaciones locales pendientes de commit.
- Los archivos `sql/02_seed_login.sql` y `docs/Alcance_Funcional_Lumibell_MVP_1_mes.md` no forman parte de estos cambios pendientes.
- Se detectaron textos con problemas de codificación de caracteres, por ejemplo `ubicación`, `contraseña` y `código` representados incorrectamente en algunos archivos. Se recomienda corregirlos antes de consolidar los cambios.
- La pantalla de Reportes todavía no ha sido implementada.

