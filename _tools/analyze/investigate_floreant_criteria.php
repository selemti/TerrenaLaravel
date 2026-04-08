<?php
/**
 * Investigate what exact criteria Floreant uses for "Item Sales Grand Total"
 */

echo "=== INVESTIGATING FLOREANT EXCLUSION CRITERIA ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Expected totals from Floreant
$floreantItems = 631.00;

echo "Expected Items Total: \${$floreantItems}\n\n";

// 1. Let's examine all tickets with paid=true and voided=false
echo "ALL TICKETS (paid=true, voided=false):\n";
echo "=======================================\n";

$sqlAllTickets = "
SELECT t.id, t.folio_date, t.sub_total, t.total_discount, t.total_price,
       COUNT(ti.id) as items_count,
       SUM(ti.total_price) as items_total,
       COUNT(tim.id) as modifiers_count,
       SUM(COALESCE(tim.total_price, 0)) as modifiers_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
GROUP BY t.id, t.folio_date, t.sub_total, t.total_discount, t.total_price
ORDER BY t.id
";

$stmt = $pdo->query($sqlAllTickets);
$allTickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

$totalAll = 0;
foreach ($allTickets as $ticket) {
    echo "Ticket {$ticket['id']}: Sub=\${$ticket['sub_total']}, Disc=\${$ticket['total_discount']}, Final=\${$ticket['total_price']}, Items=\${$ticket['items_total']}\n";
    $totalAll += $ticket['items_total'];
}

$expectedDifference = $totalAll - $floreantItems;
echo "\nTotal from ALL tickets: \${$totalAll}\n";
echo "Expected: \${$floreantItems}, Difference: \${$expectedDifference}\n\n";

// 2. Let's check specific exclusion criteria that might match Floreant
echo "\nCHECKING VARIOUS EXCLUSION CRITERIA:\n";
echo "=====================================\n";

// Exclude only total_price = 0 (current conciliation)
$sqlExcludeZero = "
SELECT SUM(ti.total_price) as items_gross
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlExcludeZero);
$excludeZero = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Exclude only total_price = 0: \${$excludeZero['items_gross']}\n";

// Exclude tickets with total_price = 0 OR total_discount >= sub_total (100% discount)
$sqlExclude100Disc = "
SELECT SUM(ti.total_price) as items_gross
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
  AND t.total_discount < t.sub_total
";

$stmt = $pdo->query($sqlExclude100Disc);
$exclude100Disc = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Exclude 100% discount tickets: \${$exclude100Disc['items_gross']}\n";

// Exclude tickets with items_total > total_price by more than 10%
$sqlExclude10Diff = "
SELECT SUM(ti.total_price) as items_gross
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
  AND (ti.total_price - t.total_price) / t.total_price <= 0.1
";

$stmt = $pdo->query($sqlExclude10Diff);
$exclude10Diff = $stmt->fetch(PDO::FETCH_ASSOC);
echo "Exclude tickets with >10% item difference: \${$exclude10Diff['items_gross']}\n";

// Try to find the exact match by testing different thresholds
echo "\nFINDING EXACT THRESHOLD:\n";
echo "=========================\n";

$threshold = 0;
$bestMatch = 999999;
$bestThreshold = 0;

for ($i = 0; $i <= 100; $i++) {
    $thresholdPercent = $i / 100;
    $sqlThreshold = "
    SELECT SUM(ti.total_price) as items_gross
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    WHERE DATE(t.folio_date) = '2025-12-16'
      AND t.paid = true
      AND t.voided = false
      AND t.total_price > 0
      AND (ti.total_price - t.total_price) / t.total_price <= {$thresholdPercent}
    ";

    $stmt = $pdo->query($sqlThreshold);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $difference = abs($result['items_gross'] - $floreantItems);

    if ($difference < $bestMatch) {
        $bestMatch = $difference;
        $bestThreshold = $thresholdPercent;
    }
}

echo "Best threshold: {$bestThreshold} (difference: \${$bestMatch})\n";

// 3. Let's check if there are tickets with specific payment methods or terminal types
echo "\nCHECKING OTHER POSSIBLE CRITERIA:\n";
echo "==================================\n";

// Check terminal-specific exclusions
$sqlTerminalExclusions = "
SELECT t.terminal_id, COUNT(*) as ticket_count, SUM(ti.total_price) as items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY t.terminal_id
ORDER BY t.terminal_id
";

$stmt = $pdo->query($sqlTerminalExclusions);
$terminalResults = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($terminalResults as $terminal) {
    echo "Terminal {$terminal['terminal_id']}: {$terminal['ticket_count']} tickets, Items=\${$terminal['items_total']}\n";
}

// 4. Let's examine the specific tickets that are causing the large differences
echo "\n\nTICKETS WITH LARGE DISCREPANCIES:\n";
echo "==================================\n";

$sqlLargeDiff = "
SELECT t.id, t.terminal_id, t.total_price,
       SUM(ti.total_price) as items_total,
       SUM(ti.total_price) - t.total_price as difference,
       (SUM(ti.total_price) - t.total_price) * 100.0 / t.total_price as percent_diff,
       COUNT(ti.id) as items_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY t.id, t.terminal_id, t.total_price
ORDER BY percent_diff DESC
LIMIT 10
";

$stmt = $pdo->query($sqlLargeDiff);
$largeDiffTickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($largeDiffTickets as $ticket) {
    echo "Ticket {$ticket['id']}: Items=\${$ticket['items_total']}, Final=\${$ticket['total_price']}, Diff=\${$ticket['difference']} ({$ticket['percent_diff']}%)\n";
}

// 5. Let's check if there's a pattern based on time of day
echo "\n\nCHECKING TIME-BASED PATTERNS:\n";
echo "=============================\n";

$sqlTimePatterns = "
SELECT
    EXTRACT(HOUR FROM t.folio_date) as hour,
    COUNT(*) as ticket_count,
    SUM(ti.total_price) as items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY EXTRACT(HOUR FROM t.folio_date)
ORDER BY hour
";

$stmt = $pdo->query($sqlTimePatterns);
$timeResults = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($timeResults as $time) {
    echo "Hour {$time['hour']}: {$time['ticket_count']} tickets, Items=\${$time['items_total']}\n";
}

$pdo = null;
?>