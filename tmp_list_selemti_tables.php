<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$tables = DB::connection('pgsql')->select("SELECT table_name FROM information_schema.tables WHERE table_schema = 'selemti' ORDER BY table_name");
foreach ($tables as $t) {
    echo $t->table_name . PHP_EOL;
}
