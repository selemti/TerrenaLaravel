<?php
/**
 * Script de verificación de integridad de base de datos
 * 
 * Este script verifica que las tablas críticas existan y estén intactas
 * y crea backups automáticos si detecta algún problema o periódicamente.
 */

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Configuración del entorno
$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Tablas críticas que deben existir
$critical_tables = [
    'public.ticket',
    'public.transactions', 
    'public.ticket_item',
    'public.ticket_discount',
    'public.ticket_item_discount',
    'selemti.users',
    'selemti.cat_sucursales',
    'selemti.cat_almacenes',
    'selemti.items',
    'selemti.recipes'
];

function checkDatabaseIntegrity($critical_tables) {
    $missing_tables = [];
    
    foreach ($critical_tables as $table) {
        try {
            // Extraer nombre de esquema y tabla
            $parts = explode('.', $table);
            $schema = $parts[0];
            $table_name = $parts[1];
            
            // Verificar si la tabla existe
            $exists = DB::select("
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = ? AND table_name = ?
                ) AS table_exists;
            ", [$schema, $table_name]);
            
            if (!$exists[0]->table_exists) {
                $missing_tables[] = $table;
            }
        } catch (Exception $e) {
            echo "Error verificando tabla $table: " . $e->getMessage() . "\n";
            $missing_tables[] = $table;
        }
    }
    
    return $missing_tables;
}

function createBackup() {
    $timestamp = date('Y-m-d-His');
    $filename = "auto_backup_{$timestamp}.sql";
    $backup_dir = "database/backups";
    
    // Crear directorio de backups si no existe
    if (!is_dir($backup_dir)) {
        mkdir($backup_dir, 0755, true);
    }
    
    $full_path = $backup_dir . '/' . $filename;
    
    // Comando para crear backup con pg_dump
    $db_config = [
        'host' => $_ENV['DB_HOST'] ?? 'localhost',
        'port' => $_ENV['DB_PORT'] ?? '5433',
        'database' => $_ENV['DB_DATABASE'] ?? 'pos',
        'username' => $_ENV['DB_USERNAME'] ?? 'postgres',
        'password' => $_ENV['DB_PASSWORD'] ?? 'T3rr3n4#p0s'
    ];
    
    $command = sprintf(
        'pg_dump -h %s -p %s -U %s -d %s -f "%s" --schema=public --schema=selemti',
        $db_config['host'],
        $db_config['port'],
        $db_config['username'],
        $db_config['database'],
        $full_path
    );
    
    // Configurar variable de entorno para contraseña
    putenv("PGPASSWORD=" . $db_config['password']);
    
    $output = [];
    $return_code = 0;
    exec($command, $output, $return_code);
    
    if ($return_code === 0) {
        echo "✅ Backup creado exitosamente: $full_path\n";
        return $full_path;
    } else {
        echo "❌ Error creando backup\n";
        var_dump($output);
        return false;
    }
}

// Ejecutar verificación
echo "🔍 Verificando integridad de la base de datos...\n";

$missing_tables = checkDatabaseIntegrity($critical_tables);

if (empty($missing_tables)) {
    echo "✅ La base de datos está completa y sana\n";
    
    // Crear backup periódico (por ejemplo, diario)
    $should_backup = true; // En una implementación real, se verificaría la última fecha de backup
    
    if ($should_backup) {
        echo "📦 Creando backup periódico...\n";
        createBackup();
    }
} else {
    echo "❌ Se detectaron problemas de integridad:\n";
    foreach ($missing_tables as $table) {
        echo "  - Tabla faltante: $table\n";
    }
    
    echo "🔄 Creando backup de emergencia...\n";
    $backup_path = createBackup();
    
    if ($backup_path) {
        echo "💡 Se ha creado un backup de emergencia en: $backup_path\n";
        echo "🚨 ¡La base de datos ha sido comprometida! Revisar inmediatamente.\n";
    } else {
        echo "❌ ¡ALERTA! No se pudo crear backup de emergencia. ¡Riesgo crítico!\n";
    }
}

echo "✅ Verificación de integridad completada\n";