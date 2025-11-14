<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class CorregirTicketsProblematicos extends Command
{
    protected $signature = 'ventas:corregir-tickets 
                            {tipo : Tipo de corrección: descuento100|abiertos|preview}
                            {--fecha-inicio= : Fecha inicio (formato: YYYY-MM-DD)}
                            {--fecha-fin= : Fecha fin (formato: YYYY-MM-DD)}
                            {--dry-run : Simular sin aplicar cambios}
                            {--ticket-id= : Corregir solo un ticket específico}';

    protected $description = 'Corrige tickets problemáticos identificados en el análisis';

    public function handle()
    {
        $tipo = $this->argument('tipo');
        $dry_run = $this->option('dry-run');

        $this->warn('╔═══════════════════════════════════════════════════════════════════╗');
        $this->warn('║          🔧 CORRECCIÓN DE TICKETS PROBLEMÁTICOS                   ║');
        $this->warn('╚═══════════════════════════════════════════════════════════════════╝');
        $this->newLine();

        if ($dry_run) {
            $this->info('🔍 MODO DRY-RUN: No se aplicarán cambios a la base de datos');
            $this->newLine();
        } else {
            $this->error('⚠️  ATENCIÓN: Este comando modificará la base de datos');
            if (! $this->confirm('¿Estás seguro de continuar?')) {
                $this->info('Operación cancelada.');

                return Command::SUCCESS;
            }
        }

        switch ($tipo) {
            case 'preview':
                return $this->previewProblematicos();
            case 'descuento100':
                return $this->corregirDescuento100($dry_run);
            case 'abiertos':
                return $this->corregirTicketsAbiertos($dry_run);
            default:
                $this->error("Tipo de corrección no válido: {$tipo}");
                $this->info('Tipos disponibles: preview, descuento100, abiertos');

                return Command::FAILURE;
        }
    }

    private function previewProblematicos()
    {
        [$fecha_inicio, $fecha_fin] = $this->determinarPeriodo();

        $this->info("📅 Período: {$fecha_inicio} a {$fecha_fin}");
        $this->newLine();

        // 1. Tickets con descuento 100%
        $tickets_desc100 = $this->obtenerTicketsDescuento100($fecha_inicio, $fecha_fin);

        $this->warn('🚨 TICKETS CON DESCUENTO 100% (total_price = 0):');
        $this->line('   Total: '.count($tickets_desc100));

        if (count($tickets_desc100) > 0) {
            $headers = ['ID', 'Fecha', 'Total Price', 'Descuento', 'Items', 'Acción Sugerida'];
            $rows = array_map(function ($t) {
                $accion = $t->suma_items > 0
                    ? "Restaurar total_price = \${$t->suma_items}"
                    : 'Anular (voided = TRUE)';

                return [
                    $t->id,
                    substr($t->create_date, 0, 10),
                    '$'.$t->total_price,
                    '$'.$t->total_discount,
                    '$'.$t->suma_items,
                    $accion,
                ];
            }, array_slice($tickets_desc100, 0, 20));

            $this->table($headers, $rows);

            if (count($tickets_desc100) > 20) {
                $this->line('   ... y '.(count($tickets_desc100) - 20).' más');
            }
        }
        $this->newLine();

        // 2. Tickets abiertos
        $tickets_abiertos = $this->obtenerTicketsAbiertos($fecha_inicio, $fecha_fin);

        $this->warn('📋 TICKETS ABIERTOS SIN PAGAR:');
        $this->line('   Total: '.count($tickets_abiertos));

        if (count($tickets_abiertos) > 0) {
            $headers = ['ID', 'Creación', 'Cierre', 'Total', 'Desc', 'Neto', 'Acción'];
            $rows = array_map(function ($t) {
                $neto = $t->total_price - $t->total_discount;
                $accion = $neto <= 0 ? 'Anular' : 'Revisar manual';

                return [
                    $t->id,
                    substr($t->fecha_creacion, 0, 10),
                    $t->closing_date ? substr($t->closing_date, 0, 10) : 'NULL',
                    '$'.$t->total_price,
                    '$'.$t->total_discount,
                    '$'.$neto,
                    $accion,
                ];
            }, array_slice($tickets_abiertos, 0, 20));

            $this->table($headers, $rows);

            if (count($tickets_abiertos) > 20) {
                $this->line('   ... y '.(count($tickets_abiertos) - 20).' más');
            }
        }
        $this->newLine();

        $this->info('💡 Para corregir, ejecuta:');
        $this->line('   php artisan ventas:corregir-tickets descuento100 --dry-run');
        $this->line('   php artisan ventas:corregir-tickets abiertos --dry-run');

        return Command::SUCCESS;
    }

    private function corregirDescuento100($dry_run)
    {
        [$fecha_inicio, $fecha_fin] = $this->determinarPeriodo();
        $tickets = $this->obtenerTicketsDescuento100($fecha_inicio, $fecha_fin);

        if (count($tickets) === 0) {
            $this->info('✅ No se encontraron tickets con descuento 100% problemáticos');

            return Command::SUCCESS;
        }

        $this->info('📋 Tickets a corregir: '.count($tickets));
        $this->newLine();

        $corregidos = 0;
        $anulados = 0;
        $omitidos = 0;

        DB::beginTransaction();

        try {
            foreach ($tickets as $ticket) {
                $this->line("Procesando ticket #{$ticket->id}...");

                if ($ticket->suma_items > 0) {
                    // Caso A: Restaurar total_price con la suma de items
                    $nuevo_total = $ticket->suma_items;

                    if (! $dry_run) {
                        DB::update('
                            UPDATE public.ticket 
                            SET total_price = :total_price,
                                updated_date = NOW()
                            WHERE id = :id
                        ', [
                            'total_price' => $nuevo_total,
                            'id' => $ticket->id,
                        ]);
                    }

                    $this->info("  ✓ Restaurado: total_price = \${$nuevo_total} (era \$0)");
                    $corregidos++;

                } elseif ($ticket->total_discount > 0) {
                    // Caso B: No hay items, pero hay descuento - Anular ticket
                    if (! $dry_run) {
                        DB::update('
                            UPDATE public.ticket 
                            SET voided = TRUE,
                                updated_date = NOW()
                            WHERE id = :id
                        ', ['id' => $ticket->id]);
                    }

                    $this->warn("  ⚠ Anulado: Sin items pero descuento de \${$ticket->total_discount}");
                    $anulados++;

                } else {
                    $this->comment('  - Omitido: Sin items ni descuento válido');
                    $omitidos++;
                }
            }

            if (! $dry_run) {
                DB::commit();
                $this->newLine();
                $this->info('✅ Cambios guardados en la base de datos');
            } else {
                DB::rollBack();
                $this->newLine();
                $this->warn('🔍 DRY-RUN: No se guardaron cambios');
            }

            $this->newLine();
            $this->info('📊 RESUMEN:');
            $this->line("   Tickets corregidos (total_price restaurado): {$corregidos}");
            $this->line("   Tickets anulados: {$anulados}");
            $this->line("   Tickets omitidos: {$omitidos}");

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error('❌ Error al procesar tickets: '.$e->getMessage());

            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }

    private function corregirTicketsAbiertos($dry_run)
    {
        [$fecha_inicio, $fecha_fin] = $this->determinarPeriodo();
        $tickets = $this->obtenerTicketsAbiertos($fecha_inicio, $fecha_fin);

        if (count($tickets) === 0) {
            $this->info('✅ No se encontraron tickets abiertos problemáticos');

            return Command::SUCCESS;
        }

        $this->info('📋 Tickets a revisar: '.count($tickets));
        $this->newLine();

        $anulados = 0;
        $omitidos = 0;

        DB::beginTransaction();

        try {
            foreach ($tickets as $ticket) {
                $neto = $ticket->total_price - $ticket->total_discount;

                $this->line("Procesando ticket #{$ticket->id} (neto: \${$neto})...");

                if ($neto <= 0) {
                    // Anular tickets con neto cero o negativo
                    if (! $dry_run) {
                        DB::update('
                            UPDATE public.ticket 
                            SET voided = TRUE,
                                updated_date = NOW()
                            WHERE id = :id
                        ', ['id' => $ticket->id]);
                    }

                    $this->warn("  ⚠ Anulado: Neto = \${$neto}");
                    $anulados++;

                } else {
                    // Tickets con neto positivo requieren revisión manual
                    $this->comment("  - Omitido: Requiere revisión manual (neto = \${$neto})");
                    $omitidos++;
                }
            }

            if (! $dry_run) {
                DB::commit();
                $this->newLine();
                $this->info('✅ Cambios guardados en la base de datos');
            } else {
                DB::rollBack();
                $this->newLine();
                $this->warn('🔍 DRY-RUN: No se guardaron cambios');
            }

            $this->newLine();
            $this->info('📊 RESUMEN:');
            $this->line("   Tickets anulados (neto <= 0): {$anulados}");
            $this->line("   Tickets omitidos (requieren revisión): {$omitidos}");

            if ($omitidos > 0) {
                $this->newLine();
                $this->warn("⚠️  HAY {$omitidos} TICKETS QUE REQUIEREN REVISIÓN MANUAL");
                $this->line('   Usa: php artisan ventas:corregir-tickets preview --ticket-id=ID');
            }

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error('❌ Error al procesar tickets: '.$e->getMessage());

            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }

    private function obtenerTicketsDescuento100($fecha_inicio, $fecha_fin)
    {
        $where_id = $this->option('ticket-id')
            ? 'AND t.id = :ticket_id'
            : '';

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
              {$where_id}
            ORDER BY t.total_discount DESC
        ";

        $params = [
            'fecha_inicio' => $fecha_inicio,
            'fecha_fin' => $fecha_fin,
        ];

        if ($this->option('ticket-id')) {
            $params['ticket_id'] = $this->option('ticket-id');
        }

        return DB::select($query, $params);
    }

    private function obtenerTicketsAbiertos($fecha_inicio, $fecha_fin)
    {
        $where_id = $this->option('ticket-id')
            ? 'AND t.id = :ticket_id'
            : '';

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
              {$where_id}
            ORDER BY t.total_discount DESC
        ";

        $params = [
            'fecha_inicio' => $fecha_inicio,
            'fecha_fin' => $fecha_fin,
        ];

        if ($this->option('ticket-id')) {
            $params['ticket_id'] = $this->option('ticket-id');
        }

        return DB::select($query, $params);
    }

    private function determinarPeriodo()
    {
        if ($this->option('fecha-inicio') && $this->option('fecha-fin')) {
            return [$this->option('fecha-inicio'), $this->option('fecha-fin')];
        }

        // Por defecto: mes anterior
        $mes_anterior = Carbon::now()->subMonth();

        return [$mes_anterior->startOfMonth()->format('Y-m-d'), $mes_anterior->endOfMonth()->format('Y-m-d')];
    }
}
