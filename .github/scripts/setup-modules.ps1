param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Modules = Join-Path $env:CORE_SOURCE "modules"

if (Test-Path $Modules) {
    Remove-Item $Modules -Recurse -Force
}

New-Item -ItemType Directory -Path $Modules | Out-Null

function Copy-Module {
    param(
        [string]$Source,
        [string]$Name
    )

    if (-not (Test-Path $Source)) {
        throw "Module source not found: $Source"
    }

    $Destination = Join-Path $Modules $Name

    Write-Host "[Module] $Name"

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
Write-Host "[OK] Modules installed:"
Get-ChildItem $Modules -Directory |
    ForEach-Object {
        Write-Host "  - $($_.Name)"
    }