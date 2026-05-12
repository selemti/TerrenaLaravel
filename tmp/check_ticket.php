<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use App\Services\Finance\SalesResolutionService;

$service = app(SalesResolutionService::class);
$ticketId = 28326;

$ticket = DB::connection('pgsql')->table('public.ticket')->where('id', $ticketId)->first();
$discounts = DB::connection('pgsql')->table('public.ticket_discount')->where('ticket_id', $ticketId)->get();
$items = DB::connection('pgsql')->table('public.ticket_item')->where('ticket_id', $ticketId)->get();

echo "Ticket ID: $ticketId\n";
echo "Subtotal: {$ticket->sub_total}\n";
echo "Total Price: {$ticket->total_price}\n";
echo "Total Discount: {$ticket->total_discount}\n";

echo "\nTicket Discounts:\n";
foreach ($discounts as $d) {
    echo "Name: {$d->name}, Type: {$d->type}, Value: {$d->value}\n";
}

echo "\nTicket Items:\n";
foreach ($items as $i) {
    echo "ID: {$i->id}, Name: {$i->item_name}, Sub: {$i->sub_total}, Desc: {$i->discount}, Total: {$i->total_price}\n";
    
    $iDiscounts = DB::connection('pgsql')->table('public.ticket_item_discount')->where('ticket_itemid', $i->id)->get();
    foreach ($iDiscounts as $id) {
        echo "  - Item Discount: Name: {$id->name}, Type: {$id->type}, Value: {$id->value}, Amount: {$id->amount}\n";
    }
}

$res = $service->resolveNetLiquidation($ticketId);
echo "\nResolution:\n";
print_r($res);
