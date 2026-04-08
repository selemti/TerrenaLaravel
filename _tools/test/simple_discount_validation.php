<?php
/**
 * Simple validation for discount source
 */

echo "=== SIMPLE DISCOUNT SOURCE VALIDATION ===\n\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Get total from ticket_item_discount
$sqlItem = "SELECT SUM(amount) as total FROM public.ticket_item_discount
            WHERE ticket_itemid IN (
                SELECT id FROM public.ticket_item
                WHERE ticket_id IN (
                    SELECT id FROM public.ticket
                    WHERE DATE(folio_date) = '2025-12-16'
                    AND paid = true AND voided = false AND total_price > 0
                )
            )";

$stmt = $pdo->query($sqlItem);
$itemResult = $stmt->fetch(PDO::FETCH_ASSOC);
$itemTotal = $itemResult['total'] ?? 0;

// Get total from ticket_discount
$sqlTicket = "SELECT COALESCE(SUM(
    CASE
        WHEN type = 1 THEN (value / 100) * sub_total
        ELSE 0
    END
), 0) as total FROM public.ticket_discount
            WHERE ticket_id IN (
                SELECT id FROM public.ticket
                WHERE DATE(folio_date) = '2025-12-16'
                AND paid = true AND voided = false AND total_price > 0
            )";

$stmt = $pdo->query($sqlTicket);
$ticketResult = $stmt->fetch(PDO::FETCH_ASSOC);
$ticketTotal = $ticketResult['total'] ?? 0;

$floreantExpected = 8.80;

echo "RESULTS:\n";
echo "========\n";
echo "Item discounts total: \${$itemTotal}\n";
echo "Ticket discounts total: \${$ticketTotal}\n";
$combinedTotal = $itemTotal + $ticketTotal;
echo "Combined total: \${$combinedTotal}\n";
echo "Floreant expected: \${$floreantExpected}\n\n";

// Check matches
$itemMatches = abs($itemTotal - $floreantExpected) < 0.01;
$ticketMatches = abs($ticketTotal - $floreantExpected) < 0.01;
$combinedMatches = abs(($itemTotal + $ticketTotal) - $floreantExpected) < 0.01;

echo "MATCH ANALYSIS:\n";
echo "==============\n";
echo "Item discounts only matches $8.80: " . ($itemMatches ? "✅ YES" : "❌ NO") . "\n";
echo "Ticket discounts only matches $8.80: " . ($ticketMatches ? "✅ YES" : "❌ NO") . "\n";
echo "Combined matches $8.80: " . ($combinedMatches ? "✅ YES" : "❌ NO") . "\n\n";

if ($itemMatches) {
    echo "✅ CONCLUSION: The $8.80 comes ONLY from item_discounts\n";
} elseif ($ticketMatches) {
    echo "✅ CONCLUSION: The $8.80 comes ONLY from ticket_discounts\n";
} elseif ($combinedMatches) {
    echo "✅ CONCLUSION: The $8.80 comes from both tables combined\n";
} else {
    echo "❌ CONCLUSION: Unable to determine exact source of $8.80\n";
}

// Show the actual record
echo "\n\nACTUAL DISCOUNT RECORD:\n";
echo "======================\n";

$sqlRecord = "SELECT * FROM public.ticket_item_discount
              WHERE ticket_itemid IN (
                  SELECT id FROM public.ticket_item
                  WHERE ticket_id IN (
                      SELECT id FROM public.ticket
                      WHERE DATE(folio_date) = '2025-12-16'
                      AND paid = true AND voided = false AND total_price > 0
                  )
              )";

$stmt = $pdo->query($sqlRecord);
$records = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($records as $record) {
    echo "Record ID {$record['id']}: {$record['name']}\n";
    echo "  Amount: \${$record['amount']}\n";
    echo "  Type: {$record['type']}\n";
    echo "  Value: {$record['value']}\n";
    echo "  Ticket Item ID: {$record['ticket_itemid']}\n";
}

$pdo = null;
?>