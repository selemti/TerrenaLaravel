<?php
/**
 * Final discovery to match exactly with Floreant
 */

echo "=== FINDING THE MISSING \$26.80 ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

echo "1. CHECKING ALL POSSIBLE FILTERS:\n";
echo "=================================\n";

// Check if Floreant might be using closing_date instead of folio_date
$sql = "
SELECT COUNT(*) as count, SUM(total_price) as total
FROM public.ticket
WHERE closing_date >= '2025-12-16 00:00:00'
  AND closing_date <= '2025-12-16 23:59:59'
  AND paid = true
  AND voided = false
";
$stmt = $pdo->query($sql);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Using closing_date: {$result['count']} tickets, total: \${$result['total']}\n\n";

// Check if there are any tickets with different date formats
$sql2 = "
SELECT id, folio_date, total_price
FROM public.ticket
WHERE folio_date::date = '2025-12-16'
  AND paid = true
  AND voided = false
  AND total_price > 0
ORDER BY folio_date
";
$stmt = $pdo->query($sql2);
$tickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Tickets with positive totals:\n";
$positive_total = 0;
foreach($tickets as $ticket) {
    echo "- Ticket {$ticket['id']}: \${$ticket['total_price']}\n";
    $positive_total += $ticket['total_price'];
}
echo "\nPositive total: \${$positive_total}\n";
$difference_pos = $positive_total - 631;
echo "Difference from Floreant: \${$difference_pos}\n\n";

// Let's try including ticket 46291 but with a different calculation
$sql3 = "
SELECT SUM(ti.total_price) as total_items
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.id IN (46283, 46284, 46285, 46286, 46287, 46288, 46290)  -- All except 46291
";
$stmt = $pdo->query($sql3);
$result3 = $stmt->fetch(PDO::FETCH_ASSOC);
echo "All tickets except 46291: \${$result3['total_items']}\n";
echo "Difference from Floreant: \${$result3['total_items'] - 631}\n\n";

// Let's try a different approach - maybe there's a calculation issue
echo "2. CHECKING FOR CALCULATION PATTERNS:\n";
echo "====================================\n";

// The difference is $26.8. Let's see if there's an item worth exactly that
$sql4 = "
SELECT item_name, total_price, item_price, item_count
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND total_price > 0
  AND total_price < 30
ORDER BY total_price DESC
";
$stmt = $pdo->query($sql4);
$small_items = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Items with total < \$30:\n";
foreach($small_items as $item) {
    echo "- {$item['item_name']}: \${$item['total_price']}\n";
}

// Let's try a different strategy - what if we need to add some items back?
echo "\n3. HYPOTHESIS TESTING:\n";
echo "=====================\n";

// Hypothesis: Floreant might be including some items from tickets that have partial discounts
$sql5 = "
SELECT t.id, t.total_discount, t.total_price,
       SUM(ti.total_price) as items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
GROUP BY t.id, t.total_discount, t.total_price
HAVING t.total_discount > 0
ORDER BY t.id
";
$stmt = $pdo->query($sql5);
$discounted = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Tickets with discounts:\n";
foreach($discounted as $ticket) {
    echo "- Ticket {$ticket['id']}: Discount=\${$ticket['total_discount']}, Items=\${$ticket['items_total']}, Final=\${$ticket['total_price']}\n";
}

// Now let's try the key insight - what if Floreant is calculating items differently?
echo "\n4. KEY INSIGHT - FLOREANT MIGHT BE CALCULATING ITEMS DIFFERENTLY:\n";
echo "==================================================================\n";

// Floreant might be using item_price * item_count instead of total_price
$sql6 = "
SELECT
    ti.item_name,
    ti.item_count,
    ti.item_price,
    ti.total_price,
    SUM(ti.item_count * ti.item_price) as calculated_total,
    SUM(ti.total_price) as actual_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.id != 46291  -- Exclude the 100% discount ticket
GROUP BY ti.item_name, ti.item_count, ti.item_price, ti.total_price
";

$stmt = $pdo->query($sql6);
$items_calc = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Comparison: calculated vs actual total:\n";
$calc_total = 0;
$actual_total = 0;
foreach($items_calc as $item) {
    echo "- {$item['item_name']}: Calculated=\${$item['calculated_total']}, Actual=\${$item['actual_total']}\n";
    $calc_total += $item['calculated_total'];
    $actual_total += $item['actual_total'];
}

echo "\nCalculated total: \${$calc_total}\n";
echo "Actual total: \${$actual_total}\n";
echo "Floreant expected: \$631\n";
echo "Difference from calculated: \${$calc_total - 631}\n";
echo "Difference from actual: \${$actual_total - 631}\n";

// Let's try the ultimate test - what if we use the exact calculation method
if (abs($calc_total - 631) < 1) {
    echo "\nFOUND! Floreant uses item_price * item_count instead of total_price!\n";
} else {
    echo "\nStill not matching. Let's try one more approach.\n";

    // Maybe there's a specific ticket we need to include differently
    echo "\n5. ULTIMATE TEST - CHECKING EVERY POSSIBLE COMBINATION:\n";
    echo "========================================================\n";

    // What if we include all items but exclude only the ticket with 100% discount?
    $sql7 = "
    SELECT SUM(ti.total_price) as all_except_100discount
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    WHERE DATE(t.folio_date) = '2025-12-16'
      AND t.paid = true
      AND t.voided = false
      AND NOT (t.total_price = 0 AND t.total_discount > 0)  -- Exclude tickets with 100% discount
    ";

    $stmt = $pdo->query($sql7);
    $result7 = $stmt->fetch(PDO::FETCH_ASSOC);

    echo "All except tickets with 100% discount: \${$result7['all_except_100discount']}\n";
    echo "Difference from Floreant: \${$result7['all_except_100discount'] - 631}\n";

    if (abs($result7['all_except_100discount'] - 631) < 1) {
        echo "FOUND! Floreant includes all items except those from tickets with 100% discount!\n";
    }
}

$pdo = null;
?>