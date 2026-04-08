<?php
// Script to connect to the database and get production and purchasing related tables

require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

echo "Connecting to database..." . PHP_EOL;

try {
    // Test basic connection
    $test = DB::connection('pgsql')->select('SELECT 1 as test');
    echo "Database connection successful. Test result: " . $test[0]->test . PHP_EOL;
    
    // Get production related tables
    echo PHP_EOL . "PRODUCTION RELATED TABLES:" . PHP_EOL;
    $production_tables = DB::connection('pgsql')->select("
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'selemti'
        AND (table_name LIKE '%prod%' OR table_name LIKE '%op_%' OR table_name LIKE '%yield%' OR table_name LIKE '%merma%' OR table_name LIKE '%batch%' OR table_name LIKE '%production%')
        ORDER BY table_name
    ");
    foreach ($production_tables as $table) {
        echo $table->table_name . PHP_EOL;
    }
    
    // Get purchasing related tables
    echo PHP_EOL . "PURCHASING RELATED TABLES:" . PHP_EOL;
    $purchasing_tables = DB::connection('pgsql')->select("
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'selemti'
        AND (table_name LIKE '%compra%' OR table_name LIKE '%purchase%' OR table_name LIKE '%requisition%' OR table_name LIKE '%receiving%' OR table_name LIKE '%solicitud%' OR table_name LIKE '%proveedor%' OR table_name LIKE '%cotizacion%' OR table_name LIKE '%replenish%' OR table_name LIKE '%reorder%')
        ORDER BY table_name
    ");
    foreach ($purchasing_tables as $table) {
        echo $table->table_name . PHP_EOL;
    }
    
    // Check the columns for production tables
    echo PHP_EOL . "PRODUCTION TABLES COLUMNS:" . PHP_EOL;
    foreach ($production_tables as $table) {
        echo PHP_EOL . "=== {$table->table_name} ===" . PHP_EOL;
        try {
            $columns = DB::connection('pgsql')->select("
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'selemti' AND table_name = ?
                ORDER BY ordinal_position
            ", [$table->table_name]);
            
            foreach ($columns as $col) {
                $nullable = $col->is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
                $default = $col->column_default ? ' DEFAULT ' . $col->column_default : '';
                echo sprintf("  %s %s %s%s", $col->column_name, $col->data_type, $nullable, $default) . PHP_EOL;
            }
        } catch (Exception $e) {
            echo "  Table {$table->table_name} not found or error: " . $e->getMessage() . PHP_EOL;
        }
    }
    
    // Check the columns for purchasing tables
    echo PHP_EOL . "PURCHASING TABLES COLUMNS:" . PHP_EOL;
    foreach ($purchasing_tables as $table) {
        echo PHP_EOL . "=== {$table->table_name} ===" . PHP_EOL;
        try {
            $columns = DB::connection('pgsql')->select("
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'selemti' AND table_name = ?
                ORDER BY ordinal_position
            ", [$table->table_name]);
            
            foreach ($columns as $col) {
                $nullable = $col->is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
                $default = $col->column_default ? ' DEFAULT ' . $col->column_default : '';
                echo sprintf("  %s %s %s%s", $col->column_name, $col->data_type, $nullable, $default) . PHP_EOL;
            }
        } catch (Exception $e) {
            echo "  Table {$table->table_name} not found or error: " . $e->getMessage() . PHP_EOL;
        }
    }
    
    echo PHP_EOL . "Database schema analysis completed." . PHP_EOL;

} catch (Exception $e) {
    echo "Database connection error: " . $e->getMessage() . PHP_EOL;
}