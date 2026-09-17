@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul
title AzerothCore Repack

set "ROOT=%~dp0"

set "MYSQL_START=%ROOT%_mysql\mysql_start.bat"
set "MYSQL_INSTALL=%ROOT%_mysql\install_mysql.bat"

set "SOURCES_DOWNLOAD=%ROOT%_sources\download_sources.bat"
set "DATA_DOWNLOAD=%ROOT%data\download_data.bat"

set "WORLDSERVER=%ROOT%azerothcore\worldserver.exe"
set "AUTHSERVER=%ROOT%azerothcore\authserver.exe"

set "MYSQL_PORT=3306"
set "WORLD_PORT=8085"


:MENU
cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║                 A Z E R O T H C O R E                        ║
echo  ║                         R E P A C K                          ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo       1.  Installations
echo       2.  Démarrer le serveur AzerothCore
echo       3.  Quitter
echo.
echo  ──────────────────────────────────────────────────────────────
echo.

set /p "CHOICE=       Votre choix : "

if "%CHOICE%"=="1" goto INSTALL
if "%CHOICE%"=="2" goto START_SERVER
if "%CHOICE%"=="3" goto EXIT

goto MENU


:: ================================================================
:: INSTALLATIONS
:: ================================================================

:INSTALL
cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║                     I N S T A L L A T I O N S                ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo       1.  Installation de MySQL
echo       2.  Téléchargement des sources AzerothCore
echo       3.  Téléchargement des Data AzerothCore
echo       4.  Retour
echo.
echo  ──────────────────────────────────────────────────────────────
echo.

set /p "CHOICE=       Votre choix : "

if "%CHOICE%"=="1" goto INSTALL_MYSQL
if "%CHOICE%"=="2" goto DOWNLOAD_SOURCES
if "%CHOICE%"=="3" goto DOWNLOAD_DATA
if "%CHOICE%"=="4" goto MENU

goto INSTALL


:: ================================================================
:: INSTALLATION MYSQL
:: ================================================================

:INSTALL_MYSQL
cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║                   I N S T A L L A T I O N                    ║
echo  ║                         M Y S Q L                             ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.

if not exist "%MYSQL_INSTALL%" (
    echo  [ERREUR] Script introuvable :
    echo  %MYSQL_INSTALL%
    echo.
    pause
    goto INSTALL
)

echo  Lancement de l'installation MySQL...
echo.

start "AzerothCore - Installation MySQL" cmd /k ^
    call "%MYSQL_INSTALL%"

echo  [OK] Installation lancée dans un nouveau terminal.
echo.
pause
goto INSTALL


:: ================================================================
:: TELECHARGEMENT SOURCES
:: ================================================================

:DOWNLOAD_SOURCES
cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║                  S O U R C E S   A Z E R O T H C O R E       ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.

if not exist "%SOURCES_DOWNLOAD%" (
    echo  [ERREUR] Script introuvable :
    echo  %SOURCES_DOWNLOAD%
    echo.
    pause
    goto INSTALL
)

echo  Lancement du téléchargement des sources...
echo.

start "AzerothCore - Sources" cmd /k ^
    call "%SOURCES_DOWNLOAD%"

echo  [OK] Téléchargement lancé dans un nouveau terminal.
echo.
pause
goto INSTALL


:: ================================================================
:: TELECHARGEMENT DATA
:: ================================================================

:DOWNLOAD_DATA
cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║                    D A T A   A Z E R O T H                   ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.

if not exist "%DATA_DOWNLOAD%" (
    echo  [ERREUR] Script introuvable :
    echo  %DATA_DOWNLOAD%
    echo.
    pause
    goto INSTALL
)

echo  Lancement du téléchargement des Data...
echo.

start "AzerothCore - Data" cmd /k ^
    call "%DATA_DOWNLOAD%"

echo  [OK] Téléchargement lancé dans un nouveau terminal.
echo.
pause
goto INSTALL


:: ================================================================
:: DEMARRAGE DU SERVEUR
:: ================================================================

:START_SERVER
cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║              D É M A R R A G E   D U   S E R V E U R        ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.

:: ------------------------------------------------
:: Vérification des fichiers
:: ------------------------------------------------

if not exist "%MYSQL_START%" (
    echo  [ERREUR] mysql_start.bat est introuvable.
    echo.
    echo  %MYSQL_START%
    echo.
    pause
    goto MENU
)

if not exist "%WORLDSERVER%" (
    echo  [ERREUR] worldserver.exe est introuvable.
    echo.
    echo  %WORLDSERVER%
    echo.
    pause
    goto MENU
)

if not exist "%AUTHSERVER%" (
    echo  [ERREUR] authserver.exe est introuvable.
    echo.
    echo  %AUTHSERVER%
    echo.
    pause
    goto MENU
)


:: ================================================================
:: MYSQL
:: ================================================================

echo.
echo  [1/3] Démarrage de MySQL...
echo.

start "AzerothCore - MySQL" cmd /k ^
    call "%MYSQL_START%"

echo  [OK] MySQL lancé.
echo.
echo  [ATTENTE] Vérification du port MySQL (%MYSQL_PORT%)...
echo.

call :WAIT_FOR_PORT %MYSQL_PORT% "MySQL"

if errorlevel 1 (
    echo.
    echo  [ERREUR] MySQL ne semble pas avoir démarré correctement.
    echo.
    pause
    goto MENU
)

echo.
echo  [OK] MySQL est prêt.
echo.


:: ================================================================
:: WORLDSERVER
:: ================================================================

echo  [2/3] Démarrage de Worldserver...
echo.

start "AzerothCore - Worldserver" cmd /k ^
    "%WORLDSERVER%"

echo  [OK] Worldserver lancé.
echo.
echo  [ATTENTE] Vérification du port Worldserver (%WORLD_PORT%)...
echo.

call :WAIT_FOR_PORT %WORLD_PORT% "Worldserver"

if errorlevel 1 (
    echo.
    echo  [ERREUR] Worldserver ne semble pas avoir démarré correctement.
    echo.
    echo  Vérifiez le terminal Worldserver.
    echo.
    pause
    goto MENU
)

echo.
echo  [OK] Worldserver est prêt.
echo.


:: ================================================================
:: AUTHSERVER
:: ================================================================

echo  [3/3] Démarrage de Authserver...
echo.

start "AzerothCore - Authserver" cmd /k ^
    "%AUTHSERVER%"

echo  [OK] Authserver lancé.
echo.

echo  ──────────────────────────────────────────────────────────────
echo.
echo       Le serveur AzerothCore est maintenant démarré.
echo.
echo       MySQL       : 127.0.0.1:%MYSQL_PORT%
echo       Worldserver : 127.0.0.1:%WORLD_PORT%
echo       Authserver  : démarré
echo.
echo  ──────────────────────────────────────────────────────────────
echo.

pause
goto MENU


:: ================================================================
:: ATTENDRE UN PORT TCP
:: ================================================================

:WAIT_FOR_PORT

set "WAIT_PORT=%~1"
set "WAIT_NAME=%~2"
set "WAIT_COUNT=0"

:WAIT_LOOP

set /a WAIT_COUNT+=1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$client = New-Object System.Net.Sockets.TcpClient; try { $client.Connect('127.0.0.1',%WAIT_PORT%); $client.Close(); exit 0 } catch { exit 1 }" ^
    >nul 2>&1

if not errorlevel 1 (
    exit /b 0
)

if %WAIT_COUNT% GEQ 60 (
    exit /b 1
)

<nul set /p "=  [ATTENTE] %WAIT_NAME% démarre... %WAIT_COUNT%/60 secondes   "
echo.

timeout /t 1 /nobreak >nul

goto WAIT_LOOP


:: ================================================================
:: QUITTER
:: ================================================================

:EXIT

cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║                  AzerothCore Repack                          ║
echo  ║                                                              ║
echo  ║                       Fermeture...                           ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.

endlocal
exit /b 0