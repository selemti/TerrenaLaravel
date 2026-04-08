<?php
// Script to connect to the database and get schema information

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
    
    // Get tables in selemti schema
    echo PHP_EOL . "SELEMTI SCHEMA TABLES:" . PHP_EOL;
    $selemti_tables = DB::connection('pgsql')->select("
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'selemti'
        ORDER BY table_name
    ");
    foreach ($selemti_tables as $table) {
        echo "- " . $table->table_name . PHP_EOL;
    }
    
    // Get tables in public schema  
    echo PHP_EOL . "PUBLIC SCHEMA TABLES:" . PHP_EOL;
    $public_tables = DB::connection('pgsql')->select("
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        ORDER BY table_name
    ");
    foreach ($public_tables as $table) {
        echo "- " . $table->table_name . PHP_EOL;
    }
    
    // Get columns for key inventory tables
    echo PHP_EOL . "KEY INVENTORY TABLES COLUMNS:" . PHP_EOL;
    $key_tables = ['mov_inv', 'stock', 'recepcion', 'recepcion_det', 'transfer_cab', 'transfer_det', 'hist_cost_insumo', 'stock_policy'];
    
    foreach ($key_tables as $table) {
        echo PHP_EOL . "=== {$table} ===" . PHP_EOL;
        try {
            $columns = DB::connection('pgsql')->select("
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'selemti' AND table_name = ?
                ORDER BY ordinal_position
            ", [$table]);
            
            foreach ($columns as $col) {
                $nullable = $col->is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
                $default = $col->column_default ? ' DEFAULT ' . $col->column_default : '';
                echo sprintf("  %s %s %s%s", $col->column_name, $col->data_type, $nullable, $default) . PHP_EOL;
            }
        } catch (Exception $e) {
            echo "  Table {$table} not found or error: " . $e->getMessage() . PHP_EOL;
        }
    }
    
    // Get columns for key recipe tables
    echo PHP_EOL . "KEY RECIPE TABLES COLUMNS:" . PHP_EOL;
    $recipe_tables = ['receta', 'receta_version', 'receta_insumo', 'pos_map'];
    
    foreach ($recipe_tables as $table) {
        echo PHP_EOL . "=== {$table} ===" . PHP_EOL;
        try {
            $columns = DB::connection('pgsql')->select("
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'selemti' AND table_name = ?
                ORDER BY ordinal_position
            ", [$table]);
            
            foreach ($columns as $col) {
                $nullable = $col->is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
                $default = $col->column_default ? ' DEFAULT ' . $col->column_default : '';
                echo sprintf("  %s %s %s%s", $col->column_name, $col->data_type, $nullable, $default) . PHP_EOL;
            }
        } catch (Exception $e) {
            echo "  Table {$table} not found or error: " . $e->getMessage() . PHP_EOL;
        }
    }
    
    // Get columns for key POS tables
    echo PHP_EOL . "KEY POS TABLES COLUMNS:" . PHP_EOL;
    $pos_tables = ['ticket', 'ticket_item', 'menu_item', 'menu_group', 'transactions', 'terminal'];
    
    foreach ($pos_tables as $table) {
        echo PHP_EOL . "=== {$table} (public schema) ===" . PHP_EOL;
        try {
            $columns = DB::connection('pgsql')->select("
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = ?
                ORDER BY ordinal_position
            ", [$table]);
            
            foreach ($columns as $col) {
                $nullable = $col->is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
                $default = $col->column_default ? ' DEFAULT ' . $col->column_default : '';
                echo sprintf("  %s %s %s%s", $col->column_name, $col->data_type, $nullable, $default) . PHP_EOL;
            }
        } catch (Exception $e) {
            echo "  Table {$table} not found or error: " . $e->getMessage() . PHP_EOL;
        }
    }
    
    echo PHP_EOL . "Database schema analysis completed." . PHP_EOL;

} catch (Exception $e) {
    echo "Database connection error: " . $e->getMessage() . PHP_EOL;
}