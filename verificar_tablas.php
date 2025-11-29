<?php
require_once 'vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Create a Laravel application instance
$app = require_once 'bootstrap/app.php';

// Set the application to handle HTTP requests
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

try {
    $tables = DB::connection('pgsql')->select("
        SELECT table_schema, table_name 
        FROM information_schema.tables 
        WHERE table_type = 'BASE TABLE' 
        AND table_schema IN ('public', 'selemti') 
        ORDER BY table_schema, table_name
    ");
    
    echo "Tablas actuales en la base de datos:\n";
    echo "=====================================\n";
    
    foreach ($tables as $table) {
        echo $table->table_schema . '.' . $table->table_name . "\n";
    }
    
    echo "\nTotal de tablas: " . count($tables) . "\n";
    
} catch (Exception $e) {
    echo "Error al conectar con la base de datos: " . $e->getMessage() . "\n";
}