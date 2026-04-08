<?php
/**
 * Find the exact match for Floreant's calculation
 */

echo "=== FINDING EXACT FLOREANT MATCH ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Expected totals from Floreant
$floreantItems = 631.00;

echo "Expected Items Total: \${$floreantItems}\n\n";

// 1. Let's get the exact calculation from the Floreant text report
echo "Comparing with different calculation approaches:\n";
echo "================================================\n";

// Approach 1: Exclude only ticket 46291 (total_price = 0)
$sqlApproach1 = "
SELECT SUM(ti.total_price) as items_gross,
       COUNT(DISTINCT t.id) as tickets_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlApproach1);
$approach1 = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Approach 1 (exclude only total_price=0): \${$approach1['items_gross']} from {$approach1['tickets_count']} tickets\n";
$diff1 = $floreantItems - $approach1['items_gross'];
echo "Difference: \${$diff1}\n\n";

// Approach 2: Use only tickets where items_total = total_price (exact match)
$sqlApproach2 = "
SELECT SUM(ti.total_price) as items_gross,
       COUNT(DISTINCT t.id) as tickets_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
  AND ABS(ti.total_price - t.total_price) < 0.01  -- Consider rounding differences
";

$stmt = $pdo->query($sqlApproach2);
$approach2 = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Approach 2 (items = total): \${$approach2['items_gross']} from {$approach2['tickets_count']} tickets\n";
$diff2 = $floreantItems - $approach2['items_gross'];
echo "Difference: \${$diff2}\n\n";

// Approach 3: Round to nearest cent
$sqlApproach3 = "
SELECT SUM(ROUND(ti.total_price::numeric, 2)) as items_gross,
       COUNT(DISTINCT t.id) as tickets_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
  AND ROUND(ti.total_price::numeric, 2) = ROUND(t.total_price::numeric, 2)
";

$stmt = $pdo->query($sqlApproach3);
$approach3 = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Approach 3 (rounded to cent): \${$approach3['items_gross']} from {$approach3['tickets_count']} tickets\n";
$diff3 = $floreantItems - $approach3['items_gross'];
echo "Difference: \${$diff3}\n\n";

// 2. Let's list all tickets to see if there's a specific one missing
echo "LISTING ALL TICKETS EXCEPT 46291:\n";
echo "==================================\n";

$sqlTicketList = "
SELECT t.id, t.total_price,
       SUM(ti.total_price) as items_total,
       ROUND((SUM(ti.total_price) - t.total_price)::numeric, 2) as difference
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY t.id, t.total_price
ORDER BY t.id
";

$stmt = $pdo->query($sqlTicketList);
$ticketList = $stmt->fetchAll(PDO::FETCH_ASSOC);

$totalExcluding46291 = 0;
foreach ($ticketList as $ticket) {
    echo "Ticket {$ticket['id']}: Items=\${$ticket['items_total']}, Final=\${$ticket['total_price']}, Diff=\${$ticket['difference']}\n";
    $totalExcluding46291 += $ticket['items_total'];
}

echo "\nTotal excluding 46291: \${$totalExcluding46291}\n";
$diffTotal = $floreantItems - $totalExcluding46291;
echo "Expected: \${$floreantItems}, Difference: \${$diffTotal}\n\n";

// 3. Let's check if there's a fractional cent rounding issue
echo "CHECKING ROUNDING DIFFERENCES:\n";
echo "==============================\n";

$roundedTotal = round($totalExcluding46291, 2);
$roundedDifference = abs($roundedTotal - $floreantItems);

echo "Total rounded to 2 decimals: \${$roundedTotal}\n";
echo "Expected: \${$floreantItems}, Difference: \${$roundedDifference}\n";

if ($roundedDifference < 0.01) {
    echo "✅ MATCH FOUND! Rounding explains the difference.\n";
} else {
    echo "❌ Still not matching. Looking for other causes...\n";
}

// 4. Let's check each ticket's item totals individually
echo "\n\nINDIVIDUAL ITEM TOTALS CALCULATION:\n";
echo "====================================\n";

$sqlIndividualItems = "
SELECT ti.id, ti.item_name, ti.item_count, ti.item_price, ti.total_price,
       t.id as ticket_id, t.total_price as ticket_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
ORDER BY t.id, ti.id
LIMIT 20
";

$stmt = $pdo->query($sqlIndividualItems);
$individualItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "First 20 individual items:\n";
foreach ($individualItems as $item) {
    echo "Ticket {$item['ticket_id']}, Item {$item['id']}: {$item['item_name']} x{$item['item_count']} @\${$item['item_price']} = \${$item['total_price']}\n";
}

// 5. Final manual calculation
echo "\n\nMANUAL CALCULATION:\n";
echo "===================\n";

$sqlManual = "
SELECT
    SUM(ti.total_price) as exact_items_total,
    SUM(ROUND(ti.total_price::numeric, 2)) as rounded_items_total,
    COUNT(DISTINCT ti.id) as total_items,
    COUNT(DISTINCT t.id) as total_tickets
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlManual);
$manual = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Exact items total: \${$manual['exact_items_total']}\n";
echo "Rounded items total: \${$manual['rounded_items_total']}\n";
echo "Total items: {$manual['total_items']}\n";
echo "Total tickets: {$manual['total_tickets']}\n";

$pdo = null;
?>