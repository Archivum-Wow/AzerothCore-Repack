param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$Sources = $PSScriptRoot
$RepackRoot = Split-Path $Sources -Parent
$ToolsRoot = Join-Path $RepackRoot "_tools"
$CurlExe = Join-Path $ToolsRoot "curl-8.22.0_1-win64-mingw\curl.exe"

$AcCommit = "06234df3d5ab26c93f4f1f06f3edb828b73ecd3c"
$AleCommit = "bd74eae623ca63154d3eb49e1d187e872ef13370"
$PbCommit = "b6696bdbd3740e575598d167d69f39f68cc0b907"

$AcZip = Join-Path $Sources "azerothcore-wotlk.zip"
$AleZip = Join-Path $Sources "mod-ale.zip"
$PbZip = Join-Path $Sources "mod-playerbots.zip"

$AcUrl = "https://github.com/mod-playerbots/azerothcore-wotlk/archive/$AcCommit.zip"
$AleUrl = "https://github.com/azerothcore/mod-ale/archive/$AleCommit.zip"
$PbUrl = "https://github.com/mod-playerbots/mod-playerbots/archive/$PbCommit.zip"

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
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Downloading mod-playerbots" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Download-File $PbUrl $PbZip

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Downloads completed" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] AzerothCore    : $AcZip"
Write-Host "[OK] mod-ale        : $AleZip"
Write-Host "[OK] mod-playerbots : $PbZip"
Write-Host ""

if (-not $NonInteractive) {
    Read-Host "Press Enter to continue"
}
