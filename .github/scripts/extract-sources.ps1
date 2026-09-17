param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root = $env:GITHUB_WORKSPACE
$RepackRoot = Join-Path $Root $Variant
$SourcesRoot = Join-Path $RepackRoot "_sources"
$DownloadScript = Join-Path $SourcesRoot "download_sources.ps1"

Write-Host "========================================"
Write-Host " Extracting sources: $Variant"
Write-Host "========================================"

if (-not (Test-Path $DownloadScript)) {
    throw "Source download script not found: $DownloadScript"
}

Write-Host "[Sources] Running download_sources.ps1..."

& $DownloadScript -NonInteractive

$zipFiles = Get-ChildItem $SourcesRoot -Filter "*.zip" -File

if ($zipFiles.Count -eq 0) {
    throw "No source ZIP files were found in $SourcesRoot"
}

$ExtractRoot = Join-Path $SourcesRoot "_extracted"

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
}

# ------------------------------------------------------------
# Find AzerothCore source
# ------------------------------------------------------------

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
    Write-Host "Extracted files:"
    Get-ChildItem $ExtractRoot -Recurse -Directory |
        Select-Object -First 100 |
        ForEach-Object { Write-Host "  $($_.FullName)" }

    throw "AzerothCore source could not be detected."
}

Write-Host ""
Write-Host "[OK] AzerothCore source:"
Write-Host "     $CoreSource"

# ------------------------------------------------------------
# Find modules
# ------------------------------------------------------------

$ModuleCandidates = Get-ChildItem `
    -Path $ExtractRoot `
    -Directory `
    -Recurse `
    -ErrorAction SilentlyContinue

$AleSource = $ModuleCandidates |
    Where-Object {
        $_.Name -match "^mod[-_]ale$"
    } |
    Select-Object -First 1

if (-not $AleSource) {
    throw "mod-ale source could not be detected."
}

Write-Host "[OK] mod-ale:"
Write-Host "     $($AleSource.FullName)"

$PlayerBotsSource = $null

if ($Variant -eq "PlayerBots") {
    $PlayerBotsSource = $ModuleCandidates |
        Where-Object {
            $_.Name -match "^mod[-_]playerbots$"
        } |
        Select-Object -First 1

    if (-not $PlayerBotsSource) {
        throw "mod-playerbots source could not be detected."
    }

    Write-Host "[OK] mod-playerbots:"
    Write-Host "     $($PlayerBotsSource.FullName)"
}

# ------------------------------------------------------------
# Export paths
# ------------------------------------------------------------

$coreForward = "$CoreSource".Replace("\", "/")
$aleForward = $AleSource.FullName.Replace("\", "/")

"CORE_SOURCE=$coreForward" | Out-File $env:GITHUB_ENV -Append
"ALE_SOURCE=$aleForward" | Out-File $env:GITHUB_ENV -Append

if ($PlayerBotsSource) {
    $pbForward = $PlayerBotsSource.FullName.Replace("\", "/")
    "PLAYERBOTS_SOURCE=$pbForward" | Out-File $env:GITHUB_ENV -Append
}

Write-Host ""
Write-Host "[OK] Source extraction completed."