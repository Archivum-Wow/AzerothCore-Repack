param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root       = $env:GITHUB_WORKSPACE
$RepackRoot = Join-Path $Root $Variant
$Runtime    = Join-Path $RepackRoot "azerothcore"
$BuildRoot  = $env:CORE_BUILD

if (-not $BuildRoot) {
    $BuildRoot = Join-Path $env:CORE_SOURCE "build"
}

Write-Host "========================================"
Write-Host " Collecte du runtime : $Variant"
Write-Host " Build Root          : $BuildRoot"
Write-Host "========================================"

if (-not (Test-Path (Join-Path $BuildRoot "bin\Release"))) {
    if (Test-Path (Join-Path $BuildRoot "bin")) {
        $BuildRoot = Join-Path $BuildRoot "bin"
    } elseif (-not (Test-Path $BuildRoot)) {
        throw "Sortie de build introuvable : $BuildRoot"
    }
}

if (Test-Path $Runtime) {
    Write-Host "[Clean] Réinitialisation du runtime..."
    Remove-Item $Runtime -Recurse -Force
}
New-Item -ItemType Directory -Path $Runtime -Force | Out-Null

$AllowedDlls = @(
    "legacy.dll",
    "libcrypto-3-x64.dll",
    "libssl-3-x64.dll",
    "libmysql.dll"
)

$Executables = @(
    "authserver.exe",
    "worldserver.exe",
    "map_extractor.exe",
    "vmap4_extractor.exe",
    "vmap4_assembler.exe",
    "mmaps_generator.exe"
)

foreach ($exe in $Executables) {
    $source = Get-ChildItem `
        -Path $BuildRoot `
        -Filter $exe `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $source) {
        throw "Exécutable requis introuvable : $exe"
    }

    Copy-Item $source.FullName (Join-Path $Runtime $exe) -Force
    Write-Host "[EXE] $exe"
}

$mmapsConfig = Get-ChildItem `
    -Path $BuildRoot `
    -Filter "mmaps-config.yaml" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($mmapsConfig) {
    Copy-Item $mmapsConfig.FullName (Join-Path $Runtime "mmaps-config.yaml") -Force
    Write-Host "[YML] mmaps-config.yaml"
}

Write-Host ""
Write-Host "[DLL] Copie des DLLs autorisées..."

foreach ($dllName in $AllowedDlls) {
    $dll = Get-ChildItem `
        -Path $BuildRoot `
        -Filter $dllName `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($dll) {
        Copy-Item $dll.FullName (Join-Path $Runtime $dllName) -Force
        Write-Host "  [DLL] $dllName"
    }
}

$runtimeMysqlDll = Join-Path $Runtime "libmysql.dll"
if (-not (Test-Path $runtimeMysqlDll)) {
    $mysqlLibDll = Join-Path $RepackRoot "_mysql\server\lib\libmysql.dll"
    if (Test-Path $mysqlLibDll) {
        Copy-Item $mysqlLibDll $runtimeMysqlDll -Force
        Write-Host "  [DLL] libmysql.dll (depuis MySQL server)"
    }
}

$missingSsl = -not (
    (Test-Path (Join-Path $Runtime "libcrypto-3-x64.dll")) -and
    (Test-Path (Join-Path $Runtime "libssl-3-x64.dll")) -and
    (Test-Path (Join-Path $Runtime "legacy.dll"))
)

if ($missingSsl) {
    $opensslCandidates = @(
        "C:\Program Files\OpenSSL\bin",
        "C:\Program Files\OpenSSL-Win64\bin",
        "C:\OpenSSL-Win64\bin"
    )
    foreach ($dir in $opensslCandidates) {
        if (Test-Path $dir) {
            foreach ($name in @("libcrypto-3-x64.dll", "libssl-3-x64.dll", "legacy.dll")) {
                $src = Join-Path $dir $name
                $dst = Join-Path $Runtime $name
                if ((Test-Path $src) -and (-not (Test-Path $dst))) {
                    Copy-Item $src $dst -Force
                    Write-Host "  [DLL] $name (depuis OpenSSL)"
                }
            }
            break
        }
    }
}

Write-Host "[OK] DLLs copiées."

$LuaCandidates = @(
    (Join-Path $env:CORE_SOURCE "lua_scripts"),
    (Join-Path $env:CORE_SOURCE "modules\mod-ale\lua_scripts")
)

foreach ($lua in $LuaCandidates) {
    if (Test-Path $lua) {
        $destination = Join-Path $Runtime "lua_scripts"
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Copy-Item "$lua\*" $destination -Recurse -Force
        Write-Host "[LUA] Scripts copiés depuis $lua"
    }
}

$ConfigDir        = Join-Path $Runtime "configs"
$ModulesConfigDir = Join-Path $ConfigDir "modules"

New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
New-Item -ItemType Directory -Path $ModulesConfigDir -Force | Out-Null

$buildConfigCandidates = @(
    (Join-Path $BuildRoot "bin\Release\configs"),
    (Join-Path $BuildRoot "bin\configs"),
    (Join-Path $BuildRoot "configs")
)

foreach ($cand in $buildConfigCandidates) {
    if (Test-Path $cand) {
        Write-Host "[CONF] Copie depuis $cand..."
        Copy-Item "$cand\*" $ConfigDir -Recurse -Force
        break
    }
}

$allConfDist = Get-ChildItem `
    -Path @($BuildRoot, (Join-Path $env:CORE_SOURCE "modules")) `
    -Filter "*.conf.dist" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

foreach ($file in $allConfDist) {
    $isModule = ($file.FullName -match "modules|mod[-_]") -and
                ($file.Name -notmatch "^(worldserver|authserver)")

    if ($isModule) {
        Copy-Item $file.FullName (Join-Path $ModulesConfigDir $file.Name) -Force
        Copy-Item $file.FullName (Join-Path $ConfigDir $file.Name) -Force
    } else {
        Copy-Item $file.FullName (Join-Path $ConfigDir $file.Name) -Force
    }
}

Get-ChildItem -Path $ConfigDir -Filter "*.conf.dist" -Recurse -File | ForEach-Object {
    $activePath = $_.FullName -replace "\.dist$", ""
    Copy-Item $_.FullName $activePath -Force
}

Get-ChildItem -Path $ConfigDir -Filter "*.conf.dist" -Recurse -File |
    Remove-Item -Force

Write-Host ""
Write-Host "[OK] Runtime collecté."

Write-Host ""
Write-Host "Contenu racine du runtime :"
Get-ChildItem $Runtime -File | Select-Object Name | Format-Table -AutoSize