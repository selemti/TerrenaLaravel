<?php
// Script para obtener información sobre vistas de stock
require_once __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

echo "ANÁLISIS DE VISTAS RELACIONADAS CON STOCK\n";
echo "=========================================\n\n";

try {
    // Verificar vistas relacionadas con stock
    echo "TODAS LAS VISTAS RELACIONADAS CON STOCK:\n";
    echo "---------------------------------------\n";
    $stock_views = DB::connection('pgsql')->select("
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'selemti' 
        AND (table_name ILIKE '%stock%' OR table_name ILIKE '%kardex%' OR table_name ILIKE '%valoriz%')
        ORDER BY table_name
    ");
    foreach ($stock_views as $view) {
        echo "- {$view->table_name}\n";
    }
    echo "\n";

    // Verificar la estructura de la vista v_stock_actual
    echo "ESTRUCTURA DE LA VISTA v_stock_actual:\n";
    echo "--------------------------------------\n";
    $stock_view_columns = DB::connection('pgsql')->select("
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_schema = 'selemti' 
        AND table_name = 'v_stock_actual'
        ORDER BY ordinal_position
    ");
    foreach ($stock_view_columns as $column) {
        echo "- {$column->column_name}: {$column->data_type} (nullable: {$column->is_nullable}, default: {$column->column_default})\n";
    }
    echo "\n";

    // Verificar si existe vw_kardex (que sí se encontró en la primera consulta)
    echo "VERIFICAR EXISTENCIA DE vw_kardex:\n";
    echo "----------------------------------\n";
    $kardex_columns = DB::connection('pgsql')->select("
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_schema = 'selemti' 
        AND table_name = 'vw_kardex'
        ORDER BY ordinal_position
    ");
    foreach ($kardex_columns as $column) {
        echo "- {$column->column_name}: {$column->data_type} (nullable: {$column->is_nullable}, default: {$column->column_default})\n";
    }
    echo "\n";

    // Contar registros en v_stock_actual
    echo "CONTEO REGISTROS EN v_stock_actual:\n";
    echo "-----------------------------------\n";
    $count = DB::connection('pgsql')->select("SELECT COUNT(*) as total FROM selemti.v_stock_actual");
    echo "Total registros: {$count[0]->total}\n\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}