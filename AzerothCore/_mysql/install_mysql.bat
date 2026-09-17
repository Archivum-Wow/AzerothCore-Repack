@echo off
setlocal EnableExtensions

set "MYSQL_ROOT=%~dp0"
set "ROOT=%MYSQL_ROOT%.."
set "TOOLS=%ROOT%\_tools"

set "CURL=%TOOLS%\curl-8.22.0_1-win64-mingw\curl.exe"

set "MYSQL_VERSION=8.4.6"
set "MYSQL_URL=https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-%MYSQL_VERSION%-winx64.zip"

set "MYSQL_SERVER=%MYSQL_ROOT%server"
set "MYSQL_ARCHIVE=%MYSQL_ROOT%mysql.zip"
set "MYSQL_TEMP=%MYSQL_ROOT%_temp"

echo.
echo ========================================
echo       MySQL Portable Installer
echo ========================================
echo.

if not exist "%CURL%" (
    echo [ERROR] curl.exe not found:
    echo %CURL%
    echo.
    pause
    exit /b 1
)

if exist "%MYSQL_SERVER%\bin\mysqld.exe" (
    echo [MySQL] MySQL is already installed.
    echo.
    echo Location:
    echo %MYSQL_SERVER%
    echo.
    pause
    exit /b 0
)

echo [MySQL] Version : %MYSQL_VERSION%
echo.

echo [MySQL] Downloading...
echo.

"%CURL%" -L --fail ^
    "%MYSQL_URL%" ^
    -o "%MYSQL_ARCHIVE%"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to download MySQL.
    echo.
    pause
    exit /b 1
)

echo.
echo [MySQL] Download completed.
echo.

if exist "%MYSQL_TEMP%" (
    rmdir /S /Q "%MYSQL_TEMP%"
)

mkdir "%MYSQL_TEMP%"

echo [MySQL] Extracting...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Expand-Archive -LiteralPath '%MYSQL_ARCHIVE%' -DestinationPath '%MYSQL_TEMP%' -Force"

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to extract MySQL.
    echo.
    rmdir /S /Q "%MYSQL_TEMP%"
    del /Q "%MYSQL_ARCHIVE%"
    pause
    exit /b 1
)

echo [MySQL] Installing server files...
echo.

if exist "%MYSQL_SERVER%" (
    rmdir /S /Q "%MYSQL_SERVER%"
)

mkdir "%MYSQL_SERVER%"

rem MySQL ZIP contains a versioned root directory.
for /D %%D in ("%MYSQL_TEMP%\mysql-*") do (
    xcopy "%%D\*" "%MYSQL_SERVER%\" /E /I /H /Y >nul
)

if not exist "%MYSQL_SERVER%\bin\mysqld.exe" (
    echo.
    echo [ERROR] mysqld.exe was not found after extraction.
    echo.
    echo Expected:
    echo %MYSQL_SERVER%\bin\mysqld.exe
    echo.
    rmdir /S /Q "%MYSQL_TEMP%"
    del /Q "%MYSQL_ARCHIVE%"
    pause
    exit /b 1
)

echo [MySQL] Creating directories...
echo.

if not exist "%MYSQL_ROOT%data" (
    mkdir "%MYSQL_ROOT%data"
)

if not exist "%MYSQL_ROOT%data\logs" (
    mkdir "%MYSQL_ROOT%data\logs"
)

if not exist "%MYSQL_ROOT%data\conf" (
    mkdir "%MYSQL_ROOT%data\conf"
)

echo [MySQL] Cleaning temporary files...
echo.

rmdir /S /Q "%MYSQL_TEMP%"
del /Q "%MYSQL_ARCHIVE%"

echo.
echo ========================================
echo MySQL installed successfully.
echo.
echo Server:
echo %MYSQL_SERVER%
echo.
echo Executable:
echo %MYSQL_SERVER%\bin\mysqld.exe
echo ========================================
echo.

endlocal
pause