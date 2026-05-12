<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

try {
    $sql = file_get_contents(__DIR__ . '/tmp_update_fn_consumo.sql');
    DB::connection('pgsql')->unprepared($sql);
    echo "SUCCESS: Function selemti.fn_expandir_consumo_ticket updated.";
} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage();
}
