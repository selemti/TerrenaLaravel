<?php
/**
 * Test exact Floreant POS queries to understand discrepancy
 */

echo "=== EJECUTANDO QUERIES EXACTOS DE FLOREANT ===\n\n";

// Conexión directa a PostgreSQL
try {
    $pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✓ Conexión a PostgreSQL establecida\n\n";
} catch (Exception $e) {
    echo "✗ Error de conexión: " . $e->getMessage() . "\n";
    exit;
}

// Función para ejecutar queries
function executeQuery($pdo, $sql, $label) {
    echo "--- $label ---\n";
    try {
        $stmt = $pdo->query($sql);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        foreach ($result as $key => $value) {
            echo "$key: $value\n";
        }
    } catch (Exception $e) {
        echo "✗ Error: " . $e->getMessage() . "\n";
    }
    echo "\n";
}

// 1. Items Grand Total (Floreant: $631.00)
$sql1 = "
SELECT SUM(ti.total_price) as items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

// 2. Modifiers Grand Total (Floreant: $50.00)
$sql2 = "
SELECT SUM(tim.total_price) as modifiers_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND tim.total_price > 0
";

// 3. Total Discounts (Floreant: $8.80)
$sql3 = "
SELECT SUM(COALESCE(ti.discount, 0)) as total_discounts
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

// 4. Tickets count
$sql4 = "
SELECT COUNT(DISTINCT t.id) as ticket_count
FROM public.ticket t
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

// 5. Debug: Ticket con 100% descuento
$sql5 = "
SELECT t.id, t.total_price, t.total_discount, COUNT(ti.id) as items_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price = 0
  AND t.total_discount > 0
GROUP BY t.id, t.total_price, t.total_discount
";

// Ejecutar todos los queries
echo "1. Items Grand Total (Floreant: $631.00)\n";
$stmt1 = $pdo->query($sql1);
$result1 = $stmt1->fetch(PDO::FETCH_ASSOC);
$itemsTotal = $result1['items_total'];
echo "Resultado: $" . number_format($itemsTotal, 2) . "\n\n";

echo "2. Modifiers Grand Total (Floreant: $50.00)\n";
$stmt2 = $pdo->query($sql2);
$result2 = $stmt2->fetch(PDO::FETCH_ASSOC);
$modifiersTotal = $result2['modifiers_total'];
echo "Resultado: $" . number_format($modifiersTotal, 2) . "\n\n";

echo "3. Total Discounts (Floreant: $8.80)\n";
$stmt3 = $pdo->query($sql3);
$result3 = $stmt3->fetch(PDO::FETCH_ASSOC);
$totalDiscounts = $result3['total_discounts'];
echo "Resultado: $" . number_format($totalDiscounts, 2) . "\n\n";

echo "4. Tickets Count\n";
$stmt4 = $pdo->query($sql4);
$result4 = $stmt4->fetch(PDO::FETCH_ASSOC);
$ticketCount = $result4['ticket_count'];
echo "Resultado: $ticketCount tickets\n\n";

echo "5. Tickets con 100% descuento\n";
$stmt5 = $pdo->query($sql5);
$discountTickets = $stmt5->fetchAll(PDO::FETCH_ASSOC);
if ($discountTickets) {
    foreach ($discountTickets as $ticket) {
        echo "Ticket {$ticket['id']}: Total \${$ticket['total_price']}, Discount \${$ticket['total_discount']}, Items: {$ticket['items_count']}\n";
    }
} else {
    echo "No se encontraron tickets con 100% descuento\n";
}
echo "\n";

// Cálculo de Net Sales
$netSales = ($itemsTotal - $totalDiscounts) + $modifiersTotal;

echo "=== COMPARACIÓN FINAL ===\n";
echo "Floreant TXT Report:\n";
echo "- Items: $631.00\n";
echo "- Modifiers: $50.00\n";
echo "- Discounts: $8.80\n";
echo "- Net Sales: $622.20\n\n";

echo "Mis cálculos actuales:\n";
echo "- Items: $" . number_format($itemsTotal, 2);
echo ($itemsTotal == 631) ? " ✓" : " ✗" . " (Esperado: 631)\n";
echo "- Modifiers: $" . number_format($modifiersTotal, 2);
echo ($modifiersTotal == 50) ? " ✓" : " ✗" . " (Esperado: 50)\n";
echo "- Discounts: $" . number_format($totalDiscounts, 2);
echo ($totalDiscounts == 8.8) ? " ✓" : " ✗" . " (Esperado: 8.8)\n";
echo "- Net Sales: $" . number_format($netSales, 2);
echo ($netSales == 622.2) ? " ✓" : " ✗" . " (Esperado: 622.2)\n\n";

if ($itemsTotal == 631 && $modifiersTotal == 50 && $totalDiscounts == 8.8 && $netSales == 622.2) {
    echo "🎉 TODO COINCIDE! Los cálculos son correctos.\n\n";
} else {
    echo "❌ Hay discrepancias. Necesito revisar la lógica.\n\n";

    echo "=== ANÁLISIS DE DISCREPANCIAS ===\n";

    if ($itemsTotal != 631) {
        echo "Diferencia en Items: $" . number_format(abs($itemsTotal - 631), 2) . "\n";
        echo "Posibles causas:\n";
        echo "- Tickets o items con diferentes condiciones\n";
        echo "- Problemas con las fechas o filtros\n";
        echo "- Diferencias en el cálculo de total_price\n\n";
    }

    if ($modifiersTotal != 50) {
        echo "Diferencia en Modifiers: $" . number_format(abs($modifiersTotal - 50), 2) . "\n";
        echo "Posibles causas:\n";
        echo "- Modificadores con condiciones diferentes\n";
        echo "- Problemas con la tabla ticket_item_modifier\n";
        echo "- Filtros adicionales aplicados por Floreant\n\n";
    }

    if ($totalDiscounts != 8.8) {
        echo "Diferencia en Discounts: $" . number_format(abs($totalDiscounts - 8.8), 2) . "\n";
        echo "Posibles causas:\n";
        echo "- Descuentos calculados de manera diferente\n";
        echo "- Orígenes de descuentos distintos (ticket vs item)\n\n";
    }
}

$pdo = null;