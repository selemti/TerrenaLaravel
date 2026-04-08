<?php
// Corregir el error de sintaxis en routes/web.php
$file = 'routes/web.php';
$content = file_get_contents($file);

// Encontrar y reemplazar la línea malformada
$content = str_replace(
    'Route::get(\'/mods/v2\', [SalesModsController::class, \'showV2\'])->name(\'reports.sales.mods.v2\');, [SalesModsController::class, \'exportPdf\'])->name(\'reports.sales.mods.export.pdf\');',
    'Route::get(\'/mods/v2\', [SalesModsController::class, \'showV2\'])->name(\'reports.sales.mods.v2\');',
    $content
);

// Escribir el archivo corregido
file_put_contents($file, $content);

echo "✅ Error de sintaxis corregido\n";
echo "📁 Archivo corregido: {$file}\n";