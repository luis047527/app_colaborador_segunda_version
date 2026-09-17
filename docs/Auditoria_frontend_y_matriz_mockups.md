# Auditoría del frontend y matriz de mockups

## Propósito

Este documento fija el punto de partida para la reingeniería visual móvil de Lumibell. Los mockups de `docs/Mock ups` son la referencia principal para composición, jerarquía, colores, navegación y estados de interfaz.

## Estado técnico actual

- El frontend está construido con Flutter y Material 3.
- La autenticación y el token se administran mediante `AuthService` y Provider.
- Existe un servicio HTTP básico para solicitudes `GET`, `POST`, `PUT` y `DELETE`.
- No existe todavía un sistema visual compartido: colores, tarjetas, botones y campos están declarados directamente en las pantallas.
- No existen pruebas Flutter en la carpeta `test`.
- La navegación combina `Navigator.push` con barras inferiores locales; aún no existe un contenedor de navegación persistente por rol.
- Las pantallas de colaboradores y horarios concentran presentación, estado y llamadas HTTP en el mismo archivo.
- Existen textos con caracteres dañados por codificación que deben normalizarse durante la reingeniería.
- `flutter analyze` no produjo salida y tuvo que cancelarse después de más de dos minutos. Debe repetirse al terminar la preparación técnica.

## Sistema visual identificado en los mockups

### Identidad

- Azul marino para títulos, navegación e información principal.
- Marrón/cobre para acciones primarias y selección activa.
- Blanco cálido y crema para fondos y superficies.
- Verde para éxito y estado activo.
- Rojo para error, falta y estado inactivo.
- Naranja para tardanza y refrigerio.
- Violeta para permisos y estados complementarios.

### Componentes recurrentes

- Encabezado móvil con título centrado y acción lateral.
- Tarjetas blancas con bordes suaves, radios amplios y sombra ligera.
- Botones primarios marrones de ancho completo.
- Botones secundarios blancos con borde marrón.
- Campos de formulario con borde gris azulado y etiquetas superiores.
- Chips y etiquetas de estado con fondo tonal.
- Filas con icono dentro de un contenedor circular o redondeado.
- Navegación inferior de cuatro destinos con destino activo sobre fondo crema.
- Estados dedicados de carga, vacío, éxito y error.

### Criterio móvil

- La interfaz debe diseñarse primero para teléfonos.
- Debe respetar `SafeArea`, teclado y barras del sistema.
- El contenido largo debe desplazarse verticalmente.
- Los controles táctiles deben conservar un tamaño mínimo cómodo.
- El contenido puede limitar su ancho en pantallas grandes sin alterar la composición móvil.

## Matriz mockup–implementación

| Mockup | Pantalla objetivo | Estado actual | Soporte del backend | Trabajo requerido |
|---|---|---|---|---|
| 1. Inicio administrador | Inicio administrativo | Parcial | No existe endpoint de dashboard o actividad | Reconstruir visualmente; usar datos disponibles y señalar datos temporales |
| 2. Lista de colaboradores | Gestión de colaboradores | Parcial | Lista de empleados disponible | Agregar búsqueda, filtros, estados, menú de acciones y estado vacío |
| 3. Crear/editar colaborador | Formulario de colaborador | Creación básica | Usuario y empleado admiten creación/edición | Separar crear/editar, cargar datos, validar y reproducir secciones del mockup |
| 4. Asignar horario | Selección y detalle por colaborador | Diálogo básico | Lista de empleados, actualización de empleado y consulta de horario | Crear flujo móvil dedicado con búsqueda y detalle semanal |
| 5. Editar horario | Editor semanal | Creación básica | Se puede crear y consultar; no actualizar un horario existente | Crear UI completa; la persistencia de edición requerirá ampliar backend o crear una nueva vigencia |
| 6. Registro de marcación | Escaneo y resultado | Parcial | Generación de QR y marcación disponibles | Crear pantalla de preparación, escáner, éxito y error dedicados |
| 7. Perfil | Perfil del colaborador | No implementado | Usuario propio disponible; perfil laboral propio devuelve solo el ID | Crear interfaz; ampliar datos del endpoint propio para contenido laboral completo |
| 8. Mi horario de hoy | Jornada diaria | Básico | Horario del día disponible | Reconstruir tarjetas, tolerancia, estado del día y accesos secundarios |
| 9. Historial de asistencias | Historial y resumen | No implementado | No existe endpoint de historial | Preparar estructura visual; requiere endpoint para datos reales, filtros y balances |

## Navegación objetivo

### Administrador

1. Inicio
2. Colaboradores
3. Horarios
4. Perfil

### Colaborador

1. Inicio o resumen del día
2. Marcar
3. Mi horario o historial, según el flujo consolidado
4. Perfil

Antes de implementar la barra del colaborador se unificará la diferencia entre los mockups 6, 8 y 9 para evitar destinos que cambien de posición.

## Funcionalidad utilizable sin modificar el backend

- Inicio de sesión y cierre de sesión.
- Datos básicos del usuario autenticado.
- Lista, creación, actualización y desactivación de usuarios.
- Lista, creación y actualización de empleados.
- Lista y detalle de sedes.
- Lista, creación y detalle de horarios.
- Asignación de horario a un empleado.
- Consulta del horario del día.
- Generación de QR temporal por sede.
- Registro secuencial de marcaciones con QR y GPS.

## Dependencias funcionales pendientes

- Dashboard administrativo con indicadores y actividad real.
- Historial y detalle de marcaciones.
- Resumen de horas, tardanzas, permisos, vacaciones y faltas.
- Actualización versionada de horarios existentes.
- Perfil laboral propio completo.
- Supervisores disponibles para asignación.
- Carga real de fotografías si se requiere almacenamiento de archivos y no solo URL.

## Orden aprobado de reconstrucción

1. Sistema visual y componentes compartidos.
2. Contenedores de navegación móvil por rol.
3. Inicio administrativo.
4. Lista y formulario de colaboradores.
5. Gestión y asignación de horarios.
6. Jornada y marcación del colaborador.
7. Perfil del colaborador.
8. Historial cuando exista soporte de datos.
9. Comparación visual, análisis estático y pruebas.

