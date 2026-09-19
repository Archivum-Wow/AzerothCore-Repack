param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root       = $env:GITHUB_WORKSPACE
$RepackRoot = Join-Path $Root $Variant

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

$sourcesDir = Join-Path $RepackRoot "_sources"
if (Test-Path $sourcesDir) {
    Write-Host "[Cleanup] Suppression des ZIPs dans _sources..."
    Get-ChildItem -Path $sourcesDir -Filter "*.zip" -File -Recurse -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

$extractedDir = Join-Path $sourcesDir "_extracted"
if (Test-Path $extractedDir) {
    Write-Host "[Cleanup] Suppression de _extracted..."
    Remove-Item $extractedDir -Recurse -Force
}

$mysqlServer = Join-Path $RepackRoot "_mysql\server"
if (Test-Path $mysqlServer) {
    Write-Host "[Cleanup] Suppression de _mysql\server..."
    Remove-Item $mysqlServer -Recurse -Force
}

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

if (Test-Path $Output) {
    Remove-Item $Output -Force
}

Write-Host ""
Write-Host "[ZIP] Création de $Output"

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