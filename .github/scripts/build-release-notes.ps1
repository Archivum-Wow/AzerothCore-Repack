param(
    [Parameter(Mandatory = $true)]
    [string]$CommitsJson,

    [Parameter(Mandatory = $true)]
    [string]$Tag,

    [Parameter(Mandatory = $true)]
    [string]$Built,

    [Parameter(Mandatory = $true)]
    [string]$OutFile
)

$ErrorActionPreference = "Stop"

$commits = $CommitsJson | ConvertFrom-Json

$builtList = @(
    $Built -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
)

if ($builtList.Count -eq 0) {
    throw "Aucune variante compilée : rien à publier."
}

$variants = [ordered]@{
    "AzerothCore" = @{
        Key     = "azerothcore"
        Title   = "AzerothCore"
        Archive = "AzerothCore-Repack-Windows-x64.zip"
    }
    "PlayerBots"  = @{
        Key     = "playerbots"
        Title   = "AzerothCore + PlayerBots"
        Archive = "AzerothCore-PlayerBots-Repack-Windows-x64.zip"
    }
}

function Get-UpdateSummary {
    param($Entry)

    if (-not $Entry.changed) {
        return "inchangé"
    }

    $compare = "https://github.com/$($Entry.repo)/compare/$($Entry.old)...$($Entry.new)"
    $ahead   = $null

    try {
        $headers = @{
            "Accept"     = "application/vnd.github+json"
            "User-Agent" = "azerothcore-repack"
        }

        if ($env:GITHUB_TOKEN) {
            $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
        }

        $response = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$($Entry.repo)/compare/$($Entry.old)...$($Entry.new)" `
            -Headers $headers

        $ahead = $response.ahead_by
    }
    catch {
        Write-Host "[Notes] Comparaison indisponible pour $($Entry.repo) : $($_.Exception.Message)"
    }

    if ($null -ne $ahead) {
        $label = if ($ahead -gt 1) { "nouveaux commits" } else { "nouveau commit" }
        return "[$ahead $label]($compare)"
    }

    return "[voir les changements]($compare)"
}

$lines = New-Object System.Collections.Generic.List[string]

$builtOn = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm")
$lines.Add("Repack compilé le **$builtOn UTC**.")
$lines.Add("")

$lines.Add("## Archives")
$lines.Add("")
$lines.Add("| Variante | Archive |")
$lines.Add("| --- | --- |")

foreach ($name in $builtList) {
    if (-not $variants.Contains($name)) {
        Write-Warning "Variante inconnue, ignorée : $name"
        continue
    }

    $lines.Add("| $($variants[$name].Title) | ``$($variants[$name].Archive)`` |")
}

$lines.Add("")
$lines.Add("## Sources compilées")

foreach ($name in $builtList) {
    if (-not $variants.Contains($name)) {
        continue
    }

    $entries = $commits.($variants[$name].Key)

    $lines.Add("")
    $lines.Add("### $($variants[$name].Title)")
    $lines.Add("")

    if (-not $entries) {
        $lines.Add("_Informations de commit indisponibles._")
        continue
    }

    $lines.Add("| Dépôt | Commit | Mise à jour |")
    $lines.Add("| --- | --- | --- |")

    foreach ($entry in $entries) {
        $short  = $entry.new.Substring(0, 7)
        $link   = "https://github.com/$($entry.repo)/commit/$($entry.new)"
        $update = Get-UpdateSummary -Entry $entry

        $lines.Add("| [$($entry.repo)](https://github.com/$($entry.repo)) | [``$short``]($link) | $update |")
    }
}

if ($env:GITHUB_SERVER_URL -and $env:GITHUB_REPOSITORY -and $env:GITHUB_RUN_ID) {
    $run = "$env:GITHUB_SERVER_URL/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID"
    $lines.Add("")
    $lines.Add("---")
    $lines.Add("")
    $lines.Add("[Détail de la compilation]($run)")
}

$content  = ($lines -join "`n") + "`n"
$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutFile, $content, $encoding)

Write-Host "[Notes] Release $Tag - $($builtList.Count) variante(s) : $($builtList -join ', ')"
Write-Host "[Notes] Notes écrites dans : $OutFile"
