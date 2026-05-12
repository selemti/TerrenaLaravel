<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$cols = DB::connection('pgsql')->select("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = 'inv_consumo_pos'");
echo "COLS FOR selemti.inv_consumo_pos:\n";
foreach ($cols as $c) {
    echo "{$c->column_name}: {$c->data_type}\n";
}
echo "\nCOLS FOR public.ticket (in POS if possible, or mapping):\n";
try {
   $cols_pos = DB::connection('pos_pg')->select("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ticket'");
   foreach ($cols_pos as $c) {
       echo "{$c->column_name}: {$c->data_type}\n";
   }
} catch(\Exception $e) {}
