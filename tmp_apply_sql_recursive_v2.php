<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

try {
    $sql = file_get_contents(__DIR__ . '/tmp_update_fn_consumo_recursive_v2.sql');
    DB::connection('pgsql')->unprepared($sql);
    echo "SUCCESS: Recursive Function v2.1 Applied.";
} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage();
}
