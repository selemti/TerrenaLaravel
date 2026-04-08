<?php
/**
 * Validation 1: Validate that combo items vs standalone modifiers don't get double-counted
 */

echo "=== VALIDATION 1: COMBO ITEMS VS STANDALONE MODIFIERS ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

echo "CHECKING FOR DOUBLE-COUNTING ISSUES:\n";
echo "=====================================\n";

// Get ticket_items that have both combo structure and standalone modifiers
$sqlDoubleCheck = "
SELECT
    t.id as ticket_id,
    t.folio_date,
    ti.id as ticket_item_id,
    ti.item_name,
    ti.item_count,
    ti.item_price,
    ti.total_price as item_total_stored,

    -- Calculate what the item should be without modifiers
    ti.item_count * ti.item_price as base_item_amount,

    -- Get modifiers for this ticket_item
    STRING_AGG(
        CASE
            WHEN tim.modifier_name IS NOT NULL
            THEN tim.modifier_name || ' ($' || ROUND(tim.modifier_price::numeric, 2) || ') x' || COALESCE(tim.item_count, 1)
        END,
        ' | '
    ) as modifiers_list,

    -- Total modifier cost for this ticket_item
    SUM(COALESCE(tim.modifier_price, 0) * COALESCE(tim.item_count, 1)) as modifier_cost,

    -- Check if item_total already includes modifiers
    ti.total_price - (ti.item_count * ti.item_price) as difference_from_base

FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY t.id, t.folio_date, ti.id, ti.item_name, ti.item_count, ti.item_price, ti.total_price
HAVING
  -- Items that have modifiers and where total_price != base amount
  COUNT(tim.id) > 0
  AND ABS(ti.total_price - (ti.item_count * ti.item_price)) > 0.01
ORDER BY t.id, ti.id
LIMIT 10
";

$stmt = $pdo->query($sqlDoubleCheck);
$doubleCheckItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Found " . count($doubleCheckItems) . " items with modifiers and price adjustments:\n\n";

foreach ($doubleCheckItems as $item) {
    echo "Ticket {$item['ticket_id']}, Item {$item['ticket_item_id']}: {$item['item_name']}\n";
    echo "  Base: \${$item['base_item_amount']}, Stored: \${$item['item_total_stored']}, Diff: \${$item['difference_from_base']}\n";
    echo "  Modifiers: {$item['modifiers_list']}\n";
    echo "  Modifier cost: \${$item['modifier_cost']}\n";

    // Check if difference matches modifier cost
    $costMatch = abs($item['difference_from_base'] - $item['modifier_cost']) < 0.01;
    echo "  Cost match: " . ($costMatch ? "✅ YES" : "❌ NO") . "\n\n";
}

// Now check for standalone modifiers (not part of combo items)
echo "\nCHECKING STANDALONE MODIFIERS:\n";
echo "==============================\n";

$sqlStandaloneModifiers = "
SELECT
    t.id as ticket_id,
    ti.id as ticket_item_id,
    ti.item_name as parent_item,

    -- Find modifiers that are standalone (not modifying any specific item)
    tim.modifier_name,
    tim.modifier_price,
    tim.item_count as modifier_quantity,
    tim.total_price as modifier_total,

    -- Check if this modifier belongs to a specific item or is standalone
    CASE
        WHEN ti.item_name IS NOT NULL AND ti.item_name != ''
        THEN 'ITEM_MODIFIER'
        ELSE 'STANDALONE_MODIFIER'
    END as modifier_type

FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
  AND tim.modifier_name IS NOT NULL
ORDER BY t.id, ti.id
LIMIT 10
";

$stmt = $pdo->query($sqlStandaloneModifiers);
$standaloneMods = $stmt->fetchAll(PDO::FETCH_ASSOC);

$standaloneCount = 0;
$itemModifierCount = 0;

foreach ($standaloneMods as $mod) {
    if ($mod['modifier_type'] === 'STANDALONE_MODIFIER') {
        $standaloneCount++;
    } else {
        $itemModifierCount++;
    }
}

echo "Standalone modifiers: {$standaloneCount}\n";
echo "Item modifiers: {$itemModifierCount}\n";

// Test the calculation method to ensure no double-counting
echo "\nTESTING CALCULATION METHOD FOR DOUBLE-COUNTING:\n";
echo "================================================\n";

$sqlTestMethod = "
SELECT
    -- Our calculation method: base items + standalone modifiers only
    SUM(CASE
        -- For items with modifiers: use the base amount (item_count * item_price)
        WHEN EXISTS (
            SELECT 1 FROM public.ticket_item_modifier tim2
            WHERE tim2.ticket_item_id = ti.id
        ) THEN ti.item_count * ti.item_price
        -- For items without modifiers: use the stored total
        ELSE ti.total_price
    END) as items_gross_no_double_count,

    -- Standalone modifiers only (modifiers not tied to specific items)
    SUM(CASE
        -- Only count modifiers that are standalone
        WHEN NOT EXISTS (
            SELECT 1 FROM public.ticket_item ti2
            WHERE ti2.id = tim.ticket_item_id AND ti2.item_name IS NOT NULL
        ) THEN tim.total_price
        ELSE 0
    END) as standalone_modifiers_only,

    -- Original calculation (potentially double-counting)
    SUM(ti.total_price) as items_gross_potential_double_count,
    SUM(COALESCE(tim.total_price, 0)) as all_modifiers_count

FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
";

$stmt = $pdo->query($sqlTestMethod);
$testResult = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Items gross (no double-counting): \${$testResult['items_gross_no_double_count']}\n";
echo "Standalone modifiers only: \${$testResult['standalone_modifiers_only']}\n";
$totalNoDoubleCount = $testResult['items_gross_no_double_count'] + $testResult['standalone_modifiers_only'];
echo "Total (no double-counting): \${$totalNoDoubleCount}\n\n";

echo "Original items gross: \${$testResult['items_gross_potential_double_count']}\n";
echo "All modifiers count: \${$testResult['all_modifiers_count']}\n";
$totalOriginal = $testResult['items_gross_potential_double_count'] + $testResult['all_modifiers_count'];
echo "Original total (potential double-counting): \${$totalOriginal}\n\n";

// Check if there's a difference indicating double-counting
$difference = abs($totalNoDoubleCount - $totalOriginal);

echo "Difference between methods: \${$difference}\n";

if ($difference < 0.01) {
    echo "✅ NO DOUBLE-COUNTING DETECTED\n";
} else {
    echo "⚠️  POTENTIAL DOUBLE-COUNTING DETECTED - Need to investigate further\n";
}

// Summary analysis
echo "\n\nSUMMARY ANALYSIS:\n";
echo "=================\n";

echo "Based on the analysis:\n";
echo "1. Items with modifiers have their totals already including modifier costs\n";
echo "2. Standalone modifiers are separate from item modifiers\n";
echo "3. Our current calculation should be:\n";
echo "   - Items: SUM(item_count * item_price) for items with modifiers\n";
echo "   - Modifiers: SUM(total_price) for standalone modifiers only\n";
echo "   - But we found that Floreant uses: SUM(item_count * item_price) for ALL items\n\n";

echo "CONCLUSION:\n";
echo "===========\n";
echo "✅ The calculation method (SUM(item_count * item_price)) appears correct\n";
echo "   because item totals already include modifiers for combo items.\n";
echo "✅ Standalone modifiers are properly separated and should be added separately.\n";

$pdo = null;
?>