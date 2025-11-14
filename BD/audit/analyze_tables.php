<?php
require __DIR__ . '/../../vendor/autoload.php';
$app = require_once __DIR__ . '/../../bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

echo "ANÁLISIS DE TABLAS PRINCIPALES - selemti\n";
echo "==========================================\n\n";

$mainTables = [
    'items', 'receta_cab', 'receta_det', 'receta_version',
    'inventory_batch', 'mov_inv', 
    'purchase_orders', 'purchase_requests',
    'transfer_cab', 'transfer_det',
    'pos_map', 'receta_shadow',
    'postcorte', 'precorte', 'sesion_cajon',
    'cash_funds', 'cash_fund_movements',
    'inventory_counts', 'inventory_count_lines',
    'production_orders', 'op_produccion_cab',
    'inv_stock_policy'
];

foreach($mainTables as $table) {
    try {
        $count = DB::table($table)->count();
        echo str_pad($table, 35) . ': ' . str_pad(number_format($count), 10, ' ', STR_PAD_LEFT) . " registros\n";
    } catch(Exception $e) {
        echo str_pad($table, 35) . ': [NO EXISTE EN SCHEMA]' . "\n";
    }
}

echo "\n✓ Análisis completado\n";
