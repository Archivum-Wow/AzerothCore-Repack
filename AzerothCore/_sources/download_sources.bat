@echo off
setlocal EnableExtensions

set "SOURCES=%~dp0"
set "ROOT=%SOURCES%.."
set "CURL=%ROOT%\_tools\curl-8.22.0_1-win64-mingw\curl.exe"

set "AC_COMMIT=2fb90e3b1f6d3cea2a552f12a69aa5e24d195061"
set "ALE_COMMIT=bd74eae623ca63154d3eb49e1d187e872ef13370"

if not exist "%CURL%" (
    echo.
    echo [ERROR] curl.exe not found:
    echo %CURL%
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Downloading AzerothCore
echo ========================================
echo.

"%CURL%" -L --fail ^
    "https://github.com/azerothcore/azerothcore-wotlk/archive/%AC_COMMIT%.zip" ^
    -o "%SOURCES%azerothcore-wotlk.zip"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to download AzerothCore.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Downloading mod-ale
echo ========================================
echo.

"%CURL%" -L --fail ^
    "https://github.com/azerothcore/mod-ale/archive/%ALE_COMMIT%.zip" ^
    -o "%SOURCES%mod-ale.zip"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to download mod-ale.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Downloads completed
echo ========================================
echo.
echo [OK] AzerothCore : %SOURCES%azerothcore-wotlk.zip
echo [OK] mod-ale     : %SOURCES%mod-ale.zip
echo.

endlocal
pause