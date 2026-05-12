<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

// Configure pos_pg connection
$base = config('database.connections.pgsql');
$host = env('POS_DB_HOST', env('DB_HOST', '127.0.0.1'));
if ($host === '127.0.0.1') $host = '172.24.240.1';
$base['host'] = $host;
$base['port'] = env('POS_DB_PORT', env('DB_PORT', '5432'));
$base['database'] = env('POS_DB_DATABASE', env('DB_DATABASE', 'pos'));
$base['username'] = env('POS_DB_USERNAME', env('DB_USERNAME', 'postgres'));
$base['password'] = env('POS_DB_PASSWORD', env('DB_PASSWORD', ''));
config(['database.connections.pos_pg' => $base]);

print_r(DB::connection('pos_pg')->select("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ticket_item'"));
