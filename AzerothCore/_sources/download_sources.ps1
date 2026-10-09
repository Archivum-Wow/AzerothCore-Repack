param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$Sources = $PSScriptRoot
$RepackRoot = Split-Path $Sources -Parent
$ToolsRoot = Join-Path $RepackRoot "_tools"
$CurlExe = Join-Path $ToolsRoot "curl-8.22.0_1-win64-mingw\curl.exe"

$AcCommit = "a05a04313eadcc61b38aaa1c9a7a9cd56395f279"
$AleCommit = "cead0cb2e58ec0f73676ba578eff26cddb79fc01"

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
