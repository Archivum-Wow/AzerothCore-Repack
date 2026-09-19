param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root           = $env:GITHUB_WORKSPACE
$RepackRoot     = Join-Path $Root $Variant
$SourcesRoot    = Join-Path $RepackRoot "_sources"
$DownloadScript = Join-Path $SourcesRoot "download_sources.ps1"

Write-Host "========================================"
Write-Host " Extraction des sources : $Variant"
Write-Host "========================================"

if (-not (Test-Path $DownloadScript)) {
    throw "Script de téléchargement introuvable : $DownloadScript"
}

Write-Host "[Sources] Exécution de download_sources.ps1..."
& $DownloadScript -NonInteractive

$zipFiles = Get-ChildItem $SourcesRoot -Filter "*.zip" -File

if ($zipFiles.Count -eq 0) {
    throw "Aucun fichier ZIP trouvé dans $SourcesRoot"
}

$ExtractRoot = if ($env:GITHUB_ACTIONS) {
    "C:\s"
} else {
    Join-Path $SourcesRoot "_extracted"
}

if (Test-Path $ExtractRoot) {
    Remove-Item $ExtractRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $ExtractRoot | Out-Null

foreach ($zip in $zipFiles) {
    Write-Host ""
    Write-Host "[Extract] $($zip.Name)"

    $destination = Join-Path $ExtractRoot ([IO.Path]::GetFileNameWithoutExtension($zip.Name))
    New-Item -ItemType Directory -Path $destination | Out-Null

    Expand-Archive `
        -Path $zip.FullName `
        -DestinationPath $destination `
        -Force

    $inner = @(Get-ChildItem $destination -Force)

    if ($inner.Count -eq 1 -and $inner[0].PSIsContainer) {
        $staging = Join-Path $ExtractRoot ("_flat_" + [Guid]::NewGuid().ToString("N").Substring(0, 8))

        Move-Item $inner[0].FullName $staging
        Remove-Item $destination -Recurse -Force
        Move-Item $staging $destination

        Write-Host "[Flatten] $($inner[0].Name) -> $destination"
    }

    Remove-Item $zip.FullName -Force
    Write-Host "[Cleanup] ZIP supprimé : $($zip.Name)"
}

function Find-AzerothCoreSource {
    param([string]$Path)

    $matches = Get-ChildItem `
        -Path $Path `
        -Filter "CMakeLists.txt" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Where-Object {
            Test-Path (Join-Path $_.Directory.FullName "src") -PathType Container
        }

    if ($matches.Count -eq 0) {
        return $null
    }

    return $matches |
        Sort-Object FullName |
        Select-Object -First 1 |
        ForEach-Object { $_.Directory.FullName }
}

$CoreSource = Find-AzerothCoreSource $ExtractRoot

if (-not $CoreSource) {
    Write-Host ""
    Write-Host "Dossiers extraits :"
    Get-ChildItem $ExtractRoot -Recurse -Directory |
        Select-Object -First 100 |
        ForEach-Object { Write-Host "  $($_.FullName)" }

    throw "Impossible de détecter les sources AzerothCore."
}

Write-Host ""
Write-Host "[OK] Source AzerothCore :"
Write-Host "     $CoreSource"

function Find-ModuleSource {
    param(
        [string]$Path,
        [string]$Pattern
    )

    $candidates = Get-ChildItem `
        -Path $Path `
        -Directory `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Where-Object {
            ($_.Name -match $Pattern) -and (
                (Test-Path (Join-Path $_.FullName "CMakeLists.txt")) -or
                (Test-Path (Join-Path $_.FullName "include.sh")) -or
                (Test-Path (Join-Path $_.FullName "src"))
            )
        }

    if ($candidates) {
        return ($candidates |
            Sort-Object { $_.FullName.Length } -Descending |
            Select-Object -First 1).FullName
    }

    return $null
}

$AleSource = Find-ModuleSource -Path $ExtractRoot -Pattern "mod[-_]ale"

if (-not $AleSource) {
    throw "Impossible de détecter mod-ale dans $ExtractRoot."
}

Write-Host "[OK] mod-ale :"
Write-Host "     $AleSource"

$PlayerBotsSource = $null

if ($Variant -eq "PlayerBots") {
    $PlayerBotsSource = Find-ModuleSource -Path $ExtractRoot -Pattern "mod[-_]playerbots"

    if (-not $PlayerBotsSource) {
        throw "Impossible de détecter mod-playerbots dans $ExtractRoot."
    }

    Write-Host "[OK] mod-playerbots :"
    Write-Host "     $PlayerBotsSource"
}

$coreForward = "$CoreSource".Replace("\", "/")
$aleForward  = "$AleSource".Replace("\", "/")

"CORE_SOURCE=$coreForward" | Out-File $env:GITHUB_ENV -Append
"ALE_SOURCE=$aleForward"   | Out-File $env:GITHUB_ENV -Append

if ($PlayerBotsSource) {
    $pbForward = "$PlayerBotsSource".Replace("\", "/")
    "PLAYERBOTS_SOURCE=$pbForward" | Out-File $env:GITHUB_ENV -Append
}

$buildDir = if ($env:GITHUB_ACTIONS) {
    "C:\ac_build"
} else {
    Join-Path $CoreSource "build"
}
$buildForward = $buildDir.Replace("\", "/")
"CORE_BUILD=$buildForward" | Out-File $env:GITHUB_ENV -Append

Get-ChildItem -Path $SourcesRoot -Filter "*.zip" -File -Recurse -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[OK] Extraction des sources terminée."