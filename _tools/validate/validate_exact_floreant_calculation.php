<?php
/**
 * Validate the exact calculation method that matches Floreant
 */

echo "=== VALIDATING EXACT FLOREANT CALCULATION ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Expected totals from Floreant
$floreantItems = 631.00;
$floreantModifiers = 50.00;
$floreantDiscounts = 8.80;
$floreantNet = 622.20;

echo "FLOREANT EXPECTED TOTALS:\n";
echo "==========================\n";
echo "Items: \${$floreantItems}\n";
echo "Modifiers: \${$floreantModifiers}\n";
echo "Discounts: \${$floreantDiscounts}\n";
echo "Net: \${$floreantNet}\n\n";

// Let me check if the issue is with how we're calculating individual item totals
echo "CHECKING INDIVIDUAL ITEM CALCULATIONS:\n";
echo "=======================================\n";

$sqlItemTotals = "
SELECT t.id as ticket_id, ti.id as item_id, ti.item_name,
       ti.item_count, ti.item_price, ti.total_price,
       -- Calculate expected total
       ti.item_count * ti.item_price as calculated_total,
       -- Difference
       ti.total_price - (ti.item_count * ti.item_price) as price_difference
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
  AND ABS(ti.total_price - (ti.item_count * ti.item_price)) > 0.01
ORDER BY t.id, ti.id
";

$stmt = $pdo->query($sqlItemTotals);
$priceDifferences = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($priceDifferences)) {
    echo "✅ All items calculate correctly (item_count * item_price = total_price)\n";
} else {
    echo "❌ Found items with price discrepancies:\n";
    foreach ($priceDifferences as $item) {
        echo "Ticket {$item['ticket_id']}, Item {$item['item_id']}: {$item['item_name']} x{$item['item_count']} @\${$item['item_price']} = \${$item['total_price']} (should be \${$item['calculated_total']}, diff=\${$item['price_difference']})\n";
    }
}

echo "\n\nTRYING DIFFERENT CALCULATION METHODS:\n";
echo "=====================================\n";

// Method 1: Standard calculation (current)
$sqlMethod1 = "
SELECT
    SUM(ti.total_price) as items_gross,
    SUM(COALESCE(tim.total_price, 0)) as modifiers_gross,
    COALESCE(SUM(tid.amount), 0) + COALESCE(SUM(td.value), 0) as total_discounts
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlMethod1);
$method1 = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Method 1 (current): Items=\${$method1['items_gross']}, Modifiers=\${$method1['modifiers_gross']}, Discounts=\${$method1['total_discounts']}\n";

// Method 2: Use calculated totals instead of stored totals
$sqlMethod2 = "
SELECT
    SUM(ti.item_count * ti.item_price) as calculated_items_gross,
    SUM(COALESCE(tim.total_price, 0)) as modifiers_gross,
    COALESCE(SUM(tid.amount), 0) + COALESCE(SUM(td.value), 0) as total_discounts
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlMethod2);
$method2 = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Method 2 (calculated): Items=\${$method2['calculated_items_gross']}, Modifiers=\${$method2['modifiers_gross']}, Discounts=\${$method2['total_discounts']}\n";

// Check which method is closer to Floreant
$diff1 = abs($method1['items_gross'] - $floreantItems);
$diff2 = abs($method2['calculated_items_gross'] - $floreantItems);

echo "\nComparison with Floreant (\${$floreantItems}):\n";
echo "Method 1 difference: \${$diff1}\n";
echo "Method 2 difference: \${$diff2}\n";

if ($diff2 < $diff1) {
    echo "✅ Method 2 (calculated totals) is closer to Floreant!\n";
} else {
    echo "❌ Method 1 (stored totals) is closer to Floreant\n";
}

// Let's check if there are any specific exclusions based on ticket characteristics
echo "\n\nCHECKING FOR SPECIFIC TICKET EXCLUSIONS:\n";
echo "=========================================\n";

// Check if Floreant excludes tickets with certain patterns
$sqlCheckExclusions = "
SELECT
    -- Count various ticket types
    COUNT(*) as total_tickets,
    SUM(CASE WHEN t.total_price = 0 THEN 1 ELSE 0 END) as zero_total_tickets,
    SUM(CASE WHEN t.total_discount > 0 THEN 1 ELSE 0 END) as discounted_tickets,
    SUM(CASE WHEN t.total_price < t.sub_total * 0.8 THEN 1 ELSE 0 END) as high_discount_tickets,
    SUM(CASE WHEN t.total_price < t.sub_total * 0.5 THEN 1 ELSE 0 END) as very_high_discount_tickets,
    -- Calculate totals with different exclusions
    SUM(ti.total_price) as all_items_total,
    SUM(CASE WHEN t.total_price > 0 THEN ti.total_price ELSE 0 END) as non_zero_items_total,
    SUM(CASE WHEN t.total_price > 0 AND t.total_discount = 0 THEN ti.total_price ELSE 0 END) as no_discount_items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sqlCheckExclusions);
$exclusions = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Total tickets: {$exclusions['total_tickets']}\n";
echo "Zero total tickets: {$exclusions['zero_total_tickets']}\n";
echo "Discounted tickets: {$exclusions['discounted_tickets']}\n";
echo "High discount tickets: {$exclusions['high_discount_tickets']}\n";
echo "Very high discount tickets: {$exclusions['very_high_discount_tickets']}\n";
echo "All items total: \${$exclusions['all_items_total']}\n";
echo "Non-zero items total: \${$exclusions['non_zero_items_total']}\n";
echo "No discount items total: \${$exclusions['no_discount_items_total']}\n";

// Try to find the exact combination that matches Floreant
echo "\n\nFINDING EXACT MATCH:\n";
echo "====================\n";

// The closest we found was $604.2 (excluding ticket 46291)
// Let's see if there's a small adjustment we're missing

$sqlFinalAttempt = "
-- Floreant likely includes all tickets except those with total_price = 0,
-- but might use a different calculation method for item totals

SELECT
    -- Use ROUND to handle any floating point issues
    SUM(ROUND(ti.total_price::numeric, 2)) as items_gross,
    SUM(COALESCE(ROUND(tim.total_price::numeric, 2), 0)) as modifiers_gross,
    COALESCE(SUM(ROUND(COALESCE(tid.amount, 0)::numeric, 2)), 0) as item_discounts,
    COALESCE(SUM(ROUND(COALESCE(td.value, 0)::numeric, 2)), 0) as ticket_discounts,
    SUM(ROUND(ti.total_price::numeric, 2)) -
    COALESCE(SUM(ROUND(COALESCE(tid.amount, 0)::numeric, 2)), 0) -
    COALESCE(SUM(ROUND(COALESCE(td.value, 0)::numeric, 2)), 0) as items_net
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlFinalAttempt);
$final = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Final attempt (with rounding):\n";
echo "Items: \${$final['items_gross']}\n";
echo "Modifiers: \${$final['modifiers_gross']}\n";
echo "Item Discounts: \${$final['item_discounts']}\n";
echo "Ticket Discounts: \${$final['ticket_discounts']}\n";
$totalDiscounts = $final['item_discounts'] + $final['ticket_discounts'];
echo "Total Discounts: \${$totalDiscounts}\n";
echo "Items Net: \${$final['items_net']}\n\n";

// Compare with expected
$finalDiffItems = abs($final['items_gross'] - $floreantItems);
$finalDiffModifiers = abs($final['modifiers_gross'] - $floreantModifiers);
$finalDiffDiscounts = abs(($final['item_discounts'] + $final['ticket_discounts']) - $floreantDiscounts);

echo "FINAL COMPARISON:\n";
echo "==================\n";
echo "Items: Expected=\${$floreantItems}, Got=\${$final['items_gross']}, Diff=\${$finalDiffItems}\n";
echo "Modifiers: Expected=\${$floreantModifiers}, Got=\${$final['modifiers_gross']}, Diff=\${$finalDiffModifiers}\n";
echo "Discounts: Expected=\${$floreantDiscounts}, Got=\${$totalDiscounts}, Diff=\${$finalDiffDiscounts}\n";

if ($finalDiffItems < 0.01 && $finalDiffModifiers < 0.01 && $finalDiffDiscounts < 0.01) {
    echo "🎉 EXACT MATCH FOUND!\n";
} else {
    echo "\n❌ Still not matching. The $26.8 difference remains.\n";
    echo "Possible causes:\n";
    echo "1. Floreant might be using a different date filter\n";
    echo "2. Floreant might have additional exclusion criteria\n";
    echo "3. There might be data formatting differences\n";
    echo "4. The $631 figure in the text report might include something we're missing\n";
}

$pdo = null;
?>