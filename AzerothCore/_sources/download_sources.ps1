param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$Sources = $PSScriptRoot
$RepackRoot = Split-Path $Sources -Parent
$ToolsRoot = Join-Path $RepackRoot "_tools"
$CurlExe = Join-Path $ToolsRoot "curl-8.22.0_1-win64-mingw\curl.exe"

$AcCommit = "8c53e9f3eb2b2bc4ff438486cb28824364c4724e"
$AleCommit = "84b85cc55980dbf67d596f3d5cb34ded10c59102"

$AcZip = Join-Path $Sources "azerothcore-wotlk.zip"
$AleZip = Join-Path $Sources "mod-ale.zip"

$AcUrl = "https://github.com/azerothcore/azerothcore-wotlk/archive/$AcCommit.zip"
$AleUrl = "https://github.com/azerothcore/mod-ale/archive/$AleCommit.zip"

function Download-File {
    param([string]$Url, [string]$OutPath)
    if (Test-Path $CurlExe) {
        & $CurlExe -L --fail $Url -o $OutPath
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to download $Url using curl"
        }
    } else {
        Invoke-WebRequest -Uri $Url -OutFile $OutPath
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Downloading AzerothCore" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Download-File $AcUrl $AcZip

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Downloading mod-ale" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Download-File $AleUrl $AleZip

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Downloads completed" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] AzerothCore : $AcZip"
Write-Host "[OK] mod-ale     : $AleZip"
Write-Host ""

if (-not $NonInteractive) {
    Read-Host "Press Enter to continue"
}
