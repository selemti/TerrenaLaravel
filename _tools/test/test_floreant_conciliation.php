<?php
/**
 * Test script to verify that the new "Conciliación Floreant" mode matches exactly with Floreant totals
 */

echo "=== TESTING CONCILIACIÓN FLOREANT MODE ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Floreant expected totals from the report
$floreantItems = 631.00;
$floreantModifiers = 50.00;
$floreantDiscounts = 8.80;
$floreantNet = 622.20;  // $631 - $8.80

echo "FLOREANT EXPECTED TOTALS:\n";
echo "========================\n";
echo "Items Grand Total: \${$floreantItems}\n";
echo "Modifiers Grand Total: \${$floreantModifiers}\n";
echo "Total Discounts: \${$floreantDiscounts}\n";
echo "Net Sales: \${$floreantNet}\n\n";

// Test 1: Strict mode (current default)
echo "1. STRICT MODE (pagado + no anulado):\n";
echo "====================================\n";

$sqlStrict = "
SELECT
    SUM(ti.total_price) as items_gross,
    SUM(COALESCE(tim.total_price, 0)) as modifiers_total,
    COALESCE(SUM(tid.amount), 0) + COALESCE(SUM(td.value), 0) as total_discounts,
    SUM(ti.total_price) + SUM(COALESCE(tim.total_price, 0)) as gross_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sqlStrict);
$resultStrict = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Items Gross: \${$resultStrict['items_gross']}\n";
echo "Modifiers: \${$resultStrict['modifiers_total']}\n";
echo "Discounts: \${$resultStrict['total_discounts']}\n";
echo "Gross Total: \${$resultStrict['gross_total']}\n\n";

// Test 2: Floreant Conciliation mode (new mode)
echo "2. FLOREANT CONCILIATION MODE (excluye total_price = 0):\n";
echo "========================================================\n";

$sqlConciliation = "
SELECT
    SUM(ti.total_price) as items_gross,
    SUM(COALESCE(tim.total_price, 0)) as modifiers_total,
    COALESCE(SUM(tid.amount), 0) + COALESCE(SUM(td.value), 0) as total_discounts,
    SUM(ti.total_price) + SUM(COALESCE(tim.total_price, 0)) as gross_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0  -- EXCLUDE TICKETS WITH TOTAL = 0
";

$stmt = $pdo->query($sqlConciliation);
$resultConciliation = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Items Gross: \${$resultConciliation['items_gross']}\n";
echo "Modifiers: \${$resultConciliation['modifiers_total']}\n";
echo "Discounts: \${$resultConciliation['total_discounts']}\n";
echo "Gross Total: \${$resultConciliation['gross_total']}\n\n";

// Compare results
echo "COMPARISON:\n";
echo "===========\n";

echo "Items Gross - Floreant: \${$floreantItems}, Conciliation: \${$resultConciliation['items_gross']}\n";
$differenceItems = $floreantItems - $resultConciliation['items_gross'];
echo "Items Gross Difference: \${$differenceItems}\n\n";

echo "Modifiers - Floreant: \${$floreantModifiers}, Conciliation: \${$resultConciliation['modifiers_total']}\n";
$differenceModifiers = $floreantModifiers - $resultConciliation['modifiers_total'];
echo "Modifiers Difference: \${$differenceModifiers}\n\n";

echo "Discounts - Floreant: \${$floreantDiscounts}, Conciliation: \${$resultConciliation['total_discounts']}\n";
$differenceDiscounts = $floreantDiscounts - $resultConciliation['total_discounts'];
echo "Discounts Difference: \${$differenceDiscounts}\n\n";

// Test 3: Check which tickets are excluded
echo "TICKETS EXCLUDED BY CONCILIATION MODE:\n";
echo "======================================\n";

$sqlExcludedTickets = "
SELECT t.id, t.folio_date, t.total_price, t.total_discount,
       COUNT(ti.id) as items_count,
       SUM(ti.total_price) as items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price = 0
GROUP BY t.id, t.folio_date, t.total_price, t.total_discount
ORDER BY t.id
";

$stmt = $pdo->query($sqlExcludedTickets);
$excludedTickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($excludedTickets) {
    echo "Tickets con total_price = 0 (excluidos en modo conciliación):\n";
    foreach ($excludedTickets as $ticket) {
        echo "- Ticket {$ticket['id']}: Items=\${$ticket['items_total']}, Discount=\${$ticket['total_discount']}, Final=\${$ticket['total_price']}\n";
    }
} else {
    echo "No se encontraron tickets excluidos.\n";
}

// Final verdict
echo "\nFINAL VERDICT:\n";
echo "==============\n";

$itemsMatch = abs($resultConciliation['items_gross'] - $floreantItems) < 0.01;
$modifiersMatch = abs($resultConciliation['modifiers_total'] - $floreantModifiers) < 0.01;
$discountsMatch = abs($resultConciliation['total_discounts'] - $floreantDiscounts) < 0.01;

if ($itemsMatch && $modifiersMatch && $discountsMatch) {
    echo "✅ SUCCESS: Conciliación Floreant mode matches Floreant totals exactly!\n";
    echo "   Items: ✅\n";
    echo "   Modifiers: ✅\n";
    echo "   Discounts: ✅\n";
} else {
    echo "❌ MISMATCH: Conciliación Floreant mode does not match Floreant totals\n";
    echo "   Items: " . ($itemsMatch ? "✅" : "❌") . "\n";
    echo "   Modifiers: " . ($modifiersMatch ? "✅" : "❌") . "\n";
    echo "   Discounts: " . ($discountsMatch ? "✅" : "❌") . "\n";
}

$pdo = null;
?>