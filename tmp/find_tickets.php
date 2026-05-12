<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$tickets = DB::connection('pgsql')->table('public.ticket as t')
    ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
    ->where('t.total_discount', '>', 0)
    ->where('t.voided', false)
    ->select('t.id', 't.folio_date', 't.total_price', 't.total_discount')
    ->limit(10)
    ->get();

foreach ($tickets as $t) {
    echo "ID: {$t->id}, Date: {$t->folio_date}, Price: {$t->total_price}, Disc: {$t->total_discount}\n";
}
