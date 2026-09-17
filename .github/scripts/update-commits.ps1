param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = if ($env:GITHUB_WORKSPACE) { $env:GITHUB_WORKSPACE } else { Split-Path (Split-Path $ScriptDir -Parent) -Parent }

Write-Host "========================================"
Write-Host " Checking Repositories for Updates"
Write-Host " Repo Root: $RepoRoot"
Write-Host "========================================"

function Get-RemoteCommit {
    param([string]$RepoUrl)

    $output = & git ls-remote $RepoUrl HEAD
    if ($LASTEXITCODE -ne 0 -or -not $output) {
        throw "Failed to fetch HEAD commit from $RepoUrl"
    }

    $commit = $null
    foreach ($line in ($output -split "`r?`n")) {
        if ($line -match '^([0-9a-fA-F]{40})\s+HEAD') {
            $commit = $Matches[1].ToLower().Trim()
            break
        }
    }

    if (-not $commit) {
        throw "Could not parse commit SHA from git ls-remote output for $RepoUrl`: $output"
    }

    return $commit
}

function Update-ScriptCommits {
    param(
        [string]$FilePath,
        [hashtable]$Commits
    )

    if (-not (Test-Path $FilePath)) {
        throw "Target script not found: $FilePath"
    }

    $content = [System.IO.File]::ReadAllText($FilePath)
    $updatedContent = $content
    $hasChanges = $false

    foreach ($varName in $Commits.Keys) {
        $remoteHash = $Commits[$varName].Remote
        $pattern = '(\$' + [regex]::Escape($varName) + '\s*=\s*")([^"]*)(")'

        if ($updatedContent -match $pattern) {
            $match = [regex]::Match($updatedContent, $pattern)
            $currentVal = $match.Groups[2].Value.Trim()

            if ($currentVal.ToLower() -ne $remoteHash.ToLower()) {
                Write-Host "  - $($Commits[$varName].Label): $currentVal -> $remoteHash (UPDATED)"
                $updatedContent = [regex]::Replace($updatedContent, $pattern, "`${1}$remoteHash`${3}")
                $hasChanges = $true
            } else {
                Write-Host "  - $($Commits[$varName].Label): $currentVal (UP TO DATE)"
            }
        } else {
            Write-Warning "Variable `$$varName was not found in $FilePath"
        }
    }

    if ($hasChanges) {
        [System.IO.File]::WriteAllText($FilePath, $updatedContent)
    }

    return $hasChanges
}

# ------------------------------------------------------------
# 1. Fetch remote HEAD commits
# ------------------------------------------------------------
Write-Host ""
Write-Host "[Git] Fetching latest remote commits..."

$repos = @{
    "ac_official"  = @{ Url = "https://github.com/azerothcore/azerothcore-wotlk.git";  Label = "azerothcore/azerothcore-wotlk" }
    "ac_playerbot" = @{ Url = "https://github.com/mod-playerbots/azerothcore-wotlk.git"; Label = "mod-playerbots/azerothcore-wotlk" }
    "mod_ale"      = @{ Url = "https://github.com/azerothcore/mod-ale.git";             Label = "azerothcore/mod-ale" }
    "mod_pb"       = @{ Url = "https://github.com/mod-playerbots/mod-playerbots.git";   Label = "mod-playerbots/mod-playerbots" }
}

$latestCommits = @{}
foreach ($key in $repos.Keys) {
    $commit = Get-RemoteCommit -RepoUrl $repos[$key].Url
    $latestCommits[$key] = $commit
    Write-Host "  $($repos[$key].Label): $commit"
}

# ------------------------------------------------------------
# 2. Check and update AzerothCore
# ------------------------------------------------------------
Write-Host ""
Write-Host "Checking AzerothCore variant..."
$acScript = Join-Path $RepoRoot "AzerothCore\_sources\download_sources.ps1"
$acMap = @{
    "AcCommit"  = @{ Remote = $latestCommits["ac_official"]; Label = "AzerothCore" }
    "AleCommit" = @{ Remote = $latestCommits["mod_ale"];      Label = "mod-ale" }
}
$acChanged = Update-ScriptCommits -FilePath $acScript -Commits $acMap
Write-Host "  AzerothCore changed: $acChanged"

# ------------------------------------------------------------
# 3. Check and update PlayerBots
# ------------------------------------------------------------
Write-Host ""
Write-Host "Checking PlayerBots variant..."
$pbScript = Join-Path $RepoRoot "PlayerBots\_sources\download_sources.ps1"
$pbMap = @{
    "AcCommit"  = @{ Remote = $latestCommits["ac_playerbot"]; Label = "AzerothCore (PlayerBots)" }
    "AleCommit" = @{ Remote = $latestCommits["mod_ale"];       Label = "mod-ale" }
    "PbCommit"  = @{ Remote = $latestCommits["mod_pb"];        Label = "mod-playerbots" }
}
$pbChanged = Update-ScriptCommits -FilePath $pbScript -Commits $pbMap
Write-Host "  PlayerBots changed: $pbChanged"

# ------------------------------------------------------------
# 4. Output results for GitHub Actions
# ------------------------------------------------------------
$forceBuild = if ($Force -or ($env:FORCE_BUILD -eq "true")) { "true" } else { "false" }
$acOutput = if ($acChanged) { "true" } else { "false" }
$pbOutput = if ($pbChanged) { "true" } else { "false" }

Write-Host ""
Write-Host "========================================"
Write-Host " Summary:"
Write-Host "   AzerothCore updated : $acOutput"
Write-Host "   PlayerBots updated  : $pbOutput"
Write-Host "   Force build         : $forceBuild"
Write-Host "========================================"

if ($env:GITHUB_OUTPUT) {
    "ac_changed=$acOutput" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "pb_changed=$pbOutput" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "force_build=$forceBuild" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}
