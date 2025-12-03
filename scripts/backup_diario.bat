@echo off
REM Sistema de Backup Automatizado PostgreSQL
REM Se ejecuta diariamente a las 2:00 AM

cd /d "C:\xampp3\htdocs\TerrenaLaravel"
php scripts\backup_postgresql.php

REM Salir con el código de error de PHP
exit /b %ERRORLEVEL%