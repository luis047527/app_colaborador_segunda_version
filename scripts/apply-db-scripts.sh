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
has_table() {
  local t="$1"
  "${mysql[@]}" -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${database}' AND table_name='${t}';" | tr -d '[:space:]'
}
has_column() {
  local tbl="$1" col="$2"
  "${mysql[@]}" -Nse "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='${database}' AND table_name='${tbl}' AND column_name='${col}';" | tr -d '[:space:]'
}

SCRIPT_DIR="$(dirname "$0")"
SQL_DIR="${SCRIPT_DIR}/../sql"

# 00 + 01 schema
if [[ "$(has_table 'usuarios')" == "0" ]]; then
  echo "Aplicando esquema base (00_init + 01_schema_login)..."
  docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "${SQL_DIR}/00_init-db.sql" || true
  docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "${SQL_DIR}/01_schema_login.sql"
else
  echo "Esquema base ya existe; no se reaplica 00/01."
fi

# 02 seed login (idempotent)
echo "Aplicando seed login (02)..."
docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "${SQL_DIR}/02_seed_login.sql"

# 03 horarios
if [[ "$(has_table 'horarios')" == "0" ]]; then
  echo "Aplicando 03_horarios.sql (horarios + horario_dias + empleados.horario_id)..."
  docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "${SQL_DIR}/03_horarios.sql"
else
  # incremental: column may still be missing if DB was created from older volume
  if [[ "$(has_column 'empleados' 'horario_id')" == "0" ]]; then
    echo "Columna empleados.horario_id faltante, aplicando ALTER de 03_horarios.sql..."
    docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "${SQL_DIR}/03_horarios.sql" || true
  else
    echo "Tabla horarios ya existe; 03 no necesita re-aplicarse."
  fi
fi

# 04 marcaciones
if [[ "$(has_table 'marcaciones')" == "0" ]]; then
  echo "Aplicando 04_marcaciones.sql..."
  docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "${SQL_DIR}/04_marcaciones.sql"
else
  echo "Tabla marcaciones ya existe; 04 no necesita re-aplicarse."
fi

# 05 seed demo (idempotent)
echo "Aplicando 05_seed_demo_colaboradores_horarios.sql..."
docker exec -i "${container}" mysql "-u${db_user}" "-p${db_password}" "-D${database}" < "${SQL_DIR}/05_seed_demo_colaboradores_horarios.sql"

echo "Base de datos lista."
"${mysql[@]}" -e 'SHOW TABLES;'
"${mysql[@]}" -e 'SELECT id, email, rol, estado FROM usuarios ORDER BY id;'
"${mysql[@]}" -e 'SELECT id, codigo_empleado, usuario_id, horario_id FROM empleados ORDER BY id;'
"${mysql[@]}" -e 'SELECT id, nombre FROM horarios ORDER BY id;'
