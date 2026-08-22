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
$tables = docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-Nse' "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$database' AND table_name = 'usuarios';"
if ($tables.Trim() -eq '0') {
    Write-Host 'Aplicando esquema SQL...'
    Get-Content -Raw "$PSScriptRoot\..\sql\01_schema_login.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase
} else {
    Write-Host 'El esquema de login ya existe; no se modifica.'
}

$userCount = docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-Nse' "SELECT COUNT(*) FROM usuarios;"
if ($userCount.Trim() -eq '0') {
    Write-Host 'Aplicando usuarios seed...'
    Get-Content -Raw "$PSScriptRoot\..\sql\02_seed_login.sql" | docker exec -i $container mysql $mysqlUser $mysqlPassword $mysqlDatabase
} else {
    Write-Host "Ya existen $($userCount.Trim()) usuario(s); no se aplica el seed."
}

Write-Host 'Base de datos lista para probar login.'
docker exec $container mysql $mysqlUser $mysqlPassword $mysqlDatabase '-e' "SELECT id, email, rol, estado FROM usuarios ORDER BY id;"
