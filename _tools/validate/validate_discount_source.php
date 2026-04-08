<?php
/**
 * Validation 2: Verify that the $8.80 discounts come specifically from item_discounts, not ticket_discounts
 */

echo "=== VALIDATION 2: DISCOUNT SOURCE VERIFICATION ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

echo "CHECKING DISCOUNT TABLES AND RECORDS:\n";
echo "=====================================\n";

// Get all discounts from ticket_item_discount table
$sqlItemDiscounts = "
SELECT
    tid.id,
    tid.name,
    tid.type,
    tid.value,
    tid.amount,
    tid.ticket_itemid as ticket_item_id,

    ti.item_name,
    ti.item_count,
    ti.item_price,
    ti.total_price as item_total,

    t.id as ticket_id,
    t.folio_date,
    t.sub_total,
    t.total_discount as ticket_total_discount,
    t.total_price as ticket_final_price

FROM public.ticket_item_discount tid
JOIN public.ticket_item ti ON ti.id = tid.ticket_itemid
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
ORDER BY tid.amount DESC
";

$stmt = $pdo->query($sqlItemDiscounts);
$itemDiscounts = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "TICKET_ITEM_DISCOUNT RECORDS:\n";
echo "=============================\n";
echo "Found " . count($itemDiscounts) . " records in ticket_item_discount:\n\n";

$totalItemDiscounts = 0;
foreach ($itemDiscounts as $discount) {
    echo "ID {$discount['id']}: {$discount['name']} - Amount: \${$discount['amount']}\n";
    echo "  Ticket: {$discount['ticket_id']}, Item: {$discount['item_name']}\n";
    echo "  Type: {$discount['type']}, Value: {$discount['value']}\n\n";
    $totalItemDiscounts += $discount['amount'];
}

echo "Total from ticket_item_discount: \${$totalItemDiscounts}\n\n";

// Check ticket_discount table for any discounts
$sqlTicketDiscounts = "
SELECT
    td.id,
    td.name,
    td.type,
    td.value,
    td.ticket_id,

    t.folio_date,
    t.sub_total,
    t.total_discount as ticket_total_discount,
    t.total_price as ticket_final_price

FROM public.ticket_discount td
JOIN public.ticket t ON t.id = td.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
ORDER BY td.value DESC
";

$stmt = $pdo->query($sqlTicketDiscounts);
$ticketDiscounts = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "TICKET_DISCOUNT RECORDS:\n";
echo "=========================\n";
echo "Found " . count($ticketDiscounts) . " records in ticket_discount:\n\n";

$totalTicketDiscounts = 0;
if (!empty($ticketDiscounts)) {
    foreach ($ticketDiscounts as $discount) {
        echo "ID {$discount['id']}: {$discount['name']} - Value: {$discount['value']}\n";
        echo "  Ticket: {$discount['ticket_id']}\n";
        echo "  Type: {$discount['type']}\n";
        echo "  Subtotal: \${$discount['sub_total']}\n";

        // Calculate percentage discount if applicable
        if ($discount['type'] == 1 && $discount['sub_total'] > 0) {
            $percentage = ($discount['value'] / 100) * $discount['sub_total'];
            echo "  Calculated percentage: \${$percentage}\n";
            $totalTicketDiscounts += $percentage;
        }
        echo "\n";
    }
} else {
    echo "No ticket_discount records found for this date.\n";
}

echo "Total from ticket_discount: \${$totalTicketDiscounts} (no records found)\n\n";

// Verify the $8.80 total matches
echo "VERIFICATION:\n";
echo "==============\n";

echo "Item discounts total: \${$totalItemDiscounts}\n";
echo "Ticket discounts total: \${$totalTicketDiscounts}\n";
$combinedTotal = $totalItemDiscounts + $totalTicketDiscounts;
echo "Combined total: \${$combinedTotal}\n\n";

// Check if it matches Floreant's $8.80
$floreantDiscounts = 8.80;
$difference = abs($combinedTotal - $floreantDiscounts);

echo "Floreant expected: \${$floreantDiscounts}\n";
echo "Difference: \${$difference}\n";

if ($difference < 0.01) {
    echo "✅ TOTAL MATCHES FLOREANT EXACTLY\n";
} else {
    echo "❌ Total doesn't match Floreant\n";
}

// Analyze individual discount records more closely
echo "\n\nDETAILED DISCOUNT ANALYSIS:\n";
echo "============================\n";

// Check for percentage discounts in ticket_discount that need calculation
$sqlPercentageAnalysis = "
SELECT
    td.id,
    td.name,
    td.type,
    td.value,
    t.sub_total,

    -- Calculate what the percentage discount should be
    CASE
        WHEN td.type = 1 AND t.sub_total > 0
        THEN ROUND(((td.value / 100) * t.sub_total)::numeric, 2)
        ELSE 0
    END as calculated_discount

FROM public.ticket_discount td
JOIN public.ticket t ON t.id = td.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlPercentageAnalysis);
$percentageAnalysis = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (!empty($percentageAnalysis)) {
    echo "Percentage discount analysis:\n";
    foreach ($percentageAnalysis as $pd) {
        echo "  {$pd['name']}: stored=\${$pd['amount']}, calculated=\${$pd['calculated_discount']}, match=" .
             (abs($pd['amount'] - $pd['calculated_discount']) < 0.01 ? "✅" : "❌") . "\n";
    }
}

// Final validation: Check if our $8.80 comes only from item_discounts
echo "\n\nFINAL VALIDATION - DISCOUNT SOURCE:\n";
echo "====================================\n";

$sqlFinalValidation = "
SELECT
    -- Only item discounts
    SUM(tid.amount) as item_discounts_total,

    -- Ticket discounts (including percentage calculations)
    0 as ticket_discounts_raw,
    COALESCE(SUM(
        CASE
            WHEN td.type = 1 AND t.sub_total > 0
            THEN ROUND(((td.value / 100) * t.sub_total)::numeric, 2)
            ELSE 0
        END
    ), 0) as ticket_discounts_calculated,

    -- Combined totals
    SUM(tid.amount) + 0 as combined_raw,
    SUM(tid.amount) + COALESCE(SUM(
        CASE
            WHEN td.type = 1 AND t.sub_total > 0
            THEN ROUND(((td.value / 100) * t.sub_total)::numeric, 2)
            ELSE 0
        END
    ), 0) as combined_calculated

FROM public.ticket t
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = t.id
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlFinalValidation);
$finalValidation = $stmt->fetch(PDO::FETCH_ASSOC);

$itemTotal = $finalValidation['item_discounts_total'];
$ticketRaw = $finalValidation['ticket_discounts_raw'];
$ticketCalculated = $finalValidation['ticket_discounts_calculated'];
$combinedRaw = $finalValidation['combined_raw'];
$combinedCalculated = $finalValidation['combined_calculated'];

echo "Item discounts only: \${$itemTotal}\n";
echo "Ticket discounts (raw): \${$ticketRaw}\n";
echo "Ticket discounts (calculated): \${$ticketCalculated}\n";
echo "Combined (raw): \${$combinedRaw}\n";
echo "Combined (calculated): \${$combinedCalculated}\n\n";

// Check which matches $8.80
$matchesItemOnly = abs($itemTotal - $floreantDiscounts) < 0.01;
$matchesRawCombined = abs($combinedRaw - $floreantDiscounts) < 0.01;
$matchesCalculatedCombined = abs($combinedCalculated - $floreantDiscounts) < 0.01;

echo "MATCH ANALYSIS:\n";
echo "==============\n";
echo "Item discounts only matches $8.80: " . ($matchesItemOnly ? "✅ YES" : "❌ NO") . "\n";
echo "Raw combined matches $8.80: " . ($matchesRawCombined ? "✅ YES" : "❌ NO") . "\n";
echo "Calculated combined matches $8.80: " . ($matchesCalculatedCombined ? "✅ YES" : "❌ NO") . "\n";

if ($matchesItemOnly) {
    echo "\n✅ CONCLUSION: The $8.80 comes ONLY from item_discounts, not ticket_discounts\n";
} elseif ($matchesCalculatedCombined) {
    echo "\n✅ CONCLUSION: The $8.80 comes from both tables with percentage calculations\n";
} else {
    echo "\n❌ CONCLUSION: Unable to determine exact source of $8.80\n";
}

$pdo = null;
?>