<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

print_r(DB::connection('pgsql')->select("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = 'inv_consumo_pos_det'"));
