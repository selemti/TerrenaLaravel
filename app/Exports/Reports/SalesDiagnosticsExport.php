<?php

namespace App\Exports\Reports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithTitle;

class SalesDiagnosticsExport implements FromArray, ShouldAutoSize, WithTitle
{
    protected Carbon $start;
    protected Carbon $end;
    protected Collection $rows;
    protected array $summary;
    protected ?string $severity;

    public function __construct(
        Carbon $start,
        Carbon $end,
        Collection $rows,
        array $summary,
        ?string $severity = null
    ) {
        $this->start = $start;
        $this->end = $end;
        $this->rows = $rows;
        $this->summary = $summary;
        $this->severity = $severity;
    }

    public function array(): array
    {
        $output = [];
        $output[] = ['Diagnósticos diarios - Terrena ERP'];
        $output[] = ['Fecha inicial', $this->start->format('Y-m-d')];
        $output[] = ['Fecha final', $this->end->format('Y-m-d')];
        $output[] = ['Filtro severidad', $this->severity ?? 'Todas'];
        $output[] = ['Generado', now('America/Mexico_City')->format('Y-m-d H:i')];
        $output[] = [];

        $output[] = ['Fecha', 'Vista origen', 'Severidad', 'Filas detectadas'];

        foreach ($this->rows as $row) {
            $output[] = [
                isset($row->report_date) ? (string) $row->report_date : $this->start->format('Y-m-d'),
                $this->translateViewName($row->source_view ?? 'unknown'),
                strtoupper((string) ($row->severity ?? 'INFO')),
                (int) ($row->rows ?? 0),
            ];
        }

        $output[] = [];
        $output[] = ['Resumen'];
        $output[] = ['Total verificaciones', $this->summary['total_checks'] ?? $this->rows->count()];
        $output[] = ['Total filtrado', $this->summary['filtered_count'] ?? $this->rows->count()];
        $output[] = ['CRITICAL', $this->summary['critical_count'] ?? 0];
        $output[] = ['WARN', $this->summary['warning_count'] ?? 0];
        $output[] = ['INFO', $this->summary['info_count'] ?? 0];
        $output[] = ['Filas afectadas', $this->summary['total_rows_affected'] ?? 0];

        return $output;
    }

    public function title(): string
    {
        return 'Diagnósticos diarios';
    }

    protected function translateViewName(string $view): string
    {
        return match ($view) {
            'vw_diag_neto_vs_cobros' => 'Neto vs cobros',
            'vw_diag_discount_header_vs_lines' => 'Descuentos encabezado vs líneas',
            'vw_diag_paid_but_no_payments' => 'Tickets pagados sin pagos',
            'vw_diag_unnormalized_payments' => 'Pagos sin normalizar',
            'vw_diag_service_charge_vs_paid' => 'Servicio vs pagos',
            'vw_diag_drawer_vs_cash_transactions' => 'Cajón vs efectivo',
            'vw_diag_orphans_tickets' => 'Tickets huérfanos',
            'vw_diag_orphans_tx' => 'Transacciones huérfanas',
            'vw_diag_high_discounts' => 'Descuentos altos',
            default => $view,
        };
    }
}
