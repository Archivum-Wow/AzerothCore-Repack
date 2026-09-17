param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Root = $env:GITHUB_WORKSPACE
$RepackRoot = Join-Path $Root $Variant
$Runtime = Join-Path $RepackRoot "azerothcore"
$Build = Join-Path $env:CORE_SOURCE "build\bin\Release"

Write-Host "========================================"
Write-Host " Collecting runtime: $Variant"
Write-Host "========================================"

if (-not (Test-Path $Build)) {
    throw "Build output not found: $Build"
}

New-Item -ItemType Directory -Path $Runtime -Force | Out-Null

# ------------------------------------------------------------
# Required executables
# ------------------------------------------------------------

$Executables = @(
    "authserver.exe",
    "worldserver.exe",
    "mapextractor.exe",
    "vmap4extractor.exe",
    "vmap4assembler.exe",
    "mmaps_generator.exe"
)

foreach ($exe in $Executables) {

    $source = Get-ChildItem `
        -Path $env:CORE_SOURCE\build `
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
    -Path $env:CORE_SOURCE\build `
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

Get-ChildItem `
    -Path $env:CORE_SOURCE\build `
    -Filter "*.conf.dist" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    ForEach-Object {

        $dist = Join-Path $Runtime $_.Name

        Copy-Item `
            $_.FullName `
            $dist `
            -Force

        $activeName = $_.Name -replace "\.dist$", ""
        $active = Join-Path $Runtime $activeName

        Copy-Item `
            $_.FullName `
            $active `
            -Force

        Write-Host "[CONF] $activeName"
    }

Write-Host ""
Write-Host "[OK] Runtime collected."

Write-Host ""
Write-Host "Runtime:"
Get-ChildItem $Runtime -File |
    Select-Object Name |
    Format-Table -AutoSize