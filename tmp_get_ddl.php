<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

try {
    $result = DB::connection('pgsql')->select("SELECT pg_get_functiondef('selemti.fn_expandir_consumo_ticket'::regproc) as ddl");
    echo $result[0]->ddl;
} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage();
}
