<?php
$tables = [
    'items',
    'mov_inv',
    'lote',
    'almacen',
    'unidades_medida_legacy',
    'recepcion_cab',
    'recepcion_det',
    'transfer_cab',
    'transfer_det',
    'stock_policy',
    'inventory_counts',
    'inventory_count_lines',
    'item_categories',
    'conversiones_unidad_legacy'
];

$conn_string = 'host=localhost port=5433 dbname=pos user=postgres password=urmikz';
$conn = pg_connect($conn_string);

if (!connection) {
    die('ERROR: Could not connect to PostgreSQL');
}

$output = '=== ESTRUCTURA DE TABLAS INVENTARIO - SCHEMA SELEMTI ===' . PHP_EOL;
$output .= 'Generado: ' . date('Y-m-d H:i:s') . PHP_EOL;
$output .= str_repeat('=', 80) . PHP_EOL . PHP_EOL;

foreach ($tables as $table_name) {
    $output .= '=== TABLA: ' . $table_name . ' ===' . PHP_EOL;

    $query = "SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = '$table_name' ORDER BY ordinal_position";

    $result = pg_query($conn, $query);

    if (!result) {
        $output .= 'ERROR: ' . pg_last_error($conn) . PHP_EOL;
        $output .= str_repeat('-', 80) . PHP_EOL . PHP_EOL;
        continue;
    }

    $rows = pg_fetch_all($result);

    if (empty(rows)) {
        $output .= 'TABLA NO ENCONTRADA' . PHP_EOL;
        $output .= str_repeat('-', 80) . PHP_EOL . PHP_EOL;
        continue;
    }

    $output .= sprintf('%-40s | %-20s | %-8s | %s' . PHP_EOL, 'COLUMNA', 'TIPO', 'NULL', 'DEFAULT');
    $output .= str_repeat('-', 80) . PHP_EOL;

    foreach ($rows as $row) {
        $output .= sprintf('%-40s | %-20s | %-8s | %s' . PHP_EOL, $row['column_name'], $row['data_type'], $row['is_nullable'] === 'YES' ? 'SI' : 'NO', $row['column_default'] ?? '');
    }

    $output .= PHP_EOL . str_repeat('-', 80) . PHP_EOL . PHP_EOL;
}

pg_close($conn);
file_put_contents('C:/xampp3/htdocs/TerrenaLaravel/inventario_bd_estructura.txt', $output);
echo $output;
?>
