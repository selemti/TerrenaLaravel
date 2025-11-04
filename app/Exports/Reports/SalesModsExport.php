<?php

namespace App\Exports\Reports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithTitle;

class SalesModsExport implements FromArray, ShouldAutoSize, WithTitle
{
    protected Carbon $start;
    protected Carbon $end;
    protected Collection $rows;
    protected array $summary;
    protected ?string $branch;

    public function __construct(Carbon $start, Carbon $end, Collection $rows, array $summary, ?string $branch = null)
    {
        $this->start = $start;
        $this->end = $end;
        $this->rows = $rows;
        $this->summary = $summary;
        $this->branch = $branch;
    }

    public function array(): array
    {
        $output = [];
        $output[] = ['Ítems y modificadores - Terrena ERP'];
        $output[] = ['Fecha inicial', $this->start->format('Y-m-d')];
        $output[] = ['Fecha final', $this->end->format('Y-m-d')];
        $output[] = ['Sucursal', $this->branch ?? 'Todas'];
        $output[] = ['Generado', now('America/Mexico_City')->format('Y-m-d H:i')];
        $output[] = [];

        $output[] = ['Fecha', 'Ítem', 'Modificador', 'Cantidad ítem', 'Veces seleccionado', 'Monto extra', 'Sucursal'];

        foreach ($this->rows as $row) {
            $output[] = [
                isset($row->report_date) ? (string) $row->report_date : $this->start->format('Y-m-d'),
                $row->item_name ?? $row->item ?? 'N/D',
                $row->modifier_name ?? $row->modifier ?? 'N/D',
                (float) ($row->qty_item ?? $row->qty ?? 0),
                (int) ($row->mods_count ?? 0),
                round((float) ($row->mods_total_amount ?? 0), 2),
                $row->branch_key ?? $row->branch ?? $row->sucursal ?? 'N/D',
            ];
        }

        $output[] = [];
        $output[] = ['Resumen'];
        $output[] = ['Ítems únicos', $this->summary['total_items'] ?? 0];
        $output[] = ['Modificadores únicos', $this->summary['total_modifiers'] ?? 0];
        $output[] = ['Combinaciones', $this->summary['total_combinations'] ?? $this->rows->count()];
        $output[] = ['Total extra', round((float) ($this->summary['total_amount'] ?? 0), 2)];
        $output[] = ['Selecciones', $this->summary['total_selections'] ?? 0];
        $output[] = ['Promedio por selección', round((float) ($this->summary['avg_amount_per_selection'] ?? 0), 2)];

        return $output;
    }

    public function title(): string
    {
        return 'Ítems y modificadores';
    }
}
