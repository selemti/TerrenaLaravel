<?php
// Script para obtener información específica de la tabla stock
require_once __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

echo "INFORMACIÓN ADICIONAL DE LA TABLA 'stock'\n";
echo "=========================================\n\n";

try {
    // Verificar estructura de tabla stock
    echo "ESTRUCTURA TABLA 'stock':\n";
    echo "------------------------\n";
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

    // Obtener conteo de registros
    echo "CONTEO DE REGISTROS EN LA TABLA 'stock':\n";
    echo "--------------------------------------\n";
    $count = DB::connection('pgsql')->select("SELECT COUNT(*) as total FROM selemti.stock");
    echo "Total registros: {$count[0]->total}\n\n";

    // Mostrar algunos registros de ejemplo
    echo "EJEMPLO DE REGISTROS DE LA TABLA 'stock':\n";
    echo "----------------------------------------\n";
    $example_records = DB::connection('pgsql')->select("SELECT * FROM selemti.stock LIMIT 5");
    foreach ($example_records as $record) {
        echo "item_id: {$record->item_id}, almacen_id: {$record->almacen_id}, cantidad_actual: {$record->cantidad_actual}, costo_promedio: {$record->costo_promedio}\n";
    }
    echo "\n";

    // Verificar si existen vistas relacionadas con stock
    echo "VISTAS RELACIONADAS CON STOCK:\n";
    echo "------------------------------\n";
    $stock_views = DB::connection('pgsql')->select("
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'selemti' 
        AND table_name ILIKE '%stock%'
        ORDER BY table_name
    ");
    foreach ($stock_views as $view) {
        echo "- {$view->table_name}\n";
    }
    echo "\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}