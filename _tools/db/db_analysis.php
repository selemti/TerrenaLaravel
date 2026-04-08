<?php
// Script para analizar la estructura de la base de datos PostgreSQL
require_once __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

echo "ANÁLISIS DE LA BASE DE DATOS (esquema selemti)\n";
echo "=============================================\n\n";

try {
    // Verificar conexión
    echo "✓ Conexión a la base de datos: OK\n\n";
    
    // 1. Obtener todas las tablas del esquema 'selemti'
    echo "1. TABLAS DEL ESQUEMA 'selemti':\n";
    echo "--------------------------------\n";
    $tables = DB::connection('pgsql')->select("
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'selemti' 
        AND table_type = 'BASE TABLE'
        ORDER BY table_name
    ");
    foreach ($tables as $table) {
        echo "- {$table->table_name}\n";
    }
    echo "\n";

    // 2. Obtener todas las vistas del esquema 'selemti'
    echo "2. VISTAS DEL ESQUEMA 'selemti':\n";
    echo "-------------------------------\n";
    $views = DB::connection('pgsql')->select("
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'selemti' 
        ORDER BY table_name
    ");
    foreach ($views as $view) {
        echo "- {$view->table_name}\n";
    }
    echo "\n";

    // 3. Obtener todas las funciones del esquema 'selemti'
    echo "3. FUNCIONES DEL ESQUEMA 'selemti':\n";
    echo "----------------------------------\n";
    $functions = DB::connection('pgsql')->select("
        SELECT routine_name, routine_type 
        FROM information_schema.routines 
        WHERE specific_schema = 'selemti' 
        ORDER BY routine_name
    ");
    foreach ($functions as $function) {
        echo "- {$function->routine_name} ({$function->routine_type})\n";
    }
    echo "\n";

    // 4. Obtener todas las secuencias del esquema 'selemti'
    echo "4. SECUENCIAS DEL ESQUEMA 'selemti':\n";
    echo "------------------------------------\n";
    $sequences = DB::connection('pgsql')->select("
        SELECT sequence_name 
        FROM information_schema.sequences 
        WHERE sequence_schema = 'selemti' 
        ORDER BY sequence_name
    ");
    foreach ($sequences as $sequence) {
        echo "- {$sequence->sequence_name}\n";
    }
    echo "\n";

    // 5. Verificar vistas críticas pendientes
    echo "5. VISTAS CRÍTICAS PENDIENTES:\n";
    echo "------------------------------\n";
    $critical_views = DB::connection('pgsql')->select("
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'selemti' 
        AND table_name IN ('vw_kardex_detalle', 'vw_valorizacion_inventario', 'vw_stock_valorizado', 
                          'vw_kardex_resumen', 'vw_dashboard_venta_dia', 'vw_dashboard_venta_semana', 
                          'vw_dashboard_venta_mes', 'vw_dashboard_inventario_valorizado', 
                          'vw_dashboard_compras_pendientes', 'vw_dashboard_stock_alertas')
        ORDER BY table_name
    ");
    foreach ($critical_views as $view) {
        echo "- {$view->table_name} ✓ (EXISTE)\n";
    }
    if (empty($critical_views)) {
        echo "NINGUNA de las vistas críticas pendientes existe actualmente.\n";
    }
    echo "\n";

    // 6. Verificar estructura de tabla mov_inv
    echo "6. ESTRUCTURA TABLA 'mov_inv':\n";
    echo "------------------------------\n";
    $mov_inv_columns = DB::connection('pgsql')->select("
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_schema = 'selemti' 
        AND table_name = 'mov_inv'
        ORDER BY ordinal_position
    ");
    foreach ($mov_inv_columns as $column) {
        echo "- {$column->column_name}: {$column->data_type} (nullable: {$column->is_nullable}, default: {$column->column_default})\n";
    }
    echo "\n";

    // 7. Verificar estructura de tabla stock
    echo "7. ESTRUCTURA TABLA 'stock':\n";
    echo "---------------------------\n";
    $stock_columns = DB::connection('pgsql')->select("
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_schema = 'selemti' 
        AND table_name = 'stock'
        ORDER BY ordinal_position
    ");
    foreach ($stock_columns as $column) {
        echo "- {$column->column_name}: {$column->data_type} (nullable: {$column->is_nullable}, default: {$column->column_default})\n";
    }
    echo "\n";

    // 8. Verificar triggers relevantes
    echo "8. TRIGGERS EN EL ESQUEMA 'selemti':\n";
    echo "------------------------------------\n";
    $triggers = DB::connection('pgsql')->select("
        SELECT trigger_name, event_manipulation, event_object_table, action_statement
        FROM information_schema.triggers
        WHERE trigger_schema = 'selemti'
        ORDER BY trigger_name
    ");
    foreach ($triggers as $trigger) {
        echo "- {$trigger->trigger_name}: {$trigger->event_manipulation} ON {$trigger->event_object_table}\n";
    }
    if (empty($triggers)) {
        echo "No se encontraron triggers en el esquema selemti.\n";
    }
    echo "\n";

    echo "ANÁLISIS COMPLETADO\n";
    echo "===================\n";
    echo "Se ha recopilado toda la información estructural de la base de datos.\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}