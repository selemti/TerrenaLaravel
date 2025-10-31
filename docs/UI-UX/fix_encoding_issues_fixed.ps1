# Script para corregir problemas de codificacion renombrando archivos con caracteres especiales

Write-Host "Iniciando correccion de problemas de codificacion..." -ForegroundColor Green

# Funcion para renombrar archivos con caracteres especiales
function Rename-WithEncodingFix {
    param(
        [string]$Path,
        [string]$NewName
    )
    
    try {
        Rename-Item -Path $Path -NewName $NewName -ErrorAction Stop
        Write-Host "Renombrado: $($Path) -> $($NewName)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error al renombrar: $($Path) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Corrigiendo archivos en la carpeta principal UI-UX
Write-Host "`nCorrigiendo archivos en carpeta principal..." -ForegroundColor Yellow

# Archivo con tilde en "ANALISIS"
$analisisFile = "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\ANALISIS COMO EXPERTO FULL STACK, BD, POSERP Y UIUX.md"
if (Test-Path $analisisFile) {
    Rename-WithEncodingFix -Path $analisisFile -NewName "ANALISIS COMO EXPERTO FULL STACK, BD, POSERP Y UIUX.md"
}

# Archivo con tilde en "RADIOGRAFIA"
$radiografiaFile = "C:\xampp3\htdocs\TerrenaLaravel\docs\UI-UX\RADIOGRAFIA COMPLETA DEL PROYECTO .md"
if (Test-Path $radiografiaFile) {
    Rename-WithEncodingFix -Path $radiografiaFile -NewName "RADIOGRAFIA COMPLETA DEL PROYECTO .md"
}

Write-Host "`nCorreccion de codificacion completada!" -ForegroundColor Green
Write-Host "Todos los archivos con caracteres especiales han sido renombrados." -ForegroundColor Cyan