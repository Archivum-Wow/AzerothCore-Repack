<#
.SYNOPSIS
    Configure et compile AzerothCore (ou sa variante PlayerBots) avec CMake.

.DESCRIPTION
    Ce script :
      - Supprime le dossier de build précédent (build propre à chaque exécution)
      - Configure CMake en mode Release avec Visual Studio 2022
      - Lance la compilation parallèle
      - Supporte sccache si les variables d'environnement adéquates sont définies

    Les variables d'environnement attendues sont :
      - CORE_SOURCE : chemin racine du code source AzerothCore
      - CORE_BUILD  : chemin du dossier de build (optionnel, sinon calculé)
      - BOOST_ROOT  : chemin racine de Boost (optionnel)
      - MYSQL_ROOT_DIR : chemin racine de MySQL

.PARAMETER Variant
    Variante à compiler : "AzerothCore" (vanilla) ou "PlayerBots".

.EXAMPLE
    .\build-server.ps1 -Variant AzerothCore
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Résolution des chemins
# ------------------------------------------------------------
$Source = $env:CORE_SOURCE
$Build = $env:CORE_BUILD

if (-not $Build) {
    # En CI on utilise un dossier dédié hors du workspace (chemins plus courts)
    # En local on utilise un sous-dossier "build" du source
    $Build = if ($env:GITHUB_ACTIONS) { "C:\ac_build" } else { Join-Path $Source "build" }
}

if (-not $Source) {
    throw "La variable d'environnement CORE_SOURCE n'est pas définie."
}

Write-Host "========================================"
Write-Host " Compilation : $Variant"
Write-Host " Source      : $Source"
Write-Host " Build       : $Build"
Write-Host "========================================"

# ------------------------------------------------------------
# Nettoyage : on repart toujours d'un build propre
# ------------------------------------------------------------
if (Test-Path $Build) {
    Write-Host "[Clean] Suppression du build précédent..."
    Remove-Item $Build -Recurse -Force
}

New-Item -ItemType Directory -Path $Build | Out-Null

Push-Location $Build

try {

    # ------------------------------------------------------------
    # Arguments CMake
    # On évite d'utiliser $args (variable automatique réservée PowerShell)
    # ------------------------------------------------------------
    $cmakeArgs = @(
        "-S", $Source
        "-B", "."
        "-G", "Visual Studio 17 2022"
        "-A", "x64"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DAPPS_BUILD=all"
        "-DTOOLS_BUILD=all"
        "-DLUA_VERSION=luajit"
        "-DMYSQL_ROOT_DIR=$env:MYSQL_ROOT_DIR"
    )

    # Support de sccache (accélère énormément les rebuilds en CI)
    if ($env:CMAKE_C_COMPILER_LAUNCHER) {
        $cmakeArgs += "-DCMAKE_C_COMPILER_LAUNCHER=$env:CMAKE_C_COMPILER_LAUNCHER"
    }
    if ($env:CMAKE_CXX_COMPILER_LAUNCHER) {
        $cmakeArgs += "-DCMAKE_CXX_COMPILER_LAUNCHER=$env:CMAKE_CXX_COMPILER_LAUNCHER"
    }

    # Boost : on normalise le chemin en slash pour CMake
    if ($env:BOOST_ROOT) {
        $boostPath = $env:BOOST_ROOT.Replace('\', '/').TrimEnd('/')
        $cmakeArgs += "-DBOOST_ROOT=$boostPath"
        $cmakeArgs += "-DBoost_NO_BOOST_CMAKE=ON"
    }

    Write-Host ""
    Write-Host "[CMake] Configuration..."

    & cmake @cmakeArgs

    if ($LASTEXITCODE -ne 0) {
        throw "La configuration CMake a échoué."
    }

    Write-Host ""
    Write-Host "[CMake] Compilation Release en parallèle..."

    & cmake --build . --config Release --parallel

    if ($LASTEXITCODE -ne 0) {
        throw "La compilation CMake a échoué."
    }

    Write-Host ""
    Write-Host "[OK] Compilation terminée."
}
finally {
    Pop-Location
}