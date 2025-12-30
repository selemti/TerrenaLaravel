@echo off
REM Script de Backup Automático para PostgreSQL
REM Este script crea un respaldo diario de la base de datos con timestamp

echo Iniciando backup de la base de datos... %date% %time%

REM Configura la ruta de PostgreSQL y variables
set PG_PATH="C:\Program Files\PostgreSQL\13\bin"
set DB_HOST=localhost
set DB_PORT=5433
set DB_NAME=pos
set DB_USER=postgres
set DB_PASS=T3rr3n4#p0s
set BACKUP_DIR="C:\xampp3\htdocs\TerrenaLaravel\backups"
set DATESTAMP=%date:~0,2%-%date:~3,2%-%date:~6,4%_%time:~0,2%%time:~3,2%%time:~6,2%

REM Crea directorio de backups si no existe
if not exist %BACKUP_DIR% mkdir %BACKUP_DIR%

REM Configura contraseña para pg_dump
set PGPASSWORD=%DB_PASS%

REM Realiza el backup con pg_dump
%PG_PATH%\pg_dump.exe -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -F c -b -v -f "%BACKUP_DIR%\backup_%DATESTAMP%.sql" --schema=public --schema=selemti

REM Verifica si el backup fue exitoso
if %ERRORLEVEL% EQU 0 (
    echo Backup completado exitosamente: backup_%DATESTAMP%.sql
    REM Mantener solo los últimos 7 días de backups
    forfiles /p %BACKUP_DIR% /m backup_*.sql /d -7 /c "cmd /c del @path" 2>nul
) else (
    echo Error en el backup
    exit /b 1
)

echo Backup diario completado.