<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AnalyzarDiscrepanciasVentas extends Command
{
    protected $signature = 'ventas:analizar-discrepancias 
                            {--mes= : Mes a analizar (formato: YYYY-MM, ej: 2025-10)}
                            {--fecha-inicio= : Fecha inicio (formato: YYYY-MM-DD)}
                            {--fecha-fin= : Fecha fin (formato: YYYY-MM-DD)}
                            {--exportar : Exportar resultados a archivo}
                            {--detalle : Mostrar detalles de tickets problemáticos}';

    protected $description = 'Analiza discrepancias en reportes de ventas vs base de datos';

    private $output_dir;

    public function __construct()
    {
        parent::__construct();
        $this->output_dir = storage_path('app/analisis_ventas');
        if (!file_exists($this->output_dir)) {
            mkdir($this->output_dir, 0755, true);
        }
    }

    public function handle()
    {
        $this->info("╔═══════════════════════════════════════════════════════════════════╗");
        $this->info("║   🔬 ANÁLISIS DE DISCREPANCIAS EN VENTAS - DRAWER PULL vs BD    ║");
        $this->info("╚═══════════════════════════════════════════════════════════════════╝");
        $this->newLine();

        // Determinar período a analizar
        [$fecha_inicio, $fecha_fin] = $this->determinarPeriodo();
        
        $this->info("📅 Período de análisis: {$fecha_inicio} a {$fecha_fin}");
        $this->newLine();

        // Ejecutar análisis
        $resultados = $this->ejecutarAnalisis($fecha_inicio, $fecha_fin);

        // Mostrar resultados
        $this->mostrarResultados($resultados);

        // Exportar si se solicitó
        if ($this->option('exportar')) {
            $this->exportarResultados($resultados, $fecha_inicio, $fecha_fin);
        }

        $this->newLine();
        $this->info("✅ Análisis completado");

        return Command::SUCCESS;
    }

    private function determinarPeriodo()
    {
        if ($this->option('fecha-inicio') && $this->option('fecha-fin')) {
            return [$this->option('fecha-inicio'), $this->option('fecha-fin')];
        }

        if ($this->option('mes')) {
            $mes = Carbon::parse($this->option('mes') . '-01');
            return [$mes->startOfMonth()->format('Y-m-d'), $mes->endOfMonth()->format('Y-m-d')];
        }

        // Por defecto: mes anterior
        $mes_anterior = Carbon::now()->subMonth();
        return [$mes_anterior->startOfMonth()->format('Y-m-d'), $mes_anterior->endOfMonth()->format('Y-m-d')];
    }

    private function ejecutarAnalisis($fecha_inicio, $fecha_fin)
    {
        $resultados = [];

        // 1. Tickets con descuento 100% problemáticos
        $this->info('⏳ Analizando tickets con descuento 100%...');
        $resultados['descuento_100'] = $this->analizarDescuento100($fecha_inicio, $fecha_fin);
        $this->line('   ✔ Completado');

        // 2. Tickets con pago ≠ neto
        $this->info('⏳ Analizando discrepancias pago vs neto...');
        $resultados['pago_vs_neto'] = $this->analizarPagoVsNeto($fecha_inicio, $fecha_fin);
        $this->line('   ✔ Completado');

        // 3. Tickets abiertos sin pagar
        $this->info('⏳ Analizando tickets abiertos...');
        $resultados['tickets_abiertos'] = $this->analizarTicketsAbiertos($fecha_inicio, $fecha_fin);
        $this->line('   ✔ Completado');

        // 4. Comparación Drawer Pull vs BD
        $this->info('⏳ Comparando Drawer Pull Reports vs BD...');
        $resultados['drawer_pull'] = $this->compararDrawerPull($fecha_inicio, $fecha_fin);
        $this->line('   ✔ Completado');

        return $resultados;
    }

    private function analizarDescuento100($fecha_inicio, $fecha_fin)
    {
        $query = "
            SELECT 
                t.id,
                t.create_date,
                t.closing_date,
                t.total_price,
                t.total_discount,
                t.paid,
                t.voided,
                COALESCE((SELECT SUM(ti.total_price) FROM public.ticket_item ti WHERE ti.ticket_id = t.id), 0) as suma_items
            FROM public.ticket t
            WHERE DATE(t.create_date) BETWEEN :fecha_inicio AND :fecha_fin
              AND t.total_price = 0
              AND t.total_discount > 0
              AND t.paid = FALSE
              AND t.voided = FALSE
            ORDER BY t.total_discount DESC
        ";

        $tickets = DB::select($query, [
            'fecha_inicio' => $fecha_inicio,
            'fecha_fin' => $fecha_fin
        ]);

        $total_descuentos = array_sum(array_column($tickets, 'total_discount'));

        return [
            'total_tickets' => count($tickets),
            'total_descuentos' => $total_descuentos,
            'tickets' => $tickets
        ];
    }

    private function analizarPagoVsNeto($fecha_inicio, $fecha_fin)
    {
        $query = "
            SELECT 
                t.id,
                DATE(t.create_date) as fecha,
                t.total_price,
                t.total_discount,
                (t.total_price - t.total_discount) as neto_esperado,
                COALESCE((
                    SELECT SUM(tr.amount) 
                    FROM public.transactions tr 
                    WHERE tr.ticket_id = t.id 
                      AND tr.payment_type IN ('CASH', 'CREDIT_CARD', 'DEBIT_CARD')
                ), 0) as total_pagado,
                COALESCE((
                    SELECT SUM(tr.amount) 
                    FROM public.transactions tr 
                    WHERE tr.ticket_id = t.id 
                      AND tr.payment_type IN ('CASH', 'CREDIT_CARD', 'DEBIT_CARD')
                ), 0) - (t.total_price - t.total_discount) as diferencia
            FROM public.ticket t
            WHERE DATE(t.create_date) BETWEEN :fecha_inicio AND :fecha_fin
              AND t.paid = TRUE
              AND t.voided = FALSE
              AND t.total_price > 0
              AND ABS(COALESCE((
                    SELECT SUM(tr.amount) 
                    FROM public.transactions tr 
                    WHERE tr.ticket_id = t.id 
                      AND tr.payment_type IN ('CASH', 'CREDIT_CARD', 'DEBIT_CARD')
                ), 0) - (t.total_price - t.total_discount)) > 0.50
            ORDER BY t.id DESC
            LIMIT 100
        ";

        $tickets = DB::select($query, [
            'fecha_inicio' => $fecha_inicio,
            'fecha_fin' => $fecha_fin
        ]);

        $total_diferencia = array_sum(array_column($tickets, 'diferencia'));

        return [
            'total_tickets' => count($tickets),
            'total_diferencia' => $total_diferencia,
            'tickets' => $tickets
        ];
    }

    private function analizarTicketsAbiertos($fecha_inicio, $fecha_fin)
    {
        $query = "
            SELECT 
                t.id,
                DATE(t.create_date) as fecha_creacion,
                t.closing_date,
                t.total_price,
                t.total_discount,
                (t.total_price - t.total_discount) as neto,
                t.paid,
                t.voided
            FROM public.ticket t
            WHERE DATE(t.create_date) BETWEEN :fecha_inicio AND :fecha_fin
              AND (t.closing_date IS NULL OR t.paid = FALSE)
              AND t.voided = FALSE
              AND (t.total_price > 0 OR t.total_discount > 0)
            ORDER BY t.total_discount DESC
        ";

        $tickets = DB::select($query, [
            'fecha_inicio' => $fecha_inicio,
            'fecha_fin' => $fecha_fin
        ]);

        $total_price = array_sum(array_column($tickets, 'total_price'));
        $total_discount = array_sum(array_column($tickets, 'total_discount'));

        return [
            'total_tickets' => count($tickets),
            'total_price' => $total_price,
            'total_discount' => $total_discount,
            'neto' => $total_price - $total_discount,
            'tickets' => $tickets
        ];
    }

    private function compararDrawerPull($fecha_inicio, $fecha_fin)
    {
        // Por ahora retornamos empty array - implementar más adelante
        // cuando confirmemos la estructura exacta de drawer_pull_report
        return [];
    }

    private function mostrarResultados($resultados)
    {
        $this->newLine();
        $this->info("╔═══════════════════════════════════════════════════════════════════╗");
        $this->info("║                        📊 RESULTADOS                              ║");
        $this->info("╚═══════════════════════════════════════════════════════════════════╝");
        $this->newLine();

        // 1. Descuentos 100%
        $this->warn("🚨 PROBLEMA #1: Tickets con Descuento 100% Mal Registrados");
        $this->line("   Total tickets afectados: " . $resultados['descuento_100']['total_tickets']);
        $this->line("   Total descuentos fantasma: $" . number_format($resultados['descuento_100']['total_descuentos'], 2));
        
        if ($this->option('detalle') && count($resultados['descuento_100']['tickets']) > 0) {
            $this->newLine();
            $headers = ['ID', 'Fecha', 'Total Price', 'Descuento', 'Pagado', 'Anulado'];
            $rows = array_map(fn($t) => [
                $t->id,
                $t->create_date,
                '$' . $t->total_price,
                '$' . $t->total_discount,
                $t->paid ? 'Sí' : 'No',
                $t->voided ? 'Sí' : 'No'
            ], array_slice($resultados['descuento_100']['tickets'], 0, 10));
            $this->table($headers, $rows);
            if (count($resultados['descuento_100']['tickets']) > 10) {
                $this->line("   ... y " . (count($resultados['descuento_100']['tickets']) - 10) . " más");
            }
        }
        $this->newLine();

        // 2. Pago vs Neto
        $this->warn("⚠️  PROBLEMA #2: Descuentos NO Aplicados en Pagos");
        $this->line("   Total tickets afectados: " . $resultados['pago_vs_neto']['total_tickets']);
        $this->line("   Total sobrecobros: $" . number_format($resultados['pago_vs_neto']['total_diferencia'], 2));
        
        if ($this->option('detalle') && count($resultados['pago_vs_neto']['tickets']) > 0) {
            $this->newLine();
            $headers = ['ID', 'Fecha', 'Neto Esperado', 'Total Pagado', 'Diferencia'];
            $rows = array_map(fn($t) => [
                $t->id,
                $t->fecha,
                '$' . number_format($t->neto_esperado, 2),
                '$' . number_format($t->total_pagado, 2),
                '$' . number_format($t->diferencia, 2)
            ], array_slice($resultados['pago_vs_neto']['tickets'], 0, 10));
            $this->table($headers, $rows);
            if (count($resultados['pago_vs_neto']['tickets']) > 10) {
                $this->line("   ... y " . (count($resultados['pago_vs_neto']['tickets']) - 10) . " más");
            }
        }
        $this->newLine();

        // 3. Tickets abiertos
        $this->warn("📋 PROBLEMA #3: Tickets Abiertos sin Pagar");
        $this->line("   Total tickets abiertos: " . $resultados['tickets_abiertos']['total_tickets']);
        $this->line("   Total price acumulado: $" . number_format($resultados['tickets_abiertos']['total_price'], 2));
        $this->line("   Total descuentos: $" . number_format($resultados['tickets_abiertos']['total_discount'], 2));
        $this->line("   Neto pendiente: $" . number_format($resultados['tickets_abiertos']['neto'], 2));
        $this->newLine();

        // 4. Resumen financiero
        $this->info("💰 IMPACTO FINANCIERO TOTAL:");
        $total_descuentos_fantasma = $resultados['descuento_100']['total_descuentos'];
        $total_sobrecobros = $resultados['pago_vs_neto']['total_diferencia'];
        $total_sin_cobrar = $resultados['tickets_abiertos']['neto'];
        
        $this->line("   Descuentos fantasma (reportados incorrectamente): $" . number_format($total_descuentos_fantasma, 2));
        $this->line("   Sobrecobros (descuentos no aplicados): $" . number_format($total_sobrecobros, 2));
        $this->line("   Tickets sin cobrar: $" . number_format($total_sin_cobrar, 2));
        $this->line("   ─────────────────────────────────────────────");
        $this->line("   TOTAL DISCREPANCIAS: $" . number_format($total_descuentos_fantasma + abs($total_sobrecobros) + abs($total_sin_cobrar), 2));
        $this->newLine();
    }

    private function exportarResultados($resultados, $fecha_inicio, $fecha_fin)
    {
        $timestamp = Carbon::now()->format('Y-m-d_His');
        $filename = "analisis_ventas_{$fecha_inicio}_a_{$fecha_fin}_{$timestamp}.json";
        $filepath = $this->output_dir . '/' . $filename;

        $export = [
            'periodo' => [
                'fecha_inicio' => $fecha_inicio,
                'fecha_fin' => $fecha_fin,
            ],
            'fecha_analisis' => Carbon::now()->toDateTimeString(),
            'resultados' => $resultados,
            'resumen' => [
                'descuentos_fantasma' => $resultados['descuento_100']['total_descuentos'],
                'sobrecobros' => $resultados['pago_vs_neto']['total_diferencia'],
                'tickets_sin_cobrar' => $resultados['tickets_abiertos']['neto'],
                'total_discrepancias' => 
                    $resultados['descuento_100']['total_descuentos'] + 
                    abs($resultados['pago_vs_neto']['total_diferencia']) + 
                    abs($resultados['tickets_abiertos']['neto'])
            ]
        ];

        file_put_contents($filepath, json_encode($export, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        $this->info("📄 Resultados exportados a: {$filepath}");
    }
}
