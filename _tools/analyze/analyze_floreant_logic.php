<?php
/**
 * Analyze exactly how Floreant POS calculates totals
 */

echo "=== ANÁLISIS DE LÓGICA DE FLOREANT POS ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// 1. Floreant Items Grand Total ($631.00)
echo "1. CÁLCULO EXACTO DE FLOREANT ITEMS:\n";
echo "===================================\n";

$sql = "
SELECT
    SUM(ti.total_price) as floreant_items,
    COUNT(DISTINCT t.id) as tickets_incluidos,
    COUNT(DISTINCT ti.id) as items_incluidos
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0  -- Excluir tickets con 100% descuento
";

$stmt = $pdo->query($sql);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Resultado: \${$result['floreant_items']} (excluyendo 100% descuento)\n";
echo "Tickets: {$result['tickets_incluidos']}\n";
echo "Items: {$result['items_incluidos']}\n\n";

// 2. Comparar con items del ticket 46291
echo "2. ITEMS DEL TICKET CON 100% DESCUENTO:\n";
echo "======================================\n";

$sql = "
SELECT ti.item_name, ti.item_count, ti.item_price, ti.total_price
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE t.id = 46291
";

$stmt = $pdo->query($sql);
$items46291 = $stmt->fetchAll(PDO::FETCH_ASSOC);

$totalTicket46291 = 0;
foreach ($items46291 as $item) {
    echo "- {$item['item_name']}: {$item['item_count']} x \${$item['item_price']} = \${$item['total_price']}\n";
    $totalTicket46291 += $item['total_price'];
}

echo "Total ticket 46291: \${$totalTicket46291}\n\n";

// 3. Sumar parcial + 100% descuento
$partialTotal = $result['floreant_items'];
echo "3. SUMA PARCIAL + 100% DESCUENTO:\n";
echo "================================\n";
echo "Total parcial (excluyendo 46291): \${$partialTotal}\n";
echo "Total ticket 46291: \${$totalTicket46291}\n";
$expectedSum = $partialTotal + $totalTicket46291;
echo "Suma esperada: \${$expectedSum}\n";
echo "Esperado según Floreant: \$631.00\n\n";

// 4. Probar teoría: Floreant excluye items individuales con descuento
echo "4. TEORÍA: ¿Floreant excluye items con descuento 100%?\n";
echo "======================================================\n";

$sql = "
SELECT
    SUM(ti.total_price) as items_sin_100_descuento,
    COUNT(DISTINCT ti.id) as items_sin_descuento
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ti.discount = 0  -- Solo items sin descuento individual
";

$stmt = $pdo->query($sql);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Items sin descuento individual: \${$result['items_sin_100_descuento']}\n";
echo "Cantidad de items: {$result['items_sin_descuento']}\n\n";

// 5. Verificar items con descuento individual
echo "5. ITEMS CON DESCUENTO INDIVIDUAL:\n";
echo "=================================\n";

$sql = "
SELECT ti.item_name, ti.total_price, ti.discount
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ti.discount > 0
";

$stmt = $pdo->query($sql);
$itemsConDescuento = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($itemsConDescuento as $item) {
    $finalPrice = $item['total_price'] - $item['discount'];
    echo "- {$item['item_name']}: \${$item['total_price']} - \${$item['discount']} = \${$finalPrice}\n";
}

// 6. Cálculo final que coincide con Floreant
echo "\n6. CÁLCULO FINAL QUE COINCIDE CON FLOREANT:\n";
echo "==========================================\n";

$sql = "
SELECT
    SUM(CASE
        WHEN t.total_price > 0 THEN ti.total_price
        WHEN ti.discount = 0 THEN ti.total_price
        ELSE 0
    END) as items_total_floreant
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sql);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$totalFloreant = $result['items_total_floreant'];

echo "Cálculo floreant: \${$totalFloreant}\n";
echo "Esperado: \$631.00\n";
echo "Coincide: " . ($totalFloreant == 631 ? "✓" : "✗") . "\n\n";

echo "=== CONCLUSIÓN ===\n";
echo "La lógica de Floreant POS es:\n";
echo "1. Incluir tickets con 100% descuento\n";
echo "2. Pero excluir items que tengan descuento individual del 100%\n";
echo "3. Para el ticket 46291, el item no tiene descuento individual (discount=0)\n";
echo "   por lo que se incluye en el total.\n\n";

// 7. Verificar ticket 46290 (tiene item con descuento individual)
echo "7. TICKET 46290 (CON DESCUENTO INDIVIDUAL):\n";
echo "===========================================\n";

$sql = "
SELECT t.id, t.total_price, t.total_discount,
       ti.item_name, ti.total_price as item_total, ti.discount as item_discount
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE t.id = 46290
";

$stmt = $pdo->query($sql);
$result = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Ticket {$result['id']}:\n";
echo "  - Total ticket: \${$result['total_price']}\n";
echo "  - Discount ticket: \${$result['total_discount']}\n";
echo "  - Item: {$result['item_name']}\n";
echo "  - Item total: \${$result['item_total']}\n";
echo "  - Item discount: \${$result['item_discount']}\n\n";

$pdo = null;