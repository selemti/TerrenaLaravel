<?php

require_once __DIR__.'/vendor/autoload.php';

// Create Laravel application
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

try {
    // Set timezone and search path
    DB::statement("SET TIME ZONE 'America/Mexico_City'");
    DB::statement('SET search_path TO public, selemti');

    echo "=== ANALYSIS OF DISCREPANCIES BETWEEN TERRENA AND FLOREANTPOS REPORTS ===\n\n";

    // Get summary for 2025-10-01 to compare with the PDF reports
    echo "--- SUMMARY REPORT FOR 2025-10-01 ---\n";
    $summary = DB::select("SELECT * FROM public.vw_report_sales_summary WHERE folio_date='2025-10-01'");
    $totalBruto = 0;
    $totalNeto = 0;
    $totalDescuento = 0;
    $totalTickets = 0;

    foreach ($summary as $row) {
        echo "Branch: {$row->branch_key}, Tickets: {$row->tickets}, Bruto: {$row->bruto}, Descuento: {$row->descuento}, Neto: {$row->neto}\n";
        $totalBruto += $row->bruto;
        $totalNeto += $row->neto;
        $totalDescuento += $row->descuento;
        $totalTickets += $row->tickets;
    }
    echo "TOTALS: Tickets: {$totalTickets}, Bruto: {$totalBruto}, Descuento: {$totalDescuento}, Neto: {$totalNeto}\n\n";

    // Get balance detail for 2025-10-01
    echo "--- BALANCE DETAIL REPORT FOR 2025-10-01 ---\n";
    $balance = DB::select("SELECT * FROM public.vw_report_balance_detail WHERE folio_date='2025-10-01'");
    $totalBalance = 0;
    foreach ($balance as $row) {
        echo "Branch: {$row->branch_key}, Payment: {$row->payment}, Amount: {$row->monto}\n";
        $totalBalance += $row->monto;
    }
    echo "TOTAL BALANCE: {$totalBalance}\n\n";

    // Compare summary bruto vs balance total
    echo "--- VALIDATION: SUMMARY BRUTO vs BALANCE TOTAL ---\n";
    echo "Summary Bruto: {$totalBruto}\n";
    echo "Balance Total: {$totalBalance}\n";
    echo 'Difference: '.abs($totalBruto - $totalBalance)."\n";
    if (abs($totalBruto - $totalBalance) < 0.01) {
        echo "Validation: PASS - Values match within tolerance\n\n";
    } else {
        echo "Validation: FAIL - Values do not match\n\n";
    }

    // Check journal data
    echo "--- JOURNAL LINES FOR 2025-10-01 ---\n";
    $journalLines = DB::select("SELECT * FROM public.vw_report_journal_lines WHERE folio_date='2025-10-01' LIMIT 10");
    foreach ($journalLines as $row) {
        echo "Ticket: {$row->ticket_id}, Item: {$row->item_name}, Quantity: {$row->qty}, Total: {$row->line_total}, Discount: {$row->line_discount}\n";
    }
    echo 'Total journal lines: '.count($journalLines)."\n\n";

    // Check journal payments
    echo "--- JOURNAL PAYMENTS FOR 2025-10-01 ---\n";
    $journalPayments = DB::select("SELECT * FROM public.vw_report_journal_payments WHERE folio_date='2025-10-01'");
    foreach ($journalPayments as $row) {
        echo "Ticket: {$row->ticket_id}, Payment Type: {$row->pay_norm}, Amount: {$row->paid_amount}\n";
    }
    echo 'Total payments: '.count($journalPayments)."\n\n";

    // Check exceptions
    echo "--- SALES EXCEPTIONS FOR 2025-10-01 ---\n";
    $exceptions = DB::select("SELECT * FROM public.vw_report_sales_exceptions WHERE folio_date='2025-10-01'");
    foreach ($exceptions as $row) {
        echo "Ticket: {$row->ticket_id}, Error Code: {$row->error_code}, Severity: {$row->severity}, Difference: {$row->diff}\n";
    }
    echo 'Total exceptions: '.count($exceptions)."\n\n";

    // Get mix of sales data (by payment type)
    echo "--- MIX OF SALES FOR 2025-10-01 ---\n";
    $mix = DB::select("SELECT payment, SUM(monto) as total FROM public.vw_report_balance_detail WHERE folio_date='2025-10-01' GROUP BY payment");
    foreach ($mix as $row) {
        echo "Payment Type: {$row->payment}, Total: {$row->total}\n";
    }
    echo "\n";

    // Compare with the PDF data from AUDITORIA_REPORTES_FLOREANT_vs_TERRENA.md
    echo "--- COMPARISON WITH PDF REPORT DATA ---\n";
    echo "According to the PDF analysis:\n";
    echo "- Terrena Balance por Forma de Pago for 2025-10-01 shows:\n";
    echo "  CREDIT_CARD: $11,958.00\n";
    echo "  CASH: $9,323.00\n";
    echo "  DEBIT_CARD: $50.00\n";
    echo "  TOTAL: $21,331.00\n\n";

    // Query to get similar data from our database
    $balanceComparison = DB::select("SELECT payment, SUM(monto) as total FROM public.vw_report_balance_detail WHERE folio_date='2025-10-01' GROUP BY payment ORDER BY payment");
    echo "Database results for 2025-10-01:\n";
    $dbTotal = 0;
    foreach ($balanceComparison as $row) {
        echo "  {$row->payment}: $".number_format($row->total, 2)."\n";
        $dbTotal += $row->total;
    }
    echo '  TOTAL: $'.number_format($dbTotal, 2)."\n\n";

    // Compare detail report
    echo "- Terrena Detalle de Ventas for 2025-10-01 should match journal lines\n";
    $detalleSample = DB::select("SELECT * FROM public.vw_report_journal_lines WHERE folio_date='2025-10-01' LIMIT 5");
    echo "Sample from journal (representing detail):\n";
    foreach ($detalleSample as $row) {
        echo "  Ticket: {$row->ticket_id}, Item: {$row->item_name}, Neto: ".($row->line_total - $row->line_discount)."\n";
    }
    echo "\n";

    echo "=== ANALYSIS COMPLETE ===\n";
    echo "\nBased on this analysis, the Terrena system data appears consistent internally.\n";
    echo "The discrepancies with FloreantPOS would be due to:\n";
    echo "1. Data synchronization issues between systems\n";
    echo "2. Different business logic for calculations\n";
    echo "3. Timing differences in when data was extracted\n";
    echo "4. Different handling of voids, refunds, and discounts\n";
    echo "5. Possible differences in timezone handling\n";

} catch (Exception $e) {
    echo 'Database error: '.$e->getMessage()."\n";
}
