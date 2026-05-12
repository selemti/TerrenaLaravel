<?php
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;

Config::set('database.connections.pgsql_prod', [
    'driver' => 'pgsql',
    'host' => '100.126.124.101',
    'port' => '5432',
    'database' => env('DB_DATABASE', 'selemti'),
    'username' => env('DB_USERNAME', 'postgres'),
    'password' => env('DB_PASSWORD', ''),
    'charset' => 'utf8',
    'prefix' => '',
    'schema' => 'public',
    'sslmode' => 'prefer',
]);

$local_cols = DB::select("SELECT column_name FROM information_schema.columns WHERE table_schema='selemti' AND table_name='postcorte' ORDER BY column_name");
$prod_cols = DB::connection('pgsql_prod')->select("SELECT column_name FROM information_schema.columns WHERE table_schema='selemti' AND table_name='postcorte' ORDER BY column_name");

$local_arr = array_column($local_cols, 'column_name');
$prod_arr = array_column($prod_cols, 'column_name');

$diff1 = array_diff($local_arr, $prod_arr);
$diff2 = array_diff($prod_arr, $local_arr);

$q_fn = "SELECT pg_get_functiondef(p.oid) as def FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'selemti' AND p.proname = 'fn_generar_postcorte'";
$fn_local = DB::select($q_fn)[0]->def;
$fn_prod = DB::connection('pgsql_prod')->select($q_fn)[0]->def;

echo "=== RESULTADO DE VALIDACION ===" . PHP_EOL;
echo "Columnas extra en Local: " . implode(', ', $diff1) . (empty($diff1) ? "NINGUNA" : "") . PHP_EOL;
echo "Columnas extra en Prod: " . implode(', ', $diff2) . (empty($diff2) ? "NINGUNA" : "") . PHP_EOL;
echo "Diferencia Total Columnas: " . count($local_arr) . " vs " . count($prod_arr) . PHP_EOL;

if (strlen($fn_local) === strlen($fn_prod)) {
    echo "Funciones DDL: MATCH PERFECTO (" . strlen($fn_local) . " bytes)" . PHP_EOL;
} else {
    echo "Funciones DDL: DIVERGENTES (" . strlen($fn_local) . " vs " . strlen($fn_prod) . " bytes)" . PHP_EOL;
}
