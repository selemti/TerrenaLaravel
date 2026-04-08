<?php
/**
 * Simple test for the fixed "Conciliación Floreant" mode
 */

require_once __DIR__ . '/vendor/autoload.php';

use App\Services\Reports\ItemModsReportService;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

echo "=== VALIDACIÓN: CONCILIACIÓN FLOREANT (CORREGIDO) ===\n\n";

try {
    // Expected totals from Floreant PDF
    $expected = [
        'items' => 631.00,
        'modifiers' => 50.00,
        'discounts' => 8.80,
        'net' => 622.20
    ];

    echo "FLOREANT ESPERADO:\n";
    echo "==================\n";
    echo "Items: \${$expected['items']}\n";
    echo "Modifiers: \${$expected['modifiers']}\n";
    echo "Discounts: \${$expected['discounts']}\n";
    echo "Net: \${$expected['net']}\n\n";

    // Create service instance
    $service = new ItemModsReportService();

    // Test for 2025-12-16 with floreant_conciliation mode
    $start = Carbon::create(2025, 12, 16)->startOfDay();
    $end = Carbon::create(2025, 12, 16)->endOfDay();
    $filters = [
        'view' => 'item_mod_combos',
        'sales_mode' => 'floreant_conciliation',
        'include_empty' => true,
    ];

    // Get data using the service
    $dataset = $service->fetch($start, $end, $filters);
    $summary = $service->summarize($dataset, 'item_mod_combos', 'floreant_conciliation');

    echo "CONCILIACIÓN FLOREANT ACTUAL (CORREGIDO):\n";
    echo "=======================================\n";
    $itemsTotal = isset($summary['items_total']) ? $summary['items_total'] : 'N/A';
    $modifiersTotal = isset($summary['modifiers_total']) ? $summary['modifiers_total'] : 'N/A';
    $discountsTotal = isset($summary['discounts_total']) ? $summary['discounts_total'] : 'N/A';
    $netTotal = isset($summary['net_total']) ? $summary['net_total'] : 'N/A';

    echo "Items: \${$itemsTotal}\n";
    echo "Modifiers: \${$modifiersTotal}\n";
    echo "Discounts: \${$discountsTotal}\n";
    echo "Net: \${$netTotal}\n\n";

    // Validation
    echo "VALIDACIÓN:\n";
    echo "============\n";

    $itemsMatch = abs(($itemsTotal ?: 0) - $expected['items']) < 0.01;
    $modifiersMatch = abs(($modifiersTotal ?: 0) - $expected['modifiers']) < 0.01;
    $discountsMatch = abs(($discountsTotal ?: 0) - $expected['discounts']) < 0.01;
    $netMatch = abs(($netTotal ?: 0) - $expected['net']) < 0.01;

    echo "Items: " . ($itemsMatch ? "✅ EXACTO (\${$itemsTotal})" : "❌ DIFERENTE (\${$itemsTotal} vs \${$expected['items']})") . "\n";
    echo "Modifiers: " . ($modifiersMatch ? "✅ EXACTO (\${$modifiersTotal})" : "❌ DIFERENTE (\${$modifiersTotal} vs \${$expected['modifiers']})") . "\n";
    echo "Discounts: " . ($discountsMatch ? "✅ EXACTO (\${$discountsTotal})" : "❌ DIFERENTE (\${$discountsTotal} vs \${$expected['discounts']})") . "\n";
    echo "Net: " . ($netMatch ? "✅ EXACTO (\${$netTotal})" : "❌ DIFERENTE (\${$netTotal} vs \${$expected['net']})") . "\n";

    // Overall validation
    if ($itemsMatch && $modifiersMatch && $discountsMatch && $netMatch) {
        echo "\n🎉 VALIDACIÓN EXITOSA: Todos los montos coinciden exactamente con Floreant!\n";
    } else {
        echo "\n❌ VALIDACIÓN FALLIDA: No todos los montos coinciden exactamente\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}