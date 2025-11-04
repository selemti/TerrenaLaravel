<?php

namespace App\Exports\Reports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithTitle;

class SalesDrawerExport implements FromArray, ShouldAutoSize, WithTitle
{
    protected Carbon $start;
    protected Carbon $end;
    protected Collection $rows;
    protected array $summary;
    protected ?string $branch;
    protected ?string $severity;

    public function __construct(Carbon $start, Carbon $end, Collection $rows, array $summary, ?string $branch = null, ?string $severity = null)
    {
        $this->start = $start;
        $this->end = $end;
        $this->rows = $rows;
        $this->summary = $summary;
        $this->branch = $branch;
        $this->severity = $severity;
    }

    public function array(): array
    {
        $output = [];
        $output[] = ['Cajón vs efectivo - Terrena ERP'];
        $output[] = ['Fecha inicial', $this->start->format('Y-m-d')];
        $output[] = ['Fecha final', $this->end->format('Y-m-d')];
        $output[] = ['Sucursal', $this->branch ?? 'Todas'];
        $output[] = ['Severidad', $this->severity ?? 'Todas'];
        $output[] = ['Generado', now('America/Mexico_City')->format('Y-m-d H:i')];
        $output[] = [];

        $output[] = ['Fecha', 'Terminal', 'Sucursal', 'Efectivo esperado', 'Efectivo registrado', 'Diferencia', 'Severidad'];

        foreach ($this->rows as $row) {
            $output[] = [
                isset($row->report_date) ? (string) $row->report_date : $this->start->format('Y-m-d'),
                $row->terminal ?? $row->terminal_name ?? 'N/D',
                $row->branch_key ?? $row->branch ?? $row->sucursal ?? 'N/D',
                round((float) ($row->efectivo_esperado ?? 0), 2),
                round((float) ($row->efectivo_registrado ?? 0), 2),
                round((float) ($row->diferencia ?? 0), 2),
                strtoupper((string) ($row->severidad ?? 'INFO')),
            ];
        }

        $output[] = [];
        $output[] = ['Resumen'];
        $output[] = ['Total terminales', $this->summary['total_terminals'] ?? $this->rows->count()];
        $output[] = ['Terminales con discrepancia', $this->summary['discrepancies_count'] ?? 0];
        $output[] = ['Total esperado', round((float) ($this->summary['total_expected'] ?? 0), 2)];
        $output[] = ['Total registrado', round((float) ($this->summary['total_registered'] ?? 0), 2)];
        $output[] = ['Diferencia acumulada', round((float) ($this->summary['total_difference'] ?? 0), 2)];

        $output[] = [];
        $output[] = ['Severidad', 'Cantidad'];
        $output[] = ['CRITICAL', $this->summary['critical_count'] ?? 0];
        $output[] = ['WARN', $this->summary['warning_count'] ?? 0];
        $output[] = ['INFO', $this->summary['info_count'] ?? 0];

        return $output;
    }

    public function title(): string
    {
        return 'Cajón vs efectivo';
    }
}
