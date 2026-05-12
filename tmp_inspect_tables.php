<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

function q($sql) {
    return DB::connection('pgsql')->select($sql);
}

echo "CHECKING selemti.receta_det COLUMNS:\n";
print_r(q("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = 'receta_det'"));

echo "\nCHECKING selemti.modificadores_pos SAMPLE:\n";
print_r(q("SELECT * FROM selemti.modificadores_pos LIMIT 5"));

echo "\nCHECKING public.ticket_item_modifier COLUMNS:\n";
try {
    print_r(q("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ticket_item_modifier'"));
} catch (\Exception $e) {
    echo "ERROR (maybe named differently in Floreant): " . $e->getMessage();
}
