param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AzerothCore", "PlayerBots")]
    [string]$Variant
)

$ErrorActionPreference = "Stop"

$Source = $env:CORE_SOURCE
$Build = $env:CORE_BUILD
if (-not $Build) {
    $Build = if ($env:GITHUB_ACTIONS) { "C:\ac_build" } else { Join-Path $Source "build" }
}

Write-Host "========================================"
Write-Host " Building: $Variant"
Write-Host " Source:   $Source"
Write-Host " Build:    $Build"
Write-Host "========================================"

if (Test-Path $Build) {
    Remove-Item $Build -Recurse -Force
}

New-Item -ItemType Directory -Path $Build | Out-Null

Push-Location $Build

try {

    $args = @(
        "-S", $Source
        "-B", "."
        "-G", "Visual Studio 17 2022"
        "-A", "x64"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DAPPS_BUILD=all"
        "-DTOOLS_BUILD=all"
        "-DLUA_VERSION=luajit"
        "-DMYSQL_ROOT_DIR=$env:MYSQL_ROOT_DIR"
    )

    if ($env:BOOST_ROOT) {
        $args += "-DBOOST_ROOT=$($env:BOOST_ROOT.Replace('\', '/').TrimEnd('/'))"
        $args += "-DBoost_NO_BOOST_CMAKE=ON"
    }

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