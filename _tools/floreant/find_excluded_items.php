<?php
/**
 * Find exactly which items Floreant POS excludes
 */

echo "=== ANÁLISIS DETALLADO DE ITEMS EXCLUIDOS POR FLOREANT ===\\n\\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// 1. Obtener TODOS los items del 16/12 sin ningún filtro
$sqlAll = "
SELECT
    ti.id as ticket_item_id,
    ti.item_name,
    ti.item_count,
    ti.item_price,
    ti.total_price,
    ti.discount,
    t.id as ticket_id,
    t.total_price as ticket_total,
    t.total_discount as ticket_discount
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
ORDER BY ti.item_name, ti.total_price DESC
";

$stmt = $pdo->query($sqlAll);
$allItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "TODOS LOS ITEMS ({".count($allItems)."}):\\n";
echo "=============================\\n";
$totalAll = 0;
foreach ($allItems as $item) {
    echo "- {$item['item_name']}: {$item['item_count']} x \${$item['item_price']} = \${$item['total_price']} (Desc: \${$item['discount']})\\n";
    $totalAll += $item['total_price'];
}
echo "\\nTotal SQL: \${$totalAll}\\n\\n";

// 2. Items Floreant deberían ser $631.00
$floreantTotal = 631.00;
$difference = $totalAll - $floreantTotal;
echo "Diferencia: \${$difference}\\n\\n";

// 3. Buscar patrones de exclusión
echo "ANÁLISIS DE PATRONES DE EXCLUSIÓN:\\n";
echo "=================================\\n";

$itemsByPrice = [];
foreach ($allItems as $item) {
    if (!isset($itemsByPrice[$item['item_name']])) {
        $itemsByPrice[$item['item_name']] = [
            'total_price' => 0,
            'total_quantity' => 0,
            'count' => 0,
            'discount' => 0,
            'tickets' => []
        ];
    }
    $itemsByPrice[$item['item_name']]['total_price'] += $item['total_price'];
    $itemsByPrice[$item['item_name']]['total_quantity'] += $item['item_count'];
    $itemsByPrice[$item['item_name']]['count']++;
    $itemsByPrice[$item['item_name']]['discount'] += $item['discount'];
    $itemsByPrice[$item['item_name']]['tickets'][] = $item['ticket_id'];
}

// Ordenar por precio total descendente
uasort($itemsByPrice, function($a, $b) {
    return $b['total_price'] <=> $a['total_price'];
});

echo "Items ordenados por precio total:\\n";
$cumulative = 0;
foreach ($itemsByPrice as $itemName => $data) {
    echo "- {$itemName}: \${$data['total_price']} ({$data['total_quantity']} u, {$data['count']} registros)\\n";
    $cumulative += $data['total_price'];

    if ($cumulative <= $floreantTotal + 10) { // Allow small rounding
        echo "  -> Acumulado: \${$cumulative}\\n";
    }
}
echo "\\n";

// 4. Buscar tickets específicos que podrían estar filtrados
echo "ANÁLISIS POR TICKET:\\n";
echo "===================\\n";

$ticketAnalysis = [];
foreach ($allItems as $item) {
    $ticketId = $item['ticket_id'];
    if (!isset($ticketAnalysis[$ticketId])) {
        $ticketAnalysis[$ticketId] = [
            'ticket_total' => $item['ticket_total'],
            'ticket_discount' => $item['ticket_discount'],
            'items' => [],
            'items_total' => 0,
            'has_100_discount' => false
        ];
    }
    $ticketAnalysis[$ticketId]['items'][] = $item;
    $ticketAnalysis[$ticketId]['items_total'] += $item['total_price'];

    if ($item['ticket_total'] == 0 && $item['ticket_discount'] > 0) {
        $ticketAnalysis[$ticketId]['has_100_discount'] = true;
    }
}

foreach ($ticketAnalysis as $ticketId => $data) {
    echo "Ticket {$ticketId}:\\n";
    echo "  - Ticket Total: \${$data['ticket_total']}\\n";
    echo "  - Ticket Discount: \${$data['ticket_discount']}\\n";
    echo "  - Items Total: \${$data['items_total']}\\n";
    echo "  - 100% Discount: " . ($data['has_100_discount'] ? 'YES' : 'NO') . "\\n";

    // Si el ticket tiene 100% descuento, ver si Floreant lo excluye completamente
    if ($data['has_100_discount']) {
        echo "  *** FLOREANT POS PROBABLEMENTE EXCLUYE ESTE TICKET COMPLETO ***\\n";
    }
    echo "\\n";
}

// 5. Calcular cuál sería el total si excluimos el ticket con 100% descuento
$ticket46291 = $ticketAnalysis[46291] ?? null;
if ($ticket46291) {
    $totalWithout46291 = $totalAll - $ticket46291['items_total'];
    $differenceWithFloreant = $totalWithout46291 - $floreantTotal;
echo "Excluyendo ticket 46291: \${$totalWithout46291} (diferencia con Floreant: \${$differenceWithFloreant})\\n";
}

// 6. Probar teoría: Floreant podría estar incluyendo solo items con precio unitario > 0
echo "\\n6. TEORÍA: Items con precio unitario > 0:\\n";
echo "=========================================\\n";

$sqlPositivePrice = "
SELECT SUM(ti.total_price) as positive_price_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ti.item_price > 0
";

$stmt = $pdo->query($sqlPositivePrice);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$positivePriceTotal = $result['positive_price_total'];

echo "Items con precio unitario > 0: \${$positivePriceTotal}\\n";
$differencePositive = $positivePriceTotal - $floreantTotal;
echo "Diferencia con Floreant: \${$differencePositive}\\n\\n";

// 7. Buscar items con precios específicos que podrían ser filtrados
echo "7. ITEMS CON PRECIOS ANOMALOS:\\n";
echo "============================\\n";

$anomalies = [];
foreach ($allItems as $item) {
    if ($item['item_price'] == 0 || $item['item_price'] < 0) {
        $anomalies[] = $item;
    }
}

if ($anomalies) {
    foreach ($anomalies as $item) {
        echo "- {$item['item_name']}: Precio \${$item['item_price']}, Total \${$item['total_price']}\\n";
    }
} else {
    echo "No se encontraron items con precios <= 0\\n";
}

echo "\\n=== CONCLUSIÓN ===\\n";
echo "El problema es que Floreant POS tiene una lógica de filtrado específica\\\\n";
echo "que aún no hemos identificado. La diferencia de \\\\\${$difference} sugiere que\\\\n";
echo "Floreant está excluyendo ciertos items o tickets de su cálculo 'Items Grand Total'.\\\\n";

$pdo = null;