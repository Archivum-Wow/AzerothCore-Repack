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

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    Write-Host "[Module] Installing $Name from $Source into $Destination..."

    Copy-Item `
        -Path "$Source\*" `
        -Destination $Destination `
        -Recurse `
        -Force

    $destCmake = Join-Path $Destination "CMakeLists.txt"
    if (-not (Test-Path $destCmake)) {
        throw "CMakeLists.txt was not found in module destination: $Destination"
    }
}

Copy-Module $env:ALE_SOURCE "mod-ale"

if ($Variant -eq "PlayerBots") {
    Copy-Module $env:PLAYERBOTS_SOURCE "mod-playerbots"
}

Write-Host ""
Write-Host "[OK] Modules installed in: $Modules"
Get-ChildItem $Modules -Directory |
    ForEach-Object {
        Write-Host "  - $($_.Name)"
    }