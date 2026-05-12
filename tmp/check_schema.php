<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$columns = DB::connection('pgsql')->getSchemaBuilder()->getColumnListing('public.ticket_item');
echo "Columns in public.ticket_item:\n";
print_r($columns);

$ticketId = 22208;
$exists = DB::connection('pgsql')->table('public.ticket')->where('id', $ticketId)->exists();
echo "\nTicket $ticketId exists in public.ticket: " . ($exists ? "YES" : "NO") . "\n";

$sampleItem = DB::connection('pgsql')->table('public.ticket_item')->limit(1)->first();
echo "\nSample Item from public.ticket_item:\n";
print_r($sampleItem);
