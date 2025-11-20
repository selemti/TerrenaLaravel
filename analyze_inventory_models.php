<?php
// Script to get detailed column information for inventory tables

require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

echo "Analyzing Inventory Tables Schema..." . PHP_EOL;

try {
    $tables = [
        'items',
        'inventory_batch',
        'unidades_medida',
        'conversiones_unidad',
        'item_vendor',
        'inventory_counts',
        'inventory_count_lines',
        'recepcion_cab',
        'recepcion_det',
        'historial_costos_item',
        'stock_policy',
        'param_sucursal',
        'almacen',
        'transfer_cab',
        'transfer_det'
    ];

    foreach ($tables as $table) {
        echo PHP_EOL . "=== {$table} ===" . PHP_EOL;
        try {
            $columns = DB::connection('pgsql')->select("
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'selemti' AND table_name = ?
                ORDER BY ordinal_position
            ", [$table]);

            if (empty($columns)) {
                echo "  ⚠️ Table not found in selemti schema" . PHP_EOL;
                continue;
            }

            $col_count = 0;
            foreach ($columns as $col) {
                $col_count++;
                $nullable = $col->is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
                $default = $col->column_default ? ' DEFAULT ' . substr($col->column_default, 0, 50) : '';
                echo sprintf("  %s %s %s%s", $col->column_name, $col->data_type, $nullable, $default) . PHP_EOL;
            }
            echo "  Total columns: {$col_count}" . PHP_EOL;

        } catch (Exception $e) {
            echo "  ❌ Error: " . $e->getMessage() . PHP_EOL;
        }
    }

    echo PHP_EOL . "Analysis completed." . PHP_EOL;

} catch (Exception $e) {
    echo "Database connection error: " . $e->getMessage() . PHP_EOL;
}
