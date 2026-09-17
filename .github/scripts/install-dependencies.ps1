param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root = $env:GITHUB_WORKSPACE
$RepackRoot = Join-Path $Root $Variant

Write-Host "========================================"
Write-Host " Installing dependencies: $Variant"
Write-Host "========================================"

if (-not (Test-Path $RepackRoot)) {
    throw "Repack directory not found: $RepackRoot"
}

# ------------------------------------------------------------
# MySQL
# ------------------------------------------------------------

$MysqlRoot = Join-Path $RepackRoot "_mysql"
$MysqlInstall = Join-Path $MysqlRoot "install_mysql.ps1"
$MysqlServer = Join-Path $MysqlRoot "server"

if (-not (Test-Path $MysqlInstall)) {
    throw "MySQL installer not found: $MysqlInstall"
}

Write-Host ""
Write-Host "[MySQL] Running existing installer..."

& $MysqlInstall -NonInteractive

if (-not (Test-Path $MysqlServer)) {
    throw "MySQL server directory was not created: $MysqlServer"
}

Write-Host "[OK] MySQL: $MysqlServer"

# ------------------------------------------------------------
# CMake
# ------------------------------------------------------------

$cmake = Get-Command cmake -ErrorAction SilentlyContinue

if (-not $cmake) {
    throw "CMake was not found on the GitHub runner."
}

Write-Host "[OK] CMake: $(& cmake --version | Select-Object -First 1)"

# ------------------------------------------------------------
# Visual Studio
# ------------------------------------------------------------

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

if (-not (Test-Path $vswhere)) {
    throw "vswhere.exe was not found."
}

$vsPath = & $vswhere `
    -latest `
    -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath

if (-not $vsPath) {
    throw "Visual Studio C++ build tools were not found."
}

Write-Host "[OK] Visual Studio: $vsPath"

# ------------------------------------------------------------
# Boost
# ------------------------------------------------------------

$boostRoot = $env:BOOST_ROOT

if (-not $boostRoot) {
    $candidates = @(
        "C:\local\boost_*",
        "C:\hostedtoolcache\windows\boost\*",
        "C:\Boost\*"
    )

    foreach ($pattern in $candidates) {
        $found = Get-ChildItem $pattern -Directory -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Select-Object -First 1

        if ($found) {
            $boostRoot = $found.FullName
            break
        }
    }
}

if (-not $boostRoot) {
    Write-Host "[Boost] Not found in environment or default paths. Installing boost-msvc-14.3 via Chocolatey..."
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    if ($choco) {
        & choco install boost-msvc-14.3 -y --no-progress
        $found = Get-ChildItem "C:\local\boost_*" -Directory -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Select-Object -First 1

        if ($found) {
            $boostRoot = $found.FullName
        }
    }
}

if (-not $boostRoot) {
    throw "BOOST_ROOT was not found on the runner, and automatic fallback installation failed."
}

$env:BOOST_ROOT = $boostRoot

Write-Host "[OK] Boost: $boostRoot"

# ------------------------------------------------------------
# OpenSSL
# ------------------------------------------------------------

$openssl = Get-Command openssl -ErrorAction SilentlyContinue

if ($openssl) {
    Write-Host "[OK] OpenSSL: $(& openssl version)"
}
else {
    Write-Warning "OpenSSL executable was not found in PATH."
    Write-Warning "CMake will try to locate the installed OpenSSL environment."
}

# ------------------------------------------------------------
# Export paths for following GitHub Actions steps
# ------------------------------------------------------------

$boostForward = $boostRoot.Replace("\", "/").TrimEnd("/")
"BOOST_ROOT=$boostForward" | Out-File -FilePath $env:GITHUB_ENV -Append

$mysqlForward = $MysqlServer.Replace("\", "/")
"MYSQL_ROOT_DIR=$mysqlForward" | Out-File -FilePath $env:GITHUB_ENV -Append

"MYSQL_DIR=$mysqlForward" | Out-File -FilePath $env:GITHUB_ENV -Append

Write-Host ""
Write-Host "[OK] Dependency setup completed."