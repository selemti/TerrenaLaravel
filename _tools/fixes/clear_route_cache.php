<?php
echo "🔄 Limpiando caché de rutas de Laravel...\n";

// Limpiar caché de rutas
$cachePath = storage_path('framework/cache/');
if (is_dir($cachePath)) {
    $files = glob($cachePath . '*');
    foreach ($files as $file) {
        if (is_file($file)) {
            unlink($file);
        }
    }
    echo "✅ Caché de rutas limpiado\n";
} else {
    echo "⚠️ Directorio de caché no encontrado\n";
}

// Optimizar composer autoload
echo "📦 Ejecutando composer dump-autoload...\n";
passthru('composer dump-autoload', $returnCode, $output, $outputText);
echo $outputText;

echo "🚀 Configuración actualizada\n";
echo "✅ Prueba la URL: http://localhost/TerrenaLaravel/reports/sales/mods/v2\n";