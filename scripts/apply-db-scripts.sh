#!/usr/bin/env bash
set -euo pipefail

container="mysql_db"
database="appdb"
db_user="appuser"
db_password="apppassword"

if [[ "$(docker ps --filter "name=^/${container}$" --filter status=running --format '{{.Names}}')" != "${container}" ]]; then
  echo "El contenedor '${container}' no está ejecutándose. Inicia Docker Compose con: docker compose up --build -d" >&2
  exit 1
fi

mysql=(docker exec "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}")
tables="$(${mysql[@]} -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${database}' AND table_name = 'usuarios';")"

if [[ "${tables}" == "0" ]]; then
  echo "Aplicando esquema SQL..."
  docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "$(dirname "$0")/../sql/01_schema_login.sql"
else
  echo "El esquema de login ya existe; no se modifica."
fi

user_count="$(${mysql[@]} -Nse 'SELECT COUNT(*) FROM usuarios;')"
if [[ "${user_count}" == "0" ]]; then
  echo "Aplicando usuarios seed..."
  docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "$(dirname "$0")/../sql/02_seed_login.sql"
else
  echo "Ya existen ${user_count} usuario(s); no se aplica el seed."
fi

echo "Base de datos lista para probar login."
"${mysql[@]}" -e 'SELECT id, email, rol, estado FROM usuarios ORDER BY id;'
