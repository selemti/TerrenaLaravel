<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "LISTADO DE TABLAS EN PGSQL\n";
echo str_repeat("-", 40) . "\n";

$results = DB::connection('pgsql')->select("
    SELECT table_schema, table_name 
    FROM information_schema.tables 
    WHERE table_schema IN ('selemti', 'public')
    ORDER BY table_schema, table_name
");

foreach ($results as $row) {
    echo "{$row->table_schema}.{$row->table_name}\n";
}
