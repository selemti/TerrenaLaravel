@echo off
echo Iniciando correccion de problemas de codificacion...

REM Renombrando archivo con tilde en ANALISIS
if exist "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\AN*.md" (
    ren "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\ANÁLISIS COMO EXPERTO FULL STACK, BD, POSERP Y UIUX.md" "ANALISIS COMO EXPERTO FULL STACK, BD, POSERP Y UIUX.md" 2>nul
    if errorlevel 1 (
        echo Error al renombrar el archivo de ANALISIS
    ) else (
        echo Archivo de ANALISIS renombrado correctamente
    )
)

REM Renombrando archivo con tilde en RADIOGRAFIA
if exist "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\RA*.md" (
    ren "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\RADIOGRAFÍA COMPLETA DEL PROYECTO .md" "RADIOGRAFIA COMPLETA DEL PROYECTO .md" 2>nul
    if errorlevel 1 (
        echo Error al renombrar el archivo de RADIOGRAFIA
    ) else (
        echo Archivo de RADIOGRAFIA renombrado correctamente
    )
)

REM Renombrando archivos con tilde en Status
if exist "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\Status\*.*" (
    ren "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\Status\STATUS_Catálogos.md" "STATUS_Catalogos.md" 2>nul
    ren "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\Status\STATUS_Producción.md" "STATUS_Produccion.md" 2>nul
    echo Archivos de Status renombrados correctamente
)

REM Renombrando archivos con tilde en Definiciones
if exist "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\Definiciones\*.*" (
    ren "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\Definiciones\Catálogos.md" "Catalogos.md" 2>nul
    ren "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\Definiciones\Producción.md" "Produccion.md" 2>nul
    echo Archivos de Definiciones renombrados correctamente
)

echo.
echo Correccion de codificacion completada!
pause