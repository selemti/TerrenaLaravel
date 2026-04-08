<?php
require_once __DIR__.'/vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Laravel bootstrap
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$tables = [
    'recepcion_cab',
    'recepcion_det', 
    'traspaso_cab',
    'traspaso_det',
    'mov_inv',
    'inventory_batch',
    'cat_unidades',
    'cat_almacenes',
    'cat_sucursales',
    'cat_proveedores',
    'items'
];

echo "Fetching sample data for inventory tables in selemti schema...\n\n";

foreach ($tables as $table) {
    $fullTableName = "selemti.{$table}";
    
    try {
        $sampleData = DB::select("SELECT * FROM {$fullTableName} LIMIT 3");
        
        echo "### Sample Data from selemti.{$table}\n\n";
        echo "```sql\n";
        echo "SELECT * FROM selemti.{$table} LIMIT 3;\n";
        echo "```\n\n";
        
        if (!empty($sampleData)) {
            // Get column names for the table
            $columnNames = array_keys(get_object_vars($sampleData[0]));
            
            // Create table header
            echo "| ";
            foreach ($columnNames as $col) {
                echo $col . " | ";
            }
            echo "\n|";
            foreach ($columnNames as $col) {
                echo "---------|";
            }
            echo "\n";
            
            // Add data rows
            foreach ($sampleData as $row) {
                echo "| ";
                foreach ($columnNames as $col) {
                    $value = $row->$col ?? 'NULL';
                    // Truncate long values for readability
                    $displayValue = strlen($value) > 50 ? substr($value, 0, 47) . '...' : $value;
                    echo $displayValue . " | ";
                }
                echo "\n";
            }
        } else {
            echo "No data found in selemti.{$table}\n";
        }
        
        echo "\n---\n\n";
    } catch (Exception $e) {
        echo "Could not fetch data from selemti.{$table}: " . $e->getMessage() . "\n\n";
    }
}