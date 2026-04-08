<?php
/**
 * Debug script to analyze remaining differences in "Conciliación Floreant" mode
 */

echo "=== DEBUGGING CONCILIACIÓN FLOREANT DIFFERENCES ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Expected totals from Floreant
$floreantItems = 631.00;
$floreantModifiers = 50.00;
$floreantDiscounts = 8.80;
$floreantNet = 622.20;  // $631 - $8.80

echo "FLOREANT EXPECTED:\n";
echo "===================\n";
echo "Items: \${$floreantItems}\n";
echo "Modifiers: \${$floreantModifiers}\n";
echo "Discounts: \${$floreantDiscounts}\n";
echo "Net: \${$floreantNet}\n\n";

// 1. First, let's get the current conciliation mode results
$sqlConciliation = "
SELECT
    SUM(ti.total_price) as items_gross,
    SUM(COALESCE(tim.total_price, 0)) as modifiers_gross,
    COALESCE(SUM(tid.amount), 0) + COALESCE(SUM(td.value), 0) as total_discounts,
    SUM(ti.total_price) - COALESCE(SUM(tid.amount), 0) - COALESCE(SUM(td.value), 0) as items_net
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

echo "CURRENT CONCILIATION MODE RESULTS:\n";
echo "==================================\n";
echo "Items Gross: \${$resultConciliation['items_gross']}\n";
echo "Modifiers: \${$resultConciliation['modifiers_gross']}\n";
echo "Discounts: \${$resultConciliation['total_discounts']}\n";
echo "Items Net: \${$resultConciliation['items_net']}\n\n";

// Calculate differences
$differenceItems = abs($resultConciliation['items_gross'] - $floreantItems);
$differenceModifiers = abs($resultConciliation['modifiers_gross'] - $floreantModifiers);
$differenceDiscounts = abs($resultConciliation['total_discounts'] - $floreantDiscounts);

echo "DIFFERENCES ANALYSIS:\n";
echo "=====================\n";
echo "Items Difference: \${$differenceItems} (Expected: \${$floreantItems}, Got: \${$resultConciliation['items_gross']})\n";
echo "Modifiers Difference: \${$differenceModifiers} (Expected: \${$floreantModifiers}, Got: \${$resultConciliation['modifiers_gross']})\n";
echo "Discounts Difference: \${$differenceDiscounts} (Expected: \${$floreantDiscounts}, Got: \${$resultConciliation['total_discounts']})\n\n";

// 2. Let's break down the discount calculation
echo "DISCOUNT BREAKDOWN:\n";
echo "===================\n";

// Ticket-level discounts only
$sqlTicketDiscounts = "
SELECT COALESCE(SUM(td.value), 0) as ticket_discounts
FROM public.ticket t
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlTicketDiscounts);
$ticketDiscounts = $stmt->fetch(PDO::FETCH_ASSOC);

// Item-level discounts only
$sqlItemDiscounts = "
SELECT COALESCE(SUM(tid.amount), 0) as item_discounts
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlItemDiscounts);
$itemDiscounts = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Ticket-level discounts: \${$ticketDiscounts['ticket_discounts']}\n";
echo "Item-level discounts: \${$itemDiscounts['item_discounts']}\n";
$totalDiscounts = $ticketDiscounts['ticket_discounts'] + $itemDiscounts['item_discounts'];
echo "Total discounts: \${$totalDiscounts}\n\n";

// 3. Let's get the ticket IDs that are included
$sqlTicketIds = "
SELECT t.id, t.folio_date, t.total_price,
       COUNT(ti.id) as items_count,
       SUM(ti.total_price) as items_total,
       COUNT(tim.id) as modifiers_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY t.id, t.folio_date, t.total_price
ORDER BY t.id
";

$stmt = $pdo->query($sqlTicketIds);
$includedTickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "TICKETS INCLUDED IN CONCILIATION MODE (total_price > 0):\n";
echo "======================================================\n";
foreach ($includedTickets as $ticket) {
    echo "Ticket {$ticket['id']}: Items=\${$ticket['items_total']}, Final=\${$ticket['total_price']}\n";
}

$includedSum = array_sum(array_column($includedTickets, 'items_total'));
$difference = $includedSum - $floreantItems;
echo "\nSum of included ticket items: \${$includedSum}\n";
echo "Difference from expected: \${$difference}\n\n";

// 4. Let's check if there are items that should be excluded
echo "CHECKING FOR POTENTIAL EXCLUSION CRITERIA:\n";
echo "=========================================\n";

// Check tickets with specific patterns
$sqlTicketPatterns = "
SELECT t.id, t.total_price,
       COUNT(ti.id) as items_count,
       SUM(ti.total_price) as items_total,
       COUNT(tim.id) as modifiers_count,
       CASE
           WHEN t.total_price = 0 THEN 'TICKET_100_DISCOUNT'
           WHEN t.total_price < t.sub_total * 0.5 THEN 'TICKET_50_PLUS_DISCOUNT'
           WHEN t.total_price < t.sub_total * 0.8 THEN 'TICKET_20_PLUS_DISCOUNT'
           ELSE 'NORMAL'
       END as discount_pattern
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY t.id, t.total_price, t.sub_total
ORDER BY t.total_price
";

$stmt = $pdo->query($sqlTicketPatterns);
$ticketPatterns = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Ticket patterns in conciliation mode:\n";
foreach ($ticketPatterns as $ticket) {
    echo "Ticket {$ticket['id']}: \${$ticket['items_total']} -> \${$ticket['total_price']} ({$ticket['discount_pattern']})\n";
}

// 5. Let's check if there's a specific ticket causing the large difference
echo "\n\nLOOKING FOR SPECIFIC TICKET THAT MIGHT BE EXCLUDED:\n";
echo "==================================================\n";

$sqlLargeTicket = "
SELECT t.id, t.total_price,
       SUM(ti.total_price) as items_total,
       SUM(COALESCE(tim.total_price, 0)) as modifiers_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY t.id, t.total_price
ORDER BY items_total DESC
LIMIT 5
";

$stmt = $pdo->query($sqlLargeTicket);
$largeTickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Top 5 largest tickets by items_total:\n";
foreach ($largeTickets as $ticket) {
    $diff = $ticket['items_total'] - $ticket['total_price'];
    echo "Ticket {$ticket['id']}: Items=\${$ticket['items_total']}, Final=\${$ticket['total_price']}, Difference=\${$diff}\n";
}

// 6. Let's try to find what Floreant might be calculating differently
echo "\n\nCHECKING POTENTIAL ALTERNATIVE CALCULATIONS:\n";
echo "=============================================\n";

// Maybe Floreant uses closing_date instead of folio_date?
$sqlClosingDate = "
SELECT SUM(ti.total_price) as items_gross,
       SUM(COALESCE(tim.total_price, 0)) as modifiers_gross
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.closing_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlClosingDate);
$closingDateResult = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Using closing_date instead of folio_date:\n";
echo "Items: \${$closingDateResult['items_gross']}\n";
echo "Modifiers: \${$closingDateResult['modifiers_gross']}\n\n";

// Maybe Floreant has additional exclusion criteria?
$sqlAdditionalExclusions = "
SELECT SUM(ti.total_price) as items_gross,
       SUM(COALESCE(tim.total_price, 0)) as modifiers_gross
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
  AND t.sub_total > 0  -- Exclude tickets with 0 subtotal too
";

$stmt = $pdo->query($sqlAdditionalExclusions);
$additionalExclusionsResult = $stmt->fetch(PDO::FETCH_ASSOC);

echo "With additional exclusion (subtotal > 0):\n";
echo "Items: \${$additionalExclusionsResult['items_gross']}\n";
echo "Modifiers: \${$additionalExclusionsResult['modifiers_gross']}\n";

$pdo = null;
?>