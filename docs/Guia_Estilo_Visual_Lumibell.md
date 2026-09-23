# Guía de estilo visual — App de Asistencias Lumibell

## 1. Propósito

Esta guía documenta la identidad visual utilizada en la aplicación móvil de asistencias Lumibell. Su objetivo es mantener consistencia entre las pantallas administrativas y las pantallas del colaborador.

Los mockups ubicados en `docs/Mock ups` son la referencia visual principal. La interfaz mostrada dentro de los teléfonos es la fuente de diseño; los textos explicativos y elementos publicitarios alrededor de los dispositivos no forman parte de la aplicación.

## 2. Principios de diseño

- Diseño pensado primero para teléfonos.
- Apariencia limpia, cálida y profesional.
- Jerarquía visual clara mediante color, tamaño y espaciado.
- Acciones principales visibles y fáciles de tocar.
- Uso consistente de tarjetas, iconos y etiquetas de estado.
- Información importante disponible sin sobrecargar la pantalla.
- Estados de carga, error, éxito y ausencia de información claramente diferenciados.
- Navegación estable según el rol del usuario.

## 3. Identidad de marca

### Logo

El logo oficial se encuentra en:

`assets/images/logo_lumibell.jpg`

Reglas de uso:

- Mantener sus proporciones originales.
- No deformarlo, rotarlo ni cambiar sus colores.
- Usarlo sobre fondos claros o crema.
- Conservar suficiente espacio libre alrededor.
- Evitar colocarlo dentro de espacios demasiado pequeños donde el texto pierda legibilidad.

### Personalidad visual

La identidad combina:

- Azul marino para confianza, estructura e información principal.
- Marrón cobre para marca, acciones principales y elementos seleccionados.
- Tonos crema y durazno para calidez.
- Blanco para superficies y tarjetas.
- Colores semánticos para estados operativos.

## 4. Paleta de colores

### Colores principales

| Uso | Color | Código |
|---|---|---|
| Azul principal | Navy | `#102650` |
| Texto secundario | Navy suave | `#526986` |
| Acción principal | Cobre | `#8D3517` |
| Cobre oscuro | Cobre oscuro | `#672713` |
| Fondo cálido | Durazno | `#F4DDCB` |
| Fondo cálido suave | Durazno suave | `#FFF2E8` |
| Fondo de la aplicación | Canvas | `#FFFCF9` |
| Superficies | Blanco | `#FFFFFF` |
| Bordes | Gris cálido | `#ECE7E2` |
| Fondo de campos | Gris azulado | `#F3F6FA` |

### Colores semánticos

| Estado | Color principal | Fondo tonal |
|---|---|---|
| Éxito / activo | `#149B58` | `#E6F8ED` |
| Error / inactivo | `#E84343` | `#FFEBEC` |
| Advertencia / tardanza | `#F47B20` | `#FFF0E4` |
| Información | `#2677E8` | `#EAF3FF` |
| Permiso / estado adicional | `#7654D8` | `#F0EAFF` |

### Reglas de color

- El cobre se reserva para acciones principales, selección activa y elementos de marca.
- El azul marino se utiliza para títulos, iconos estructurales y texto importante.
- El texto secundario debe usar azul marino suave.
- Los fondos semánticos deben combinarse con su color principal correspondiente.
- No usar únicamente el color para comunicar un estado; acompañarlo con texto o icono.

## 5. Tipografía y jerarquía

La aplicación utiliza la tipografía predeterminada de Flutter y del sistema operativo para evitar dependencias externas y conservar buena legibilidad.

| Nivel | Tamaño aproximado | Peso | Uso |
|---|---:|---:|---|
| Encabezado grande | 28 px | 800 | Saludos y títulos destacados |
| Encabezado medio | 24 px | 800 | Títulos principales |
| Título de sección | 20 px | 800 | Secciones de pantalla |
| Título de componente | 16 px | 700 | Tarjetas y filas |
| Texto principal | 16 px | 400 | Contenido relevante |
| Texto secundario | 14 px | 400 | Descripciones y ayudas |
| Etiqueta pequeña | 10–12 px | 500–700 | Estados, fechas y navegación |

Reglas:

- Utilizar azul marino en títulos.
- Utilizar azul suave en textos secundarios.
- Evitar más de tres niveles tipográficos dentro de una misma tarjeta.
- Limitar textos extensos y permitir puntos suspensivos cuando corresponda.

## 6. Espaciado

Escala utilizada:

| Nombre | Valor |
|---|---:|
| Extra pequeño | 4 px |
| Pequeño | 8 px |
| Medio | 12 px |
| Grande | 16 px |
| Extra grande | 20 px |
| Sección | 24 px |

El margen horizontal estándar de las pantallas es de `20 px`.

Reglas:

- Separar secciones principales entre 20 y 24 px.
- Separar elementos relacionados entre 8 y 12 px.
- Evitar que textos o controles toquen los bordes de la pantalla.
- Mantener un ritmo vertical uniforme.

## 7. Bordes, radios y sombras

| Elemento | Radio recomendado |
|---|---:|
| Elemento pequeño | 10 px |
| Campo o botón | 14 px |
| Tarjeta | 18 px |
| Contenedor destacado | 24 px |
| Chip de estado | Radio completo |

Las tarjetas utilizan:

- Fondo blanco.
- Borde `#ECE7E2`.
- Sombra suave y poco contrastada.
- Elevación visual discreta.

No utilizar sombras oscuras o intensas.

## 8. Formato móvil y comportamiento responsive

- El ancho máximo del aplicativo en navegador es de `430 px`.
- En teléfonos se utiliza todo el ancho disponible.
- En escritorio, la aplicación se centra sobre un fondo neutro.
- El contenido y la navegación inferior deben permanecer dentro del mismo viewport móvil.
- Todas las pantallas deben respetar `SafeArea`.
- Los formularios deben desplazarse cuando aparece el teclado.
- El contenido largo debe utilizar desplazamiento vertical.
- Los elementos interactivos deben tener aproximadamente 44–48 px de área táctil mínima.

## 9. Encabezados

Los encabezados móviles deben contener:

- Flecha de regreso cuando la pantalla es secundaria.
- Título centrado.
- Acción lateral únicamente cuando sea necesaria.
- Subtítulo pequeño cuando ayude a explicar el flujo.

Ejemplos:

- `Colaboradores` + botón `Nuevo`.
- `Asignar horario` + subtítulo `Selecciona un colaborador`.
- `Mi horario de hoy` sin acciones adicionales.

## 10. Botones

### Botón primario

- Fondo cobre.
- Texto blanco.
- Altura aproximada de 52 px.
- Radio de 14 px.
- Peso de texto 700.
- Utilizado para guardar, crear, confirmar o escanear.

### Botón secundario

- Fondo blanco.
- Borde cobre.
- Texto cobre.
- Misma altura y radio del botón primario.

### Botones destructivos

- Utilizar rojo únicamente para acciones como desactivar o eliminar.
- Solicitar confirmación antes de ejecutar la acción.

### Botones deshabilitados

- Fondo durazno suave.
- Contraste reducido.
- No deben responder a eventos táctiles.

## 11. Campos de formulario

- Fondo blanco.
- Borde gris cálido.
- Radio de 14 px.
- Etiqueta descriptiva visible.
- Borde cobre al obtener foco.
- Borde rojo cuando existe un error.
- Mensajes de validación breves y específicos.

Los campos obligatorios pueden identificarse con `*`.

Los formularios deben dividirse en secciones, por ejemplo:

- Información personal.
- Datos de acceso.
- Rol y sede.
- Información laboral.
- Estado.

## 12. Tarjetas

Las tarjetas son el componente principal para agrupar información.

Usos:

- Resumen del equipo.
- Colaboradores.
- Horarios.
- Datos del perfil.
- Información de marcaciones.
- Resumen del historial.

Una tarjeta puede contener:

- Icono tonal.
- Título.
- Texto secundario.
- Estado.
- Acción o indicador de navegación.

No incluir demasiadas acciones dentro de una misma tarjeta.

## 13. Iconografía

Se utilizan iconos de Material Symbols/Icons.

Reglas:

- Mantener el mismo icono para la misma función.
- Usar contenedores circulares o redondeados con fondo tonal.
- Usar azul marino o cobre para acciones estructurales.
- Usar colores semánticos para estados.
- No mezclar estilos de iconos sin una razón funcional.

Ejemplos:

| Función | Icono sugerido |
|---|---|
| Inicio | `home` |
| Colaboradores | `groups` |
| Horarios | `calendar_month` |
| Marcar | `qr_code_scanner` |
| Historial | `history` / `event_note` |
| Perfil | `person` |
| Ubicación | `location_on` |
| Éxito | `check` |
| Error | `close` |

## 14. Etiquetas de estado

Los chips de estado utilizan fondo tonal, texto semántico y radio completo.

Ejemplos:

- Activo: verde.
- Inactivo: rojo.
- Laborable: verde.
- Libre: gris azulado.
- Completo: verde.
- Incompleto o tardanza: naranja.
- Permiso: violeta.
- Error o falta: rojo.

## 15. Navegación

### Administrador

El footer administrativo contiene cuatro destinos:

1. Inicio.
2. Colaboradores.
3. Horarios.
4. Perfil.

### Colaborador

El footer del colaborador contiene cinco destinos:

1. Inicio.
2. Mi horario.
3. Marcar.
4. Historial.
5. Perfil.

`Marcar` ocupa la posición central por ser la acción operativa principal.

El destino activo utiliza:

- Icono cobre.
- Texto cobre.
- Fondo durazno suave.

La posición de los destinos no debe cambiar entre pantallas.

## 16. Estados de interfaz

Todas las pantallas que dependen de la API deben contemplar:

### Carga

- Indicador circular cobre.
- Texto que explique qué información se está cargando.

### Vacío

- Icono representativo.
- Título claro.
- Explicación breve.
- Acción cuando sea posible.

### Error

- Mensaje real proveniente de la API.
- Icono de error o desconexión.
- Botón `Reintentar`.
- Nunca mostrar textos técnicos como `Instance of ApiException`.

### Éxito

- Icono de confirmación verde.
- Título directo.
- Resumen de la operación realizada.
- Acción para continuar o volver.

## 17. Pantallas administrativas

La experiencia administrativa utiliza:

- Resumen del equipo.
- Accesos rápidos.
- Listas con búsqueda y filtros.
- Acciones individuales mediante menú contextual.
- Formularios de creación y edición.
- Gestión semanal de horarios.

Los datos temporales o aún no respaldados por la API deben identificarse y no presentarse como información real.

## 18. Pantallas del colaborador

La experiencia del colaborador prioriza:

- Horario del día.
- Registro de marcación.
- Historial de asistencias.
- Perfil personal y laboral.

Las pantallas deben ser principalmente de lectura, salvo acciones autorizadas como:

- Escanear QR.
- Permitir ubicación GPS.
- Cambiar contraseña.
- Seleccionar filtros del historial.

## 19. Accesibilidad

- Mantener contraste suficiente entre texto y fondo.
- No comunicar estados únicamente mediante color.
- Proporcionar etiquetas semánticas a acciones importantes.
- Permitir desplazamiento cuando el texto aumenta de tamaño.
- Evitar textos menores a 10 px.
- Utilizar áreas táctiles cómodas.
- Mostrar mensajes de validación claros.

## 20. Implementación Flutter

El sistema visual centralizado se encuentra en:

- `lib/theme/lumibell_theme.dart`
- `lib/widgets/lumibell_ui.dart`

Componentes disponibles:

- `LumibellLogo`
- `LumibellCard`
- `LumibellSectionTitle`
- `LumibellStatusChip`
- `LumibellStateView`
- `LumibellLoadingView`

Las nuevas pantallas deben utilizar estos componentes antes de crear variantes locales.

## 21. Lista de verificación para nuevas pantallas

Antes de considerar terminada una pantalla, verificar:

- ¿Respeta el mockup correspondiente?
- ¿Mantiene el ancho móvil?
- ¿Utiliza los colores del tema?
- ¿Utiliza espaciados y radios consistentes?
- ¿Mantiene el footer del rol en el mismo orden?
- ¿Tiene estados de carga, vacío y error?
- ¿El contenido se desplaza correctamente?
- ¿Funciona con teclado y `SafeArea`?
- ¿Los mensajes son comprensibles para el usuario?
- ¿Los datos mostrados provienen realmente de la API?
- ¿Las acciones destructivas solicitan confirmación?
- ¿La pantalla es utilizable sin depender exclusivamente del color?

