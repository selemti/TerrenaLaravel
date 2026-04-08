<?php
/**
 * Final test script to verify exact Floreant calculation
 */

echo "=== FINAL FLOREANT CALCULATION TEST ===\n\n";

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

// EXACT FLOREANT CALCULATION
echo "EXACT FLOREANT CALCULATION:\n";
echo "===========================\n";

$sqlExactFloreant = "
SELECT
    -- Items: total_price already includes modifiers for combo items
    SUM(ti.total_price) as items_gross,

    -- Modifiers: only standalone modifiers (not included in item totals)
    SUM(COALESCE(tim.total_price, 0)) as modifiers_gross,

    -- Discounts: ticket-level + item-level discounts
    COALESCE(SUM(td.value), 0) as ticket_level_discounts,
    COALESCE(SUM(tid.amount), 0) as item_level_discounts,

    -- Net calculation
    SUM(ti.total_price) - COALESCE(SUM(td.value), 0) - COALESCE(SUM(tid.amount), 0) as items_net
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0  -- Exclude tickets with 100% discount
";

$stmt = $pdo->query($sqlExactFloreant);
$exactFloreant = $stmt->fetch(PDO::FETCH_ASSOC);

$totalDiscounts = $exactFloreant['ticket_level_discounts'] + $exactFloreant['item_level_discounts'];

echo "Items Gross: \${$exactFloreant['items_gross']}\n";
echo "Modifiers: \${$exactFloreant['modifiers_gross']}\n";
echo "Ticket Discounts: \${$exactFloreant['ticket_level_discounts']}\n";
echo "Item Discounts: \${$exactFloreant['item_level_discounts']}\n";
echo "Total Discounts: \${$totalDiscounts}\n";
echo "Items Net: \${$exactFloreant['items_net']}\n\n";

// Compare with expected
$diffItems = abs($exactFloreant['items_gross'] - $floreantItems);
$diffModifiers = abs($exactFloreant['modifiers_gross'] - $floreantModifiers);
$diffDiscounts = abs($totalDiscounts - $floreantDiscounts);

echo "COMPARISON WITH FLOREANT:\n";
echo "=========================\n";
echo "Items: Expected=\${$floreantItems}, Got=\${$exactFloreant['items_gross']}, Diff=\${$diffItems}\n";
echo "Modifiers: Expected=\${$floreantModifiers}, Got=\${$exactFloreant['modifiers_gross']}, Diff=\${$diffModifiers}\n";
echo "Discounts: Expected=\${$floreantDiscounts}, Got=\${$totalDiscounts}, Diff=\${$diffDiscounts}\n";

// Analysis of individual tickets
echo "\n\nTICKET ANALYSIS:\n";
echo "=================\n";

$sqlTicketAnalysis = "
SELECT t.id, t.total_price,
       SUM(ti.total_price) as items_total,
       COUNT(ti.id) as items_count,
       COUNT(tim.id) as modifiers_count,
       SUM(COALESCE(tim.total_price, 0)) as modifiers_total,
       COALESCE(SUM(td.value), 0) as ticket_discounts,
       COALESCE(SUM(tid.amount), 0) as item_discounts
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
LEFT JOIN public.ticket_item_discount tid ON tid.ticket_itemid = ti.id
LEFT JOIN public.ticket_discount td ON td.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0
GROUP BY t.id, t.total_price
ORDER BY t.id
";

$stmt = $pdo->query($sqlTicketAnalysis);
$tickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

$ticketTotal = 0;
foreach ($tickets as $ticket) {
    $discounts = $ticket['ticket_discounts'] + $ticket['item_discounts'];
echo "Ticket {$ticket['id']}: Items=\${$ticket['items_total']}, Modifiers=\${$ticket['modifiers_total']}, Discounts=\${$discounts}, Final=\${$ticket['total_price']}\n";
    $ticketTotal += $ticket['items_total'];
}

echo "\nSum of all ticket items: \${$ticketTotal}\n";
echo "Difference from Floreant: \${$ticketTotal - $floreantItems}\n";

// Final validation
echo "\n\nFINAL VALIDATION:\n";
echo "==================\n";

if ($diffItems < 0.01 && $diffModifiers < 0.01 && $diffDiscounts < 0.01) {
    echo "🎉 EXACT MATCH FOUND!\n";
    echo "The calculation method replicates Floreant exactly.\n";
} else {
    echo "❌ Still not matching exactly.\n";
    echo "Remaining differences:\n";
    echo "- Items: \${$diffItems}\n";
    echo "- Modifiers: \${$diffModifiers}\n";
    echo "- Discounts: \${$diffDiscounts}\n";

    if ($diffItems >= 0.01) {
        echo "\nPossible causes for items difference:\n";
        echo "1. Rounding differences in the database\n";
        echo "2. Additional filtering criteria not identified\n";
        echo "3. Different date range or time zone handling\n";
    }
}

$pdo = null;
?>