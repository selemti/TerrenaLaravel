<?php
require_once __DIR__.'/vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

// Laravel bootstrap
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Get table information
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

echo "Fetching table structures for inventory tables in selemti schema...\n\n";

foreach ($tables as $table) {
    $fullTableName = "selemti.{$table}";
    
    if (Schema::connection('pgsql')->hasTable($fullTableName)) {
        echo "## Table: selemti.{$table}\n\n";
        
        // Get columns
        $columns = DB::select("SELECT column_name, data_type, is_nullable, column_default, ordinal_position 
                              FROM information_schema.columns 
                              WHERE table_schema = 'selemti' 
                              AND table_name = ? 
                              ORDER BY ordinal_position", [$table]);
        
        echo "### Columns\n\n";
        echo "| Column Name | Data Type | Nullable | Default |\n";
        echo "|-------------|-----------|----------|---------|\n";
        
        foreach ($columns as $column) {
            $nullable = $column->is_nullable === 'YES' ? 'Yes' : 'No';
            $default = $column->column_default ?: 'NULL';
            echo "| {$column->column_name} | {$column->data_type} | {$nullable} | {$default} |\n";
        }
        
        // Get foreign keys
        $foreignKeys = DB::select("
            SELECT 
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM information_schema.table_constraints AS tc
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
                AND tc.table_schema = 'selemti'
                AND tc.table_name = ?
        ", [$table]);
        
        if (!empty($foreignKeys)) {
            echo "\n### Foreign Keys\n\n";
            foreach ($foreignKeys as $fk) {
                echo "- {$fk->column_name} → selemti.{$fk->foreign_table_name}.{$fk->foreign_column_name}\n";
            }
        }
        
        // Get indexes
        $indexes = DB::select("
            SELECT 
                i.relname AS index_name,
                a.attname AS column_name,
                am.amname AS algorithm,
                indisunique AS is_unique
            FROM pg_class t,
                 pg_class i,
                 pg_index ix,
                 pg_attribute a,
                 pg_am am
            WHERE t.oid = ix.indrelid
                AND i.oid = ix.indexrelid
                AND a.attrelid = t.oid
                AND a.attnum = ANY(ix.indkey)
                AND t.relkind = 'r'
                AND am.oid = i.relam
                AND t.relname = ?
                AND i.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'selemti')
            ORDER BY t.relname, i.relname
        ", [$table]);
        
        if (!empty($indexes)) {
            echo "\n### Indexes\n\n";
            foreach ($indexes as $index) {
                $unique = $index->is_unique ? ' (unique)' : '';
                echo "- {$index->index_name}: {$index->column_name}{$unique}\n";
            }
        }
        
        echo "\n---\n\n";
    } else {
        echo "Table selemti.{$table} does not exist\n\n";
    }
}