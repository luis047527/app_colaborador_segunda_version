# Resumen de reingeniería frontend y backend — Lumibell

## 1. Objetivo de los cambios

Los últimos cambios transforman el MVP inicial en una aplicación móvil de asistencias alineada visualmente con los mockups de Lumibell.

El trabajo comprende:

- Reingeniería visual del frontend Flutter.
- Implementación de flujos administrativos.
- Implementación de flujos del colaborador.
- Gestión de horarios personalizados.
- Marcación mediante QR dinámico y GPS.
- Consulta del horario diario y semanal.
- Perfil laboral del colaborador.
- Historial de asistencias.
- Nuevas rutas y servicios del backend.
- Datos de demostración para probar los flujos.

## 2. Auditoría y análisis de mockups

Se revisaron los nueve mockups disponibles en `docs/Mock ups` y se relacionaron con las pantallas Flutter correspondientes.

Se creó el documento:

`docs/Auditoria_frontend_y_matriz_mockups.md`

Este documento contiene:

- Estado técnico inicial.
- Matriz mockup–implementación.
- Funcionalidades soportadas por el backend.
- Dependencias funcionales pendientes.
- Orden de reconstrucción aprobado.
- Navegación propuesta para cada rol.

## 3. Sistema visual Lumibell

Se creó un sistema visual centralizado para evitar estilos diferentes entre pantallas.

Archivos principales:

- `lib/theme/lumibell_theme.dart`
- `lib/widgets/lumibell_ui.dart`

El sistema define:

- Paleta azul marino, cobre, crema y colores semánticos.
- Tipografías y jerarquías.
- Botones primarios y secundarios.
- Campos de formulario.
- Tarjetas.
- Bordes, radios y sombras.
- Navegación inferior.
- Estados de carga, error, vacío y éxito.

Componentes compartidos:

- `LumibellLogo`
- `LumibellCard`
- `LumibellSectionTitle`
- `LumibellStatusChip`
- `LumibellStateView`
- `LumibellLoadingView`

También se creó:

`docs/Guia_Estilo_Visual_Lumibell.md`

## 4. Logo y recursos gráficos

Se incorporó el logo oficial compartido por el usuario en:

`assets/images/logo_lumibell.jpg`

El recurso fue registrado en `pubspec.yaml` y se utiliza desde un componente reutilizable.

El encabezado del inicio de sesión dejó de recrear manualmente el logotipo y utiliza el recurso oficial.

## 5. Formato móvil

Se corrigió el comportamiento de la aplicación en navegadores y pantallas grandes.

Cambios:

- Ancho máximo del aplicativo: 430 px.
- Aplicación centrada en escritorio.
- Contenido y footer dentro del mismo viewport móvil.
- Uso completo del ancho disponible en teléfonos.
- Navegación inferior limitada al ancho de la aplicación.
- Sombra exterior ligera para distinguir el aplicativo en escritorio.

La restricción se aplica desde `lib/main.dart` a todas las rutas.

## 6. Inicio administrativo

Se reconstruyó el inicio administrativo según el mockup 1.

Incluye:

- Saludo personalizado.
- Avatar o iniciales.
- Banner de marca.
- Resumen del equipo.
- Número real de colaboradores activos, inactivos y con horario.
- Accesos rápidos.
- Actividad informativa.
- Footer administrativo.

Los accesos disponibles son:

- Colaboradores.
- Horarios.
- Asistencias y QR de sede.
- Reportes, todavía pendiente de implementación real.

## 7. Lista de colaboradores

Se reconstruyó la pantalla del mockup 2.

Incluye:

- Encabezado y botón `Nuevo`.
- Búsqueda por nombre, correo, cargo y código.
- Filtros de todos, activos e inactivos.
- Tarjetas con avatar, nombre, cargo, correo y estado.
- Menú contextual por colaborador.
- Consulta rápida de detalles.
- Activación y desactivación.
- Confirmaciones antes de cambiar el estado.
- Estado vacío.
- Recarga de información.
- Navegación administrativa inferior.

## 8. Crear y editar colaboradores

Se implementó un formulario unificado basado en el mockup 3.

Archivo:

`lib/screens/colaboradores/colaborador_form_screen.dart`

Incluye:

- Información personal.
- Correo y contraseña.
- Rol.
- Sede.
- Código de empleado.
- Cargo.
- Modalidad laboral.
- Tipo de horario.
- Estado activo o inactivo.
- Validaciones de campos.
- Contraseña opcional durante la edición.
- Confirmación visual de guardado.

El supervisor aparece como campo pendiente porque el modelo actual no contiene esa relación.

## 9. Consulta y asignación de horarios

Se reconstruyó el flujo del mockup 4.

Incluye:

- Lista de colaboradores.
- Búsqueda.
- Visualización del horario asignado.
- Estado para colaboradores sin horario.
- Detalle semanal.
- Días laborables y libres.
- Horas de entrada, refrigerio y salida.
- Tolerancia.
- Asignación de un horario existente.
- Cambio de horario.

Archivos principales:

- `lib/screens/horarios/horarios_screen.dart`
- `lib/screens/horarios/horario_colaborador_screen.dart`

## 10. Editor semanal de horarios

Se implementó el editor del mockup 5.

Archivo:

`lib/screens/horarios/horario_editor_screen.dart`

Incluye:

- Datos del colaborador.
- Fecha de vigencia.
- Nombre del horario.
- Tolerancia.
- Configuración de lunes a domingo.
- Activación o desactivación de cada día.
- Hora de entrada.
- Inicio y fin del refrigerio.
- Hora de salida.
- Validación del orden cronológico.
- Confirmación de horario actualizado.

Como el backend no edita directamente un horario histórico, la aplicación crea una nueva versión y la asigna al colaborador. Esto conserva el horario anterior.

## 11. Marcación mediante QR y GPS

Se reconstruyó el flujo del mockup 6.

Archivo:

`lib/screens/asistencia/asistencia_screen.dart`

Incluye:

- Fecha y hora.
- Botón principal para escanear QR.
- Estado del horario del día.
- Estado del GPS.
- Solicitud de permisos de ubicación.
- Escáner mediante la cámara.
- Envío del QR y coordenadas.
- Resultado exitoso.
- Tipo, hora, fecha y ubicación de la marcación.
- Pantalla completa de error.
- Recomendaciones para corregir el problema.

La pantalla permanece disponible aunque el colaborador todavía no tenga horario asignado.

## 12. Perfil del colaborador

Se implementó el mockup 7.

Archivo:

`lib/screens/perfil/perfil_colaborador_screen.dart`

Incluye:

- Foto o iniciales.
- Nombre, cargo y correo.
- Sede.
- Antigüedad calculada.
- Modalidad laboral.
- Tipo y nombre del horario.
- Información de seguridad.
- Cambio real de contraseña.
- Confirmación de cierre de sesión.

El supervisor se presenta como no asignado porque todavía no existe esa relación en la base de datos.

## 13. Mi horario de hoy

Se implementó el mockup 8.

Archivo:

`lib/screens/horarios/mi_horario_screen.dart`

Incluye:

- Fecha del día.
- Entrada.
- Refrigerio.
- Salida.
- Horas requeridas.
- Tolerancia.
- Estado laborable o libre.
- Recordatorio de marcaciones.
- Acceso al horario semanal.
- Vista de los siete días.
- Estados de error y horario no asignado.

## 14. Historial de asistencias

Se implementó el mockup 9.

Archivo:

`lib/screens/asistencia/historial_asistencias_screen.dart`

Incluye:

- Filtro de hoy.
- Filtro semanal.
- Filtro mensual.
- Rango personalizado.
- Navegación entre periodos.
- Total de horas trabajadas.
- Jornadas completas e incompletas.
- Marcaciones agrupadas por día.
- Entrada y salida.
- Duración efectiva de la jornada.
- Descuento del tiempo de refrigerio.
- Detalle de marcaciones por día.
- Sede, tipo, hora y resultado.
- Estado vacío.

## 15. Navegación del administrador

El footer administrativo contiene:

1. Inicio.
2. Colaboradores.
3. Horarios.
4. Perfil.

## 16. Navegación del colaborador

El footer del colaborador se reorganizó para incluir cinco destinos:

1. Inicio.
2. Mi horario.
3. Marcar.
4. Historial.
5. Perfil.

La acción `Marcar` ocupa la posición central por ser la acción operativa principal.

## 17. Servicio HTTP del frontend

Se creó `lib/services/api_service.dart`.

El servicio:

- Incluye el token Bearer.
- Soporta `GET`, `POST`, `PUT` y `DELETE`.
- Envía y recibe JSON.
- Convierte errores del backend en `ApiException`.
- Muestra el mensaje real mediante `toString()`.
- Evita mensajes técnicos como `Instance of ApiException`.

## 18. Dependencias Flutter

Se añadieron:

- `geolocator`: permisos y ubicación GPS.
- `mobile_scanner`: escaneo de QR.
- `qr_flutter`: generación visual del QR.

También se actualizaron los registros generados de plugins para macOS y Windows.

## 19. Permisos Android

Se añadieron al manifiesto:

- Permiso de cámara.
- Permiso de ubicación precisa.

## 20. Cambios del backend

### Empleados

Se añadieron:

- `GET /api/empleados`
  - Lista empleados con usuario, sede y horario.
- `GET /api/empleados/mio`
  - Devuelve el perfil laboral completo del usuario autenticado.
- `GET /api/empleados/mio/horario-semanal`
  - Devuelve únicamente el horario semanal del colaborador autenticado.
- `GET /api/empleados/{id}/horario-hoy`
  - Se utiliza para consultar la jornada del día.

### Horarios

Se añadió:

- `GET /api/horarios`
  - Lista horarios disponibles para administrador y supervisor.

Continúan disponibles:

- `POST /api/horarios`
- `GET /api/horarios/{id}`

### Marcaciones

Se añadió el módulo completo `/api/marcaciones`.

Rutas:

- `POST /api/marcaciones/qr/sede/{sedeId}`
  - Genera un QR temporal para una sede.
- `POST /api/marcaciones`
  - Registra una marcación de colaborador.
- `GET /api/marcaciones/mio`
  - Consulta las marcaciones del usuario autenticado dentro de un rango.

## 21. Seguridad del QR

Los QR utilizan:

- Identificador de sede.
- Fecha de vencimiento.
- Nonce aleatorio.
- Firma HMAC SHA-256.
- Vigencia de dos minutos.

El backend valida:

- Firma.
- Sede.
- Vigencia.
- Usuario activo.
- Sede asignada.
- Coordenadas GPS.
- Radio permitido.
- Secuencia de marcaciones.

La secuencia es:

1. `ENTRADA`
2. `SALIDA_REFRIGERIO`
3. `REGRESO_REFRIGERIO`
4. `SALIDA`

## 22. Modelo y servicios de marcaciones

Se añadieron:

- `server/models/marcaciones.js`
- `server/services/marcaciones.js`
- `server/routes/marcaciones.js`

El servicio calcula la distancia entre el dispositivo y la sede, registra si se encuentra fuera del radio y determina el siguiente tipo de marcación.

## 23. Migraciones y base de datos local

La base Docker existente había sido creada antes de las migraciones de horarios y marcaciones.

Se aplicaron localmente:

- `sql/03_horarios.sql`
- `sql/04_marcaciones.sql`

Esto añadió:

- Tabla `horarios`.
- Tabla `horario_dias`.
- Campo `empleados.horario_id`.
- Tabla `marcaciones`.

Los usuarios y datos anteriores se conservaron.

## 24. Datos de demostración

Se creó:

`sql/05_seed_demo_colaboradores_horarios.sql`

El script es idempotente y agrega:

### Horarios

- Horario Oficina `08:00–17:00`.
- Horario Part Time `09:00–14:00`.

### Colaboradores

- `ana.torres@lumibell.com`
- `juan.perez@lumibell.com`

Password de desarrollo:

`Lumibell2026`

### Asignaciones

- Carlos utiliza el horario part time.
- Ana y Juan utilizan el horario de oficina.

### Historial

Carlos dispone de:

- Una jornada completa con cuatro marcaciones.
- Una jornada incompleta con una entrada.

Estos datos permiten revisar visualmente el horario y el historial sin tener que registrar previamente una jornada completa.

## 25. Docker y entorno local

Se detectó que Docker mantenía una versión antigua del backend.

Se realizaron las siguientes acciones:

- Reconstrucción de la imagen del servidor.
- Recreación de `node_server`.
- Conservación del volumen MySQL.
- Aplicación incremental de migraciones.
- Verificación directa de endpoints autenticados.

## 26. Verificaciones realizadas

Se verificó:

- Inicio de sesión del administrador.
- Inicio de sesión del colaborador.
- Lista de empleados.
- Perfil propio.
- Horario del día.
- Horario semanal.
- Historial propio.
- Dos horarios con siete días.
- Cinco marcaciones de demostración.
- `git diff --check` sin errores de parche.

Pruebas del backend:

- 108 pruebas exitosas.
- 1 prueba fallida relacionada con la especificación OpenAPI de `/api/auth/login`.

La prueba fallida no corresponde al flujo de horarios o marcaciones, pero debe corregirse antes de cerrar la versión.

## 27. Problema conocido con Flutter

Los comandos `flutter analyze`, `dart analyze` y algunos intentos de `flutter build web` permanecieron bloqueados sin producir salida en el entorno actual.

Además, Flutter Web mantuvo en ocasiones compilaciones antiguas después de cambios estructurales.

Cuando esto ocurra:

1. Detener la ejecución desde el IDE.
2. Ejecutar nuevamente la aplicación.
3. Recargar Chrome con `Ctrl + Shift + R`.
4. Iniciar sesión nuevamente.

## 28. Estado actual

- Los cambios se encuentran localmente pendientes de commit.
- El frontend administrativo está funcionalmente avanzado.
- Los flujos principales del colaborador están implementados.
- El backend local Docker contiene las rutas actuales.
- La base local contiene horarios y datos de demostración.

## 29. Funcionalidades pendientes o parciales

- Dashboard administrativo completamente dinámico.
- Actividad reciente real.
- Reportes administrativos.
- Perfil administrativo.
- Relación de supervisor en la base de datos.
- Carga real de fotografías.
- Gestión de dispositivos registrados.
- Solicitudes, permisos y vacaciones.
- Cálculo formal de tardanzas, faltas y balances contra reglas de negocio.
- Corrección de la especificación OpenAPI de autenticación.
- Pruebas de widgets Flutter.
- Validación final de compilación Flutter cuando se resuelva el bloqueo de herramientas.

