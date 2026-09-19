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

if (-not $Source) {
    throw "La variable d'environnement CORE_SOURCE n'est pas définie."
}

Write-Host "========================================"
Write-Host " Compilation : $Variant"
Write-Host " Source      : $Source"
Write-Host " Build       : $Build"
Write-Host "========================================"

if (Test-Path $Build) {
    Write-Host "[Clean] Suppression du build précédent..."
    Remove-Item $Build -Recurse -Force
}

New-Item -ItemType Directory -Path $Build | Out-Null

$rcWorkaround = @'
<Project>
  <Target Name="AcTrimResourceCompileIncludes" BeforeTargets="ResourceCompile">
    <ItemGroup>
      <ResourceCompile>
        <AdditionalIncludeDirectories>%(RootDir)%(Directory);$(MSBuildThisFileDirectory)</AdditionalIncludeDirectories>
      </ResourceCompile>
    </ItemGroup>
  </Target>
</Project>
'@

Set-Content `
    -Path (Join-Path $Build "Directory.Build.targets") `
    -Value $rcWorkaround `
    -Encoding UTF8

Write-Host "[RC] Includes du compilateur de ressources restreints (Directory.Build.targets)."

Push-Location $Build

try {

    $cmakeArgs = @(
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

    if ($env:CMAKE_C_COMPILER_LAUNCHER) {
        $cmakeArgs += "-DCMAKE_C_COMPILER_LAUNCHER=$env:CMAKE_C_COMPILER_LAUNCHER"
    }
    if ($env:CMAKE_CXX_COMPILER_LAUNCHER) {
        $cmakeArgs += "-DCMAKE_CXX_COMPILER_LAUNCHER=$env:CMAKE_CXX_COMPILER_LAUNCHER"
    }

    if ($env:BOOST_ROOT) {
        $boostPath = $env:BOOST_ROOT.Replace('\', '/').TrimEnd('/')
        $cmakeArgs += "-DBOOST_ROOT=$boostPath"
        $cmakeArgs += "-DBoost_NO_BOOST_CMAKE=ON"
    }

    Write-Host ""
    Write-Host "[CMake] Configuration..."

    & cmake @cmakeArgs

    if ($LASTEXITCODE -ne 0) {
        throw "La configuration CMake a échoué."
    }

    Write-Host ""
    Write-Host "[CMake] Compilation Release en parallèle..."

    & cmake --build . --config Release --parallel

    if ($LASTEXITCODE -ne 0) {
        throw "La compilation CMake a échoué."
    }

    Write-Host ""
    Write-Host "[OK] Compilation terminée."
}
finally {
    Pop-Location
}