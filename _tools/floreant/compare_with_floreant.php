<?php
/**
 * Compare our calculations with what Floreant should include
 */

echo "=== COMPARAR CON FLOREANT ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Floreant totals from the text report
$floreant_items = 631.00;
$floreant_modifiers = 50.00;
$floreant_discounts = 8.80;
$floreant_net = 622.20;  // $631 - $8.80

echo "FLOREANT REPORT Totals:\n";
echo "=======================\n";
echo "Items Grand Total: \${$floreant_items}\n";
echo "Modifiers Grand Total: \${$floreant_modifiers}\n";
echo "Total Discounts: \${$floreant_discounts}\n";
echo "Net Sales: \${$floreant_net}\n\n";

// Our SQL calculation
$sql = "
SELECT
    SUM(ti.total_price) as sql_items,
    SUM(COALESCE(tim.total_price, 0)) as sql_modifiers
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sql);
$result = $stmt->fetch(PDO::FETCH_ASSOC);

echo "OUR SQL Totals:\n";
echo "===============\n";
echo "Items: \${$result['sql_items']}\n";
echo "Modifiers: \${$result['sql_modifiers']}\n\n";

// Calculate the difference
$items_diff = $result['sql_items'] - $floreant_items;
$modifiers_diff = $result['sql_modifiers'] - $floreant_modifiers;

echo "DIFFERENCES:\n";
echo "============\n";
echo "Items difference: \${$items_diff}\n";
echo "Modifiers difference: \${$modifiers_diff}\n\n";

// Let's check individual ticket items vs what Floreant includes
$sql_items = "
SELECT ti.id, ti.item_name, ti.item_count, ti.item_price, ti.total_price,
       t.id as ticket_id, t.total_price as ticket_total, t.total_discount as ticket_discount
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ti.total_price > 0
ORDER BY t.id, ti.total_price DESC
";

$stmt = $pdo->query($sql_items);
$items = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "ALL ITEMS BY TICKET:\n";
echo "====================\n";
$sql_total = 0;
$included_total = 0;

foreach ($items as $item) {
    $status = "INCLUDED";

    // Check if Floreant would exclude this item
    if ($item['ticket_total'] == 0) {
        $status = "EXCLUDED (ticket 100% discount)";
    } elseif ($item['total_price'] == 0) {
        $status = "EXCLUDED (item zero price)";
    }

    echo "- {$item['item_name']} (Ticket {$item['ticket_id']}): \${$item['total_price']} - {$status}\n";

    $sql_total += $item['total_price'];
    if ($status == "INCLUDED") {
        $included_total += $item['total_price'];
    }
}

echo "\nSQL Total: \${$sql_total}\n";
echo "Included Total: \${$included_total}\n";
echo "Floreant Expected: \${$floreant_items}\n";
$difference_calc = $included_total - $floreant_items;
echo "Difference: \${$difference_calc}\n\n";

// Let's check if there's an item that exactly accounts for the difference
$difference = $included_total - $floreant_items;
echo "Looking for an item worth \${$difference}...\n";

if (abs($difference) > 0.01) {
    echo "STILL A DISCREPANCY OF \${$difference}\n";
    echo "This suggests Floreant has additional filtering logic.\n";

    // Let's check if there are any items with special characteristics
    echo "\nChecking for items with zero or negative prices:\n";
    $sql_zero = "
    SELECT ti.item_name, ti.total_price, ti.item_price
    FROM public.ticket_item ti
    JOIN public.ticket t ON t.id = ti.ticket_id
    WHERE DATE(t.folio_date) = '2025-12-16'
      AND t.paid = true
      AND t.voided = false
      AND (ti.item_price <= 0 OR ti.total_price <= 0)
    ";

    $stmt = $pdo->query($sql_zero);
    $zero_items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($zero_items) {
        foreach ($zero_items as $item) {
            echo "- {$item['item_name']}: price=\${$item['item_price']}, total=\${$item['total_price']}\n";
        }
    } else {
        echo "No items with zero or negative prices found.\n";
    }
}

$pdo = null;
?>