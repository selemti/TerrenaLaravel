<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class AnalyzeFloreantTotals extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'floreant:analyze-totals {date=2025-12-16 : Date to analyze in YYYY-MM-DD format}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Analyze Floreant/Jasper sales totals for a specific date';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $date = $this->argument('date');
        
        $this->info("Analyzing sales totals for date: $date");
        $this->newLine();

        // Consulta para modo STRICT: paid=true AND voided=false
        $this->info("=== RESULTADOS MODO STRICT (paid=true AND voided=false) ===");
        $strictData = DB::select("
            SELECT 
                SUM(total_price) as items_gross,
                SUM(total_discount) as items_discount,
                SUM(total_price - total_discount) as items_net
            FROM ticket 
            WHERE DATE(create_date) = ?
            AND paid = true
            AND voided = false
        ", [$date]);

        $strictResult = $strictData[0];
        $this->line("Items Gross: " . ($strictResult->items_gross ?? 0));
        $this->line("Items Discount: " . ($strictResult->items_discount ?? 0));
        $this->line("Items Net: " . ($strictResult->items_net ?? 0));
        $this->newLine();

        // Consulta para modo JASPER: paid=true sin filtrar voided
        $this->info("=== RESULTADOS MODO JASPER (paid=true sin filtrar voided) ===");
        $jasperData = DB::select("
            SELECT 
                SUM(total_price) as items_gross,
                SUM(total_discount) as items_discount,
                SUM(total_price - total_discount) as items_net
            FROM ticket 
            WHERE DATE(create_date) = ?
            AND paid = true
        ", [$date]);

        $jasperResult = $jasperData[0];
        $this->line("Items Gross: " . ($jasperResult->items_gross ?? 0));
        $this->line("Items Discount: " . ($jasperResult->items_discount ?? 0));
        $this->line("Items Net: " . ($jasperResult->items_net ?? 0));
        $this->newLine();

        // Lista de tickets con paid=true AND voided=true para la fecha especificada
        $this->info("=== TICKETS CON PAID=TRUE Y VOIDED=TRUE PARA $date ===");
        $voidedTickets = DB::select("
            SELECT 
                id, 
                total_price, 
                total_discount,
                create_date,
                closing_date,
                void_reason
            FROM ticket 
            WHERE DATE(create_date) = ?
            AND paid = true
            AND voided = true
        ", [$date]);

        if (count($voidedTickets) > 0) {
            foreach ($voidedTickets as $ticket) {
                $this->line("Ticket ID: {$ticket->id}, Total Price: {$ticket->total_price}, Total Discount: {$ticket->total_discount}");
                $this->line("  Fecha creación: {$ticket->create_date}, Fecha cierre: {$ticket->closing_date}");
                if (!empty($ticket->void_reason)) {
                    $this->line("  Motivo anulación: {$ticket->void_reason}");
                }
                $this->line("---");
            }
        } else {
            $this->line("No se encontraron tickets con paid=true y voided=true para esta fecha.");
        }
        $this->newLine();

        // Verificar detalles de tickets anulados
        $this->info("=== DETALLES DE TICKETS ANULADOS ===");
        $voidDetails = DB::select("
            SELECT 
                COUNT(*) as total_voided_tickets,
                SUM(total_price) as sum_voided_amount,
                AVG(total_price) as avg_voided_amount
            FROM ticket 
            WHERE DATE(create_date) = ?
            AND voided = true
        ", [$date]);

        $voidDetail = $voidDetails[0];
        $this->line("Total de tickets anulados: {$voidDetail->total_voided_tickets}");
        $this->line("Suma de montos anulados: {$voidDetail->sum_voided_amount}");
        $this->line("Promedio de monto anulado: {$voidDetail->avg_voided_amount}");
        $this->newLine();

        // Consulta para verificar TTL VOIDS con posibles fechas cercanas
        $this->info("=== ANALYSIS DE POSIBLES FECHAS PARA TTL VOIDS ===");
        $this->line("TTL VOIDS reportado en Exceptions Report: 16.00");
        
        // Verificar si hay registros con monto específico que coincida
        $possibleMatchQuery = DB::select("
            SELECT 
                id,
                total_price,
                create_date
            FROM ticket
            WHERE ABS(total_price - 16.00) < 0.01
            AND DATE(create_date) BETWEEN ? - INTERVAL '1 day' AND ? + INTERVAL '1 day'
        ", [$date, $date]);
        
        if(count($possibleMatchQuery) > 0) {
            foreach($possibleMatchQuery as $match) {
                $this->line("Posible coincidencia - Ticket ID: {$match->id}, Amount: {$match->total_price}, Fecha: {$match->create_date}");
            }
        } else {
            $this->line("No se encontraron coincidencias exactas de 16.00 en un rango de 1 día.");
        }
        $this->newLine();

        $this->info("Cálculos realizados exitosamente. Comparar estos valores con el reporte PDF:");
        $this->line("Item Sales Grand Total: 21.0 631.00 Discount 8.8 Net Sales 622.20");
        $this->line("TTL VOIDS en Exceptions Report: 16.00");
    }
}