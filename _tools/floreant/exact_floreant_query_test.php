<?php
/**
 * Test with the exact same query structure that Floreant uses
 */

echo "=== EXACT FLOREANT QUERY TEST ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Floreant expected totals
$floreantItems = 631.00;
$floreantModifiers = 50.00;
$floreantDiscounts = 8.80;
$floreantNet = 622.20;  // $631 - $8.80

echo "FLOREANT EXPECTED:\n";
echo "Items: \${$floreantItems}\n";
echo "Modifiers: \${$floreantModifiers}\n";
echo "Discounts: \${$floreantDiscounts}\n\n";

// Let's use the same query that Floreant uses for "Item Sales Grand Total"
// Based on our analysis, it should exclude tickets with total_price = 0
$sql = "
SELECT
    SUM(ti.total_price) as items_gross,
    SUM(COALESCE(tim.total_price, 0)) as modifiers_gross,
    COALESCE(SUM(tid.amount), 0) as item_discounts,
    COALESCE(SUM(td.value), 0) as ticket_discounts,
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

echo "EXACT QUERY:\n";
echo $sql . "\n\n";

$stmt = $pdo->query($sql);
$result = $stmt->fetch(PDO::FETCH_ASSOC);

echo "RESULTS:\n";
echo "========\n";
echo "Items Gross: \${$result['items_gross']}\n";
echo "Modifiers Gross: \${$result['modifiers_gross']}\n";
echo "Item Discounts: \${$result['item_discounts']}\n";
echo "Ticket Discounts: \${$result['ticket_discounts']}\n";
echo "Total Discounts: \${$result['total_discounts']}\n";
echo "Items Net: \${$result['items_net']}\n\n";

// Compare with Floreant
echo "COMPARISON WITH FLOREANT:\n";
echo "=========================\n";

$differenceItems = abs($result['items_gross'] - $floreantItems);
$differenceModifiers = abs($result['modifiers_gross'] - $floreantModifiers);
$differenceDiscounts = abs($result['total_discounts'] - $floreantDiscounts);

echo "Items: Expected=\${$floreantItems}, Got=\${$result['items_grosso']}, Difference=\${$differenceItems}\n";
echo "Modifiers: Expected=\${$floreantModifiers}, Got=\${$result['modifiers_gross']}, Difference=\${$differenceModifiers}\n";
echo "Discounts: Expected=\${$floreantDiscounts}, Got=\${$result['total_discounts']}, Difference=\${$differenceDiscounts}\n\n";

// Check if we have a match
$itemsMatch = $differenceItems < 0.01;
$modifiersMatch = $differenceModifiers < 0.01;
$discountsMatch = $differenceDiscounts < 0.01;

if ($itemsMatch && $modifiersMatch && $discountsMatch) {
    echo "🎉 PERFECT MATCH! The query produces exactly the same totals as Floreant.\n";
} else {
    echo "❌ Still not matching. Let's debug further.\n";

    // Let's check what tickets are included/excluded
    echo "\nDEBUG - TICKETS INCLUSION:\n";
    echo "========================\n";

    // Get all tickets with paid=true and voided=false
    $sqlAllTickets = "
    SELECT t.id, t.total_price, t.total_discount,
           COUNT(ti.id) as items_count,
           SUM(ti.total_price) as items_total
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    WHERE DATE(t.folio_date) = '2025-12-16'
      AND t.paid = true
      AND t.voided = false
    GROUP BY t.id, t.total_price, t.total_discount
    ORDER BY t.id
    ";

    $stmt = $pdo->query($sqlAllTickets);
    $allTickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "All tickets (paid=true, voided=false):\n";
    foreach ($allTickets as $ticket) {
        $included = $ticket['total_price'] > 0 ? "INCLUDED" : "EXCLUDED";
        echo "- Ticket {$ticket['id']}: Items=\${$ticket['items_total']}, Final=\${$ticket['total_price']} - {$included}\n";
    }

    // Let's try a different approach - maybe the discount calculation is different
    echo "\nALTERNATIVE DISCOUNT CALCULATION:\n";
    echo "================================\n";

    $sqlAlt = "
    SELECT
        SUM(ti.total_price) as items_gross,
        SUM(COALESCE(tim.total_price, 0)) as modifiers,
        -- Try different discount calculation
        (SELECT COALESCE(SUM(amount), 0) FROM public.ticket_item_discount WHERE ticket_itemid IN (SELECT id FROM public.ticket_item WHERE ticket_id IN (SELECT id FROM public.ticket WHERE DATE(folio_date) = '2025-12-16' AND paid = true AND voided = false AND total_price > 0))) as item_discounts,
        (SELECT COALESCE(SUM(value), 0) FROM public.ticket_discount WHERE ticket_id IN (SELECT id FROM public.ticket WHERE DATE(folio_date) = '2025-12-16' AND paid = true AND voided = false AND total_price > 0)) as ticket_discounts
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
    WHERE DATE(t.folio_date) = '2025-12-16'
      AND t.paid = true
      AND t.voided = false
      AND t.total_price > 0
    ";

    $stmt = $pdo->query($sqlAlt);
    $resultAlt = $stmt->fetch(PDO::FETCH_ASSOC);

    echo "Alternative discount calculation:\n";
    echo "Items: \${$resultAlt['items_gross']}\n";
    echo "Modifiers: \${$resultAlt['modifiers']}\n";
    echo "Item Discounts: \${$resultAlt['item_discounts']}\n";
    echo "Ticket Discounts: \${$resultAlt['ticket_discounts']}\n";
}

$pdo = null;
?>