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
config(['database.connections.pos_pg' => $base]);

$ticket = DB::connection('pos_pg')->table('public.ticket')->orderBy('id', 'desc')->first();
if ($ticket) {
    echo "TICKET FOUND: ID={$ticket->id}\n";
    $items = DB::connection('pos_pg')->table('public.ticket_item')->where('ticket_id', $ticket->id)->get();
    foreach ($items as $i) {
        echo "   -> ITEM: ID={$i->item_id} | NAME={$i->item_name}\n";
    }
} else {
    echo "NO TICKETS FOUND.\n";
}
