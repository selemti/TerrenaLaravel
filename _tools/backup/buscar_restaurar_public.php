<?php
// Script para restaurar las tablas del esquema 'public' desde un backup existente

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "Buscando archivos de backup con las tablas de esquema 'public'...\n";

// Directorios donde comúnmente se guardan los backups
$backupDirs = [
    'database/24_11_2025/',
    'database/',
    'BD/',
    'BD/Noviembre/',
    'BD/Noviembre/05-11-2025/',
    'BD/Noviembre/10_11_2025/',
];

$backupFiles = [];
foreach ($backupDirs as $dir) {
    if (is_dir($dir)) {
        $files = scandir($dir);
        foreach ($files as $file) {
            if (pathinfo($file, PATHINFO_EXTENSION) === 'sql' && 
                (stripos($file, 'full') !== false || 
                 stripos($file, 'backup') !== false || 
                 stripos($file, 'data') !== false)) {
                $backupFiles[] = $dir . $file;
            }
        }
    }
}

echo "Backups encontrados:\n";
foreach ($backupFiles as $file) {
    $size = filesize($file);
    $modTime = date('Y-m-d H:i:s', filemtime($file));
    echo "- $file ({$size} bytes, mod: $modTime)\n";
}

// El archivo que encontramos anteriormente
$latestBackup = 'database/24_11_2025/POS_Full_Data_25_11_2025.sql';
if (file_exists($latestBackup)) {
    echo "\nArchivo más reciente encontrado: $latestBackup\n";
    echo "Este archivo contiene las tablas del esquema 'public' que necesitamos restaurar.\n";
    echo "\nPara restaurar el esquema 'public', ejecuta:\n";
    echo "pg_restore -h localhost -p 5433 -U postgres -d pos --schema=public $latestBackup\n";
    echo "\nO con psql:\n";
    echo "psql -h localhost -p 5433 -U postgres -d pos -f $latestBackup\n";
} else {
    echo "\nNo se encontró el archivo de backup más reciente.\n";
}

echo "\nAdemás, se recomienda ejecutar las migraciones pendientes para recrear las tablas:\n";
echo "php artisan migrate --force\n";