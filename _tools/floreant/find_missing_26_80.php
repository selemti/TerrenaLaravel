<?php
/**
 * Find the missing $26.80 that Floreant includes
 */

echo "=== BUSCAR LOS $26.80 FALTANTES ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// 1. Let's check the exact SQL that Floreant might be running
echo "1. CHECKING DIFFERENT SQL APPROACHES:\n";
echo "======================================\n";

// Approach 1: Using closing_date instead of folio_date
$sql1 = "
SELECT SUM(ti.total_price) as total_closing_date
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.closing_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sql1);
$result1 = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Using closing_date: \${$result1['total_closing_date']}\n";

// Approach 2: Check if there are tickets we're missing
$sql2 = "
SELECT COUNT(*) as total_tickets, SUM(total_price) as total_amount
FROM public.ticket
WHERE DATE(folio_date) = '2025-12-16'
  AND paid = true
  AND voided = false
";

$stmt = $pdo->query($sql2);
$result2 = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Total tickets: {$result2['total_tickets']}, Total: \${$result2['total_amount']}\n";

// 3. Let's check if there's a specific calculation issue
echo "\n2. DETAILED ITEM ANALYSIS:\n";
echo "==========================\n";

$sql3 = "
SELECT
    ti.item_name,
    SUM(ti.total_price) as total_item,
    COUNT(*) as occurrences,
    AVG(ti.item_price) as avg_price,
    SUM(ti.item_count) as total_quantity
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.id != 46291  -- Exclude the 100% discount ticket
GROUP BY ti.item_name
ORDER BY total_item DESC
";

$stmt = $pdo->query($sql3);
$items = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Items breakdown (excluding ticket 46291):\n";
$subtotal = 0;
foreach ($items as $item) {
    echo "- {$item['item_name']}: \${$item['total_item']} ({$item['occurrences']} veces)\n";
    $subtotal += $item['total_item'];
}

echo "\nSubtotal: \${$subtotal}\n";
$difference_sub = $subtotal - 631;
echo "Difference from Floreant: \${$difference_sub}\n";

// 4. Let's check if there are multiple entries for the same item that we might be double-counting or missing
echo "\n3. CHECKING DUPLICATE ENTRIES:\n";
echo "==============================\n";

$sql4 = "
SELECT ti.id, ti.item_name, ti.item_count, ti.item_price, ti.total_price,
       t.id as ticket_id, t.total_price as ticket_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ti.item_name IN (
    SELECT item_name
    FROM public.ticket_item ti2
    JOIN public.ticket t2 ON t2.id = ti2.ticket_id
    WHERE DATE(t2.folio_date) = '2025-12-16'
      AND t2.paid = true
      AND t2.voided = false
    GROUP BY item_name
    HAVING COUNT(*) > 1
  )
ORDER BY ti.item_name, ticket_id
";

$stmt = $pdo->query($sql4);
$duplicates = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Items that appear multiple times:\n";
$duplicate_total = 0;
foreach ($duplicates as $item) {
    echo "- {$item['item_name']} (Ticket {$item['ticket_id']}): \${$item['total_price']}\n";
    $duplicate_total += $item['total_price'];
}

echo "\nTotal from duplicates: \${$duplicate_total}\n";

// 5. Let's try to understand what might be the missing $26.80
echo "\n4. TRYING DIFFERENT CALCULATIONS:\n";
echo "=================================\n";

// What if we include the 100% discount ticket items but subtract the discount?
$sql5 = "
SELECT
    SUM(CASE
        WHEN t.total_price = 0 THEN ti.total_price - ti.discount
        ELSE ti.total_price
    END) as adjusted_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sql5);
$result5 = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Adjusted total (100% discount items at net value): \${$result5['adjusted_total']}\n";
$difference_adj = $result5['adjusted_total'] - 631;
echo "Difference from Floreant: \${$difference_adj}\n";

// 6. Let's try another approach - maybe there's a data issue
echo "\n5. CHECKING FOR DATA INCONSISTENCIES:\n";
echo "====================================\n";

$sql6 = "
SELECT t.id, t.folio_date, t.total_price, t.total_discount,
       COUNT(ti.id) as item_count,
       SUM(ti.total_price) as items_sum,
       SUM(ti.total_price) - t.total_price as diff
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
GROUP BY t.id, t.folio_date, t.total_price, t.total_discount
ORDER BY t.id
";

$stmt = $pdo->query($sql6);
$tickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Ticket analysis:\n";
foreach ($tickets as $ticket) {
    echo "- Ticket {$ticket['id']}: Items=\${$ticket['items_sum']}, Ticket=\${$ticket['total_price']}, Diff=\${$ticket['diff']}\n";
}

// 7. Final calculation - let's see what happens if we use the sum of ticket totals directly
$sql7 = "
SELECT SUM(total_price) as ticket_sum_total
FROM public.ticket
WHERE DATE(folio_date) = '2025-12-16'
  AND paid = true
  AND voided = false
";

$stmt = $pdo->query($sql7);
$result7 = $stmt->fetch(PDO::FETCH_ASSOC);

echo "\n6. FINAL ATTEMPTS:\n";
echo "==================\n";
echo "Sum of ticket.total_price: \${$result7['ticket_sum_total']}\n";
echo "Floreant total: \$631\n";
$difference_final = $result7['ticket_sum_total'] - 631;
echo "Difference: \${$difference_final}\n";

if (abs($result7['ticket_sum_total'] - 631) < 1) {
    echo "FOUND! Floreant uses the sum of ticket.total_price directly!\n";
} else {
    echo "Still not matching. Let's try one more approach.\n";

    // What if we add the discounts back differently?
    $expected_net = 631;
    $actual_tickets = $result7['ticket_sum_total'];
    $difference = $expected_net - $actual_tickets;

    echo "Difference needed: \${$difference}\n";
    echo "This suggests Floreant is adding back something we're missing.\n";
}

$pdo = null;
?>