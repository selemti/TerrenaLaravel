<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

function q($sql, $params = []) {
    try {
        return DB::connection('pgsql')->select($sql, $params);
    } catch (\Exception $e) {
        return "ERROR: " . $e->getMessage();
    }
}

echo "CHECKING IF insumo CAN LINK TO receta:\n";
print_r(q("SELECT column_name FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = 'insumo' AND column_name LIKE '%receta%'"));

echo "\nCHECKING IF receta_cab CAN BE AN insumo:\n";
print_r(q("SELECT column_name FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = 'receta_cab' AND column_name LIKE '%insumo%'"));

echo "\nCHECKING cat_almacenes TO SEE TYPES OF STOCK:\n";
print_r(q("SELECT * FROM selemti.cat_almacenes"));
