<#
.SYNOPSIS
    Installe et vérifie toutes les dépendances de compilation.

.DESCRIPTION
    Ce script :
      - Installe MySQL (via install_mysql.ps1 du repack)
      - Vérifie la présence de CMake, Visual Studio, Boost, OpenSSL
      - Tente une installation de secours de Boost via Chocolatey si absent
      - Exporte les chemins dans GITHUB_ENV

.PARAMETER Variant
    Variante cible : "AzerothCore" ou "PlayerBots".

.EXAMPLE
    .\install-dependencies.ps1 -Variant AzerothCore
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root       = $env:GITHUB_WORKSPACE
$RepackRoot = Join-Path $Root $Variant

Write-Host "========================================"
Write-Host " Installation des dépendances : $Variant"
Write-Host "========================================"

if (-not (Test-Path $RepackRoot)) {
    throw "Dossier du repack introuvable : $RepackRoot"
}

# ------------------------------------------------------------
# MySQL
# ------------------------------------------------------------
$MysqlRoot    = Join-Path $RepackRoot "_mysql"
$MysqlInstall = Join-Path $MysqlRoot "install_mysql.ps1"
$MysqlServer  = Join-Path $MysqlRoot "server"

if (-not (Test-Path $MysqlInstall)) {
    throw "Installateur MySQL introuvable : $MysqlInstall"
}

Write-Host ""
Write-Host "[MySQL] Exécution de l'installateur..."
& $MysqlInstall -NonInteractive

if (-not (Test-Path $MysqlServer)) {
    throw "Le dossier MySQL server n'a pas été créé : $MysqlServer"
}

Write-Host "[OK] MySQL : $MysqlServer"

# ------------------------------------------------------------
# CMake
# ------------------------------------------------------------
$cmake = Get-Command cmake -ErrorAction SilentlyContinue

if (-not $cmake) {
    throw "CMake est introuvable sur le runner."
}

Write-Host "[OK] CMake : $(& cmake --version | Select-Object -First 1)"

# ------------------------------------------------------------
# Visual Studio
# ------------------------------------------------------------
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

if (-not (Test-Path $vswhere)) {
    throw "vswhere.exe est introuvable."
}

$vsPath = & $vswhere `
    -latest `
    -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath

if (-not $vsPath) {
    throw "Les outils de build C++ de Visual Studio sont introuvables."
}

Write-Host "[OK] Visual Studio : $vsPath"

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
    Write-Host "[Boost] Introuvable. Tentative d'installation via Chocolatey..."
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
    throw "BOOST_ROOT est introuvable et l'installation de secours a échoué."
}

$env:BOOST_ROOT = $boostRoot
Write-Host "[OK] Boost : $boostRoot"

# ------------------------------------------------------------
# OpenSSL
# ------------------------------------------------------------
$openssl = Get-Command openssl -ErrorAction SilentlyContinue

if ($openssl) {
    Write-Host "[OK] OpenSSL : $(& openssl version)"
}
else {
    Write-Warning "OpenSSL est absent du PATH."
    Write-Warning "CMake tentera de localiser l'installation système."
}

# ------------------------------------------------------------
# Export pour les étapes suivantes
# ------------------------------------------------------------
$boostForward = $boostRoot.Replace("\", "/").TrimEnd("/")
"BOOST_ROOT=$boostForward" | Out-File -FilePath $env:GITHUB_ENV -Append

$mysqlForward = $MysqlServer.Replace("\", "/")
"MYSQL_ROOT_DIR=$mysqlForward" | Out-File -FilePath $env:GITHUB_ENV -Append
"MYSQL_DIR=$mysqlForward"      | Out-File -FilePath $env:GITHUB_ENV -Append

Write-Host ""
Write-Host "[OK] Installation des dépendances terminée."