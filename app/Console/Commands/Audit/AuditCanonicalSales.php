<?php

namespace App\Console\Commands\Audit;

use App\Services\Finance\SalesResolutionService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class AuditCanonicalSales extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'audit:canonical-sales {--limit=50} {--ticket=} {--date=2025-10-18}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Compara la liquidación legacy vs la resolución canónica (Fase 1)';

    private $service;

    public function __construct(SalesResolutionService $service)
    {
        parent::__construct();
        $this->service = $service;
    }

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $limit = $this->option('limit');
        $ticketId = $this->option('ticket');
        $date = $this->option('date');

        $query = DB::connection('pgsql')
            ->table('public.ticket')
            ->where('voided', false)
            ->orderBy('id', 'desc');

        if ($ticketId) {
            $query->where('id', $ticketId);
        } else {
            $query->whereDate('folio_date', $date)
                ->where('total_discount', '>', 0)
                ->limit($limit);
        }

        $tickets = $query->get();

        if ($tickets->isEmpty()) {
            $this->warn("No se encontraron tickets con descuentos para la fecha: {$date}");

            return;
        }

        $headers = ['ID', 'Bruto', 'Neto (L)', 'Neto (C)', 'Desc (L)', 'Desc (C)', 'Diff', 'BUG-04?'];
        $rows = [];

        $totalLegacy = 0;
        $totalCanon = 0;
        $bug04Count = 0;
        $anomalies = 0;

        foreach ($tickets as $t) {
            $resolution = $this->service->resolveNetLiquidation($t->id);

            $legacyNet = (float) $t->total_price;
            $canonNet = $resolution['net_liquidation'];
            $diffNet = $legacyNet - $canonNet;

            $totalLegacy += $legacyNet;
            $totalCanon += $canonNet;

            if ($resolution['is_normalized']) {
                $bug04Count++;
            }
            if (abs($diffNet) > 0.01 && ! $resolution['is_normalized']) {
                $anomalies++;
            }

            $rows[] = [
                $t->id,
                $t->sub_total,
                $legacyNet,
                $canonNet,
                $t->total_discount,
                $resolution['resolved_discount'],
                $diffNet != 0 ? "<fg=red>{$diffNet}</>" : '0',
                $resolution['is_normalized'] ? '<fg=green>SI</>' : 'NO',
            ];
        }

        $this->table($headers, $rows);

        $absDiff = abs($totalLegacy - $totalCanon);
        $perDiff = $totalLegacy > 0 ? ($absDiff / $totalLegacy) * 100 : 0;

        $this->newLine();
        $this->info('--- RESUMEN DE PARIDAD (STAGING) ---');
        $this->line('Total Legacy:  $'.number_format($totalLegacy, 2));
        $this->line('Total Canon:   $'.number_format($totalCanon, 2));
        $this->line('Dif. Absoluta: $'.number_format($absDiff, 2));
        $this->line('Dif. Porcent.: '.number_format($perDiff, 2).'%');
        $this->line('Casos BUG-04 Detectados: '.$bug04Count);
        $this->line('Anomalías (No BUG-04):   '.$anomalies);

        if ($absDiff > 0) {
            $this->warn('Divergencia detectada. El Modo Canon está saneando la data.');
        } else {
            $this->info('Paridad perfecta detectada.');
        }
    }
}
