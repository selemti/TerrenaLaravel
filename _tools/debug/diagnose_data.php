<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "DIAGNÓSTICO DE DATOS - 1 DE OCTUBRE 2025\n";
echo str_repeat('=', 80)."\n\n";

// Verificar cuántos tickets tenemos
$ticketCount = DB::connection('pgsql')->selectOne("
    SELECT COUNT(*) as total 
    FROM public.ticket 
    WHERE folio_date = '2025-10-01'
");
echo "Total de tickets en 2025-10-01: {$ticketCount->total}\n\n";

// Verificar cuántos ticket_items
$itemCount = DB::connection('pgsql')->selectOne("
    SELECT COUNT(*) as total 
    FROM public.ticket_item ti
    INNER JOIN public.ticket t ON t.id = ti.ticket_id
    WHERE t.folio_date = '2025-10-01'
");
echo "Total de ticket_items en 2025-10-01: {$itemCount->total}\n\n";

// Ver un ticket específico
$sample = DB::connection('pgsql')->select("
    SELECT 
        t.id as ticket_id,
        t.total_price,
        t.total_discount,
        t.sub_total,
        COUNT(ti.id) as num_items,
        SUM(ti.item_price * ti.item_quantity) as suma_items
    FROM public.ticket t
    LEFT JOIN public.ticket_item ti ON t.id = ti.ticket_id
    WHERE t.folio_date = '2025-10-01'
    AND t.id = 15480
    GROUP BY t.id
");

echo "Ticket #15480:\n";
print_r($sample);

// Ver los items de ese ticket
$items = DB::connection('pgsql')->select('
    SELECT 
        item_name,
        item_price,
        item_quantity,
        (item_price * item_quantity) as total
    FROM public.ticket_item
    WHERE ticket_id = 15480
');

echo "\nItems del ticket #15480:\n";
foreach ($items as $item) {
    echo sprintf("  %s: $%s x %s = $%s\n",
        $item->item_name,
        $item->item_price,
        $item->item_quantity,
        $item->total
    );
}
