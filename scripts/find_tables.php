<?php

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

// Buscar tablas relacionadas con transacciones y pagos
$tables = DB::connection('pgsql')->select("
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND (
        table_name LIKE '%payment%' 
        OR table_name LIKE '%trans%'
        OR table_name LIKE '%cash%'
    )
    ORDER BY table_name
");

echo "Tablas relacionadas con pagos/transacciones:\n";
echo str_repeat("-", 50) . "\n";
foreach ($tables as $table) {
    echo $table->table_name . "\n";
}

// Buscar drawer_pull_report
echo "\n\nBuscar tablas drawer:\n";
echo str_repeat("-", 50) . "\n";
$drawer_tables = DB::connection('pgsql')->select("
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%drawer%'
");

foreach ($drawer_tables as $table) {
    echo $table->table_name . "\n";
}

// Ver todas las tablas en public
echo "\n\nTodas las tablas en public schema:\n";
echo str_repeat("-", 50) . "\n";
$all_tables = DB::connection('pgsql')->select("
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    ORDER BY table_name
    LIMIT 50
");

foreach ($all_tables as $table) {
    echo $table->table_name . "\n";
}
