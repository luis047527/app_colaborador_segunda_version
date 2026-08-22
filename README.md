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
Flutter → API REST → Node.js → MySQL
```

Desarrollo local con Docker y MySQL.

## Base de datos MySQL con Docker

Para desarrollar localmente, la base de datos MySQL se ejecuta en un contenedor Docker:

### Opción 1: Usando docker run (comando directo)

```bash
docker run -d --name mysql_db \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=appdb \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=apppassword \
  -p 3306:3306 \
  -v mysql_data:/var/lib/mysql \
  mysql:8.0
```

### Opción 2: Usando Dockerfile (construir imagen personalizada)

Con un Dockerfile personalizado, puedes construir y iniciar la base de datos así. El `Dockerfile.db` incluye un script de inicialización automático:

```bash
# 1. Construir la imagen (ejecuta init-db.sql automáticamente)
docker build -t my-mysql-db -f Dockerfile.db .

# 2. Ejecutar el contenedor
docker run -d --name mysql_db \
  -p 3306:3306 \
  -v mysql_data:/var/lib/mysql \
  my-mysql-db
```

**`init-db.sql`**: Este script se copia automáticamente a `/docker-entrypoint-initdb.d/` y ejecuta las siguientes acciones al iniciar el contenedor:
- Crea la base de datos `appdb`
- Crea el usuario `appuser` con password `apppassword`
- Otorga todos los privilegios sobre `appdb`

```bash
# Verificar que el script se ejecutó correctamente
docker exec mysql_db mysql -u root -prootpassword -e "SHOW DATABASES;"
# Deberías ver: appdb, information_schema, mysql, performance_schema, sys
```

### Opción 3: Usando Docker Compose (recomendado)

`docker-compose.yml` levanta los dos servicios juntos:

- **`db`**: MySQL 8.0 construido desde `Dockerfile.db` (ejecuta `init-db.sql` automáticamente), con volumen persistente `mysql_data` y healthcheck.
- **`server`**: Node.js + Express construido desde `server/Dockerfile`, con las variables `DB_HOST=db`, `DB_PORT=3306`, `DB_USER=appuser`, `DB_PASSWORD=apppassword`, `DB_NAME=appdb`. Arranca cuando la base de datos está healthy (`depends_on`).

```bash
# Levantar ambos servicios
docker compose up --build -d

# Verificar estado
docker compose ps

# Probar el servidor
curl http://localhost:3000   # → hello node

# Detener todo
docker compose down
```

> Nota: si existe un contenedor llamado `mysql_db` creado manualmente con `docker run`, elimínalo primero (`docker rm -f mysql_db`) para evitar conflictos de nombre.

### Configuración actual (ambos métodos)

- **Imagen**: `mysql:8.0` (o tu imagen personalizada `my-mysql-db`)
- **Puerto**: 3306 (host → container)
- **Base de datos**: `appdb` (creada automáticamente)
- **Usuario root**: `root` / `rootpassword`
- **Usuario aplicación**: `appuser` / `apppassword`

### Credenciales de acceso

| Componente | Usuario | Contraseña | Host |
|------------|---------|------------|------|
| Root | `root` | `rootpassword` | `localhost:3306` |
| Aplicación | `appuser` | `apppassword` | `db` (nombre del contenedor) |

### Cómo conectar

**Desde el contenedor Node.js:**
Las variables de entorno en `docker-compose.yml` configuraron automáticamente:
- `DB_HOST: db`
- `DB_PORT: 3306`
- `DB_USER: appuser`
- `DB_PASSWORD: apppassword`
- `DB_NAME: appdb`

**Desde host local (opcional):**
```bash
# Con root
mysql -u root -prootpassword -h localhost -P 3306

# Con usuario de la app
mysql -u appuser -papppassword -h localhost -P 3306 db
```

### Detener y reiniciar

```bash
# Detener contenedor
docker stop mysql_db

# Iniciar nuevamente
docker start mysql_db

# Ver logs
docker logs mysql_db

# Reconstruir imagen (solo con Dockerfile)
docker build -t my-mysql-db -f Dockerfile.db .
```

## Pasos realizados

```powershell
cd "D:\App con ia"
flutter create --empty app_colaborador_segunda_version
cd ".\app_colaborador_segunda_version"
flutter pub get
flutter analyze
code .
```

## Progreso

- [x] Requisitos definidos.
- [x] Proyecto Flutter creado (`flutter create`, `pub get`, `analyze`).
- [x] Arquitectura definida: Flutter → API REST → Node.js → MySQL.
- [x] Base de datos MySQL con Docker (`Dockerfile.db` + `init-db.sql`).
- [x] Servidor base Node.js con Express (puerto 3000, responde `hello node`).
- [ ] Diseñar tablas del esquema MySQL.
- [ ] Crear APIs REST en el backend Node.js.
- [ ] Definir arquitectura Flutter.
- [ ] Implementar Login.
- [ ] Implementar Inicio, Registrar, Historial, Solicitudes y Perfil.
- [ ] Implementar QR, GPS y cámara.
- [ ] Implementar aprobaciones y horas compensables.
- [ ] Integrar Flutter + Node.js + MySQL.
- [ ] Probar y corregir.
- [ ] Desplegar.

**Próximo paso:** diseñar las tablas del esquema MySQL.


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