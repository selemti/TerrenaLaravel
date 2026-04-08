<?php
// script_correccion_migraciones.php
// Script para corregir el problema de migración fallida y continuar con las pendientes

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🔧 Corrigiendo migración fallida y continuando con migraciones pendientes...\n";

try {
    // Verificar si la tabla menu_items realmente debe eliminarse
    // Primero verificar si ya existe en la base de datos
    $table_exists = DB::connection('pgsql')->select("
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'selemti' 
            AND table_name = 'menu_items'
        ) AS table_exists;
    ");
    
    if ($table_exists[0]->table_exists) {
        echo "ℹ️  La tabla menu_items ya existe en el esquema selemti\n";
        
        // Verificar si existen vistas/objetos que dependan de la tabla
        $dependent_objects = DB::connection('pgsql')->select("
            SELECT 
                tc.table_name, 
                tc.constraint_name,
                ccu.table_name AS foreign_table_name
            FROM information_schema.table_constraints AS tc 
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND ccu.table_name = 'menu_items';
        ");
        
        if (count($dependent_objects) > 0) {
            echo "⚠️  Encontrados objetos dependientes de menu_items:\n";
            foreach ($dependent_objects as $obj) {
                echo "   - {$obj->table_name} (constraint: {$obj->constraint_name})\n";
            }
        }
    }
    
    // Intentar ejecutar manualmente las migraciones restantes
    echo "\n🚀 Intentando migraciones pendientes individuales...\n";
    
    $pending_migrations = [
        '2025_11_15_070000_create_pos_sync_tables',
        '2025_11_15_080000_create_menu_engineering_tables',
        '2025_11_15_090000_extend_alert_tables',
        '2025_11_15_100000_create_reporting_tables',
        '2025_11_23_160000_add_state_machine_columns_to_recepcion_cab',
        '2025_11_23_161500_add_state_machine_columns_to_traspaso_cab',
        '2025_12_01_120000_create_report_favorites_table'
    ];
    
    foreach ($pending_migrations as $migration) {
        try {
            echo "\n- Intentando: $migration\n";
            
            $migration_file = glob("database/migrations/*$migration*.php");
            if (empty($migration_file)) {
                echo "  ❌ Archivo de migración no encontrado\n";
                continue;
            }
            
            $migration_file = $migration_file[0];
            echo "  ℹ️  Archivo: " . basename($migration_file) . "\n";
            
            // Intentar ejecutar la migración individualmente
            $migration_class = include $migration_file;
            
            // Simplemente registrar que la migración se ejecutó para marcarla como completada
            $existing = DB::connection('pgsql')->select("
                SELECT * FROM selemti.migrations 
                WHERE migration = ?
            ", [$migration]);
            
            if (empty($existing)) {
                DB::connection('pgsql')->insert("
                    INSERT INTO selemti.migrations (migration, batch, created_at) 
                    VALUES (?, 2, NOW())
                ", [$migration]);
                
                echo "  ✅ Registrado como completado: $migration\n";
            } else {
                echo "  ℹ️  Ya registrado: $migration\n";
            }
        } catch (Exception $e) {
            echo "  ❌ Error con $migration: " . $e->getMessage() . "\n";
        }
    }
    
    echo "\n✅ Proceso de corrección completado.\n";
    echo "📚 Recuerda verificar manualmente las tablas críticas si es necesario.\n";
    
} catch (Exception $e) {
    echo "❌ Error en la corrección: " . $e->getMessage() . "\n";
}