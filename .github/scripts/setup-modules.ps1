param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Modules = Join-Path $env:CORE_SOURCE "modules"

if (-not (Test-Path $Modules)) {
    throw "AzerothCore modules directory not found: $Modules"
}

function Copy-Module {
    param(
        [string]$Source,
        [string]$Name
    )

    if (-not (Test-Path $Source)) {
        throw "Module source not found: $Source"
    }

    $Destination = Join-Path $Modules $Name

    if (Test-Path $Destination) {
        Remove-Item $Destination -Recurse -Force
    }

    Write-Host "[Module] Installing $Name..."

    Copy-Item `
        -Path $Source `
        -Destination $Destination `
        -Recurse `
        -Force
}

Copy-Module $env:ALE_SOURCE "mod-ale"

if ($Variant -eq "PlayerBots") {
    Copy-Module $env:PLAYERBOTS_SOURCE "mod-playerbots"
}

Write-Host ""
Write-Host "[OK] Modules installed in $Modules:"
Get-ChildItem $Modules -Directory |
    ForEach-Object {
        Write-Host "  - $($_.Name)"
    }