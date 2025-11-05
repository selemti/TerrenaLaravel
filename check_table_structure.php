<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Estructura de la tabla TICKET ===\n\n";
$columns = DB::connection('pgsql')->select("
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'ticket'
    ORDER BY ordinal_position
");

foreach ($columns as $col) {
    echo sprintf("%-30s %-20s %s\n", $col->column_name, $col->data_type, $col->is_nullable);
}

echo "\n\n=== Estructura de la tabla TICKET_ITEM ===\n\n";
$columnsItem = DB::connection('pgsql')->select("
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'ticket_item'
    ORDER BY ordinal_position
");

foreach ($columnsItem as $col) {
    echo sprintf("%-30s %-20s %s\n", $col->column_name, $col->data_type, $col->is_nullable);
}

echo "\n\n=== Estructura de la tabla TRANSACTIONS ===\n\n";
$columns2 = DB::connection('pgsql')->select("
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'transactions'
    ORDER BY ordinal_position
");

foreach ($columns2 as $col) {
    echo sprintf("%-30s %-20s %s\n", $col->column_name, $col->data_type, $col->is_nullable);
}
