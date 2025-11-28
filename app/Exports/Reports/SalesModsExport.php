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

    protected string $view;

    protected ?string $branch;

    public function __construct(Carbon $start, Carbon $end, Collection $rows, array $summary, string $view = 'legacy', ?string $branch = null)
    {
        $this->start = $start;
        $this->end = $end;
        $this->rows = $rows;
        $this->summary = $summary;
        $this->view = $view;
        $this->branch = $branch;
    }

    public function array(): array
    {
        $output = [];
        $output[] = ['Ítems y modificadores - Terrena ERP'];
        $output[] = ['Fecha inicial', $this->start->format('Y-m-d')];
        $output[] = ['Fecha final', $this->end->format('Y-m-d')];
        $output[] = ['Sucursal', $this->branch ?? 'Todas'];
        $output[] = ['Vista', $this->getViewLabel()];
        $output[] = ['Generado', now('America/Mexico_City')->format('Y-m-d H:i')];
        $output[] = [];

        // Headers y datos según la vista
        match ($this->view) {
            'summary_items' => $this->appendSummaryItems($output),
            'summary_item_mods' => $this->appendSummaryItemMods($output),
            'detail' => $this->appendDetail($output),
            default => $this->appendLegacy($output),
        };

        // Resumen
        $output[] = [];
        $output[] = ['Resumen'];
        $this->appendSummary($output);

        return $output;
    }

    protected function getViewLabel(): string
    {
        return match ($this->view) {
            'summary_items' => 'Resumen por Ítem',
            'summary_item_mods' => 'Resumen Ítems + Modificadores',
            'detail' => 'Detalle por Ticket',
            default => 'Legacy',
        };
    }

    protected function appendSummaryItems(array &$output): void
    {
        $output[] = ['Categoría', 'Grupo menú', 'Menú Item', 'Precio ítem', 'Unidades vendidas', 'Ingreso bruto', 'Descuento', 'Ingreso neto'];

        foreach ($this->rows as $row) {
            $output[] = [
                $row->categoria ?? 'N/D',
                $row->grupo_menu ?? 'N/D',
                $row->menu_item ?? 'N/D',
                round((float) ($row->precio_item ?? 0), 2),
                (int) ($row->unidades_vendidas ?? 0),
                round((float) ($row->ingreso_bruto_item ?? 0), 2),
                round((float) ($row->descuento_item ?? 0), 2),
                round((float) ($row->ingreso_neto_item ?? 0), 2),
            ];
        }
    }

    protected function appendSummaryItemMods(array &$output): void
    {
        // Verificar si hay columna de fecha
        $hasFecha = $this->rows->first() && isset($this->rows->first()->fecha);

        $headers = $hasFecha
            ? ['Fecha', 'Categoría', 'Grupo menú', 'Menú Item', 'Grupo modificador', 'Modificador', 'Precio extra', 'Sucursal', 'Terminal', 'Unidades ítem', 'Selecciones', 'Monto extra']
            : ['Categoría', 'Grupo menú', 'Menú Item', 'Grupo modificador', 'Modificador', 'Precio extra', 'Sucursal', 'Terminal', 'Unidades ítem', 'Selecciones', 'Monto extra'];

        $output[] = $headers;

        foreach ($this->rows as $row) {
            $rowData = $hasFecha
                ? [
                    isset($row->fecha) ? (string) $row->fecha : 'N/D',
                    $row->categoria ?? 'N/D',
                    $row->grupo_menu ?? 'N/D',
                    $row->menu_item ?? 'N/D',
                    $row->grupo_modificador ?? 'N/D',
                    $row->modificador ?? 'N/D',
                    round((float) ($row->precio_extra_mod ?? 0), 2),
                    $row->sucursal ?? 'N/D',
                    isset($row->terminal) ? (string) $row->terminal : 'N/D',
                    (int) ($row->unidades_item ?? 0),
                    (int) ($row->selecciones_modificador ?? 0),
                    round((float) ($row->monto_extra_modificador ?? 0), 2),
                ]
                : [
                    $row->categoria ?? 'N/D',
                    $row->grupo_menu ?? 'N/D',
                    $row->menu_item ?? 'N/D',
                    $row->grupo_modificador ?? 'N/D',
                    $row->modificador ?? 'N/D',
                    round((float) ($row->precio_extra_mod ?? 0), 2),
                    $row->sucursal ?? 'N/D',
                    isset($row->terminal) ? (string) $row->terminal : 'N/D',
                    (int) ($row->unidades_item ?? 0),
                    (int) ($row->selecciones_modificador ?? 0),
                    round((float) ($row->monto_extra_modificador ?? 0), 2),
                ];

            $output[] = $rowData;
        }
    }

    protected function appendDetail(array &$output): void
    {
        $output[] = ['Fecha', 'Ítem', 'Modificador', 'Cantidad ítem', 'Selecciones', 'Monto extra', 'Sucursal', 'Terminal', 'Ticket ID', 'Ticket Item ID'];

        foreach ($this->rows as $row) {
            $output[] = [
                isset($row->fecha) ? (string) $row->fecha : 'N/D',
                $row->item ?? 'N/D',
                $row->modificador ?? 'N/D',
                (float) ($row->cantidad_item ?? 0),
                (int) ($row->selecciones ?? 0),
                round((float) ($row->monto_extra ?? 0), 2),
                $row->sucursal ?? 'N/D',
                isset($row->terminal) ? (string) $row->terminal : 'N/D',
                isset($row->ticket_id) ? (string) $row->ticket_id : 'N/D',
                isset($row->ticket_item_id) ? (string) $row->ticket_item_id : 'N/D',
            ];
        }
    }

    protected function appendLegacy(array &$output): void
    {
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
    }

    protected function appendSummary(array &$output): void
    {
        if ($this->view === 'summary_items') {
            $output[] = ['Total ítems únicos', $this->summary['total_items'] ?? 0];
            $output[] = ['Total categorías', $this->summary['total_categories'] ?? 0];
            $output[] = ['Total grupos', $this->summary['total_groups'] ?? 0];
            $output[] = ['Unidades totales', $this->summary['total_units'] ?? 0];
            $output[] = ['Ingreso bruto', round((float) ($this->summary['total_gross'] ?? 0), 2)];
            $output[] = ['Descuento total', round((float) ($this->summary['total_discount'] ?? 0), 2)];
            $output[] = ['Ingreso neto', round((float) ($this->summary['total_net'] ?? 0), 2)];
        } elseif ($this->view === 'detail') {
            $output[] = ['Total registros', $this->summary['total_records'] ?? 0];
            $output[] = ['Ítems únicos', $this->summary['total_items'] ?? 0];
            $output[] = ['Modificadores únicos', $this->summary['total_modifiers'] ?? 0];
            $output[] = ['Tickets únicos', $this->summary['total_tickets'] ?? 0];
            $output[] = ['Total monto extra', round((float) ($this->summary['total_amount'] ?? 0), 2)];
            $output[] = ['Total selecciones', $this->summary['total_selections'] ?? 0];
        } else {
            // summary_item_mods y legacy
            $output[] = ['Ítems únicos', $this->summary['total_items'] ?? 0];
            $output[] = ['Modificadores únicos', $this->summary['total_modifiers'] ?? 0];
            $output[] = ['Combinaciones', $this->summary['total_combinations'] ?? $this->rows->count()];
            $output[] = ['Total extra', round((float) ($this->summary['total_amount'] ?? 0), 2)];
            $output[] = ['Selecciones', $this->summary['total_selections'] ?? 0];
            $output[] = ['Promedio por selección', round((float) ($this->summary['avg_amount_per_selection'] ?? 0), 2)];
        }
    }

    public function title(): string
    {
        return 'Ítems y modificadores';
    }
}
