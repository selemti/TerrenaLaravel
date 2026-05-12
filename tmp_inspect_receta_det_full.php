<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

function q($sql) {
    return DB::connection('pgsql')->select($sql);
}

echo "FULL COLUMNS FOR selemti.receta_det:\n";
print_r(q("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = 'receta_det' ORDER BY ordinal_position"));
