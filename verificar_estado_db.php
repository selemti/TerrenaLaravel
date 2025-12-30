<?php
// verificar_estado_db.php
// Script para verificar el estado actual de la base de datos

require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "🔍 Verificando estado actual de la base de datos...\n\n";

try {
    // 1. Verificar esquemas existentes
    echo "1. ESQUEMAS EXISTENTES:\n";
    echo "======================\n";
    
    $schemas = DB::connection('pgsql')->select("
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name
    ");
    
    foreach ($schemas as $schema) {
        echo "- " . $schema->schema_name . "\n";
    }
    
    // 2. Contar tablas en selemti
    echo "\n2. TABLAS EN EL ESQUEMA 'selemti':\n";
    echo "==================================\n";
    
    $selemti_tables = DB::connection('pgsql')->select("
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'selemti' 
        ORDER BY table_name
    ");
    
    echo "Total tablas en selemti: " . count($selemti_tables) . "\n";
    
    // 3. Contar tablas en public
    echo "\n3. TABLAS EN EL ESQUEMA 'public':\n";
    echo "==================================\n";
    
    $public_count = DB::connection('pgsql')->select("
        SELECT COUNT(*) as count
        FROM information_schema.tables 
        WHERE table_schema = 'public'
    ");
    
    echo "Total tablas en public: " . $public_count[0]->count . "\n";
    
    // 4. Verificar tablas críticas en selemti
    echo "\n4. VERIFICACIÓN DE TABLAS CRÍTICAS EN 'selemti':\n";
    echo "==============================================\n";
    
    $critical_tables = [
        'recepcion_cab',
        'recepcion_det', 
        'mov_inv',
        'inventory_batch',
        'items',
        'cat_unidades',
        'cat_almacenes',
        'cat_proveedores',
        'purchase_requests',
        'purchase_orders',
        'vendor_quotes'
    ];
    
    foreach ($critical_tables as $table) {
        $exists = DB::connection('pgsql')->select("
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'selemti' AND table_name = ?
            ) AS table_exists;
        ", [$table]);
        
        $status = $exists[0]->table_exists ? "✅ EXISTE" : "❌ FALTA";
        echo "$status - $table\n";
    }
    
    // 5. Verificar índices relacionados con tickets (posiblemente en ambos esquemas)
    echo "\n5. ÍNDICES RELACIONADOS CON TICKETS:\n";
    echo "====================================\n";
    
    $ticket_indexes = DB::connection('pgsql')->select("
        SELECT schemaname, tablename, indexname 
        FROM pg_indexes 
        WHERE schemaname IN ('public', 'selemti') 
        AND indexname ILIKE '%ticket%'
        ORDER BY indexname
    ");
    
    if (count($ticket_indexes) > 0) {
        foreach ($ticket_indexes as $index) {
            echo "- {$index->schemaname}.{$index->tablename}.{$index->indexname}\n";
        }
    } else {
        echo "No se encontraron índices relacionados con 'ticket'\n";
    }
    
    // 6. Verificar índices específicos de rendimiento para reportes de excepciones
    echo "\n6. ÍNDICES ESPECÍFICOS DE RENDIMIENTO:\n";
    echo "=====================================\n";
    
    $perf_indexes = [
        'idx_transactions_ticket_id',
        'idx_ticket_discount_ticket_id', 
        'idx_ticket_item_discount_itemid'
    ];
    
    foreach ($perf_indexes as $index) {
        $exists = DB::connection('pgsql')->select("
            SELECT EXISTS (
                SELECT FROM pg_indexes 
                WHERE indexname = ?
            ) AS index_exists;
        ", [$index]);
        
        $status = $exists[0]->index_exists ? "✅ EXISTE" : "❌ FALTA";
        echo "$status - $index\n";
    }
    
    // 7. Verificar si hay vistas importantes
    echo "\n7. VISTAS IMPORTANTES EN 'public':\n";
    echo "==================================\n";
    
    $views = DB::connection('pgsql')->select("
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = 'public'
        AND table_name ILIKE '%vw%'
        ORDER BY table_name
        LIMIT 10
    ");
    
    if (count($views) > 0) {
        foreach ($views as $view) {
            echo "- {$view->table_name}\n";
        }
    } else {
        echo "No se encontraron vistas en 'public'\n";
    }
    
    echo "\n✅ VERIFICACIÓN COMPLETADA\n";
    
} catch (Exception $e) {
    echo "❌ Error al conectar con la base de datos: " . $e->getMessage() . "\n";
}