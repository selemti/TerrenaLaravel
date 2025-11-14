<?php

require __DIR__.'/../vendor/autoload.php';

$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Get ticket_item columns
$columns = DB::select("
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='ticket_item' 
    ORDER BY ordinal_position
");

echo "Columnas de public.ticket_item:\n";
echo str_repeat('=', 50)."\n";
foreach ($columns as $col) {
    echo "- {$col->column_name} ({$col->data_type})\n";
}
