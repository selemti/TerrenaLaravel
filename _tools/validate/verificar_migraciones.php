<?php
// verificar_migraciones.php
// Script para verificar el estado de las migraciones en Laravel

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🔍 Verificando estado de migraciones de Laravel...\n\n";

try {
    // 1. Verificar si existe la tabla 'migrations' en selemti
    echo "1. VERIFICANDO TABLA DE MIGRACIONES:\n";
    echo "==================================\n";
    
    $migration_table_exists = DB::connection('pgsql')->select("
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'selemti' 
            AND table_name = 'migrations'
        ) AS table_exists;
    ");
    
    if (!$migration_table_exists[0]->table_exists) {
        echo "❌ La tabla 'migrations' no existe en el esquema 'selemti'\n";
        exit(1);
    } else {
        echo "✅ Tabla 'migrations' existe en el esquema 'selemti'\n";
    }
    
    // 2. Obtener las últimas 10 migraciones ejecutadas
    echo "\n2. ÚTIMAS 10 MIGRACIONES EJECUTADAS:\n";
    echo "==================================\n";
    
    $last_migrations = DB::connection('pgsql')->select("
        SELECT id, migration, batch, created_at
        FROM selemti.migrations
        ORDER BY id DESC
        LIMIT 10
    ");
    
    foreach ($last_migrations as $migration) {
        echo "- ID: {$migration->id}, Batch: {$migration->batch}, Migration: {$migration->migration}, Date: {$migration->created_at}\n";
    }
    
    // 3. Obtener todas las migraciones ejecutadas
    $all_executed = DB::connection('pgsql')->select("
        SELECT migration
        FROM selemti.migrations
        ORDER BY id
    ");
    
    $executed_migrations = array_column($all_executed, 'migration');
    echo "\nTotal migraciones ejecutadas: " . count($executed_migrations) . "\n";
    
    // 4. Obtener todos los archivos de migración del filesystem
    echo "\n3. ARCHIVOS DE MIGRACIÓN EN EL SISTEMA:\n";
    echo "=======================================\n";
    
    $migration_files = glob(__DIR__ . '/database/migrations/*.php');
    $migration_files = array_filter($migration_files, function($file) {
        $filename = basename($file);
        // Solo archivos con formato de migración de Laravel
        return preg_match('/^\d{4}_\d{2}_\d{2}_\d{6}_.*\.php$/', $filename);
    });
    
    $filesystem_migrations = [];
    foreach ($migration_files as $file) {
        $filename = basename($file);
        $migration_name = str_replace('.php', '', $filename);
        $filesystem_migrations[] = $migration_name;
    }
    
    echo "Total archivos de migración: " . count($filesystem_migrations) . "\n";
    
    // 5. Comparar y encontrar migraciones pendientes
    echo "\n4. MIGRACIONES PENDIENTES:\n";
    echo "==========================\n";
    
    $pending_migrations = array_diff($filesystem_migrations, $executed_migrations);
    sort($pending_migrations);
    
    if (count($pending_migrations) > 0) {
        echo "Migraciones pendientes (" . count($pending_migrations) . "):\n";
        foreach ($pending_migrations as $migration) {
            // Verificar si es una migración reciente (¿2025-11-26 o después?)
            $is_recent = strpos($migration, '2025_11_26') !== false || 
                        strpos($migration, '2025_11_27') !== false || 
                        strpos($migration, '2025_11_28') !== false || 
                        strpos($migration, '2025_11_29') !== false;
            
            $recent_marker = $is_recent ? " 🆕" : "";
            echo "- $migration$recent_marker\n";
        }
    } else {
        echo "✅ No hay migraciones pendientes\n";
    }
    
    // 6. Específicamente verificar migraciones recientes
    echo "\n5. MIGRACIONES RECIENTES (2025-11-26 en adelante):\n";
    echo "==================================================\n";
    
    $recent_migrations = array_filter($pending_migrations, function($migration) {
        return strpos($migration, '2025_11_26') !== false || 
               strpos($migration, '2025_11_27') !== false || 
               strpos($migration, '2025_11_28') !== false || 
               strpos($migration, '2025_11_29') !== false;
    });
    
    if (count($recent_migrations) > 0) {
        echo "Migraciones recientes pendientes:\n";
        foreach ($recent_migrations as $migration) {
            echo "- $migration\n";
        }
    } else {
        echo "✅ No hay migraciones recientes pendientes (desde 2025-11-26)\n";
    }
    
    // 7. Específicamente verificar migraciones relacionadas con performance
    echo "\n6. MIGRACIONES RELACIONADAS CON PERFORMANCE:\n";
    echo "=============================================\n";
    
    $perf_migrations = array_filter($pending_migrations, function($migration) {
        return (stripos($migration, 'ticket') !== false && 
                (stripos($migration, 'index') !== false || 
                 stripos($migration, 'performance') !== false || 
                 stripos($migration, 'optimize') !== false)) ||
               (stripos($migration, 'ticket_item') !== false && 
                stripos($migration, 'index') !== false) ||
               (stripos($migration, 'ticket_item_modifier') !== false && 
                stripos($migration, 'index') !== false);
    });
    
    if (count($perf_migrations) > 0) {
        echo "Migraciones de performance pendientes:\n";
        foreach ($perf_migrations as $migration) {
            echo "- $migration\n";
        }
    } else {
        echo "✅ No hay migraciones de performance pendientes\n";
    }
    
    // 8. Resumen
    echo "\n7. RESUMEN:\n";
    echo "==========\n";
    echo "Migraciones ejecutadas: " . count($executed_migrations) . "\n";
    echo "Migraciones pendientes: " . count($pending_migrations) . "\n";
    echo "Migraciones recientes pendientes: " . count($recent_migrations) . "\n";
    echo "Migraciones de performance pendientes: " . count($perf_migrations) . "\n";
    
    // Mostrar migraciones que faltan que son críticas para el funcionamiento
    echo "\n8. MIGRACIONES PENDIENTES CRÍTICAS:\n";
    echo "==================================\n";
    
    $critical_indicators = [
        'create_cash_funds_table',
        'create_cash_fund_movements_table', 
        'create_cash_fund_arqueos_table',
        'create_cat_sucursales_table',
        'create_cat_almacenes_table',
        'create_cat_proveedores_table',
        'create_cat_unidades_table',
        'create_cat_uom_conversion_table',
        'create_inv_stock_policy_table',
        'create_inventory_receiving_tables',
        'create_inventory_counts_tables',
        'create_production_tables',
        'create_pos_consumption_tables',
        'create_purchasing_tables',
        'create_costing_extension_tables',
        'create_menu_engineering_tables'
    ];
    
    foreach ($critical_indicators as $indicator) {
        $missing_critical = array_filter($pending_migrations, function($migration) use ($indicator) {
            return stripos($migration, $indicator) !== false;
        });
        
        if (!empty($missing_critical)) {
            foreach ($missing_critical as $migration) {
                echo "⚠️  Migración crítica pendiente: $migration\n";
            }
        }
    }
    
    // Verificar si todas las migraciones pendientes están relacionadas con 'selemti'
    echo "\n9. VERIFICACIÓN DE MIGRACIONES PENDIENTES:\n";
    echo "========================================\n";
    
    $selemti_migrations = array_filter($pending_migrations, function($migration) {
        return stripos($migration, 'selemti') !== false || 
               stripos($migration, 'cash_fund') !== false ||
               stripos($migration, 'cat_') !== false ||
               stripos($migration, 'inventory') !== false ||
               stripos($migration, 'recipe') !== false;
    });
    
    echo "Migraciones pendientes que afectan el esquema 'selemti': " . count($selemti_migrations) . "\n";
    
    if (count($selemti_migrations) > 0) {
        echo "Ejemplos:\n";
        $example_count = 0;
        foreach ($selemti_migrations as $migration) {
            if ($example_count++ < 10) { // Mostrar solo los primeros 10
                echo "- $migration\n";
            } else {
                break;
            }
        }
        if (count($selemti_migrations) > 10) {
            echo "... y " . (count($selemti_migrations) - 10) . " más\n";
        }
    }
    
    echo "\n✅ VERIFICACIÓN DE MIGRACIONES COMPLETADA\n";

} catch (Exception $e) {
    echo "❌ Error al verificar migraciones: " . $e->getMessage() . "\n";
    
    // También intentar con el comando de Laravel directamente
    echo "\nIntentando con el comando de Laravel:\n";
    try {
        // Ejecutar el comando de migración de Laravel
        $output = [];
        $return_code = 0;
        exec('php artisan migrate:status 2>&1', $output, $return_code);
        
        if ($return_code === 0) {
            echo "✅ Comando de migración de Laravel ejecutado correctamente\n";
            foreach ($output as $line) {
                echo $line . "\n";
            }
        } else {
            echo "❌ Comando de migración de Laravel falló\n";
            foreach ($output as $line) {
                echo $line . "\n";
            }
        }
    } catch (Exception $cmd_ex) {
        echo "❌ Error al ejecutar comando de Laravel: " . $cmd_ex->getMessage() . "\n";
    }
}