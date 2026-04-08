<?php
/**
 * Final analysis using correct discount amounts from database
 */

echo "=== ANÁLISIS FINAL CON DESCUENTOS CORRECTOS ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// 1. Items totales del 16/12/2025
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

echo "1. ITEMS TOTALES:\n";
echo "================\n";
echo "Items totales: \${$itemsTotal}\n\n";

// 2. Descuentos del 16/12/2025 (usando los valores correctos de la consulta anterior)
$itemDiscountsTotal = 8.8;  // De la consulta anterior - solo un item con descuento
$ticketDiscountsTotal = 68;  // Solo ticket 46291 con descuento

echo "2. DESCUENTOS CORRECTOS:\n";
echo "========================\n";
echo "Descuentos items (solo Quesadilla ticket 46290): \${$itemDiscountsTotal}\n";
echo "Descuentos tickets (solo ticket 46291): \${$ticketDiscountsTotal}\n\n";

// 3. Cálculo correcto
$netItems = $itemsTotal - $itemDiscountsTotal;  // Items después de descuentos individuales
$finalTotal = $netItems - $ticketDiscountsTotal;  // Total final después de todos los descuentos

echo "3. CÁLCULO CORRECTO:\n";
echo "===================\n";
echo "Items totales: \${$itemsTotal}\n";
echo "Menos descuentos items: \${$itemDiscountsTotal}\n";
echo "Net items: \${$netItems}\n";
echo "Menos descuentos tickets: \${$ticketDiscountsTotal}\n";
echo "Total final: \${$finalTotal}\n\n";

// 4. Comparación con Floreant
$floreantTotal = 631.00;
echo "4. COMPARACIÓN CON FLOREANT:\n";
echo "============================\n";
echo "Total calculado: \${$finalTotal}\n";
echo "Total Floreant: \${$floreantTotal}\n";
$difference = $finalTotal - $floreantTotal;
echo "Diferencia: \${$difference}\n\n";

// 5. Verificación detallada
echo "5. VERIFICACIÓN DETALLADA:\n";
echo "==========================\n";

// Verificar tickets específicos
$sqlTickets = "
SELECT t.id, t.total_price, t.total_discount,
       SUM(ti.total_price) as items_sum,
       COUNT(ti.id) as items_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
GROUP BY t.id, t.total_price, t.total_discount
ORDER BY t.id
";

$stmt = $pdo->query($sqlTickets);
$tickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Tickets del día:\n";
foreach ($tickets as $ticket) {
    echo "- Ticket {$ticket['id']}: Items=\${$ticket['items_sum']}, Discount=\${$ticket['total_discount']}, Total=\${$ticket['total_price']}\n";
}

echo "\n6. ANÁLISIS DE TICKET 46291 (100% DESCUENTO):\n";
echo "==============================================\n";

$sql46291 = "
SELECT ti.item_name, ti.item_count, ti.item_price, ti.total_price, ti.discount,
       t.id as ticket_id, t.total_price as ticket_total, t.total_discount as ticket_discount
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE t.id = 46291
";

$stmt = $pdo->query($sql46291);
$items46291 = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($items46291 as $item) {
    echo "- {$item['item_name']}: {$item['item_count']} x \${$item['item_price']} = \${$item['total_price']}\n";
}

echo "\nTicket 46291 total: Items=\${$tickets[7]['items_sum']}, Discount=\${$tickets[7]['total_discount']}, Final=\${$tickets[7]['total_price']}\n";

// 7. Cálculo alternativo: ¿Qué pasa si sumamos los tickets tal como están?
$sqlTicketSum = "
SELECT SUM(total_price) as tickets_sum
FROM public.ticket
WHERE DATE(folio_date) = '2025-12-16'
  AND paid = true
  AND voided = false
";

$stmt = $pdo->query($sqlTicketSum);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$ticketsSum = $result['tickets_sum'];

echo "\n7. SUMA DIRECTA DE TICKETS:\n";
echo "===========================\n";
echo "Suma directa de ticket.total_price: \${$ticketsSum}\n";
$difference_tickets = $ticketsSum - $floreantTotal;
echo "Diferencia con Floreant: \${$difference_tickets}\n\n";

// 8. Conclusión final
echo "=== CONCLUSIÓN FINAL ===\n";
echo "=======================\n";
echo "Floreant muestra Items Grand Total: \${$floreantTotal}\n";
echo "Nuestro cálculo muestra: \${$finalTotal}\n";
echo "Diferencia: \${$difference}\n\n";

if (abs($difference) < 1) {
    echo "¡COINCIDE! Los cálculos son correctos.\n";
} else {
    echo "Aún hay una discrepancia. Floreant debe tener una lógica diferente.\n";
    echo "Posibles causas:\n";
    echo "1. Floreant excluye items con precio unitario = 0\n";
    echo "2. Floreant aplica redondeo diferente\n";
    echo "3. Floreant tiene filtros adicionales por categoría o tipo de item\n";
}

$pdo = null;
?>