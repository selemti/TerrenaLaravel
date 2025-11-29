<?php
/**
 * Script de backup automático para la base de datos
 * 
 * Este script crea un backup diario de la base de datos
 * y mantiene solo los últimos 7 días de backups
 */

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

function createDatabaseBackup() {
    $config = [
        'host' => $_ENV['DB_HOST'] ?? 'localhost',
        'port' => $_ENV['DB_PORT'] ?? '5433',
        'database' => $_ENV['DB_DATABASE'] ?? 'pos',
        'username' => $_ENV['DB_USERNAME'] ?? 'postgres',
        'password' => $_ENV['DB_PASSWORD'] ?? 'T3rr3n4#p0s'
    ];
    
    $timestamp = date('Y-m-d_His');
    $backupDir = __DIR__ . '/backups';
    
    // Crear directorio de backups si no existe
    if (!is_dir($backupDir)) {
        mkdir($backupDir, 0755, true);
    }
    
    $filename = $backupDir . '/laravel_backup_' . $timestamp . '.sql';
    
    // Comando para crear backup con pg_dump
    $command = sprintf(
        'pg_dump -h %s -p %s -U %s -d %s -F p -v -f "%s" --schema=public --schema=selemti',
        $config['host'],
        $config['port'],
        $config['username'],
        $config['database'],
        $filename
    );
    
    // Configurar variable de entorno para contraseña
    putenv("PGPASSWORD=" . $config['password']);
    
    $output = [];
    $return_code = 0;
    exec($command, $output, $return_code);
    
    if ($return_code === 0) {
        echo "✅ Backup creado exitosamente: $filename\n";
        
        // Mantener solo los últimos 7 días de backups
        cleanOldBackups($backupDir);
        
        return $filename;
    } else {
        echo "❌ Error creando backup\n";
        foreach ($output as $line) {
            echo $line . "\n";
        }
        return false;
    }
}

function cleanOldBackups($backupDir) {
    $files = glob($backupDir . '/laravel_backup_*.sql');
    
    // Ordenar por tiempo de modificación (más reciente primero)
    usort($files, function($a, $b) {
        return filemtime($b) <=> filemtime($a);
    });
    
    // Eliminar backups anteriores a 7 días
    $sevenDaysAgo = time() - (7 * 24 * 60 * 60);
    
    foreach ($files as $file) {
        if (filemtime($file) < $sevenDaysAgo) {
            unlink($file);
            echo "🗑️  Eliminado backup antiguo: " . basename($file) . "\n";
        }
    }
    
    // Mantener máximo 10 archivos más recientes, eliminar los demás
    if (count($files) > 10) {
        for ($i = 10; $i < count($files); $i++) {
            unlink($files[$i]);
            echo "🗑️  Eliminado backup excedente: " . basename($files[$i]) . "\n";
        }
    }
}

// Ejecutar backup
echo "🚀 Iniciando backup automático...\n";
echo "📅 Fecha y hora: " . date('Y-m-d H:i:s') . "\n";

$result = createDatabaseBackup();

if ($result) {
    echo "✨ Backup automático completado exitosamente\n";
} else {
    echo "💥 Error en el backup automático\n";
    exit(1);
}