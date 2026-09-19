param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Modules = Join-Path $env:CORE_SOURCE "modules"

if (-not (Test-Path $Modules)) {
    throw "Dossier modules introuvable : $Modules"
}

function Copy-Module {
    param(
        [string]$Source,
        [string]$Name
    )

    if (-not (Test-Path $Source)) {
        throw "Source du module introuvable : $Source"
    }

    $Destination = Join-Path $Modules $Name

    if (Test-Path $Destination) {
        Remove-Item $Destination -Recurse -Force
    }

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    Write-Host "[Module] Installation de $Name depuis $Source..."

    Copy-Item `
        -Path "$Source\*" `
        -Destination $Destination `
        -Recurse `
        -Force

    $hasCmake   = Test-Path (Join-Path $Destination "CMakeLists.txt")
    $hasInclude = Test-Path (Join-Path $Destination "include.sh")
    $hasSrc     = Test-Path (Join-Path $Destination "src")

    if (-not ($hasCmake -or $hasInclude -or $hasSrc)) {
        throw "Le module $Name ne contient aucun fichier valide dans : $Destination"
    }
}

Copy-Module $env:ALE_SOURCE "mod-ale"

if ($Variant -eq "PlayerBots") {
    Copy-Module $env:PLAYERBOTS_SOURCE "mod-playerbots"
}

Write-Host ""
Write-Host "[OK] Modules installés dans : $Modules"
Get-ChildItem $Modules -Directory |
    ForEach-Object { Write-Host "  - $($_.Name)" }