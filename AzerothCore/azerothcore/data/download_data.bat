@echo off
setlocal EnableExtensions

set "ROOT=%~dp0..\.."
set "DATA=%~dp0"
set "CURL=%ROOT%\_tools\curl-8.22.0_1-win64-mingw\curl.exe"
set "ZIP=%DATA%Data.zip"
set "URL=https://github.com/wowgaming/client-data/releases/download/v20.0/Data.zip"

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
echo   Downloading World of Warcraft Data
echo ========================================
echo.

"%CURL%" -L --fail ^
    "%URL%" ^
    -o "%ZIP%"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to download Data.zip.
    pause
    exit /b 1
)

echo.
echo [OK] Download completed.
echo.
echo [INFO] Extracting Data.zip...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%DATA%' -Force"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to extract Data.zip.
    pause
    exit /b 1
)

del /Q "%ZIP%"

echo.
echo [OK] Client data installed successfully.
echo.

endlocal
pause
