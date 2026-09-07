# Alcance Funcional — App Colaborador (Lumibell)

## 1. Objetivo de la Aplicación

Desarrollar una aplicación móvil de gestión de asistencia para empresas pequeñas y medianas, optimizando el control de horas, la puntualidad y la productividad del personal.

### Objetivo General

Mejorar la gestión de la asistencia laboral mediante una herramienta digital centralizada.

### Objetivos Específicos

1. Permitir al colaborador consultar en tiempo real su balance de horas (asistencia, tardanzas, permisos).
2. Brindar al supervisor y al administrador visibilidad completa de la asistencia de todo el equipo.
3. Generar reportes de asistencia ordenados y confiables.
4. Fomentar la autogestión del colaborador, mejorando su puntualidad y productividad.

---

## 2. Objetivo de la Versión 1

Poner a prueba la aplicación internamente en Lumibell Studios con el personal administrativo y sus trabajadores (6 colaboradores). Validar la funcionalidad, el cumplimiento de los objetivos específicos y la utilidad práctica de la herramienta como base para una futura comercialización.

---

## 3. Recursos, Dedicación y Cronograma

### 3.1 Equipo

| Miembro | Rol | Dedicación semanal |
|---------|-----|---------------------|
| Luis Bello | Líder de producto + Desarrollador Frontend (Flutter/Dart) | 4 horas/semana (2 sesiones de 2h) |
| David Ortiz | Desarrollador Backend (Node.js/Express/MySQL) | 2 horas/semana (1 sesión de 2h) |

### 3.2 Herramientas de IA en el Desarrollo

Se utilizarán herramientas de IA como copiloto de desarrollo para acelerar la construcción:

| Herramienta | Uso | Impacto esperado |
|-------------|-----|-------------------|
| **GitHub Copilot / Cursor** | Generación de código Flutter, Dart, JavaScript | Reducción del 40-50% en tiempo de desarrollo de frontend y backend |
| **ChatGPT / Claude** | Generación de esquemas SQL, rutas API, lógica de negocio | Reducción del 30-40% en tiempo de diseño backend |
| **ChatGPT / Claude** | Documentación, diagramas, alcance | Reducción del 50% en tiempo de documentación |
| **Código asistido por IA** | Debugging, corrección de errores de integración | Reducción del 20-30% en tiempo de resolución de problemas |
| **IA generativa** | Generación de widgets UI, prompts de diseño | Reducción del 30% en tiempo de desarrollo de pantallas |

**Nota:** La IA no reemplaza el juicio humano en validación de reglas de negocio, decisiones de UX/UI, ni pruebas en dispositivos reales.

### 3.3 Escenarios de Cronograma

#### Escenario A: Sin herramientas de IA

| Dedicación semanal | Tiempo estimado (V1 completa) | Fecha estimada |
|--------------------|-------------------------------|----------------|
| 6 horas/semana (4+2) | 12-18 meses | Julio 2027 - Ene 2028 |
| 10 horas/semana (6+4) | 7-10 meses | Ene 2027 - Ago 2027 |

#### Escenario B: Con herramientas de IA

| Dedicación semanal | Tiempo estimado (V1 completa) | Fecha estimada |
|--------------------|-------------------------------|----------------|
| 6 horas/semana (4+2) | **4-6 meses** | Ene 2027 - May 2027 |
| 10 horas/semana (6+4) | **2.5-3.5 meses** | Nov 2026 - Feb 2027 |
| 15 horas/semana (10+5) | **2 meses** | Nov 2026 - Dic 2026 |

#### Escenario C: Mínimo viable (V1 con módulos esenciales)

*Solo Login + Inicio + Registro de Asistencia + Historial*

| Dedicación semanal | Tiempo estimado | Fecha estimada |
|--------------------|-----------------|----------------|
| 6 horas/semana con IA | **3-4 meses** | Ene 2027 - Abr 2027 |
| 10 horas/semana con IA | **6-8 semanas** | Nov 2026 - Ene 2027 |

### 3.4 Recomendación

Dado que el Módulo 1 ya está completado y el Módulo 2 tiene DB y API listas, el esfuerzo restante se concentra en los módulos 3-8. El escenario más realista con los recursos actuales es el **Escenario B (6h/semana con IA): 4-6 meses** para la versión completa, o **6-8 semanas** para un MVP funcional con los módulos esenciales.

---

## 4. Alcance de Funcionalidades

Lista de funcionalidades generada a partir de los documentos *APP Colaborador* y *Handoff Fase 2 — Base de Datos*.

### 4.1 Autenticación y Sesión

- **Inicio de sesión:** Acceso mediante credenciales (email y contraseña) con autenticación JWT de 8 horas.
- **Gestión de roles:** Soporte para tres roles: Administrador, Supervisor y Colaborador, asignados directamente al perfil del usuario.
- **Cierre de sesión:** Finalización segura de la sesión desde la pantalla de perfil.
- **Estado del usuario:** Control de estados (Activo, Inactivo, Bloqueado) con validación en cada intento de acceso.
- **Último acceso:** Registro de la fecha y hora del último login por usuario.

### 4.2 Pantalla de Inicio (`InicioScreen`)

- **Dashboard e identidad:** Saludo personalizado, cargo actual, tipo de jornada (Full Time, Part Time, etc.), fecha y hora en tiempo real.
- **Timeline de jornada:** Visualización gráfica horizontal del progreso del día con eventos completados, en curso y pendientes, adaptados al tipo de jornada.
- **Resumen del horario diario:** Consulta rápida de la hora de entrada, refrigerio, salida y jornada requerida del día.
- **Calendario operativo mensual:** Visualización interactiva del mes con estados codificados por colores (asistencia completa, tardanzas, faltas, vacaciones, permisos, feriados y días sin registro).
- **Resumen mensual de incidencias:** Conteo rápido de asistencias completas, tardanzas, faltas, vacaciones y permisos del mes.
- **Próximas vacaciones:** Visualización de los días de descanso programados y acceso a su detalle.
- **Recordatorios contextuales:** Avisos operativos según el estado actual del colaborador.
- **Notificaciones:** Panel de notificaciones con indicador de no leídas y listado de las últimas 5 notificaciones recibidas.

### 4.3 Registro de Asistencia (`RegistrarScreen`)

- **Marcación independiente:** Registro de eventos individuales (Entrada, Salida, Salida de Almuerzo, Regreso de Almuerzo, Salida de Permiso y Regreso de Permiso).
- **Métodos de marcación flexibles:**
  - **Código QR:** Marcación mediante escaneo con validación de tokens temporales por sede.
  - **GPS + Foto:** Marcación mediante validación de ubicación dentro del radio permitido de la sede, con captura de fotografía.
- **Validación de reglas de secuencia en backend:** Restricciones automáticas para evitar dobles entradas consecutivas, salidas sin entrada previa o retornos sin salida previa.
- **Validación de ubicación y conectividad:** Comprobación del estado del GPS, radio de la sede y conexión a internet (Wi-Fi o datos) antes de registrar.
- **Resumen operativo del día:** Visualización en tiempo real de la jornada requerida, horas trabajadas, balance actual, tardanzas y permisos del día.

### 4.4 Historial y Reportes (`HistorialScreen`)

- **Navegación temporal:** Visualización de registros filtrados por Hoy, Semana, Mes o un rango de fechas personalizado.
- **Balance del período:** Comparativa entre las horas trabajadas y las horas requeridas (balance positivo, negativo o exacto).
- **Lista compacta de jornadas:** Historial optimizado para dispositivos móviles que muestra fecha, horas de entrada/salida, jornada trabajada, balance diario y estado mediante badges de color.
- **Filtros avanzados:** Opciones para acotar la búsqueda por estado de jornada, tardanzas, faltas, permisos o vacaciones.

### 4.5 Gestión de Solicitudes (`SolicitudesScreen`)

- **Creación de solicitudes dinámicas:** Opciones para solicitar permisos personales (por horas o tiempo parcial), vacaciones, corrección de asistencia, compensación de horas extras o emisión de documentos.
- **Resumen de estado:** Conteo rápido de solicitudes pendientes, aprobadas, rechazadas y con observación en el período.
- **Seguimiento y trazabilidad:** Listado de solicitudes recientes con detalle de fechas, motivos, estados y la trazabilidad de aprobación (cargo y nombre del aprobador).

### 4.6 Aprobaciones y Horas Compensables

- **Aprobación de solicitudes:** El Supervisor y el Administrador pueden aprobar o rechazar solicitudes de permisos, vacaciones, correcciones de asistencia y compensación de horas extras.
- **Jerarquía de aprobación:** Las solicitudes del Supervisor son aprobadas por el Administrador. Las solicitudes del Colaborador son aprobadas por el Supervisor.
- **Correcciones de asistencia:** Requieren aprobación explícita antes de ser aplicadas al registro.
- **Horas compensables:** Seguimiento de horas extras acumulables como compensación futura.

### 4.7 Horarios (`HorariosScreen`)

- **Horarios fijos:** Configuración de horario estándar todos los días de la semana.
- **Horarios variables:** Horarios que cambian según el día o la semana.
- **Horarios rotativos:** Turnos que rotan periódicamente (mañana, tarde, noche) según mes asignado.
- **Horarios flexibles:** Horarios con rangos de entrada y salida flexibles por día.
- **Horarios personalizados:** Configuración individualizada del horario del colaborador.
- **Consulta semanal:** Visualización detallada del horario asignado por día de la semana, incluyendo días de descanso.

### 4.8 Perfil y Configuración (`PerfilScreen`)

- **Información laboral:** Datos clave como rol, modalidad laboral (Full Time, Part Time), tipo de horario, sede asignada, supervisor a cargo y antigüedad.
- **Consulta de horario semanal:** Visualización detallada del horario asignado por día de la semana.
- **Configuraciones básicas de usuario:** Ajuste de preferencias personales como activación/desactivación de notificaciones, selección de tema (Claro, Oscuro o Automático) e idioma (Español o Inglés).
- **Cierre de sesión:** Finalización segura de la sesión desde la pantalla de perfil.

---

## 5. Fuera del Alcance

Los siguientes elementos **no están contemplados** en el alcance del proyecto:

- **Funcionamiento offline:** La aplicación requiere conexión a internet en todo momento. No se permite la marcación ni consulta sin conectividad.
- **Autorregistro de empleados:** Los usuarios son creados y dados de alta por el Administrador. No existe flujo de auto-registro.
- **Dashboard web administrativo:** Solo se desarrolla la aplicación móvil. No se incluye un panel web de gestión.
- **Procesamiento de nómina:** Se gestionan horas y compensaciones, pero no el cálculo de sueldos ni pagos.
- **Notificaciones push:** Las notificaciones son exclusivamente dentro de la aplicación (almacenadas en la base de datos). No se integran servicios de push (Firebase/APN).
- **Exportación de reportes:** Los reportes se consultan en pantalla. No se incluye exportación a PDF ni Excel.
- **Integración con sistemas externos:** No se contemplan integraciones con sistemas de RRHH, contabilidad ni payroll.
- **Geofencing dinámico:** El radio de tolerancia por sede es configurado por el Administrador y es fijo. No es configurable por el colaborador.
- **Multi-empresa / Multi-sede avanzada:** La aplicación está diseñada para una sola empresa con sedes asignadas a cada colaborador, sin gestión multi-tenant.
- **Mensajería interna:** No incluye funcionalidad de chat o comunicación entre usuarios.
- **Registro de ventas o punto de venta:** Es exclusivamente una aplicación de control de asistencia.

---

## 6. Arquitectura Tecnológica

```
Flutter (Frontend) → API REST (Node.js / Express) → MySQL (Base de Datos)
```

- **Desarrollo local:** Docker Compose con MySQL 8.0 y Node.js.
- **Autenticación:** JWT con token de 8 horas.
- **Base de datos:** MySQL 8.0 con esquema relacional (tablas: `usuarios`, `sedes`, `empleados`, `marcaciones`, `balances_diarios`, `notificaciones`).
- **Estados de usuario:** ACTIVO, INACTIVO, BLOQUEADO.
- **Roles:** ADMINISTRADOR, SUPERVISOR, COLABORADOR.

---

## 7. Progreso del Desarrollo

| Módulo | Esquema BD | API | Pantallas | Conexión | Estado |
|--------|------------|-----|-----------|----------|--------|
| 1. Login | ✅ | ✅ | ✅ | ✅ | **Completado** |
| 2. Inicio | ✅ | ✅ | ⬜ | ⬜ | **Pendiente** |
| 3. Registrar Asistencia | ⬜ | ⬜ | ⬜ | ⬜ | **Pendiente** |
| 4. Historial | ⬜ | ⬜ | ⬜ | ⬜ | **Pendiente** |
| 5. Solicitudes | ⬜ | ⬜ | ⬜ | ⬜ | **Pendiente** |
| 6. Aprobaciones | ⬜ | ⬜ | ⬜ | ⬜ | **Pendiente** |
| 7. Horarios | ⬜ | ⬜ | ⬜ | ⬜ | **Pendiente** |
| 8. Perfil | ⬜ | ⬜ | ⬜ | ⬜ | **Pendiente** |
| Integración y despliegue | — | — | — | — | **Pendiente** |
