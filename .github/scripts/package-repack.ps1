param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root = $env:GITHUB_WORKSPACE

$RepackRoot = Join-Path $Root $Variant

if ($Variant -eq "AzerothCore") {
    $OutputName = "AzerothCore-Repack-Windows-x64.zip"
}
else {
    $OutputName = "AzerothCore-PlayerBots-Repack-Windows-x64.zip"
}

$Output = Join-Path $Root $OutputName

Write-Host "========================================"
Write-Host " Packaging: $Variant"
Write-Host "========================================"

if (-not (Test-Path $RepackRoot)) {
    throw "Repack directory not found: $RepackRoot"
}

if (Test-Path $Output) {
    Remove-Item $Output -Force
}

Write-Host "[ZIP] Creating $Output"

Compress-Archive `
    -Path "$RepackRoot\*" `
    -DestinationPath $Output `
    -CompressionLevel Optimal `
    -Force

if (-not (Test-Path $Output)) {
    throw "ZIP was not created."
}

Write-Host ""
Write-Host "[OK] Package created:"
Write-Host "     $Output"

Write-Host ""
Write-Host "Size:"
(Get-Item $Output).Length / 1MB |
    ForEach-Object {
        "{0:N2} MB" -f $_
    }