@echo off
REM Script para analizar discrepancias en ventas
REM Uso: analizar_ventas.bat [fecha_inicio] [fecha_fin]
REM Ejemplo: analizar_ventas.bat 2025-10-01 2025-10-31

echo ========================================
echo ANÁLISIS DE DISCREPANCIAS EN VENTAS
echo ========================================
echo.

if "%1"=="" (
    echo Uso: analizar_ventas.bat [fecha_inicio] [fecha_fin]
    echo Ejemplo: analizar_ventas.bat 2025-10-01 2025-10-31
    echo.
    echo Ejecutando análisis para Agosto-Octubre 2025...
    php scripts\analyze_sales_discrepancies.php
) else (
    echo Analizando período: %1 al %2
    echo.
    php scripts\analyze_sales_discrepancies.php %1 %2
)

echo.
echo ========================================
echo Análisis completado
echo Revisa el archivo generado en storage\logs\
echo ========================================
pause
