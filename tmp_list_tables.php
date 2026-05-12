<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

function q($sql) {
    return DB::connection('pgsql')->select($sql);
}

echo "LISTING selemti TABLES/VIEWS:\n";
print_r(q("SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = 'selemti' ORDER BY table_name"));
