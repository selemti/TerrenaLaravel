<?php
/**
 * Investigate the price adjustments in individual items
 */

echo "=== INVESTIGATING PRICE ADJUSTMENTS ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

echo "INVESTIGATING ITEMS WITH PRICE DISCREPANCIES:\n";
echo "=============================================\n";

// Get items where total_price doesn't match item_count * item_price
$sqlPriceAdjustments = "
SELECT
    t.id as ticket_id,
    ti.id as item_id,
    ti.item_name,
    ti.item_count,
    ti.item_price,
    ti.total_price,
    ti.item_count * ti.item_price as expected_total,
    ti.total_price - (ti.item_count * ti.item_price) as price_difference,

    -- Check if there are modifiers
    COUNT(tim.id) as modifier_count,
    SUM(COALESCE(tim.total_price, 0)) as modifier_total,

    -- Check if there are discounts
    COUNT(tid.id) as discount_count,
    COALESCE(SUM(tid.amount), 0) as discount_amount

FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ABS(ti.total_price - (ti.item_count * ti.item_price)) > 0.01
GROUP BY t.id, ti.id, ti.item_name, ti.item_count, ti.item_price, ti.total_price
ORDER BY ti.id
";

$stmt = $pdo->query($sqlPriceAdjustments);
$adjustments = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($adjustments as $item) {
    echo "\nTicket {$item['ticket_id']}, Item {$item['item_id']}: {$item['item_name']}\n";
    echo "  Quantity: {$item['item_count']}, Unit Price: \${$item['item_price']}\n";
    echo "  Expected: \${$item['expected_total']}, Actual: \${$item['total_price']}, Diff: \${$item['price_difference']}\n";
    echo "  Modifiers: {$item['modifier_count']} (total: \${$item['modifier_total']})\n";
    echo "  Discounts: {$item['discount_count']} (amount: \${$item['discount_amount']})\n";

    // Check if modifiers explain the difference
    $modifierDifference = $item['modifier_total'] + $item['price_difference'];
    echo "  Modifier difference: \${$modifierDifference}\n";

    // Get details about modifiers
    if ($item['modifier_count'] > 0) {
        echo "  Modifier details:\n";
        $sqlModifierDetails = "
        SELECT tim.modifier_name, tim.modifier_price, tim.item_count
        FROM public.ticket_item_modifier tim
        WHERE tim.ticket_item_id = {$item['item_id']}
        ";
        $modStmt = $pdo->query($sqlModifierDetails);
        $modifiers = $modStmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($modifiers as $mod) {
            $modTotal = $mod['item_count'] * $mod['modifier_price'];
            echo "    - {$mod['modifier_name']}: {$mod['item_count']} x \${$mod['modifier_price']} = \${$modTotal}\n";
        }
    }
}

// Now let's see if Floreant calculates items differently
echo "\n\nCHECKING IF FLOREANT CALCULATES ITEMS + MODIFIERS DIFFERENTLY:\n";
echo "==============================================================\n";

$sqlFloreantLogic = "
SELECT
    SUM(
        -- Try Floreant logic: base item price + modifiers
        ti.item_count * ti.item_price + COALESCE(SUM(tim.total_price), 0)
    ) as floreant_style_items,
    SUM(COALESCE(tim.total_price, 0)) as modifiers_only,
    COUNT(DISTINCT ti.id) as items_with_modifiers
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
  AND ti.item_count * ti.item_price != ti.total_price
GROUP BY t.id
";

$stmt = $pdo->query($sqlFloreantLogic);
$floreantLogic = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Floreant-style calculation (base + mods): \${$floreantLogic['floreant_style_items']}\n";
echo "Modifiers only: \${$floreantLogic['modifiers_only']}\n";
echo "Items with modifiers: {$floreantLogic['items_with_modifiers']}\n";

// Let's try to recreate the exact Floreant calculation
$sqlExactFloreant = "
SELECT
    -- For items without modifiers: use item_count * item_price
    -- For items with modifiers: use the stored total_price (which includes modifiers)
    SUM(CASE
        WHEN EXISTS (
            SELECT 1 FROM public.ticket_item_modifier tim
            WHERE tim.ticket_item_id = ti.id
        ) THEN ti.total_price
        ELSE ti.item_count * ti.item_price
    END) as corrected_items_gross,

    SUM(COALESCE(tim.total_price, 0)) as modifiers_gross,

    -- Use only ticket-level discounts for Item Sales calculation
    COALESCE(SUM(td.value), 0) as ticket_level_discounts,

    COALESCE(SUM(tid.amount), 0) as item_level_discounts
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

$stmt = $pdo->query($sqlExactFloreant);
$exactFloreant = $stmt->fetch(PDO::FETCH_ASSOC);

$totalDiscounts = $exactFloreant['ticket_level_discounts'] + $exactFloreant['item_level_discounts'];

echo "\n\nEXACT FLOREANT CALCULATION ATTEMPT:\n";
echo "===================================\n";
echo "Items Gross: \${$exactFloreant['corrected_items_gross']}\n";
echo "Modifiers: \${$exactFloreant['modifiers_gross']}\n";
echo "Ticket Discounts: \${$exactFloreant['ticket_level_discounts']}\n";
echo "Item Discounts: \${$exactFloreant['item_level_discounts']}\n";
$netItems = $exactFloreant['corrected_items_gross'] - $totalDiscounts;
echo "Total Discounts: \${$totalDiscounts}\n";
echo "Net Items: \${$netItems}\n\n";

// Compare with expected
$floreantItems = 631.00;
$floreantModifiers = 50.00;
$floreantDiscounts = 8.80;

$diffItems = abs($exactFloreant['corrected_items_gross'] - $floreantItems);
$diffModifiers = abs($exactFloreant['modifiers_gross'] - $floreantModifiers);
$diffDiscounts = abs($totalDiscounts - $floreantDiscounts);

echo "COMPARISON WITH FLOREANT:\n";
echo "=========================\n";
echo "Items: Expected=\${$floreantItems}, Got=\${$exactFloreant['corrected_items_gross']}, Diff=\${$diffItems}\n";
echo "Modifiers: Expected=\${$floreantModifiers}, Got=\${$exactFloreant['modifiers_gross']}, Diff=\${$diffModifiers}\n";
echo "Discounts: Expected=\${$floreantDiscounts}, Got=\${$totalDiscounts}, Diff=\${$diffDiscounts}\n";

if ($diffItems < 1 && $diffModifiers < 1 && $diffDiscounts < 1) {
    echo "🎉 CLOSE MATCH FOUND! (within rounding error)\n";
    echo "This appears to be how Floreant calculates Item Sales Grand Total\n";
} else {
    echo "\n❌ Still not matching exactly\n";
}

$pdo = null;
?>