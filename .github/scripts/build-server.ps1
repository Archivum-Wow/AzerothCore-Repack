param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Source = $env:CORE_SOURCE
$Build = Join-Path $Source "build"

Write-Host "========================================"
Write-Host " Building: $Variant"
Write-Host "========================================"

if (Test-Path $Build) {
    Remove-Item $Build -Recurse -Force
}

New-Item -ItemType Directory -Path $Build | Out-Null

Push-Location $Build

try {

    $args = @(
        ".."
        "-G", "Visual Studio 17 2022"
        "-A", "x64"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DBUILD_TOOLS=all"
        "-DLUA_VERSION=luajit"
        "-DMYSQL_ROOT_DIR=$env:MYSQL_ROOT_DIR"
    )

    Write-Host "[CMake] Configuring..."

    & cmake @args

    if ($LASTEXITCODE -ne 0) {
        throw "CMake configuration failed."
    }

    Write-Host ""
    Write-Host "[CMake] Building Release..."

    & cmake --build . --config Release --parallel

    if ($LASTEXITCODE -ne 0) {
        throw "CMake build failed."
    }

    Write-Host ""
    Write-Host "[OK] Build completed."

}
finally {
    Pop-Location
}