# App Colaborador — Segunda Versión

Aplicación móvil de gestión de asistencia para Lumibell Studios.

## Estado inicial

* Documento funcional revisado: 86 páginas.
* Proyecto Flutter creado.
* Flutter: 3.29.3
* Dart: 3.7.2
* Ubicación: `D:\App con ia\app_colaborador_segunda_version`

## Requisitos definidos

**Roles:** Administrador, Supervisor/Jefa de Estudio y Colaborador.

**Funciones:** asistencia, QR, GPS + foto, horarios, historial, solicitudes, permisos, vacaciones, aprobaciones y horas compensables.

**Reglas:**

* Sin funcionamiento offline.
* Login con correo y contraseña.
* Tolerancia configurada por la empresa.
* Horas extra acumulables como compensación.
* Supervisor y Administrador pueden aprobar solicitudes.
* Las solicitudes del Supervisor las aprueba el Administrador.
* Las correcciones de asistencia requieren aprobación.
* Horarios fijos, variables, rotativos, flexibles y personalizados.

## Arquitectura

```text
Flutter → API REST → PHP → MySQL
```

Desarrollo local con XAMPP y posterior despliegue en servidor/hosting.

## Pasos realizados

```powershell
cd "D:\App con ia"
flutter create --empty app_colaborador_segunda_version
cd ".\app_colaborador_segunda_version"
flutter pub get
flutter analyze
code .
```

## Próximos pasos

1. Crear arquitectura Flutter.
2. Diseñar base de datos MySQL.
3. Crear backend PHP y APIs.
4. Implementar Login.
5. Implementar Inicio, Registrar, Historial, Solicitudes y Perfil.
6. Implementar QR, GPS y cámara.
7. Implementar aprobaciones y horas compensables.
8. Integrar Flutter + PHP + MySQL.
9. Probar y corregir.
10. Desplegar.

## Estado

```text
Requisitos       ✅
Proyecto Flutter ✅
Arquitectura     ⏳
Base de datos     ⏳
Backend PHP       ⏳
Interfaces        ⏳
Integración       ⏳
Pruebas           ⏳
Despliegue        ⏳
```

**Próximo paso:** crear la arquitectura del proyecto Flutter.


Ejemplos de horarios:

Horario Full time:
Lunes a Sábado de 10:00 am a 01:00 pm y de 02:00 pm a 07:00 pm

Horario Part Time:
Lunes a sábado de 03:00 pm a 07:00 pm

Horario Flexible:
Lunes y martes de 03:00 pm a 07:00 pm
Miércoles  10:00 am a 02:00 pm
Jueves y viernes 03:00 pm a 07:00 pm
Sábado 10:00 am a 12:30 pm y de 02:30 pm a 07:00 pm

Horario Rotativo:
Enero turno mañana 07:00 am a 03:00 pm
Febrero turno tarde 03:00 pm a 11:00 pm
Marzo tuno noche 11:00 pm a 07:00 pm