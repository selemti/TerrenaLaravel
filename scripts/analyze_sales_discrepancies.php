<?php
/**
 * Script de Análisis de Discrepancias en Ventas
 * Analiza Agosto, Septiembre y Octubre 2025
 * 
 * Este script revisa:
 * - Tickets con descuentos al 100%
 * - Tickets no pagados pero cerrados
 * - Tickets anulados con transacciones
 * - Discrepancias entre totales y pagos
 * - Patrones de errores en reportes de caja
 */

require __DIR__ . '/../vendor/autoload.php';

$app = require_once __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

class SalesDiscrepancyAnalyzer
{
    private $startDate;
    private $endDate;
    private $results = [];
    
    public function __construct($startDate, $endDate)
    {
        $this->startDate = $startDate;
        $this->endDate = $endDate;
    }
    
    public function analyze()
    {
        echo "═══════════════════════════════════════════════════════════════════════\n";
        echo "  ANÁLISIS DE DISCREPANCIAS EN VENTAS\n";
        echo "  Período: {$this->startDate} al {$this->endDate}\n";
        echo "═══════════════════════════════════════════════════════════════════════\n\n";
        
        $this->analyzeTicketsWithFullDiscount();
        $this->analyzeUnpaidTickets();
        $this->analyzeVoidedTicketsWithPayments();
        $this->analyzePaymentMismatches();
        $this->analyzeDrawerPullReports();
        $this->generateSummary();
        
        return $this->results;
    }
    
    /**
     * Analiza tickets con descuento del 100%
     */
    private function analyzeTicketsWithFullDiscount()
    {
        echo "\n[1] TICKETS CON DESCUENTO DEL 100%\n";
        echo str_repeat("-", 70) . "\n";
        
        $tickets = DB::connection('pgsql')->select("
            SELECT 
                t.id,
                t.folio_date,
                t.create_date,
                t.active_date,
                t.closing_date,
                t.paid,
                t.voided,
                t.total_price as total,
                t.total_discount as discount_amount,
                t.void_reason as discount_name,
                COALESCE(SUM(ti.total_price), 0) as items_total,
                COUNT(ti.id) as item_count
            FROM public.ticket t
            LEFT JOIN public.ticket_item ti ON t.id = ti.ticket_id
            WHERE t.folio_date BETWEEN ? AND ?
                AND t.total_discount > 0
                AND t.total_price = 0
            GROUP BY t.id, t.folio_date, t.create_date, t.active_date, t.closing_date, 
                     t.paid, t.voided, t.total_price, t.total_discount, t.void_reason
            ORDER BY t.folio_date, t.id
        ", [$this->startDate, $this->endDate]);
        
        $totalAmount = 0;
        $byMonth = [];
        
        foreach ($tickets as $ticket) {
            $month = substr($ticket->folio_date, 0, 7);
            if (!isset($byMonth[$month])) {
                $byMonth[$month] = ['count' => 0, 'amount' => 0, 'paid' => 0, 'unpaid' => 0];
            }
            
            $byMonth[$month]['count']++;
            $byMonth[$month]['amount'] += $ticket->discount_amount;
            
            if ($ticket->paid === 't' || $ticket->paid === true) {
                $byMonth[$month]['paid']++;
            } else {
                $byMonth[$month]['unpaid']++;
            }
            
            $totalAmount += $ticket->discount_amount;
        }
        
        echo sprintf("Total de tickets con descuento 100%%: %d\n", count($tickets));
        echo sprintf("Monto total descontado: $%s\n\n", number_format($totalAmount, 2));
        
        echo "Desglose por mes:\n";
        foreach ($byMonth as $month => $data) {
            echo sprintf(
                "  %s: %d tickets, $%s descontado (Pagados: %d, No pagados: %d)\n",
                $month,
                $data['count'],
                number_format($data['amount'], 2),
                $data['paid'],
                $data['unpaid']
            );
        }
        
        // Mostrar algunos ejemplos
        echo "\nEjemplos de tickets con descuento 100%:\n";
        $examples = array_slice($tickets, 0, 5);
        foreach ($examples as $ticket) {
            echo sprintf(
                "  ID: %d | Fecha: %s | Descuento: $%s | Nombre: %s | Pagado: %s | Cerrado: %s\n",
                $ticket->id,
                $ticket->folio_date,
                number_format($ticket->discount_amount, 2),
                $ticket->discount_name ?? 'N/A',
                ($ticket->paid === 't' || $ticket->paid === true) ? 'Sí' : 'No',
                $ticket->closing_date ? 'Sí' : 'No'
            );
        }
        
        $this->results['full_discount_tickets'] = [
            'total' => count($tickets),
            'amount' => $totalAmount,
            'by_month' => $byMonth,
            'tickets' => $tickets
        ];
    }
    
    /**
     * Analiza tickets no pagados pero cerrados
     */
    private function analyzeUnpaidTickets()
    {
        echo "\n\n[2] TICKETS NO PAGADOS PERO CERRADOS\n";
        echo str_repeat("-", 70) . "\n";
        
        $tickets = DB::connection('pgsql')->select("
            SELECT 
                t.id,
                t.folio_date,
                t.total_price as total,
                t.total_discount as discount_amount,
                t.paid,
                t.voided,
                t.closing_date,
                COALESCE(SUM(tr.amount), 0) as total_transactions
            FROM public.ticket t
            LEFT JOIN public.transactions tr ON t.id = tr.ticket_id 
                AND tr.payment_type NOT IN ('REFUND', 'VOID_TRANS')
            WHERE t.folio_date BETWEEN ? AND ?
                AND (t.paid = FALSE OR t.paid IS NULL)
                AND t.closing_date IS NOT NULL
                AND t.voided = FALSE
                AND t.total_price > 0
            GROUP BY t.id, t.folio_date, t.total_price, t.total_discount, t.paid, t.voided, t.closing_date
            ORDER BY t.folio_date, t.id
        ", [$this->startDate, $this->endDate]);
        
        $totalAmount = 0;
        $byMonth = [];
        
        foreach ($tickets as $ticket) {
            $month = substr($ticket->folio_date, 0, 7);
            if (!isset($byMonth[$month])) {
                $byMonth[$month] = ['count' => 0, 'amount' => 0];
            }
            
            $byMonth[$month]['count']++;
            $byMonth[$month]['amount'] += $ticket->total;
            $totalAmount += $ticket->total;
        }
        
        echo sprintf("Total de tickets no pagados pero cerrados: %d\n", count($tickets));
        echo sprintf("Monto total no cobrado: $%s\n\n", number_format($totalAmount, 2));
        
        echo "Desglose por mes:\n";
        foreach ($byMonth as $month => $data) {
            echo sprintf(
                "  %s: %d tickets, $%s no cobrado\n",
                $month,
                $data['count'],
                number_format($data['amount'], 2)
            );
        }
        
        // Mostrar ejemplos
        echo "\nEjemplos de tickets no pagados:\n";
        $examples = array_slice($tickets, 0, 5);
        foreach ($examples as $ticket) {
            echo sprintf(
                "  ID: %d | Fecha: %s | Total: $%s | Transacciones: $%s | Diferencia: $%s\n",
                $ticket->id,
                $ticket->folio_date,
                number_format($ticket->total, 2),
                number_format($ticket->total_transactions, 2),
                number_format($ticket->total - $ticket->total_transactions, 2)
            );
        }
        
        $this->results['unpaid_tickets'] = [
            'total' => count($tickets),
            'amount' => $totalAmount,
            'by_month' => $byMonth,
            'tickets' => $tickets
        ];
    }
    
    /**
     * Analiza tickets anulados con transacciones
     */
    private function analyzeVoidedTicketsWithPayments()
    {
        echo "\n\n[3] TICKETS ANULADOS CON TRANSACCIONES\n";
        echo str_repeat("-", 70) . "\n";
        
        $tickets = DB::connection('pgsql')->select("
            SELECT 
                t.id,
                t.folio_date,
                t.total_price as total,
                t.voided,
                t.closing_date as void_date,
                COUNT(tr.id) as transaction_count,
                SUM(CASE WHEN tr.payment_type = 'CASH' THEN tr.amount ELSE 0 END) as cash_amount,
                SUM(CASE WHEN tr.payment_type = 'CREDIT_CARD' THEN tr.amount ELSE 0 END) as card_amount,
                SUM(CASE WHEN tr.payment_type = 'REFUND' THEN tr.amount ELSE 0 END) as refund_amount,
                SUM(CASE WHEN tr.payment_type = 'VOID_TRANS' THEN tr.amount ELSE 0 END) as void_amount,
                SUM(tr.amount) as total_transactions
            FROM public.ticket t
            LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
            WHERE t.folio_date BETWEEN ? AND ?
                AND t.voided = TRUE
            GROUP BY t.id, t.folio_date, t.total_price, t.voided, t.closing_date
            HAVING COUNT(tr.id) > 0
            ORDER BY t.folio_date, t.id
        ", [$this->startDate, $this->endDate]);
        
        $totalAmount = 0;
        $byMonth = [];
        
        foreach ($tickets as $ticket) {
            $month = substr($ticket->folio_date, 0, 7);
            if (!isset($byMonth[$month])) {
                $byMonth[$month] = ['count' => 0, 'amount' => 0];
            }
            
            $byMonth[$month]['count']++;
            $byMonth[$month]['amount'] += $ticket->total_transactions;
            $totalAmount += $ticket->total_transactions;
        }
        
        echo sprintf("Total de tickets anulados con transacciones: %d\n", count($tickets));
        echo sprintf("Monto total en transacciones: $%s\n\n", number_format($totalAmount, 2));
        
        echo "Desglose por mes:\n";
        foreach ($byMonth as $month => $data) {
            echo sprintf(
                "  %s: %d tickets, $%s en transacciones\n",
                $month,
                $data['count'],
                number_format($data['amount'], 2)
            );
        }
        
        // Mostrar ejemplos
        echo "\nEjemplos de tickets anulados con transacciones:\n";
        $examples = array_slice($tickets, 0, 5);
        foreach ($examples as $ticket) {
            echo sprintf(
                "  ID: %d | Fecha: %s | Total: $%s | Cash: $%s | Card: $%s | Refund: $%s | Void: $%s\n",
                $ticket->id,
                $ticket->folio_date,
                number_format($ticket->total, 2),
                number_format($ticket->cash_amount, 2),
                number_format($ticket->card_amount, 2),
                number_format($ticket->refund_amount, 2),
                number_format($ticket->void_amount, 2)
            );
        }
        
        $this->results['voided_with_payments'] = [
            'total' => count($tickets),
            'amount' => $totalAmount,
            'by_month' => $byMonth,
            'tickets' => $tickets
        ];
    }
    
    /**
     * Analiza discrepancias entre total y pagos
     */
    private function analyzePaymentMismatches()
    {
        echo "\n\n[4] TICKETS CON DISCREPANCIA ENTRE TOTAL Y PAGOS\n";
        echo str_repeat("-", 70) . "\n";
        
        $tickets = DB::connection('pgsql')->select("
            SELECT 
                t.id,
                t.folio_date,
                t.total_price as total,
                t.total_discount as discount_amount,
                t.paid,
                t.voided,
                COALESCE(SUM(CASE 
                    WHEN tr.payment_type NOT IN ('REFUND', 'VOID_TRANS') 
                    THEN tr.amount 
                    ELSE 0 
                END), 0) as total_payments,
                (t.total_price - COALESCE(SUM(CASE 
                    WHEN tr.payment_type NOT IN ('REFUND', 'VOID_TRANS') 
                    THEN tr.amount 
                    ELSE 0 
                END), 0)) as difference
            FROM public.ticket t
            LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
            WHERE t.folio_date BETWEEN ? AND ?
                AND t.voided = FALSE
            GROUP BY t.id, t.folio_date, t.total_price, t.total_discount, t.paid, t.voided
            HAVING ABS(t.total_price - COALESCE(SUM(CASE 
                WHEN tr.payment_type NOT IN ('REFUND', 'VOID_TRANS') 
                THEN tr.amount 
                ELSE 0 
            END), 0)) > 0.01
            ORDER BY ABS(t.total_price - COALESCE(SUM(CASE 
                WHEN tr.payment_type NOT IN ('REFUND', 'VOID_TRANS') 
                THEN tr.amount 
                ELSE 0 
            END), 0)) DESC
        ", [$this->startDate, $this->endDate]);
        
        $totalDifference = 0;
        $byMonth = [];
        
        foreach ($tickets as $ticket) {
            $month = substr($ticket->folio_date, 0, 7);
            if (!isset($byMonth[$month])) {
                $byMonth[$month] = ['count' => 0, 'difference' => 0];
            }
            
            $byMonth[$month]['count']++;
            $byMonth[$month]['difference'] += abs($ticket->difference);
            $totalDifference += abs($ticket->difference);
        }
        
        echo sprintf("Total de tickets con discrepancia: %d\n", count($tickets));
        echo sprintf("Diferencia total absoluta: $%s\n\n", number_format($totalDifference, 2));
        
        echo "Desglose por mes:\n";
        foreach ($byMonth as $month => $data) {
            echo sprintf(
                "  %s: %d tickets, $%s de diferencia\n",
                $month,
                $data['count'],
                number_format($data['difference'], 2)
            );
        }
        
        // Mostrar los casos más graves
        echo "\nTop 10 mayores discrepancias:\n";
        $examples = array_slice($tickets, 0, 10);
        foreach ($examples as $ticket) {
            echo sprintf(
                "  ID: %d | Fecha: %s | Total: $%s | Pagado: $%s | Diferencia: $%s | Estado: %s\n",
                $ticket->id,
                $ticket->folio_date,
                number_format($ticket->total, 2),
                number_format($ticket->total_payments, 2),
                number_format($ticket->difference, 2),
                ($ticket->paid === 't' || $ticket->paid === true) ? 'Pagado' : 'No Pagado'
            );
        }
        
        $this->results['payment_mismatches'] = [
            'total' => count($tickets),
            'difference' => $totalDifference,
            'by_month' => $byMonth,
            'tickets' => $tickets
        ];
    }
    
    /**
     * Analiza los reportes de caja (Drawer Pull Reports)
     */
    private function analyzeDrawerPullReports()
    {
        echo "\n\n[5] ANÁLISIS DE REPORTES DE CAJA (DRAWER PULL REPORTS)\n";
        echo str_repeat("-", 70) . "\n";
        
        $reports = DB::connection('pgsql')->select("
            SELECT 
                dpr.id,
                DATE(dpr.report_time) as report_date,
                dpr.cash_receipt_amount as reported_cash,
                dpr.ticket_count as reported_tickets,
                dpr.net_sales as reported_net_sales,
                dpr.totaldiscountamount as reported_discounts,
                
                -- Calcular valores reales
                COALESCE(SUM(CASE 
                    WHEN tr.payment_type = 'CASH' 
                    THEN tr.amount 
                    ELSE 0 
                END), 0) as actual_cash,
                
                COUNT(DISTINCT CASE 
                    WHEN t.voided = FALSE AND t.closing_date IS NOT NULL 
                    THEN t.id 
                END) as actual_tickets,
                
                COALESCE(SUM(CASE 
                    WHEN t.voided = FALSE AND t.closing_date IS NOT NULL 
                    THEN t.total_price 
                    ELSE 0 
                END), 0) as actual_net_sales,
                
                COALESCE(SUM(CASE 
                    WHEN t.voided = FALSE 
                    THEN t.total_discount 
                    ELSE 0 
                END), 0) as actual_discounts
                
            FROM public.drawer_pull_report dpr
            LEFT JOIN public.ticket t ON DATE(t.folio_date) = DATE(dpr.report_time)
            LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
            WHERE DATE(dpr.report_time) BETWEEN ? AND ?
            GROUP BY dpr.id, dpr.report_time, dpr.cash_receipt_amount, 
                     dpr.ticket_count, dpr.net_sales, dpr.totaldiscountamount
            ORDER BY dpr.report_time
        ", [$this->startDate, $this->endDate]);
        
        $discrepancies = [];
        $totalCashDiff = 0;
        $totalTicketDiff = 0;
        $totalSalesDiff = 0;
        
        foreach ($reports as $report) {
            $cashDiff = $report->reported_cash - $report->actual_cash;
            $ticketDiff = $report->reported_tickets - $report->actual_tickets;
            $salesDiff = $report->reported_net_sales - $report->actual_net_sales;
            
            if (abs($cashDiff) > 0.01 || $ticketDiff != 0 || abs($salesDiff) > 0.01) {
                $discrepancies[] = [
                    'date' => $report->report_date,
                    'cash_diff' => $cashDiff,
                    'ticket_diff' => $ticketDiff,
                    'sales_diff' => $salesDiff,
                    'report' => $report
                ];
                
                $totalCashDiff += abs($cashDiff);
                $totalTicketDiff += abs($ticketDiff);
                $totalSalesDiff += abs($salesDiff);
            }
        }
        
        echo sprintf("Total de reportes analizados: %d\n", count($reports));
        echo sprintf("Reportes con discrepancias: %d\n\n", count($discrepancies));
        
        echo "Discrepancias totales:\n";
        echo sprintf("  Efectivo: $%s\n", number_format($totalCashDiff, 2));
        echo sprintf("  Tickets: %d\n", $totalTicketDiff);
        echo sprintf("  Ventas netas: $%s\n", number_format($totalSalesDiff, 2));
        
        // Mostrar reportes con discrepancias
        echo "\nReportes con discrepancias:\n";
        foreach ($discrepancies as $disc) {
            echo sprintf(
                "  Fecha: %s | Cash: $%s | Tickets: %d | Ventas: $%s\n",
                substr($disc['date'], 0, 10),
                number_format($disc['cash_diff'], 2),
                $disc['ticket_diff'],
                number_format($disc['sales_diff'], 2)
            );
        }
        
        $this->results['drawer_pull_discrepancies'] = [
            'total_reports' => count($reports),
            'with_discrepancies' => count($discrepancies),
            'total_cash_diff' => $totalCashDiff,
            'total_ticket_diff' => $totalTicketDiff,
            'total_sales_diff' => $totalSalesDiff,
            'discrepancies' => $discrepancies
        ];
    }
    
    /**
     * Genera resumen final
     */
    private function generateSummary()
    {
        echo "\n\n═══════════════════════════════════════════════════════════════════════\n";
        echo "  RESUMEN GENERAL\n";
        echo "═══════════════════════════════════════════════════════════════════════\n\n";
        
        echo "PROBLEMAS IDENTIFICADOS:\n\n";
        
        echo "1. Tickets con descuento 100%:\n";
        echo sprintf("   - Total: %d tickets\n", $this->results['full_discount_tickets']['total']);
        echo sprintf("   - Monto descontado: $%s\n", number_format($this->results['full_discount_tickets']['amount'], 2));
        echo sprintf("   - Impacto: Estos tickets pueden estar mal contabilizados en reportes\n\n");
        
        echo "2. Tickets no pagados pero cerrados:\n";
        echo sprintf("   - Total: %d tickets\n", $this->results['unpaid_tickets']['total']);
        echo sprintf("   - Monto no cobrado: $%s\n", number_format($this->results['unpaid_tickets']['amount'], 2));
        echo sprintf("   - Impacto: Ventas registradas sin ingreso real\n\n");
        
        echo "3. Tickets anulados con transacciones:\n";
        echo sprintf("   - Total: %d tickets\n", $this->results['voided_with_payments']['total']);
        echo sprintf("   - Monto en transacciones: $%s\n", number_format($this->results['voided_with_payments']['amount'], 2));
        echo sprintf("   - Impacto: Inconsistencia en el manejo de anulaciones\n\n");
        
        echo "4. Discrepancias pago vs total:\n";
        echo sprintf("   - Total: %d tickets\n", $this->results['payment_mismatches']['total']);
        echo sprintf("   - Diferencia total: $%s\n", number_format($this->results['payment_mismatches']['difference'], 2));
        echo sprintf("   - Impacto: Errores en el registro de pagos\n\n");
        
        echo "5. Discrepancias en reportes de caja:\n";
        echo sprintf("   - Reportes con problemas: %d\n", $this->results['drawer_pull_discrepancies']['with_discrepancies']);
        echo sprintf("   - Diferencia en efectivo: $%s\n", number_format($this->results['drawer_pull_discrepancies']['total_cash_diff'], 2));
        echo sprintf("   - Diferencia en tickets: %d\n", $this->results['drawer_pull_discrepancies']['total_ticket_diff']);
        echo sprintf("   - Diferencia en ventas: $%s\n", number_format($this->results['drawer_pull_discrepancies']['total_sales_diff'], 2));
        
        echo "\n═══════════════════════════════════════════════════════════════════════\n";
        echo "  FIN DEL ANÁLISIS\n";
        echo "═══════════════════════════════════════════════════════════════════════\n";
    }
}

// Ejecutar análisis para Agosto, Septiembre y Octubre 2025
$analyzer = new SalesDiscrepancyAnalyzer('2025-08-01', '2025-10-31');
$results = $analyzer->analyze();

// Guardar resultados en archivo JSON para análisis posterior
$outputFile = __DIR__ . '/../storage/logs/sales_discrepancies_' . date('Y-m-d_His') . '.json';
file_put_contents($outputFile, json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

echo "\n\nResultados guardados en: $outputFile\n";
