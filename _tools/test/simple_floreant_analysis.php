<?php
/**
 * Simple analysis to understand Floreant discrepancy
 */

echo "=== ANÁLISIS SIMPLE DE FLOREANT ===\\n\\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$floreantTotal = 631.00;

// 1. Query exacto del reporte Floreant (basado en el texto)
$sql = "
SELECT ti.item_name, SUM(ti.total_price) as total, COUNT(*) as count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
GROUP BY ti.item_name
ORDER BY total DESC
";

$stmt = $pdo->query($sql);
$items = $stmt->fetchAll(PDO::FETCH_ASSOC);

$sqlTotal = 0;
echo "Items SQL:\\n";
echo "==========\\n";
foreach ($items as $item) {
    echo "{$item['item_name']}: \${$item['total']} ({$item['count']} registros)\\n";
    $sqlTotal += $item['total'];
}

echo "\\nTotal SQL: \${$sqlTotal}\\n";
echo "Floreant esperado: \${$floreantTotal}\\n";
$difference = $sqlTotal - $floreantTotal;
echo "Diferencia: \${$difference}\\n";

// 2. Verificar ticket por ticket
echo "\\n\\nAnálisis por ticket:\\n";
echo "===================\\n";

$sqlTickets = "
SELECT t.id, t.total_price as ticket_total, t.total_discount as ticket_discount,
       COUNT(ti.id) as items_count,
       SUM(ti.total_price) as items_total
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
$ticketsSqlTotal = 0;
foreach ($tickets as $ticket) {
    $status = "";
    if ($ticket['ticket_total'] == 0 && $ticket['ticket_discount'] > 0) {
        $status = " [100% DESCUENTO]";
    }

    echo "Ticket {$ticket['id']}: Total=\${$ticket['ticket_discount']}, Items=\${$ticket['items_total']}, Count={$ticket['items_count']}{$status}\\n";
    $ticketsSqlTotal += $ticket['items_total'];
}

echo "\\nTotal desde tickets: \${$ticketsSqlTotal}\\n";

// 3. Intentar encontrar la lógica exacta
echo "\\n\\nBuscando patrones:\\n";
echo "==================\\n";

// ¿Qué pasa si excluimos el ticket 46291 completamente?
$excludedTicket46291 = false;
$sqlWithout46291 = "
SELECT SUM(ti.total_price) as total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.id != 46291
";

$stmt = $pdo->query($sqlWithout46291);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$totalWithout46291 = $result['total'];

echo "Sin ticket 46291: \${$totalWithout46291}\\n";
$differenceWithout46291 = $totalWithout46291 - $floreantTotal;
echo "Diferencia con Floreant: \${$differenceWithout46291}\\n";

// 4. Check if there's a specific issue with certain item types
$sqlCheckItems = "
SELECT ti.item_name, ti.item_price, ti.total_price, ti.discount,
       t.id as ticket_id, t.total_price as ticket_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND (ti.item_price * ti.item_count) != ti.total_price
ORDER BY ti.item_name, ticket_id
";

$stmt = $pdo->query($sqlCheckItems);
$mismatched = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($mismatched) {
    echo "\\nItems con cálculo anómalo:\\n";
    foreach ($mismatched as $item) {
        $expected = $item['item_price'] * $item['item_count'];
        echo "- {$item['item_name']} (Ticket {$item['ticket_id']}): Expected \${$expected}, Actual \${$item['total_price']}, Discount \${$item['discount']}\\n";
    }
} else {
    echo "\\nNo hay items con cálculo anómalo.\\n";
}

// 5. Conclusión
echo "\\n\\n=== CONCLUSIÓN ===\\n";
echo "SQL total: \${$sqlTotal}\\n";
echo "Floreant total: \${$floreantTotal}\\n";
echo "Diferencia: \${$difference}\\n";

if ($difference > 0) {
    echo "SQL muestra \${$difference} más que Floreant.\\n";
    echo "Esto significa que Floreant está excluyendo items que SQL incluye.\\n";
} elseif ($difference < 0) {
    echo "SQL muestra \${$difference} menos que Floreant.\\n";
    echo "Esto significa que Floreant está incluyendo items que SQL excluye.\\n";
} else {
    echo "¡Los totales coinciden!\\n";
}

echo "\\nPosibles causas:\\n";
echo "1. Floreant usa una fecha diferente (closing_date vs folio_date)\\n";
echo "2. Floreant aplica filtros adicionales por tipo de item\\n";
echo "3. Floreant excluye tickets con 100% descuento\\n";
echo "4. Hay un error en la importación de datos\\n";

$pdo = null;
?>