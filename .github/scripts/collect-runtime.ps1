param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root = $env:GITHUB_WORKSPACE
$RepackRoot = Join-Path $Root $Variant
$Runtime = Join-Path $RepackRoot "azerothcore"
$BuildRoot = $env:CORE_BUILD
if (-not $BuildRoot) {
    $BuildRoot = Join-Path $env:CORE_SOURCE "build"
}
$Build = Join-Path $BuildRoot "bin\Release"

Write-Host "========================================"
Write-Host " Collecting runtime: $Variant"
Write-Host " Build Root: $BuildRoot"
Write-Host "========================================"

if (-not (Test-Path $Build)) {
    # Check if binaries are located in $BuildRoot\bin or directly in $BuildRoot
    if (Test-Path (Join-Path $BuildRoot "bin")) {
        $Build = Join-Path $BuildRoot "bin"
    } elseif (Test-Path $BuildRoot) {
        $Build = $BuildRoot
    } else {
        throw "Build output not found: $Build"
    }
}

New-Item -ItemType Directory -Path $Runtime -Force | Out-Null

# ------------------------------------------------------------
# Required executables
# ------------------------------------------------------------

$Executables = @(
    "authserver.exe",
    "worldserver.exe",
    "map_extractor.exe",
    "vmap4_extractor.exe",
    "vmap4_assembler.exe",
    "mmaps_generator.exe",
    "mmaps-config.yaml"
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
        throw "Required executable not found: $exe"
    }

    Copy-Item `
        $source.FullName `
        (Join-Path $Runtime $exe) `
        -Force

    Write-Host "[EXE] $exe"
}

# ------------------------------------------------------------
# DLLs
# ------------------------------------------------------------

Get-ChildItem `
    -Path $BuildRoot `
    -Filter "*.dll" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    ForEach-Object {

        Copy-Item `
            $_.FullName `
            (Join-Path $Runtime $_.Name) `
            -Force
    }

# Copy libmysql.dll from MySQL server if not already in runtime
$runtimeMysqlDll = Join-Path $Runtime "libmysql.dll"
if (-not (Test-Path $runtimeMysqlDll)) {
    $mysqlLibDll = Join-Path $RepackRoot "_mysql\server\lib\libmysql.dll"
    if (Test-Path $mysqlLibDll) {
        Copy-Item $mysqlLibDll $runtimeMysqlDll -Force
        Write-Host "[DLL] Copied libmysql.dll"
    }
}

# Copy OpenSSL DLLs if missing
$opensslCandidates = @(
    "C:\Program Files\OpenSSL\bin",
    "C:\Program Files\OpenSSL-Win64\bin",
    "C:\OpenSSL-Win64\bin"
)
foreach ($dir in $opensslCandidates) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Filter "*.dll" -File | ForEach-Object {
            $dest = Join-Path $Runtime $_.Name
            if (-not (Test-Path $dest)) {
                Copy-Item $_.FullName $dest -Force
                Write-Host "[DLL] Copied $($_.Name)"
            }
        }
        break
    }
}

Write-Host "[OK] DLLs copied."

# ------------------------------------------------------------
# Lua scripts
# ------------------------------------------------------------

$LuaCandidates = @(
    (Join-Path $env:CORE_SOURCE "lua_scripts"),
    (Join-Path $env:CORE_SOURCE "modules\mod-ale\lua_scripts")
)

foreach ($lua in $LuaCandidates) {

    if (Test-Path $lua) {

        $destination = Join-Path $Runtime "lua_scripts"

        New-Item `
            -ItemType Directory `
            -Path $destination `
            -Force |
            Out-Null

        Copy-Item `
            "$lua\*" `
            $destination `
            -Recurse `
            -Force
    }
}

# ------------------------------------------------------------
# Configuration files
# ------------------------------------------------------------

$ConfigDir = Join-Path $Runtime "configs"
$ModulesConfigDir = Join-Path $ConfigDir "modules"

New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
New-Item -ItemType Directory -Path $ModulesConfigDir -Force | Out-Null

# 1. Check for build-generated configs directories
$buildConfigCandidates = @(
    (Join-Path $BuildRoot "bin\Release\configs"),
    (Join-Path $BuildRoot "bin\configs"),
    (Join-Path $BuildRoot "configs")
)

foreach ($cand in $buildConfigCandidates) {
    if (Test-Path $cand) {
        Write-Host "[CONF] Copying configs from $cand..."
        Copy-Item "$cand\*" $ConfigDir -Recurse -Force
        break
    }
}

# 2. Collect any *.conf.dist from build and modules directories
$allConfDist = Get-ChildItem `
    -Path @($BuildRoot, (Join-Path $env:CORE_SOURCE "modules")) `
    -Filter "*.conf.dist" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

foreach ($file in $allConfDist) {
    $isModule = ($file.FullName -match "modules|mod[-_]") -and ($file.Name -notmatch "^(worldserver|authserver)")

    if ($isModule) {
        Copy-Item $file.FullName (Join-Path $ModulesConfigDir $file.Name) -Force
        Copy-Item $file.FullName (Join-Path $ConfigDir $file.Name) -Force
    } else {
        Copy-Item $file.FullName (Join-Path $ConfigDir $file.Name) -Force
        Copy-Item $file.FullName (Join-Path $Runtime $file.Name) -Force
    }
}

# 3. Create active .conf files for all .conf.dist in Runtime, configs and modules
Get-ChildItem -Path $Runtime -Filter "*.conf.dist" -Recurse -File | ForEach-Object {
    $activePath = $_.FullName -replace "\.dist$", ""
    Copy-Item $_.FullName $activePath -Force
    Write-Host "[CONF] $($_.Name) -> $([IO.Path]::GetFileName($activePath))"
}

# 4. Ensure main configs exist in both root and configs/
foreach ($mainConf in @("worldserver.conf", "authserver.conf")) {
    $rootConf = Join-Path $Runtime $mainConf
    $cfgConf = Join-Path $ConfigDir $mainConf
    if ((Test-Path $cfgConf) -and (-not (Test-Path $rootConf))) {
        Copy-Item $cfgConf $rootConf -Force
    }
    elseif ((Test-Path $rootConf) -and (-not (Test-Path $cfgConf))) {
        Copy-Item $rootConf $cfgConf -Force
    }
}

Write-Host ""
Write-Host "[OK] Runtime collected."

Write-Host ""
Write-Host "Runtime:"
Get-ChildItem $Runtime -File |
    Select-Object Name |
    Format-Table -AutoSize