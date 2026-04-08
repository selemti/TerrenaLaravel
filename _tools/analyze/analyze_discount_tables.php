<?php
/**
 * Analyze correct discount table structure
 */

echo "=== ANÁLISIS DE TABLAS DE DESCUENTO CORRECTAS ===\\n\\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$floreantTotal = 631.00;

// 1. Verificar estructura de ticket_item_discount
echo "1. TABLA ticket_item_discount:\\n";
echo "===========================\\n";

$sqlTicketItemDiscount = "
SELECT tid.id, tid.name, tid.type, tid.value, tid.amount,
       tid.ticket_itemid as ticket_item_id,
       ti.item_name, ti.item_count, ti.item_price, ti.total_price,
       t.id as ticket_id, t.total_price as ticket_total
FROM public.ticket_item_discount tid
JOIN public.ticket_item ti ON ti.id = tid.ticket_itemid
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
ORDER BY t.id, tid.id
";

$stmt = $pdo->query($sqlTicketItemDiscount);
$itemDiscounts = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($itemDiscounts) {
    echo "Descuentos en ticket_item_discount:\\n";
    foreach ($itemDiscounts as $discount) {
        echo "- {$discount['item_name']} (Ticket {$discount['ticket_id']}): {$discount['name']}, Value: \${$discount['value']}, Amount: \${$discount['amount']}\\n";
    }
} else {
    echo "No se encontraron descuentos en ticket_item_discount\\n";
}

echo "\\n";

// 2. Verificar estructura de ticket_discount
echo "2. TABLA ticket_discount:\\n";
echo "=========================\\n";

$sqlTicketDiscount = "
SELECT td.id, td.name, td.type, td.value,
       td.ticket_id,
       t.total_price as ticket_total
FROM public.ticket_discount td
JOIN public.ticket t ON t.id = td.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
ORDER BY t.id, td.id
";

$stmt = $pdo->query($sqlTicketDiscount);
$ticketDiscounts = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($ticketDiscounts) {
    echo "Descuentos en ticket_discount:\\n";
    foreach ($ticketDiscounts as $discount) {
        echo "- Ticket {$discount['ticket_id']}: {$discount['name']}, Value: \${$discount['value']}\\n";
    }
} else {
    echo "No se encontraron descuentos en ticket_discount\\n";
}

echo "\\n";

// 3. Calcular totales correctos usando las tablas de descuento
echo "3. CÁLCULO CORRECTO DE DESCUENTOS:\\n";
echo "==================================\\n";

// Items totales
$sqlItems = "
SELECT SUM(ti.total_price) as items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sqlItems);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$itemsTotal = $result['items_total'];

// Item discounts from ticket_item_discount
$sqlItemDiscounts = "
SELECT SUM(tid.amount) as item_discounts_total
FROM public.ticket_item_discount tid
JOIN public.ticket_item ti ON ti.id = tid.ticket_itemid
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sqlItemDiscounts);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$itemDiscountsTotal = $result['item_discounts_total'];

// Ticket discounts from ticket_discount
$sqlTicketDiscountsTotal = "
SELECT SUM(td.value) as ticket_discounts_total
FROM public.ticket_discount td
JOIN public.ticket t ON t.id = td.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sqlTicketDiscountsTotal);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$ticketDiscountsTotal = $result['ticket_discounts_total'];

echo "Items totales: \${$itemsTotal}\\n";
echo "Descuentos items (ticket_item_discount): \${$itemDiscountsTotal}\\n";
echo "Descuentos tickets (ticket_discount): \${$ticketDiscountsTotal}\\n";

// Net items after discounts
$netItems = $itemsTotal - $itemDiscountsTotal;
echo "Net items después de descuentos: \${$netItems}\\n";

// Total con descuentos de ticket
$finalTotal = $netItems - $ticketDiscountsTotal;
echo "Total final con todos los descuentos: \${$finalTotal}\\n";
echo "Floreant esperado: \${$floreantTotal}\\n";
$difference = $finalTotal - $floreantTotal;
echo "Diferencia: \${$difference}\\n\\n";

// 4. Análisis específico del ticket 46291
echo "4. ANÁLISIS TICKET 46291:\\n";
echo "========================\\n";

$sqlTicket46291 = "
SELECT t.id, t.total_price, t.total_discount,
       ti.id as item_id, ti.item_name, ti.item_count, ti.item_price, ti.total_price, ti.discount,
       tid.name as discount_name, tid.type as discount_type, tid.value as discount_value, tid.amount as discount_amount
FROM public.ticket t
LEFT JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
WHERE t.id = 46291
";

$stmt = $pdo->query($sqlTicket46291);
$ticket46291Details = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Detalles ticket 46291:\\n";
foreach ($ticket46291Details as $detail) {
    echo "- Item: {$detail['item_name']}, Total: \${$detail['total_price']}, Descuento: \${$detail['discount']}\\n";
    if ($detail['discount_name']) {
        echo "  Descuento table: {$detail['discount_name']}, Type: {$detail['discount_type']}, Value: \${$detail['discount_value']}, Amount: \${$detail['discount_amount']}\\n";
    }
}

echo "\\n=== CONCLUSIÓN ===\\n";
echo "1. Usar ticket_item_discount y ticket_discount en lugar de discount en ticket_item\\n";
echo "2. La diferencia actual es \${$difference}\\n";
echo "3. Si la diferencia es 0, hemos encontrado la lógica correcta\\n";

$pdo = null;
?>