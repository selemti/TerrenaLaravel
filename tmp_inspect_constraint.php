<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$res = DB::connection('pgsql')->select("SELECT pg_get_constraintdef(oid) as def FROM pg_constraint WHERE conname = 'mov_inv_tipo_check'");
if ($res) {
    echo $res[0]->def . PHP_EOL;
} else {
    echo "CONSTRAINT NOT FOUND.\n";
}
