<?php

namespace App\Services\Reports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Servicio para reporte concentrado de Ítems + Modificadores
 *
 * Soporta 3 vistas:
 * - summary_items: Resumen por Categoría → Grupo → Item
 * - summary_item_mods: Resumen por Item + Modificador (principal)
 * - detail: Detalle a nivel de ticket
 */
class ItemModsReportService
{
    /**
     * Obtiene datos según la vista solicitada
     */
    public function fetch(
        Carbon $startDate,
        Carbon $endDate,
        array $filters = []
    ): Collection {
        $view = $filters['view'] ?? 'summary_item_mods';
        $groupByDay = (bool) ($filters['group_by_day'] ?? false);
        $branchIds = $filters['branch_ids'] ?? null;
        $terminalIds = $filters['terminal_ids'] ?? null;

        return match ($view) {
            'summary_items' => $this->fetchSummaryItems($startDate, $endDate, $branchIds, $terminalIds),
            'summary_item_mods' => $this->fetchSummaryItemMods($startDate, $endDate, $groupByDay, $branchIds, $terminalIds),
            'detail' => $this->fetchDetail($startDate, $endDate, $branchIds, $terminalIds),
            default => throw new \InvalidArgumentException("Invalid view: {$view}"),
        };
    }

    /**
     * Vista A: Resumen por Ítem (sin modificadores)
     */
    protected function fetchSummaryItems(
        Carbon $start,
        Carbon $end,
        ?array $branchIds,
        ?array $terminalIds
    ): Collection {
        $query = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59')
            ])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->selectRaw("
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS menu_item,
                ti.item_price AS precio_item,
                SUM(COALESCE(ti.item_quantity, ti.item_count, 0)) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_bruto_item,
                SUM(COALESCE(ti.discount, 0)) AS descuento_item,
                SUM(ti.total_price - COALESCE(ti.discount, 0)) AS ingreso_neto_item
            ")
            ->groupBy('ti.category_name', 'ti.group_name', 'ti.item_name', 'ti.item_price')
            ->orderBy('ti.category_name')
            ->orderBy('ti.group_name')
            ->orderBy('ti.item_name');

        if ($branchIds && count($branchIds) > 0) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        return collect($query->get());
    }

    /**
     * Vista B: Resumen Ítems + Modificadores (PRINCIPAL)
     */
    protected function fetchSummaryItemMods(
        Carbon $start,
        Carbon $end,
        bool $groupByDay,
        ?array $branchIds,
        ?array $terminalIds
    ): Collection {
        $dateSelect = $groupByDay
            ? "t.folio_date AS fecha,"
            : "";

        $dateGroupBy = $groupByDay
            ? "t.folio_date,"
            : "";

        $dateOrderBy = $groupByDay
            ? "t.folio_date,"
            : "";

        $query = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->join('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->leftJoin('public.menu_modifier as mm', 'mm.id', '=', 'tim.item_id')
            ->leftJoin('public.menu_modifier_group as mgr', 'mgr.id', '=', DB::raw('COALESCE(tim.group_id, mm.group_id)'))
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59')
            ])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->whereNotNull('tim.modifier_name')
            ->selectRaw("
                {$dateSelect}
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS menu_item,
                mgr.name AS grupo_modificador,
                tim.modifier_name AS modificador,
                tim.modifier_price AS precio_extra_mod,
                t.branch_key AS sucursal,
                t.terminal_id AS terminal,
                SUM(COALESCE(ti.item_quantity, ti.item_count, 0)) AS unidades_item,
                SUM(COALESCE(tim.item_count, 0)) AS selecciones_modificador,
                SUM(COALESCE(tim.modifier_price, 0) * COALESCE(tim.item_count, 0)) AS monto_extra_modificador
            ")
            ->groupByRaw("
                {$dateGroupBy}
                ti.category_name,
                ti.group_name,
                ti.item_name,
                mgr.name,
                tim.modifier_name,
                tim.modifier_price,
                t.branch_key,
                t.terminal_id
            ")
            ->orderByRaw("{$dateOrderBy} ti.category_name, ti.group_name, ti.item_name, mgr.name, tim.modifier_name");

        if ($branchIds && count($branchIds) > 0) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        return collect($query->get());
    }

    /**
     * Vista C: Detalle a nivel de ticket
     */
    protected function fetchDetail(
        Carbon $start,
        Carbon $end,
        ?array $branchIds,
        ?array $terminalIds
    ): Collection {
        $query = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->join('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59')
            ])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->whereNotNull('tim.modifier_name')
            ->selectRaw("
                t.folio_date AS fecha,
                ti.item_name AS item,
                tim.modifier_name AS modificador,
                COALESCE(ti.item_quantity, ti.item_count, 0) AS cantidad_item,
                COALESCE(tim.item_count, 0) AS selecciones,
                COALESCE(tim.modifier_price, 0) * COALESCE(tim.item_count, 0) AS monto_extra,
                t.branch_key AS sucursal,
                t.terminal_id AS terminal,
                t.id AS ticket_id,
                ti.id AS ticket_item_id
            ")
            ->orderByDesc('t.folio_date')
            ->orderByDesc('t.id')
            ->orderBy('ti.id')
            ->orderBy('tim.id');

        if ($branchIds && count($branchIds) > 0) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        return collect($query->get());
    }

    /**
     * Calcula KPIs según la vista
     */
    public function summarize(Collection $data, string $view): array
    {
        if ($data->isEmpty()) {
            return [
                'total_items' => 0,
                'total_modifiers' => 0,
                'total_combinations' => 0,
                'total_amount' => 0.0,
                'total_selections' => 0,
                'avg_amount_per_selection' => 0.0,
                'top_modifiers' => [],
                'days' => [],
            ];
        }

        return match ($view) {
            'summary_items' => $this->summarizeItems($data),
            'summary_item_mods' => $this->summarizeItemMods($data),
            'detail' => $this->summarizeDetail($data),
            default => [],
        };
    }

    /**
     * KPIs para summary_items
     */
    protected function summarizeItems(Collection $data): array
    {
        return [
            'total_items' => $data->pluck('menu_item')->filter()->unique()->count(),
            'total_categories' => $data->pluck('categoria')->filter()->unique()->count(),
            'total_groups' => $data->pluck('grupo_menu')->filter()->unique()->count(),
            'total_units' => (int) $data->sum('unidades_vendidas'),
            'total_gross' => round((float) $data->sum('ingreso_bruto_item'), 2),
            'total_discount' => round((float) $data->sum('descuento_item'), 2),
            'total_net' => round((float) $data->sum('ingreso_neto_item'), 2),
        ];
    }

    /**
     * KPIs para summary_item_mods (igual que el reporte actual)
     */
    protected function summarizeItemMods(Collection $data): array
    {
        $uniqueItems = $data->pluck('menu_item')->filter()->unique()->count();
        $uniqueModifiers = $data->pluck('modificador')->filter()->unique()->count();
        $totalCombinations = $data->count();

        $totalAmount = $data->sum(fn($row) => (float) ($row->monto_extra_modificador ?? 0));
        $totalSelections = $data->sum(fn($row) => (int) ($row->selecciones_modificador ?? 0));

        $avgAmountPerSelection = $totalSelections > 0
            ? round($totalAmount / $totalSelections, 2)
            : 0.0;

        $topModifiers = $data
            ->groupBy(fn($row) => $row->modificador ?? 'Sin nombre')
            ->map(function (Collection $items, string $name) {
                return [
                    'modifier' => $name,
                    'times_selected' => $items->sum(fn($row) => (int) ($row->selecciones_modificador ?? 0)),
                    'amount' => round($items->sum(fn($row) => (float) ($row->monto_extra_modificador ?? 0)), 2),
                ];
            })
            ->filter(fn($row) => $row['times_selected'] > 0 || $row['amount'] > 0)
            ->sortByDesc('amount')
            ->take(5)
            ->values()
            ->toArray();

        $days = $data->pluck('fecha')->filter()->unique()->sort()->values()->all();

        return [
            'total_items' => $uniqueItems,
            'total_modifiers' => $uniqueModifiers,
            'total_combinations' => $totalCombinations,
            'total_amount' => round($totalAmount, 2),
            'total_selections' => $totalSelections,
            'avg_amount_per_selection' => $avgAmountPerSelection,
            'top_modifiers' => $topModifiers,
            'days' => $days,
        ];
    }

    /**
     * KPIs para detail
     */
    protected function summarizeDetail(Collection $data): array
    {
        return [
            'total_records' => $data->count(),
            'total_items' => $data->pluck('item')->filter()->unique()->count(),
            'total_modifiers' => $data->pluck('modificador')->filter()->unique()->count(),
            'total_tickets' => $data->pluck('ticket_id')->filter()->unique()->count(),
            'total_amount' => round((float) $data->sum('monto_extra'), 2),
            'total_selections' => (int) $data->sum('selecciones'),
            'days' => $data->pluck('fecha')->filter()->unique()->sort()->values()->all(),
        ];
    }

    /**
     * Redondea a 2 decimales
     */
    protected function round(float $value): float
    {
        return round($value, 2);
    }
}
