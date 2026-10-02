$ErrorActionPreference = 'Stop'

$container = 'mysql_db'
$database = 'appdb'
$dbUser = 'appuser'
$dbPassword = 'apppassword'

$running = docker ps --filter "name=^/$container$" --filter "status=running" --format '{{.Names}}'
if ($running -ne $container) {
    throw "El contenedor '$container' no está ejecutándose. Inicia Docker Compose con: docker compose up --build -d"
}

$mysqlUser = "-u$dbUser"
$mysqlPassword = "-p$dbPassword"
$mysqlDatabase = "-D$database"

function Has-Table($name) {
  (docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-Nse' "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$database' AND table_name='$name';").Trim()
}
function Has-Column($table, $col) {
  $columnCount = docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-Nse' "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='$database' AND table_name='$table' AND column_name='$col';"
  if ($LASTEXITCODE -ne 0) {
    throw "No se pudo comprobar la columna '$table.$col'."
  }
  $columnCount = ("$columnCount").Trim()
  if ($columnCount -notin @('0', '1')) {
    throw "Respuesta inesperada al comprobar la columna '$table.$col'."
  }
  return $columnCount
}

$tables = Has-Table 'usuarios'
if ($tables -eq '0') {
    Write-Host 'Aplicando esquema base (00_init + 01_schema_login)...'
    Get-Content -Raw "$PSScriptRoot\..\sql\00_init-db.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase
    Get-Content -Raw "$PSScriptRoot\..\sql\01_schema_login.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase
} else {
    Write-Host 'Esquema base ya existe; no se reaplica 00/01.'
}

Write-Host 'Aplicando seed login (02)...'
Get-Content -Raw "$PSScriptRoot\..\sql\02_seed_login.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase

$horarios = Has-Table 'horarios'
if ($horarios -eq '0') {
    Write-Host 'Aplicando 03_horarios.sql...'
    Get-Content -Raw "$PSScriptRoot\..\sql\03_horarios.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase
} else {
    $col = Has-Column 'empleados' 'horario_id'
    if ($col -eq '0') {
        Write-Host 'Columna empleados.horario_id faltante, aplicando ALTER de 03...'
        try { Get-Content -Raw "$PSScriptRoot\..\sql\03_horarios.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase } catch { Write-Host "Advertencia 03: $_" }
    } else {
        Write-Host 'Tabla horarios ya existe; 03 no necesita re-aplicarse.'
    }
}

$marc = Has-Table 'marcaciones'
if ($marc -eq '0') {
    Write-Host 'Aplicando 04_marcaciones.sql...'
    Get-Content -Raw "$PSScriptRoot\..\sql\04_marcaciones.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase
} else {
    Write-Host 'Tabla marcaciones ya existe; 04 no necesita re-aplicarse.'
}

Write-Host 'Aplicando 05_seed_demo...'
Get-Content -Raw "$PSScriptRoot\..\sql\05_seed_demo_colaboradores_horarios.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase

# 06 QR estatico: aplicar solo si falta la columna para conservar los QR existentes.
$qrColumn = Has-Column 'sedes' 'qr_valor'
if ($qrColumn -eq '0') {
    Write-Host 'Aplicando 06_qr_estatico.sql (sedes.qr_valor y valores iniciales)...'
    Get-Content -Raw "$PSScriptRoot\..\sql\06_qr_estatico.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase
    if ($LASTEXITCODE -ne 0) {
        throw 'No se pudo completar 06_qr_estatico.sql. Revisa el error de MySQL antes de continuar.'
    }
} else {
    Write-Host 'Columna sedes.qr_valor ya existe; 06 no necesita re-aplicarse.'
}

Write-Host 'Base de datos lista.'
docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-e' "SHOW TABLES;"
docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-e' "SELECT id, email, rol, estado FROM usuarios ORDER BY id;"
docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-e' "SELECT id, codigo_empleado, usuario_id, horario_id FROM empleados ORDER BY id;"
docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-e' "SELECT id, nombre FROM horarios ORDER BY id;"
