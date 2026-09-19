param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$DataDir = $PSScriptRoot
$RepackRoot = Split-Path $DataDir -Parent
$ToolsRoot = Join-Path $RepackRoot "_tools"
$CurlExe = Join-Path $ToolsRoot "curl-8.22.0_1-win64-mingw\curl.exe"

$ZipFile = Join-Path $DataDir "Data.zip"
$Url = "https://github.com/wowgaming/client-data/releases/download/v20.0/Data.zip"

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
Write-Host "   Downloading World of Warcraft Data" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Download-File $Url $ZipFile

Write-Host ""
Write-Host "[OK] Download completed." -ForegroundColor Green
Write-Host ""
Write-Host "[INFO] Extracting Data.zip..." -ForegroundColor Yellow
Write-Host ""

Expand-Archive -LiteralPath $ZipFile -DestinationPath $DataDir -Force

if (Test-Path $ZipFile) {
    Remove-Item $ZipFile -Force
}

Write-Host ""
Write-Host "[OK] Client data installed successfully." -ForegroundColor Green
Write-Host ""

if (-not $NonInteractive) {
    Read-Host "Press Enter to continue"
}
