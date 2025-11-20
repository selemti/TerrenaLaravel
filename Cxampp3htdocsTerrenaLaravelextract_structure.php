<?php
/**
 * Extract complete structure from selemti inventory tables in PostgreSQL
 */

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

$conn_string = "host=localhost port=5433 dbname=pos user=postgres password=urmikz";

try {
    $conn = pg_connect($conn_string);

    if (!$conn) {
        die("ERROR: Could not connect to PostgreSQL\n");
    }

    $output = "=== ESTRUCTURA DE TABLAS INVENTARIO - SCHEMA SELEMTI ===\n";
    $output .= "Generado: " . date('Y-m-d H:i:s') . "\n";
    $output .= "Connection: pos@localhost:5433\n";
    $output .= str_repeat("=", 80) . "\n\n";

    foreach ($tables as $table_name) {
        $output .= "=== TABLA: $table_name ===\n";

        $query = "
            SELECT
                column_name,
                data_type,
                is_nullable,
                column_default
            FROM information_schema.columns
            WHERE table_schema = 'selemti' AND table_name = '$table_name'
            ORDER BY ordinal_position
        ";

        $result = pg_query($conn, $query);

        if (!$result) {
            $output .= "ERROR: " . pg_last_error($conn) . "\n";
            $output .= str_repeat("-", 80) . "\n\n";
            continue;
        }

        $rows = pg_fetch_all($result);

        if (empty($rows)) {
            $output .= "TABLA NO ENCONTRADA\n";
            $output .= str_repeat("-", 80) . "\n\n";
            continue;
        }

        // Print header
        $output .= sprintf("%-40s | %-20s | %-8s | %s\n", "COLUMNA", "TIPO", "NULL", "DEFAULT");
        $output .= str_repeat("-", 80) . "\n";

        foreach ($rows as $row) {
            $column = $row['column_name'];
            $type = $row['data_type'];
            $nullable = $row['is_nullable'] === 'YES' ? 'SI' : 'NO';
            $default = $row['column_default'] ?? '';

            $output .= sprintf("%-40s | %-20s | %-8s | %s\n", $column, $type, $nullable, $default);
        }

        $output .= "\n" . str_repeat("-", 80) . "\n\n";
    }

    pg_close($conn);

    // Write to file
    file_put_contents('C:/xampp3/htdocs/TerrenaLaravel/inventario_bd_estructura.txt', $output);

    echo "SUCCESS: Structure extracted to inventario_bd_estructura.txt\n";
    echo "Total tables processed: " . count($tables) . "\n";
    echo "\n" . $output;

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
?>
