param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$MysqlRoot = $PSScriptRoot
$RepackRoot = Split-Path $MysqlRoot -Parent
$ToolsRoot = Join-Path $RepackRoot "_tools"
$CurlExe = Join-Path $ToolsRoot "curl-8.22.0_1-win64-mingw\curl.exe"

$MysqlVersion = "8.4.6"
$MysqlUrl = "https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-$MysqlVersion-winx64.zip"

$MysqlServer = Join-Path $MysqlRoot "server"
$MysqlArchive = Join-Path $MysqlRoot "mysql.zip"
$MysqlTemp = Join-Path $MysqlRoot "_temp"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       MySQL Portable Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (Test-Path (Join-Path $MysqlServer "bin\mysqld.exe")) {
    Write-Host "[MySQL] MySQL is already installed." -ForegroundColor Green
    Write-Host "Location: $MysqlServer"
    if (-not $NonInteractive) {
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
    exit 0
}

Write-Host "[MySQL] Version : $MysqlVersion"
Write-Host "[MySQL] Downloading..."

if (Test-Path $CurlExe) {
    & $CurlExe -L --fail $MysqlUrl -o $MysqlArchive
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to download MySQL using curl.exe"
    }
} else {
    Invoke-WebRequest -Uri $MysqlUrl -OutFile $MysqlArchive
}

Write-Host "[MySQL] Download completed." -ForegroundColor Green

if (Test-Path $MysqlTemp) {
    Remove-Item $MysqlTemp -Recurse -Force
}
New-Item -ItemType Directory -Path $MysqlTemp | Out-Null

Write-Host "[MySQL] Extracting archive..."
Expand-Archive -LiteralPath $MysqlArchive -DestinationPath $MysqlTemp -Force

Write-Host "[MySQL] Installing server files..."
if (Test-Path $MysqlServer) {
    Remove-Item $MysqlServer -Recurse -Force
}
New-Item -ItemType Directory -Path $MysqlServer | Out-Null

$extractedDir = Get-ChildItem -Path $MysqlTemp -Directory -Filter "mysql-*" | Select-Object -First 1
if (-not $extractedDir) {
    throw "Extracted MySQL directory not found in $MysqlTemp"
}

Copy-Item "$($extractedDir.FullName)\*" $MysqlServer -Recurse -Force

$mysqld = Join-Path $MysqlServer "bin\mysqld.exe"
if (-not (Test-Path $mysqld)) {
    throw "mysqld.exe was not found after extraction: $mysqld"
}

Write-Host "[MySQL] Creating directories..."
$dataDir = Join-Path $MysqlRoot "data"
$logsDir = Join-Path $dataDir "logs"
$confDir = Join-Path $dataDir "conf"

foreach ($d in @($dataDir, $logsDir, $confDir)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

Write-Host "[MySQL] Cleaning temporary files..."
if (Test-Path $MysqlTemp) {
    Remove-Item $MysqlTemp -Recurse -Force
}
if (Test-Path $MysqlArchive) {
    Remove-Item $MysqlArchive -Force
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "MySQL installed successfully." -ForegroundColor Green
Write-Host "Server     : $MysqlServer"
Write-Host "Executable : $mysqld"
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if (-not $NonInteractive) {
    Read-Host "Press Enter to continue"
}
