$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$MysqlServer = Join-Path $Root "server"
$MysqlData = Join-Path $Root "data\data"
$MysqlLogs = Join-Path $Root "data\logs"

$mysqld = Join-Path $MysqlServer "bin\mysqld.exe"
$mysql = Join-Path $MysqlServer "bin\mysql.exe"
$Port = 3306

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       AzerothCore MySQL Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $mysqld)) {
    Write-Host "[ERROR] mysqld.exe not found: $mysqld" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$ibdata = Join-Path $MysqlData "ibdata1"

if (-not (Test-Path $ibdata)) {
    Write-Host "[MySQL] Data directory not initialized." -ForegroundColor Yellow
    Write-Host "[MySQL] Initializing MySQL..." -ForegroundColor Yellow
    Write-Host ""

    $dataDir = Join-Path $Root "data"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }

    $initProcess = Start-Process -FilePath $mysqld -ArgumentList @(
        "--no-defaults",
        "--initialize-insecure",
        "--basedir=$MysqlServer",
        "--datadir=$MysqlData"
    ) -Wait -PassThru -NoNewWindow

    if ($initProcess.ExitCode -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] MySQL initialization failed with exit code $($initProcess.ExitCode)." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    Write-Host ""
    Write-Host "[MySQL] Initialization completed." -ForegroundColor Green
    Write-Host ""
}

if (-not (Test-Path $ibdata)) {
    Write-Host ""
    Write-Host "[ERROR] MySQL data directory is invalid (missing $ibdata)." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path $MysqlLogs)) {
    New-Item -ItemType Directory -Path $MysqlLogs -Force | Out-Null
}

Write-Host "[MySQL] Starting server on port $Port..."

$logErr = Join-Path $MysqlLogs "mysql.err"
$serverProcess = Start-Process -FilePath $mysqld -ArgumentList @(
    "--no-defaults",
    "--basedir=$MysqlServer",
    "--datadir=$MysqlData",
    "--port=$Port",
    "--bind-address=127.0.0.1",
    "--log-error=$logErr"
) -PassThru

Write-Host "[MySQL] Waiting for server to become responsive..."

$ready = $false
for ($i = 1; $i -le 30; $i++) {
    & $mysql -u root -e "SELECT 1;" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        break
    }
    Start-Sleep -Seconds 1
}

if (-not $ready) {
    Write-Host ""
    Write-Host "[ERROR] MySQL failed to start within 30 seconds." -ForegroundColor Red
    Write-Host "Check log: $logErr"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[MySQL] Server ready." -ForegroundColor Green
Write-Host ""
Write-Host "[MySQL] Configuring AzerothCore user and privileges..."

$commands = @(
    "CREATE USER IF NOT EXISTS 'acore'@'localhost' IDENTIFIED BY 'acore';",
    "CREATE USER IF NOT EXISTS 'acore'@'127.0.0.1' IDENTIFIED BY 'acore';",
    "ALTER USER 'acore'@'localhost' IDENTIFIED BY 'acore';",
    "ALTER USER 'acore'@'127.0.0.1' IDENTIFIED BY 'acore';",
    "GRANT ALL PRIVILEGES ON acore_world.* TO 'acore'@'localhost';",
    "GRANT ALL PRIVILEGES ON acore_characters.* TO 'acore'@'localhost';",
    "GRANT ALL PRIVILEGES ON acore_auth.* TO 'acore'@'localhost';",
    "GRANT ALL PRIVILEGES ON acore_ale.* TO 'acore'@'localhost';",
    "GRANT ALL PRIVILEGES ON acore_world.* TO 'acore'@'127.0.0.1';",
    "GRANT ALL PRIVILEGES ON acore_characters.* TO 'acore'@'127.0.0.1';",
    "GRANT ALL PRIVILEGES ON acore_auth.* TO 'acore'@'127.0.0.1';",
    "GRANT ALL PRIVILEGES ON acore_ale.* TO 'acore'@'127.0.0.1';"
)

foreach ($sql in $commands) {
    & $mysql -u root -e $sql 2>$null | Out-Null
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "MySQL is ready." -ForegroundColor Green
Write-Host ""
Write-Host "Host     : 127.0.0.1"
Write-Host "Port     : $Port"
Write-Host "User     : acore"
Write-Host "Password : acore"
Write-Host ""
Write-Host "Databases:"
Write-Host "  acore_world"
Write-Host "  acore_characters"
Write-Host "  acore_auth"
Write-Host "  acore_ale"
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Server running. Keep this window open." -ForegroundColor Cyan

$serverProcess.WaitForExit()
