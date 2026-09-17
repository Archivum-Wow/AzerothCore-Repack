@echo off
setlocal EnableExtensions

set "SOURCES=%~dp0"
set "ROOT=%SOURCES%.."
set "CURL=%ROOT%\_tools\curl-8.22.0_1-win64-mingw\curl.exe"

set "AC_COMMIT=06234df3d5ab26c93f4f1f06f3edb828b73ecd3c"
set "ALE_COMMIT=bd74eae623ca63154d3eb49e1d187e872ef13370"
set "PB_COMMIT=b6696bdbd3740e575598d167d69f39f68cc0b907"

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
    "https://github.com/mod-playerbots/azerothcore-wotlk/archive/%AC_COMMIT%.zip" ^
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
echo   Downloading mod-playerbots
echo ========================================
echo.

"%CURL%" -L --fail ^
    "https://github.com/mod-playerbots/mod-playerbots/archive/%PB_COMMIT%.zip" ^
    -o "%SOURCES%mod-playerbots.zip"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to download mod-playerbots.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Downloads completed
echo ========================================
echo.
echo [OK] AzerothCore     : %SOURCES%azerothcore-wotlk.zip
echo [OK] mod-ale         : %SOURCES%mod-ale.zip
echo [OK] mod-playerbots  : %SOURCES%mod-playerbots.zip
echo.

endlocal
pause