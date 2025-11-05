<?php

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$tables = ['ticket', 'ticket_item', 'transactions', 'drawer_pull_report', 'custom_payment'];

foreach ($tables as $table) {
    $columns = DB::connection('pgsql')->select("
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = ? 
        ORDER BY ordinal_position
    ", [$table]);

    echo "\n" . str_repeat("=", 70) . "\n";
    echo "Columnas de la tabla: $table\n";
    echo str_repeat("=", 70) . "\n";
    foreach ($columns as $col) {
        echo sprintf("%-35s %s\n", $col->column_name, $col->data_type);
    }
}
