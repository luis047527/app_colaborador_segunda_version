# Alcance Funcional --- App Colaborador (Lumibell)

## Versión MVP --- Plan de implementación de 1 mes

## 1. Objetivo de la Aplicación

Desarrollar una aplicación móvil de gestión de asistencia para Lumibell
Studios, orientada a controlar de forma confiable la jornada laboral de
sus colaboradores.

La aplicación permitirá registrar y validar marcaciones mediante QR
dinámico y GPS, utilizar horarios personalizados por colaborador,
calcular las horas trabajadas frente a las horas requeridas y consultar
el historial y balance de asistencia.

**Núcleo funcional:** Usuario → Horario → Marcación → Validación →
Cálculo → Historial.

## 2. Objetivo de la Versión MVP

Implementar en aproximadamente un mes una versión funcional para prueba
interna que permita:

1.  Al Administrador crear y gestionar usuarios colaboradores.
2.  Al Administrador crear y asignar un horario personalizado a cada
    colaborador.
3.  Al colaborador consultar su horario del día.
4.  Al colaborador registrar marcaciones mediante QR dinámico + GPS.
5.  Validar las marcaciones desde el backend.
6.  Determinar si llegó temprano, dentro de la tolerancia o tarde.
7.  Calcular horas trabajadas y horas requeridas.
8.  Calcular balance positivo, negativo o exacto.
9.  Consultar marcaciones e historial.
10. Permitir al Administrador y Supervisor consultar la asistencia.
11. Registrar vacaciones de forma básica, sin solicitudes ni
    aprobaciones.

## 3. Recursos y Dedicación

  Miembro       Rol                                         Dedicación
  ------------- ------------------------------------------- ----------------
  Luis Bello    Líder de producto + Frontend Flutter/Dart   4 h/semana
  David Ortiz   Backend Node.js/Express/MySQL               4 h/semana
  **Total**     **Equipo**                                  **8 h/semana**

**Disponibilidad objetivo: 32 horas durante 4 semanas.**

Se utilizarán herramientas de IA para acelerar
generación/refactorización de código, SQL, API, debugging y
documentación. La validación humana seguirá siendo necesaria para reglas
de negocio, seguridad, integración y pruebas reales.

## 4. Cronograma de 1 Mes

### Semana 1 --- Base técnica y reglas

-   Auditar Flutter, API y BD existentes.
-   Definir tablas y relaciones.
-   Gestión de usuarios colaboradores.
-   Horarios personalizados.
-   Definir reglas de cálculo.
-   Definir estados de marcación.

**Resultado:** base técnica preparada.

### Semana 2 --- Marcación

-   QR dinámico y temporal.
-   GPS.
-   Validación de sede/radio.
-   Hora oficial del servidor.
-   Validación de secuencia.
-   Entrada, salida de refrigerio, regreso de refrigerio y salida.
-   Persistencia en MySQL.

**Criterios de aceptación — Aplicativo del colaborador:**

-   [ ] **CA-01. Verificación de ubicación:** al pulsar el botón de verificación,
    el aplicativo obtiene la ubicación actual mediante GPS y la compara con
    las coordenadas y el radio de tolerancia configurados para la sede. La
    ubicación se considera válida cuando la distancia es menor o igual al
    radio permitido.
-   [ ] **CA-02. Estado del botón de escaneo:** antes de validar la ubicación,
    el botón de escaneo de QR permanece deshabilitado. Cuando la verificación
    es correcta, se habilita y cambia de color para indicar que se puede
    continuar. Si la verificación falla, permanece deshabilitado.
-   [ ] **CA-03. Tipo y secuencia de marcación:** el colaborador puede elegir
    el tipo de marcación que corresponde a su horario. El sistema permite
    entrada, salida de refrigerio, regreso de refrigerio y salida en ese
    orden; para horarios sin refrigerio, permite entrada y salida. Una
    selección fuera de secuencia o una marcación duplicada se rechaza con
    un mensaje explicativo.
-   [ ] **CA-04. Avisos de ubicación:** si el colaborador está fuera del radio
    permitido, se muestra un aviso claro y no se permite continuar con el
    escaneo. Si no es posible obtener la ubicación, se informa el problema
    y se permite reintentar la verificación.
-   [ ] **CA-05. QR dinámico y temporal:** el sistema valida que el QR escaneado
    corresponda a la sede y esté vigente. Un QR vencido, inválido o de otra
    sede genera un aviso específico y no produce una marcación aceptada.
-   [ ] **CA-06. Hora oficial:** cada marcación aceptada recibe la fecha y hora
    del servidor del aplicativo. Cambiar la hora del dispositivo no altera
    la hora registrada.
-   [ ] **CA-07. Persistencia e historial:** cada marcación aceptada se guarda
    en MySQL y aparece en el historial del colaborador con su tipo, fecha y
    hora oficial, presentada en la zona horaria de Lima. La información
    permanece disponible al cerrar y volver a abrir el aplicativo.

**Criterios de aceptación — Aplicativo del administrador y supervisor:**

-   [ ] **CA-08. Consulta de marcaciones:** tanto el administrador como el
    supervisor pueden visualizar las marcaciones de todos los colaboradores
    activos, identificando al colaborador, el tipo de marcación, la sede y
    la fecha y hora registradas. La información coincide con la mostrada
    en el historial del colaborador.

La consulta básica del historial y la visualización administrativa de
marcaciones se incluyen en esta semana; se complementarán con el cálculo y
las consultas previstas para las semanas 3 y 4.

**Condición de cumplimiento de la Semana 2:** se considera completada cuando
todos los criterios CA-01 a CA-08 han sido verificados en el flujo integrado
del aplicativo, API y MySQL. Debe quedar evidencia del resultado de cada
criterio, incluyendo una marcación válida de extremo a extremo, los casos
de rechazo descritos y la consulta con los roles colaborador, administrador
y supervisor. Las casillas se marcan únicamente después de su verificación;
los criterios pendientes o fallidos impiden dar la semana por cumplida.

**Resultado esperado:** marcación funcional de extremo a extremo, con
validación de ubicación y QR, hora oficial persistida e historial consultable
por los roles correspondientes.

### Semana 3 --- Cálculo e historial

-   Horas requeridas.
-   Horas trabajadas.
-   Tardanza.
-   Llegada anticipada.
-   Balance positivo/negativo.
-   Historial de hoy, semana y mes.
-   Visualización de marcaciones.

**Resultado:** el sistema determina el cumplimiento de la jornada.

### Semana 4 --- Administración, vacaciones y pruebas

-   Consulta administrativa de asistencia.
-   Registro básico de vacaciones.
-   Integración Flutter/API/BD.
-   Pruebas reales.
-   Corrección de errores críticos.
-   Preparación del MVP.

**Resultado:** MVP listo para prueba interna.

# 5. Alcance de Funcionalidades

## 5.1 Autenticación y Sesión

-   Login mediante email y contraseña.
-   JWT.
-   Roles: Administrador, Supervisor y Colaborador.
-   Validación de estado del usuario.
-   Cierre de sesión.
-   Último acceso.

## 5.2 Gestión de Usuarios

El Administrador podrá: - crear colaboradores; - editar información; -
activar/desactivar usuarios; - consultar información; - asignar sede; -
asignar supervisor cuando corresponda.

Datos mínimos: - nombres; - apellidos; - email; - contraseña inicial; -
rol; - estado; - sede; - supervisor.

Estados: ACTIVO, INACTIVO, BLOQUEADO.

No existirá autorregistro.

## 5.3 Horarios Personalizados

El Administrador podrá crear y asignar un horario individual a cada
colaborador.

El horario podrá definir: - entrada; - inicio y fin de refrigerio; -
salida; - horas requeridas; - tolerancia; - días laborables; - días de
descanso.

Para el MVP se implementará únicamente el horario personalizado por
colaborador.

No se implementarán inicialmente horarios rotativos ni esquemas
flexibles avanzados.

## 5.4 Registro de Asistencia

Será el núcleo del MVP.

Tipos: - Entrada; - Salida de refrigerio; - Regreso de refrigerio; -
Salida.

Método: - **QR dinámico + GPS**.

El QR utilizará un token temporal asociado a la sede.

El sistema validará: - usuario válido y activo; - tipo de marcación
permitido; - secuencia correcta; - QR válido y vigente; - sede; -
ubicación dentro del radio; - fecha/hora oficial; - conectividad.

El backend será la autoridad para aceptar o rechazar una marcación.

## 5.5 Estado de Jornada

Estados mínimos: - NO INICIADA; - EN CURSO; - COMPLETA; - INCOMPLETA; -
VACACIONES; - DESCANSO.

La app mostrará la siguiente marcación disponible.

## 5.6 Control de Llegada

Comparará hora programada contra hora real y determinará: - llegada
anticipada; - llegada dentro de tolerancia; - llegada tarde.

## 5.7 Cálculo de Asistencia

Calculará: - horas requeridas; - horas trabajadas; - tardanza; - llegada
anticipada; - balance positivo; - balance negativo; - balance exacto; -
estado de jornada.

**Balance = Horas trabajadas − Horas requeridas.**

Ejemplo: 8 h 20 min trabajadas − 8 h requeridas = **+20 min**.

El balance a favor/en contra sí forma parte del MVP.

### Fuera del MVP: gestión de horas extras compensables

No se implementará: - banco de horas; - acumulación para compensación; -
solicitud de compensación; - aprobación de horas extras; - uso posterior
de horas acumuladas.

## 5.8 Pantalla de Registro de Marcación

Debe mostrar: - fecha y hora oficial; - horario de hoy; - entrada,
refrigerio y salida; - horas requeridas; - tolerancia; - estado de
llegada; - próxima marcación; - botón ESCANEAR QR; - estado del GPS; -
sede; - validación de ubicación.

La pantalla será exclusiva para la marcación, evitando sobrecargarla con
historial, solicitudes u otra información secundaria.

## 5.9 Historial de Asistencia

Cada colaborador podrá consultar: - Hoy; - Semana; - Mes.

Por jornada: - fecha; - entrada; - salida de refrigerio; - regreso; -
salida; - horas trabajadas; - horas requeridas; - tardanza; - llegada
anticipada; - balance; - estado.

## 5.10 Consulta Administrativa

Administrador y Supervisor podrán consultar: - colaborador; - fecha; -
horario; - marcaciones; - horas requeridas; - horas trabajadas; -
tardanza; - balance; - estado.

No se desarrollará un dashboard administrativo avanzado en el MVP.

## 5.11 Vacaciones

El Administrador podrá registrar vacaciones directamente.

En un día de vacaciones: - no se requiere marcación; - horas requeridas
= 0; - no genera balance negativo; - estado = VACACIONES.

No habrá solicitudes ni aprobación de vacaciones en el MVP.

## 5.12 Perfil

Información básica: - nombre; - rol; - sede; - supervisor; - horario
asignado.

También podrá cerrar sesión.

# 6. Fuera del Alcance del MVP

### Solicitudes y permisos

-   solicitudes de permisos;
-   aprobación/rechazo;
-   permisos por horas o parciales;
-   flujo de solicitudes.

### Correcciones

-   solicitud de corrección;
-   aprobación de corrección;
-   trazabilidad avanzada.

### Horas extras compensables

-   banco de horas;
-   acumulación para compensación;
-   solicitud;
-   aprobación;
-   utilización posterior.

**El cálculo de balance positivo/negativo sí está incluido.**

### Horarios avanzados

-   rotativos;
-   flexibles avanzados;
-   múltiples esquemas complejos.

### Otras funciones

-   notificaciones push;
-   chat;
-   PDF/Excel;
-   nómina;
-   integraciones externas;
-   multiempresa/multi-tenant;
-   geofencing avanzado;
-   ventas/POS.

# 7. Arquitectura Tecnológica

``` text
Flutter (Frontend)
        ↓
API REST
Node.js / Express
        ↓
MySQL
```

Entidades principales: - usuarios; - colaboradores; - sedes; -
horarios; - marcaciones; - balances diarios; - vacaciones.

# 8. Flujo Principal

``` text
ADMINISTRADOR
     ↓
CREA COLABORADOR
     ↓
ASIGNA SEDE
     ↓
CREA HORARIO PERSONALIZADO
     ↓
COLABORADOR INICIA SESIÓN
     ↓
CONSULTA HORARIO
     ↓
MARCA ENTRADA
     ↓
QR + GPS
     ↓
VALIDACIÓN BACKEND
     ↓
GUARDA MARCACIÓN
     ↓
MOTOR DE CÁLCULO
     ↓
HORAS / TARDANZA / BALANCE
     ↓
HISTORIAL
```

# 9. Prioridades del MVP

  Prioridad   Funcionalidad
  ----------- ---------------------------------------
  P0          Login y roles
  P0          Crear usuarios colaboradores
  P0          Crear/asignar horarios personalizados
  P0          Marcación QR
  P0          GPS y validación de sede
  P0          Hora oficial del servidor
  P0          Validación de secuencia
  P0          Guardar marcaciones
  P0          Cálculo de horas
  P0          Tardanza/llegada anticipada
  P0          Balance a favor/en contra
  P0          Historial
  P0          Consulta de asistencia
  P1          Vacaciones básicas
  P1          Mejoras administrativas
  Posterior   Solicitudes y permisos
  Posterior   Horas extras compensables
  Posterior   Horarios rotativos/flexibles

# 10. Progreso del Desarrollo

  Módulo                    BD    API   Pantallas   Conexión   Estado
  ------------------------- ----- ----- ----------- ---------- ----------------
  Login                     ✅    ✅    ✅          ✅         **Completado**
  Gestión de usuarios       ⬜    ⬜    ⬜          ⬜         Pendiente
  Horarios personalizados   ⬜    ⬜    ⬜          ⬜         Pendiente
  Marcación QR              ⬜    ⬜    ⬜          ⬜         Pendiente
  GPS / sede                ⬜    ⬜    ⬜          ⬜         Pendiente
  Motor de cálculo          ⬜    ⬜    ⬜          ⬜         Pendiente
  Historial                 ⬜    ⬜    ⬜          ⬜         Pendiente
  Vacaciones básicas        ⬜    ⬜    ⬜          ⬜         Pendiente
  Consulta administrativa   ⬜    ⬜    ⬜          ⬜         Pendiente
  Perfil básico             ⬜    ⬜    ⬜          ⬜         Pendiente
  Integración y pruebas     ---   ---   ---         ⬜         Pendiente

# 11. Criterio de Éxito del MVP

El MVP será considerado funcional cuando:

1.  El Administrador pueda crear un colaborador.
2.  El Administrador pueda asignarle una sede.
3.  El Administrador pueda crear y asignarle un horario personalizado.
4.  El colaborador pueda iniciar sesión.
5.  El colaborador pueda visualizar su horario.
6.  El colaborador pueda registrar Entrada mediante QR + GPS.
7.  El backend pueda validar y almacenar la marcación.
8.  El colaborador pueda realizar las marcaciones siguientes según la
    secuencia.
9.  El sistema pueda calcular horas trabajadas y requeridas.
10. El sistema pueda determinar tardanza o llegada anticipada.
11. El sistema pueda calcular balance positivo o negativo.
12. El colaborador pueda consultar su historial.
13. Administrador/Supervisor pueda consultar la asistencia.
14. Un día de vacaciones no genere horas pendientes.

## Objetivo final

**Que Lumibell pueda registrar de forma confiable la asistencia de sus
colaboradores y determinar si cada colaborador cumplió su jornada
laboral según su horario personalizado.**
