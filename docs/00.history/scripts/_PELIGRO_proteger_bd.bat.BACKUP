@echo off
REM ============================================================================
REM SCRIPT DE EMERGENCIA - PREVENIR BORRADO DE BASE DE DATOS
REM ============================================================================
REM Este script debe ejecutarse ANTES de cualquier otra operación
REM ============================================================================

echo.
echo ========================================================================
echo   ADVERTENCIA: PROTECCION DE BASE DE DATOS ACTIVADA
echo ========================================================================
echo.
echo Este script previene la ejecucion accidental de comandos peligrosos:
echo   - php artisan migrate:fresh
echo   - php artisan migrate:reset
echo   - php artisan migrate:rollback --step=999
echo   - php artisan db:wipe
echo.
echo Presiona Ctrl+C para CANCELAR cualquier operacion sospechosa
echo.
pause

REM Crear backup de emergencia ANTES de cualquier operacion
set TIMESTAMP=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_FILE=backup_emergencia_%TIMESTAMP%.sql

echo.
echo Creando backup de emergencia...
C:\xampp3\pgsql\bin\pg_dump.exe -h 127.0.0.1 -p 5433 -U postgres -d pos -F c -f "%~dp0%BACKUP_FILE%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [OK] Backup creado: %BACKUP_FILE%
    echo.
) else (
    echo.
    echo [ERROR] No se pudo crear el backup!
    echo ABORTANDO OPERACION
    pause
    exit /b 1
)

REM Verificar estado actual
echo Verificando estado de la base de datos...
cd /d C:\xampp3\htdocs\TerrenaLaravel
php artisan db:show | findstr "Tables"

echo.
echo ========================================================================
echo Si ves solo 23 tablas, LA BASE DE DATOS ESTA VACIA!
echo ========================================================================
echo.
echo Opciones:
echo   1. Presiona ENTER para continuar (peligroso)
echo   2. Presiona Ctrl+C para CANCELAR
echo.
pause

echo.
echo CONTINUANDO... (Dios nos ayude)
echo.
