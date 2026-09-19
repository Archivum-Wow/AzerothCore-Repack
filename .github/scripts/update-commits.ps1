param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot  = if ($env:GITHUB_WORKSPACE) {
    $env:GITHUB_WORKSPACE
} else {
    Split-Path (Split-Path $ScriptDir -Parent) -Parent
}

Write-Host "========================================"
Write-Host " Vérification des dépôts distants"
Write-Host " Repo Root : $RepoRoot"
Write-Host "========================================"

function Get-RemoteCommit {
    param([string]$RepoUrl)

    $output = & git ls-remote $RepoUrl HEAD
    if ($LASTEXITCODE -ne 0 -or -not $output) {
        throw "Impossible de récupérer le HEAD de $RepoUrl"
    }

    $commit = $null
    foreach ($line in ($output -split "`r?`n")) {
        if ($line -match '^([0-9a-fA-F]{40})\s+HEAD') {
            $commit = $Matches[1].ToLower().Trim()
            break
        }
    }

    if (-not $commit) {
        throw "Impossible de parser le SHA pour $RepoUrl : $output"
    }

    return $commit
}

function Update-ScriptCommits {
    param(
        [string]$FilePath,
        $Commits
    )

    if (-not (Test-Path $FilePath)) {
        throw "Script cible introuvable : $FilePath"
    }

    $content        = [System.IO.File]::ReadAllText($FilePath)
    $updatedContent = $content
    $hasChanges     = $false
    $details        = New-Object System.Collections.Generic.List[object]

    foreach ($varName in $Commits.Keys) {
        $remoteHash = $Commits[$varName].Remote
        $pattern = '(\$' + [regex]::Escape($varName) + '\s*=\s*")([^"]*)(")'

        if ($updatedContent -match $pattern) {
            $match      = [regex]::Match($updatedContent, $pattern)
            $currentVal = $match.Groups[2].Value.Trim()

            $changed = ($currentVal.ToLower() -ne $remoteHash.ToLower())

            if ($changed) {
                Write-Host "  - $($Commits[$varName].Label) : $currentVal -> $remoteHash (MIS À JOUR)"
                $updatedContent = [regex]::Replace($updatedContent, $pattern, "`${1}$remoteHash`${3}")
                $hasChanges     = $true
            } else {
                Write-Host "  - $($Commits[$varName].Label) : $currentVal (à jour)"
            }

            $details.Add([ordered]@{
                label   = $Commits[$varName].Label
                repo    = $Commits[$varName].Repo
                old     = $currentVal
                new     = $remoteHash
                changed = $changed
            })
        } else {
            Write-Warning "Variable `$$varName introuvable dans $FilePath"
        }
    }

    if ($hasChanges) {
        [System.IO.File]::WriteAllText($FilePath, $updatedContent)
    }

    return [pscustomobject]@{
        Changed = $hasChanges
        Details = $details
    }
}

Write-Host ""
Write-Host "[Git] Récupération des derniers commits distants..."

$repos = @{
    "ac_official"  = @{ Url = "https://github.com/azerothcore/azerothcore-wotlk.git";    Label = "azerothcore/azerothcore-wotlk" }
    "ac_playerbot" = @{ Url = "https://github.com/mod-playerbots/azerothcore-wotlk.git"; Label = "mod-playerbots/azerothcore-wotlk" }
    "mod_ale"      = @{ Url = "https://github.com/azerothcore/mod-ale.git";               Label = "azerothcore/mod-ale" }
    "mod_pb"       = @{ Url = "https://github.com/mod-playerbots/mod-playerbots.git";     Label = "mod-playerbots/mod-playerbots" }
}

$latestCommits = @{}
foreach ($key in $repos.Keys) {
    $commit = Get-RemoteCommit -RepoUrl $repos[$key].Url
    $latestCommits[$key] = $commit
    Write-Host "  $($repos[$key].Label) : $commit"
}

Write-Host ""
Write-Host "Vérification de la variante AzerothCore..."
$acScript = Join-Path $RepoRoot "AzerothCore\_sources\download_sources.ps1"
$acMap = [ordered]@{
    "AcCommit"  = @{ Remote = $latestCommits["ac_official"]; Label = "AzerothCore"; Repo = $repos["ac_official"].Label }
    "AleCommit" = @{ Remote = $latestCommits["mod_ale"];      Label = "mod-ale";     Repo = $repos["mod_ale"].Label }
}
$acResult  = Update-ScriptCommits -FilePath $acScript -Commits $acMap
$acChanged = $acResult.Changed
Write-Host "  AzerothCore modifié : $acChanged"

Write-Host ""
Write-Host "Vérification de la variante PlayerBots..."
$pbScript = Join-Path $RepoRoot "PlayerBots\_sources\download_sources.ps1"
$pbMap = [ordered]@{
    "AcCommit"  = @{ Remote = $latestCommits["ac_playerbot"]; Label = "AzerothCore (PlayerBots)"; Repo = $repos["ac_playerbot"].Label }
    "AleCommit" = @{ Remote = $latestCommits["mod_ale"];       Label = "mod-ale";                  Repo = $repos["mod_ale"].Label }
    "PbCommit"  = @{ Remote = $latestCommits["mod_pb"];        Label = "mod-playerbots";           Repo = $repos["mod_pb"].Label }
}
$pbResult  = Update-ScriptCommits -FilePath $pbScript -Commits $pbMap
$pbChanged = $pbResult.Changed
Write-Host "  PlayerBots modifié : $pbChanged"

$forceBuild = if ($Force -or ($env:FORCE_BUILD -eq "true")) { "true" } else { "false" }
$acOutput   = if ($acChanged) { "true" } else { "false" }
$pbOutput   = if ($pbChanged) { "true" } else { "false" }

Write-Host ""
Write-Host "========================================"
Write-Host " Résumé :"
Write-Host "   AzerothCore mis à jour : $acOutput"
Write-Host "   PlayerBots mis à jour  : $pbOutput"
Write-Host "   Build forcé            : $forceBuild"
Write-Host "========================================"

if ($env:GITHUB_OUTPUT) {
    "ac_changed=$acOutput"   | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "pb_changed=$pbOutput"   | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "force_build=$forceBuild" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8

    $commitsJson = [pscustomobject]@{
        azerothcore = $acResult.Details
        playerbots  = $pbResult.Details
    } | ConvertTo-Json -Depth 5 -Compress

    "commits_json=$commitsJson" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}