<#
.SYNOPSIS
    Nettoie puis compresse le repack final dans une archive ZIP.

.DESCRIPTION
    Ce script :
      - Supprime les ZIPs résiduels dans _sources
      - Supprime le dossier _extracted (dev local uniquement)
      - Supprime le dossier MySQL server (runtime lourd, inutile dans le repack)
      - Supprime les .conf parasites à la racine du runtime
      - Crée une archive ZIP contenant le contenu du dossier de variante

.PARAMETER Variant
    Variante à packager : "AzerothCore" ou "PlayerBots".

.EXAMPLE
    .\package-repack.ps1 -Variant AzerothCore
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root       = $env:GITHUB_WORKSPACE
$RepackRoot = Join-Path $Root $Variant

# Nom de sortie selon la variante
if ($Variant -eq "AzerothCore") {
    $OutputName = "AzerothCore-Repack-Windows-x64.zip"
}
else {
    $OutputName = "AzerothCore-PlayerBots-Repack-Windows-x64.zip"
}

$Output = Join-Path $Root $OutputName

Write-Host "========================================"
Write-Host " Packaging : $Variant"
Write-Host "========================================"

if (-not (Test-Path $RepackRoot)) {
    throw "Dossier du repack introuvable : $RepackRoot"
}

# ------------------------------------------------------------
# Nettoyage avant packaging
# ------------------------------------------------------------

# 1. ZIPs résiduels dans _sources
$sourcesDir = Join-Path $RepackRoot "_sources"
if (Test-Path $sourcesDir) {
    Write-Host "[Cleanup] Suppression des ZIPs dans _sources..."
    Get-ChildItem -Path $sourcesDir -Filter "*.zip" -File -Recurse -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

# 2. Dossier d'extraction local
$extractedDir = Join-Path $sourcesDir "_extracted"
if (Test-Path $extractedDir) {
    Write-Host "[Cleanup] Suppression de _extracted..."
    Remove-Item $extractedDir -Recurse -Force
}

# 3. Dossier MySQL server (runtime, pas nécessaire dans le repack)
$mysqlServer = Join-Path $RepackRoot "_mysql\server"
if (Test-Path $mysqlServer) {
    Write-Host "[Cleanup] Suppression de _mysql\server..."
    Remove-Item $mysqlServer -Recurse -Force
}

# 4. Configs parasites à la racine du runtime
$runtimeDir = Join-Path $RepackRoot "azerothcore"
if (Test-Path $runtimeDir) {
    $parasites = @(
        "worldserver.conf",
        "worldserver.conf.dist",
        "authserver.conf",
        "authserver.conf.dist"
    )
    foreach ($p in $parasites) {
        $f = Join-Path $runtimeDir $p
        if (Test-Path $f) {
            Write-Host "[Cleanup] Suppression du parasite : azerothcore\$p"
            Remove-Item $f -Force
        }
    }
}

# 5. Ancienne archive de sortie
if (Test-Path $Output) {
    Remove-Item $Output -Force
}

# ------------------------------------------------------------
# Création du ZIP
# ------------------------------------------------------------
Write-Host ""
Write-Host "[ZIP] Création de $Output"

# On compresse le CONTENU de RepackRoot pour éviter d'avoir AzerothCore/AzerothCore/
Compress-Archive `
    -Path "$RepackRoot\*" `
    -DestinationPath $Output `
    -CompressionLevel Optimal `
    -Force

if (-not (Test-Path $Output)) {
    throw "Le ZIP n'a pas été créé."
}

Write-Host ""
Write-Host "[OK] Archive créée :"
Write-Host "     $Output"

Write-Host ""
Write-Host "Taille :"
(Get-Item $Output).Length / 1MB |
    ForEach-Object { "{0:N2} MB" -f $_ }