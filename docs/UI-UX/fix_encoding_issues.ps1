# Script para corregir problemas de codificación renombrando archivos con caracteres especiales

Write-Host "Iniciando corrección de problemas de codificación..." -ForegroundColor Green

# Función para renombrar archivos con caracteres especiales
function Rename-WithEncodingFix {
    param(
        [string]$Path,
        [string]$NewName
    )
    
    try {
        Rename-Item -Path $Path -NewName $NewName -ErrorAction Stop
        Write-Host "✓ Renombrado: $($Path) -> $($NewName)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error al renombrar: $($Path) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Corrigiendo archivos en la carpeta principal UI-UX
Write-Host "`nCorrigiendo archivos en carpeta principal..." -ForegroundColor Yellow

# Archivo con tilde en "ANÁLISIS"
$analisisFile = "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\ANÁLISIS COMO EXPERTO FULL STACK, BD, POSERP Y UIUX.md"
if (Test-Path $analisisFile) {
    Rename-WithEncodingFix -Path $analisisFile -NewName "ANALISIS COMO EXPERTO FULL STACK, BD, POSERP Y UIUX.md"
}

# Archivo con tilde en "RADIOGRAFÍA"
$radiografiaFile = "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\RADIOGRAFÍA COMPLETA DEL PROYECTO .md"
if (Test-Path $radiografiaFile) {
    Rename-WithEncodingFix -Path $radiografiaFile -NewName "RADIOGRAFIA COMPLETA DEL PROYECTO .md"
}

# Corrigiendo archivos en la carpeta Status
Write-Host "`nCorrigiendo archivos en carpeta Status..." -ForegroundColor Yellow

$statusFiles = @(
    @{Old="STATUS_Catálogos.md"; New="STATUS_Catalogos.md"},
    @{Old="STATUS_Producción.md"; New="STATUS_Produccion.md"}
)

foreach ($file in $statusFiles) {
    $filePath = "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\Status\$($file.Old)"
    if (Test-Path $filePath) {
        Rename-WithEncodingFix -Path $filePath -NewName $file.New
    }
}

# Corrigiendo archivos en la carpeta Definiciones
Write-Host "`nCorrigiendo archivos en carpeta Definiciones..." -ForegroundColor Yellow

$defFiles = @(
    @{Old="Catálogos.md"; New="Catalogos.md"},
    @{Old="Producción.md"; New="Produccion.md"}
)

foreach ($file in $defFiles) {
    $filePath = "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\Definiciones\$($file.Old)"
    if (Test-Path $filePath) {
        Rename-WithEncodingFix -Path $filePath -NewName $file.New
    }
}

Write-Host "`n¡Corrección de codificación completada!" -ForegroundColor Green
Write-Host "Todos los archivos con caracteres especiales han sido renombrados." -ForegroundColor Cyan