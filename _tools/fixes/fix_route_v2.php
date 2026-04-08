<?php
// Script para agregar ruta v2.0 al archivo routes/web.php
require_once 'vendor/autoload.php';

$file = 'routes/web.php';
$content = file_get_contents($file);

// Encontrar la línea donde insertar la ruta
$pattern = '/Route::get\(\'\/mods\/export\/pdf\'/m';
$replacement = "Route::get('/mods/export/pdf', [SalesModsController::class, 'exportPdf'])->name('reports.sales.mods.export.pdf');\n\n                // Reporte mejorado v2.0\n                Route::get('/mods/v2', [SalesModsController::class, 'showV2'])->name('reports.sales.mods.v2');";

$content = preg_replace($pattern, $replacement, $content);

// Escribir el archivo modificado
file_put_contents($file, $content);

echo "✅ Ruta agregada correctamente\n";
echo "📁 Archivo modificado: {$file}\n";
echo "🌐 Nueva URL: http://localhost/TerrenaLaravel/reports/sales/mods/v2\n";