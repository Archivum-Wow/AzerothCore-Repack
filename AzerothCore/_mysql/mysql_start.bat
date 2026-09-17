@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "MYSQL_SERVER=%ROOT%server"
set "MYSQL_DATA=%ROOT%data\data"
set "MYSQL_LOGS=%ROOT%data\logs"

set "MYSQLD=%MYSQL_SERVER%\bin\mysqld.exe"
set "MYSQL=%MYSQL_SERVER%\bin\mysql.exe"

set "PORT=3306"

echo.
echo ========================================
echo       AzerothCore MySQL Server
echo ========================================
echo.

if not exist "%MYSQLD%" (
    echo [ERROR] mysqld.exe not found:
    echo %MYSQLD%
    echo.
    pause
    exit /b 1
)

if not exist "%MYSQL_DATA%\ibdata1" (
    echo [MySQL] Data directory not initialized.
    echo [MySQL] Initializing MySQL...
    echo.

    if not exist "%ROOT%data" (
        mkdir "%ROOT%data"
    )

    "%MYSQLD%" ^
        --no-defaults ^
        --initialize-insecure ^
        --basedir="%MYSQL_SERVER%" ^
        --datadir="%MYSQL_DATA%"

    if errorlevel 1 (
        echo.
        echo [ERROR] MySQL initialization failed.
        echo.
        echo Check the MySQL output above for details.
        echo.
        pause
        exit /b 1
    )

    echo.
    echo [MySQL] Initialization completed.
    echo.
)

if not exist "%MYSQL_DATA%\ibdata1" (
    echo.
    echo [ERROR] MySQL data directory is invalid.
    echo.
    echo Expected:
    echo %MYSQL_DATA%\ibdata1
    echo.
    pause
    exit /b 1
)

if not exist "%MYSQL_LOGS%" (
    mkdir "%MYSQL_LOGS%"
)

echo [MySQL] Starting server...

start "" /B "%MYSQLD%" ^
    --no-defaults ^
    --basedir="%MYSQL_SERVER%" ^
    --datadir="%MYSQL_DATA%" ^
    --port=%PORT% ^
    --bind-address=127.0.0.1 ^
    --log-error="%MYSQL_LOGS%\mysql.err"

echo [MySQL] Waiting for server...

set "READY=0"

for /L %%i in (1,1,30) do (
    "%MYSQL%" -u root -e "SELECT 1;" >nul 2>&1

    if not errorlevel 1 (
        set "READY=1"
        goto MYSQL_READY
    )

    timeout /t 1 /nobreak >nul
)

:MYSQL_READY

if "%READY%"=="0" (
    echo.
    echo [ERROR] MySQL failed to start.
    echo.
    echo Check:
    echo %MYSQL_LOGS%\mysql.err
    echo.
    pause
    exit /b 1
)

echo [MySQL] Server ready.
echo.

echo [MySQL] Configuring AzerothCore user...

"%MYSQL%" -u root -e "CREATE USER IF NOT EXISTS 'acore'@'localhost' IDENTIFIED BY 'acore';"
"%MYSQL%" -u root -e "CREATE USER IF NOT EXISTS 'acore'@'127.0.0.1' IDENTIFIED BY 'acore';"

"%MYSQL%" -u root -e "ALTER USER 'acore'@'localhost' IDENTIFIED BY 'acore';"
"%MYSQL%" -u root -e "ALTER USER 'acore'@'127.0.0.1' IDENTIFIED BY 'acore';"

"%MYSQL%" -u root -e "GRANT ALL PRIVILEGES ON acore_world.* TO 'acore'@'localhost';"
"%MYSQL%" -u root -e "GRANT ALL PRIVILEGES ON acore_characters.* TO 'acore'@'localhost';"
"%MYSQL%" -u root -e "GRANT ALL PRIVILEGES ON acore_auth.* TO 'acore'@'localhost';"
"%MYSQL%" -u root -e "GRANT ALL PRIVILEGES ON acore_ale.* TO 'acore'@'localhost';"

"%MYSQL%" -u root -e "GRANT ALL PRIVILEGES ON acore_world.* TO 'acore'@'127.0.0.1';"
"%MYSQL%" -u root -e "GRANT ALL PRIVILEGES ON acore_characters.* TO 'acore'@'127.0.0.1';"
"%MYSQL%" -u root -e "GRANT ALL PRIVILEGES ON acore_auth.* TO 'acore'@'127.0.0.1';"
"%MYSQL%" -u root -e "GRANT ALL PRIVILEGES ON acore_ale.* TO 'acore'@'127.0.0.1';"

echo.
echo ========================================
echo MySQL is ready.
echo.
echo Host     : 127.0.0.1
echo Port     : %PORT%
echo User     : acore
echo Password : acore
echo.
echo Databases:
echo   acore_world
echo   acore_characters
echo   acore_auth
echo   acore_ale
echo ========================================
echo.

endlocal