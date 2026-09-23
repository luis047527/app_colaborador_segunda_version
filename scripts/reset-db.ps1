$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent $ScriptDir
Set-Location $RepoDir

Write-Host "==> docker compose down -v (borra volumen mysql_data)..."
try { docker compose down -v } catch { docker-compose down -v }

Write-Host "==> docker compose up --build -d..."
try {
  docker compose up --build -d
} catch {
  docker-compose up --build -d
}

Write-Host "==> Esperando MySQL healthy..."
for ($i=1; $i -le 30; $i++) {
  try {
    docker exec mysql_db mysqladmin ping -h localhost -prootpassword --silent | Out-Null
    Write-Host "MySQL listo."
    break
  } catch {
    Write-Host "  esperando... ($i/30)"
    Start-Sleep -Seconds 2
  }
}

Write-Host "==> Verificando tablas..."
try {
  docker exec mysql_db mysql -uappuser -papppassword -e "SHOW TABLES; SELECT id, email, rol FROM usuarios ORDER BY id; SELECT id, codigo_empleado, horario_id FROM empleados ORDER BY id; SELECT id, nombre FROM horarios ORDER BY id;" appdb
} catch {
  Write-Host "Advertencia: verificación inicial falló, intentando apply-db-scripts.ps1..."
  & "$ScriptDir\apply-db-scripts.ps1"
}

Write-Host "==> Verificando API..."
for ($i=1; $i -le 15; $i++) {
  try {
    $h = Invoke-RestMethod -Uri http://localhost:3000/health -TimeoutSec 2
    Write-Host "API healthy: $($h | ConvertTo-Json -Compress)"
    break
  } catch {
    Write-Host "  esperando API... ($i/15)"
    Start-Sleep -Seconds 2
  }
}

Write-Host "==> Reset completo. Prueba:"
Write-Host "  curl http://localhost:3000/health"
