#!/usr/bin/env bash
set -euo pipefail
# Reset dev DB to fresh schema+seed matching sql/00..05
# Usage: ./scripts/reset-db.sh  (from repo root or scripts/)
# Recreates volume mysql_data so docker-entrypoint-initdb.d runs again.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$REPO_DIR"

echo "==> docker compose down -v (borra volumen mysql_data)..."
docker compose down -v 2>/dev/null || docker-compose down -v 2>/dev/null || {
  echo "docker compose not found, trying docker-compose..."
  docker-compose down -v
}

echo "==> docker compose up --build -d..."
if docker compose version >/dev/null 2>&1; then
  docker compose up --build -d
else
  docker-compose up --build -d
fi

echo "==> Esperando MySQL healthy..."
for i in {1..30}; do
  if docker exec mysql_db mysqladmin ping -h localhost -prootpassword --silent >/dev/null 2>&1; then
    echo "MySQL listo."
    break
  fi
  echo "  esperando... ($i/30)"
  sleep 2
done

# Verificación rápida
echo "==> Verificando tablas..."
docker exec mysql_db mysql -uappuser -papppassword -e "SHOW TABLES; SELECT id, email, rol FROM usuarios ORDER BY id; SELECT id, codigo_empleado, horario_id FROM empleados ORDER BY id; SELECT id, nombre FROM horarios ORDER BY id;" appdb || {
  echo "Advertencia: verificación inicial falló, intentando apply-db-scripts.sh..."
  ./scripts/apply-db-scripts.sh
}

echo "==> Verificando API..."
for i in {1..15}; do
  if curl -sf http://localhost:3000/health >/dev/null 2>&1; then
    echo "API healthy: $(curl -s http://localhost:3000/health)"
    break
  fi
  echo "  esperando API... ($i/15)"
  sleep 2
done

echo "==> Reset completo. Prueba:"
echo "  curl http://localhost:3000/health"
echo "  # con token admin -> debe devolver 200 con lista empleados"
