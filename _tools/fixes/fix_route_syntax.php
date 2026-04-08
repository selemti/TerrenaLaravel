<?php
// Script para corregir el error de sintaxis en routes/web.php
require_once 'vendor/autoload.php';

$file = 'routes/web.php';
$content = file_get_contents($file);

// Corregir la línea malformada
$pattern = '/Route::get\(\'\/mods\/v2\', \[SalesModsController::class, \'showV2\]\)->name\(\'reports\.sales\.mods\.v2\'\)\;,\s*\[SalesModsController::class,\s*\'exportPdf\'\]\)->name\(\'reports\.sales\.mods\.export\.pdf\'\);/m';
$replacement = "Route::get('/mods/v2', [SalesModsController::class, 'showV2'])->name('reports.sales.mods.v2');";

$content = preg_replace($pattern, $replacement, $content);

// Escribir el archivo corregido
file_put_contents($file, $content);

echo "✅ Ruta corregida correctamente\n";
echo "📁 Archivo modificado: {$file}\n";