<?php
/**
 * Debug the $41.20 difference in items total
 */

echo "=== ANÁLISIS DE LA DIFERENCIA DE $41.20 ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// 1. Obtener todos los items del 16/12
$sql = "
SELECT
    t.id as ticket_id,
    t.total_price as ticket_total,
    t.total_discount as ticket_discount,
    ti.id as ticket_item_id,
    ti.item_name,
    ti.item_count,
    ti.item_price,
    ti.total_price,
    ti.discount
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
ORDER BY t.id, ti.id
";

$stmt = $pdo->query($sql);
$items = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "TODOS LOS ITEMS (pagados + no anulados):\n";
echo "=====================================\n";
$totalItems = 0;
$totalExpected = 0;

foreach ($items as $item) {
    echo "Ticket {$item['ticket_id']}, Item {$item['ticket_item_id']}: {$item['item_name']}\n";
    echo "  - Cantidad: {$item['item_count']}, Precio: \${$item['item_price']}\n";
    echo "  - Total Item: \$" . $item['total_price'] . ", Descuento: \$" . $item['discount'] . "\n";
    echo "  - Ticket Total: \$" . $item['ticket_total'] . ", Ticket Discount: \$" . $item['ticket_discount'] . "\n";
    echo "\n";

    $totalItems += $item['total_price'];
}

echo "Total de items calculado: \$" . $totalItems . "\n";
echo "Total esperado según Floreant: \$631.00\n";
echo "Diferencia: \$" . ($totalItems - 631.00) . "\n\n";

// 2. Excluir ticket con 100% descuento
$sqlExcluding100 = "
SELECT SUM(ti.total_price) as items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price != 0  -- Excluir ticket con 100% descuento
";

$stmt = $pdo->query($sqlExcluding100);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$totalExcluding100 = $result['items_total'];

echo "Excluyendo ticket con 100% descuento:\n";
echo "=====================================\n";
echo "Total de items: \$" . $totalExcluding100 . "\n";
echo "Esperado según Floreant: \$631.00\n";
echo "Diferencia: \$" . ($totalExcluding100 - 631.00) . "\n\n";

// 3. Buscar tickets específicos que podrían estar afectando
echo "ANÁLISIS POR TICKET:\n";
echo "===================\n";

$ticketTotals = [];
foreach ($items as $item) {
    if (!isset($ticketTotals[$item['ticket_id']])) {
        $ticketTotals[$item['ticket_id']] = [
            'ticket_total' => 0,
            'items_total' => 0,
            'ticket_discount' => 0,
            'items_discount' => 0
        ];
    }

    $ticketTotals[$item['ticket_id']]['items_total'] += $item['total_price'];
    $ticketTotals[$item['ticket_id']]['items_discount'] += $item['discount'];
    $ticketTotals[$item['ticket_id']]['ticket_total'] = $item['ticket_total'];
    $ticketTotals[$item['ticket_id']]['ticket_discount'] = $item['ticket_discount'];
}

foreach ($ticketTotals as $ticketId => $data) {
    echo "Ticket {$ticketId}:\n";
    echo "  - Ticket Total: \${$data['ticket_total']}\n";
    echo "  - Items Total: \${$data['items_total']}\n";
    echo "  - Ticket Discount: \${$data['ticket_discount']}\n";
    echo "  - Items Discount: \${$data['items_discount']}\n";

    if ($data['ticket_total'] == 0 && $data['ticket_discount'] > 0) {
        echo "  *** ESTE ES EL TICKET CON 100% DESCUENTO ***\n";
    }
    echo "\n";
}

// 4. Verificar si hay tickets duplicados o problemas
echo "VERIFICACIÓN DE INTEGRIDAD:\n";
echo "=========================\n";

$ticketCount = count($ticketTotals);
$itemsCount = count($items);

echo "Tickets únicos: {$ticketCount}\n";
echo "Items totales: {$itemsCount}\n";

if ($ticketCount == 8 && $itemsCount > 20) {
    echo "✓ Número correcto de tickets\n";
} else {
    echo "❌ Posibles problemas con tickets o items duplicados\n";
}

echo "\n=== CONCLUSIÓN ===\n";
if ($totalExcluding100 == 631) {
    echo "🎉 El problema era el ticket con 100% descuento!\n";
    echo "Floreant POS excluye automáticamente tickets con 100% descuento\n";
    echo "de los cálculos de 'Items Grand Total'.\n";
} else {
    echo "❌ Aún hay discrepancias. Necesito investigar más.\n";
}

$pdo = null;