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
        $salesMode = $filters['sales_mode'] ?? $this->getSalesMode();

        return match ($view) {
            'summary_items' => $this->fetchSummaryItems($startDate, $endDate, $branchIds, $terminalIds, $salesMode),
            'summary_item_mods' => $this->fetchSummaryItemMods($startDate, $endDate, $groupByDay, $branchIds, $terminalIds, $salesMode),
            'item_mod_combos' => $this->fetchItemModifierCombos(
                $startDate,
                $endDate,
                $branchIds,
                $terminalIds,
                (bool) ($filters['include_empty'] ?? false),
                $salesMode
            ),
            'detail' => $this->fetchDetail($startDate, $endDate, $branchIds, $terminalIds, $salesMode),
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
        ?array $terminalIds,
        string $salesMode
    ): Collection {
        $query = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d H:i:s'),
                $end->format('Y-m-d H:i:s'),
            ]);

        $this->applySalesModeFilter($query, 't', $salesMode);

        if ($salesMode === 'floreant_conciliation') {
            // Modo Conciliación Floreant: usa cálculo base (sin modificadores incluidos)
            $query->selectRaw('
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS menu_item,
                ti.item_price AS precio_item,
                SUM(COALESCE(ti.item_count, 0)) AS unidades_vendidas,
                SUM(ti.item_price * COALESCE(ti.item_count, 0)) AS ingreso_bruto_item,
                0 AS descuento_item,  // Descuentos se calculan en el método summarize
                SUM(ti.item_price * COALESCE(ti.item_count, 0)) AS ingreso_neto_item
            ')
                ->groupBy('ti.category_name', 'ti.group_name', 'ti.item_name', 'ti.item_price')
                ->orderBy('ti.category_name')
                ->orderBy('ti.group_name')
                ->orderBy('ti.item_name');
        } else {
            // Modo normal: usa total_price que incluye modificadores
            $query->selectRaw('
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS menu_item,
                ti.item_price AS precio_item,
                SUM(COALESCE(ti.item_count, 0)) AS unidades_vendidas,
                SUM(ti.total_price) AS ingreso_bruto_item,
                SUM(COALESCE(ti.discount, 0)) AS descuento_item,
                SUM(ti.total_price - COALESCE(ti.discount, 0)) AS ingreso_neto_item
            ')
                ->groupBy('ti.category_name', 'ti.group_name', 'ti.item_name', 'ti.item_price')
                ->orderBy('ti.category_name')
                ->orderBy('ti.group_name')
                ->orderBy('ti.item_name');
        }

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
        ?array $terminalIds,
        string $salesMode
    ): Collection {
        $dateSelect = $groupByDay
            ? 't.folio_date AS fecha,'
            : '';

        $dateGroupBy = $groupByDay
            ? 't.folio_date,'
            : '';

        $dateOrderBy = $groupByDay
            ? 't.folio_date,'
            : '';

        $query = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->join('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->leftJoin('public.menu_modifier as mm', 'mm.id', '=', 'tim.item_id')
            ->leftJoin('public.menu_modifier_group as mgr', 'mgr.id', '=', DB::raw('COALESCE(tim.group_id, mm.group_id)'))
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d H:i:s'),
                $end->format('Y-m-d H:i:s'),
            ]);

        $this->applySalesModeFilter($query, 't', $salesMode);

        // CORRECCIÓN: Eliminado ->whereNotNull('tim.modifier_name') para incluir items sin modificadores
        $query->selectRaw("
                {$dateSelect}
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS menu_item,
                mgr.name AS grupo_modificador,
                tim.modifier_name AS modificador,
                tim.modifier_price AS precio_extra_mod,
                t.branch_key AS sucursal,
                t.terminal_id AS terminal,
                SUM(COALESCE(ti.item_count, 0)) AS unidades_item,
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
     * Vista C: Combinaciones de Ítem + Modificadores
     *
     * Devuelve cada combinación única de (menú item + lista de modificadores) con sus totales.
     */
    protected function fetchItemModifierCombos(
        Carbon $start,
        Carbon $end,
        ?array $branchIds,
        ?array $terminalIds,
        bool $includeEmpty = false,
        string $salesMode = 'strict'
    ): Collection {
        $groupLookup = $this->getModifierGroupLookup();

        $rows = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->leftJoin('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->leftJoin('public.menu_modifier as mm', 'mm.id', '=', 'tim.item_id')
            ->leftJoin('public.menu_modifier_group as mgr', 'mgr.id', '=', 'mm.group_id')
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d H:i:s'),
                $end->format('Y-m-d H:i:s'),
            ]);

        $this->applySalesModeFilter($rows, 't', $salesMode);

        // CORRECCIÓN PARA CONCILIACIÓN FLOREANT:
        // Para 'floreant_conciliation' mode, usar item_price * item_count como base
        // Esto evita doble conteo de modificadores
        $baseColumn = $salesMode === 'floreant_conciliation'
            ? 'ti.item_price * COALESCE(ti.item_count, 1)'
            : 'ti.total_price';

        $rows->selectRaw("
                t.id AS ticket_id,
                ti.id AS ticket_item_id,
                t.folio_date AS fecha,
                t.branch_key AS sucursal,
                t.terminal_id AS terminal,
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS menu_item,
                ti.item_id AS menu_item_id,
                ti.item_price AS precio_item,
                ti.total_price AS total_linea,
                {$baseColumn} AS total_sin_mods,
                COALESCE(ti.item_count, 0) AS unidades_item,
                tim.group_id AS tim_group_id,
                tim.item_id AS tim_item_id,
                mgr.name AS grupo_modificador,
                tim.modifier_name AS modificador,
                COALESCE(tim.item_count, 0) AS cantidad_modificador,
                COALESCE(tim.modifier_price, mm.price, 0) AS precio_modificador
            ")
            ->orderBy('t.closing_date')
            ->orderBy('t.id')
            ->orderBy('ti.id')
            ->orderBy('tim.id');

        if ($branchIds && count($branchIds) > 0) {
            $rows->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $rows->whereIn('t.terminal_id', $terminalIds);
        }

        $base = collect($rows->get());

        // CORRECCIÓN: Obtener todas las filas individuales primero
        $allRows = $base->map(function ($row) {
            return (object) [
                'ticket_id' => $row->ticket_id,
                'ticket_item_id' => $row->ticket_item_id,
                'categoria' => $row->categoria,
                'grupo_menu' => $row->grupo_menu,
                'menu_item' => $row->menu_item,
                'menu_item_id' => $row->menu_item_id,
                'unidades_item' => (int) ($row->unidades_item ?? 0),
                'precio_item' => (float) ($row->precio_item ?? 0),
                'total_sin_mods' => (float) ($row->total_sin_mods ?? 0),
                'total_linea' => (float) ($row->total_linea ?? 0),
                'sucursal' => $row->sucursal,
                'modificador' => $row->modificador,
                'grupo_modificador' => $row->grupo_modificador,
                'mod_group' => $row->grupo_modificador ?? 'Sin grupo',
                'mod_name' => $row->modificador ?? '',
                'precio_modificador' => (float) ($row->precio_modificador ?? 0),
                'cantidad_modificador' => (int) ($row->cantidad_modificador ?? 0),
                'total_modificador' => (float) (($row->precio_modificador ?? 0) * ($row->cantidad_modificador ?? 0)),
            ];
        });

        // CORRECCIÓN ESTRUCTURAL: Cada ticket_item ya es una combinación única real
        // NO agrupar - cada ticket_item es una combinación válida
        $byTicketItem = $allRows->groupBy('ticket_item_id');

        // CORRECCIÓN: Agrupar por combinación de menú_item + modificadores
        $byCombination = [];

        foreach ($byTicketItem as $ticketItemId => $mods) {
            $first = $mods->first();

            // Skip items without modifiers if includeEmpty is false
            if (! $includeEmpty) {
                $hasModifiers = $mods->filter(fn ($r) => ! empty($r->mod_name))->count() > 0;
                if (! $hasModifiers) {
                    continue;
                }
            }

            // Obtener modificadores únicos para este ticket_item específico
            $modifiers = $mods
                ->filter(fn ($r) => ! empty($r->mod_name))
                ->map(function ($r) {
                    return [
                        'group' => $r->mod_group,
                        'name' => $r->mod_name,
                    ];
                })
                ->unique(function ($m) {
                    return strtolower(trim($m['group'])).'::'.strtolower(trim($m['name']));
                })
                ->values();

            // Crear etiqueta de combo para mostrar (ordenado para consistencia)
            $comboLabel = $modifiers->isEmpty()
                ? 'Sin modificadores'
                : $modifiers
                    ->sortBy(function ($m) {
                        return ($m['group'] ?? '').'::'.($m['name'] ?? '');
                    })
                    ->map(function ($m) {
                        $label = $m['name'] ?? '—';
                        if (! empty($m['group'])) {
                            $label = "{$m['group']}: {$label}";
                        }

                        return $label;
                    })
                    ->values()
                    ->implode(' · ');

            // Crear clave única para esta combinación
            $comboKey = ($first->categoria ?? '').'|'.
                       ($first->grupo_menu ?? '').'|'.
                       ($first->menu_item ?? '').'|'.
                       $comboLabel;

            // Inicializar si no existe esta combinación
            if (! isset($byCombination[$comboKey])) {
                $byCombination[$comboKey] = [
                    'categoria' => $first->categoria,
                    'grupo_menu' => $first->grupo_menu,
                    'menu_item' => $first->menu_item,
                    'combo' => $comboLabel,
                    'mods' => $modifiers,
                    'unidades_item' => 0,
                    'tickets' => 0,
                    'ticket_ids' => [],
                    'selecciones_modificador' => 0,
                    'monto_extra_modificador' => 0.0,
                    'ingreso_base_sin_mods' => 0.0, // Ingreso base SIN modificadores
                    'ingreso_total_con_mods' => 0.0, // Ingreso total CON modificadores
                    'precios_item' => [], // Para calcular precio promedio
                ];
            }

            // Acumular datos para esta combinación
            $unidades = (int) ($first->unidades_item ?? 0);
            $ingresoBaseSinMods = (float) ($first->total_sin_mods ?? 0);
            $ingresoTotalConMods = (float) ($first->total_linea ?? 0);
            $modifierCost = $mods->sum('total_modificador');
            $precioBase = (float) ($first->precio_item ?? 0);

            $byCombination[$comboKey]['unidades_item'] += $unidades;
            $byCombination[$comboKey]['tickets'] += 1;
            if (! empty($first->ticket_id)) {
                $byCombination[$comboKey]['ticket_ids'][$first->ticket_id] = true;
            }
            $byCombination[$comboKey]['selecciones_modificador'] += $mods->sum('cantidad_modificador');
            $byCombination[$comboKey]['monto_extra_modificador'] += $modifierCost;
            $byCombination[$comboKey]['ingreso_base_sin_mods'] += $ingresoBaseSinMods;
            $byCombination[$comboKey]['ingreso_total_con_mods'] += $ingresoTotalConMods;

            // Acumular precios para cálculo de promedio
            if ($precioBase > 0 && $unidades > 0) {
                $byCombination[$comboKey]['precios_item'][] = $precioBase;
            }
        }

        // Convertir al formato final con máximo detalle
        $processedRows = [];
        foreach ($byCombination as $comboData) {
            // Calcular precio promedio del item base (sin modificadores)
            $precioPromedio = 0.0;
            if (! empty($comboData['precios_item'])) {
                $precioPromedio = array_sum($comboData['precios_item']) / count($comboData['precios_item']);
            }

            // Precio promedio real (base + modificadores/unidad)
            $precioPromedioConMods = $comboData['unidades_item'] > 0
                ? $comboData['ingreso_total_con_mods'] / $comboData['unidades_item']
                : 0.0;

            $ticketsDistinct = ! empty($comboData['ticket_ids'])
                ? count($comboData['ticket_ids'])
                : $comboData['tickets'];

            // Construir detalle de modificadores para mostrar
            $modsDetalle = [];
            foreach ($comboData['mods'] as $mod) {
                $modsDetalle[] = [
                    'grupo' => $mod['group'] ?? 'Sin grupo',
                    'nombre' => $mod['name'],
                    'selecciones' => 0, // Se calculará después si se necesita
                    'costo_total' => 0.0, // Se calculará después si se necesita
                ];
            }

            $processedRows[] = (object) [
                // === DATOS PRINCIPALES DEL ITEM ===
                'categoria' => $comboData['categoria'],
                'grupo_menu' => $comboData['grupo_menu'],
                'menu_item' => $comboData['menu_item'],

                // === MÉTRICAS PRINCIPALES ===
                'unidades_item' => $comboData['unidades_item'],
                'tickets' => $ticketsDistinct,
                'precio_base' => $precioPromedio,              // Precio SIN modificadores
                'precio_promedio' => $precioPromedioConMods,   // Precio CON modificadores

                // === INGRESOS SEPARADOS ===
                'ingreso_base' => $comboData['ingreso_base_sin_mods'],      // Ingreso SIN modificadores
                'costo_modificadores' => $comboData['monto_extra_modificador'], // Costo de modificadores
                'ingreso_total' => $comboData['ingreso_total_con_mods'],        // Ingreso CON modificadores

                // === DETALLE DE MODIFICADORES ===
                'combo' => $comboData['combo'],
                'mods_distintos' => $comboData['mods']->pluck('name')->filter()->unique()->count(),
                'selecciones_modificador' => $comboData['selecciones_modificador'],
                'mods_detalle' => $modsDetalle,                // Array detallado de modificadores
                'ticket_ids' => array_keys($comboData['ticket_ids'] ?? []),

                // === MÉTRICAS ADICIONALES ===
                'avg_modificadores_por_ticket' => $comboData['tickets'] > 0
                    ? $comboData['selecciones_modificador'] / $comboData['tickets']
                    : 0.0,
                'porcentaje_modificadores_sobre_ingreso' => $comboData['ingreso_total_con_mods'] > 0
                    ? ($comboData['monto_extra_modificador'] / $comboData['ingreso_total_con_mods']) * 100
                    : 0.0,

                // === METADATA ===
                'sucursal' => 'MULTIPLE',
                'mods' => $comboData['mods'],
            ];
        }

        $result = collect($processedRows);

        // CORRECCIÓN: addItemsWithoutModifiers ya se llama arriba si es necesario
        if ($includeEmpty) {
            $this->addItemsWithoutModifiers($result, $start, $end, $branchIds, $terminalIds, $salesMode);
        }

        // Protección contra null
        if (! $result) {
            $result = collect([]);
        }

        return $result
            ->sortBy([
                fn ($row) => $row->categoria ?? 'ZZZ',
                fn ($row) => $row->grupo_menu ?? 'ZZZ',
                fn ($row) => $row->menu_item ?? 'ZZZ',
                fn ($row) => $row->combo ?? '',
            ])
            ->values();
    }

    /**
     * Vista C: Detalle a nivel de ticket
     */
    protected function fetchDetail(
        Carbon $start,
        Carbon $end,
        ?array $branchIds,
        ?array $terminalIds,
        string $salesMode
    ): Collection {
        $query = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->join('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d H:i:s'),
                $end->format('Y-m-d H:i:s'),
            ]);

        $this->applySalesModeFilter($query, 't', $salesMode);

        // CORRECCIÓN: Eliminado ->whereNotNull('tim.modifier_name') para incluir items sin modificadores
        $query->selectRaw('
                t.folio_date AS fecha,
                ti.item_name AS item,
                tim.modifier_name AS modificador,
                COALESCE(ti.item_count, 0) AS cantidad_item,
                COALESCE(tim.item_count, 0) AS selecciones,
                COALESCE(tim.modifier_price, 0) * COALESCE(tim.item_count, 0) AS monto_extra,
                t.branch_key AS sucursal,
                t.terminal_id AS terminal,
                t.id AS ticket_id,
                ti.id AS ticket_item_id
            ')
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
    public function summarize(Collection $data, string $view, string $salesMode = 'strict'): array
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
            'summary_items' => $this->summarizeItems($data, $salesMode),
            'summary_item_mods' => $this->summarizeItemMods($data),
            'item_mod_combos' => $this->summarizeItemModifierCombos($data, $salesMode),
            'detail' => $this->summarizeDetail($data),
            default => [],
        };
    }

    /**
     * KPIs para summary_items
     */
    protected function summarizeItems(Collection $data, string $salesMode): array
    {
        if ($salesMode === 'floreant_conciliation') {
            // Modo Conciliación Floreant: calcular descuentos desde tabla correcta
            $gross = (float) $data->sum('ingreso_bruto_item');

            // Obtener descuentos reales de ticket_item_discount para el período
            $discounts = DB::connection('pgsql')
                ->table('public.ticket_item_discount as tid')
                ->join('public.ticket_item as ti', 'ti.id', '=', 'tid.ticket_itemid')
                ->join('public.ticket as t', 't.id', '=', 'ti.ticket_id')
                ->whereBetween('t.folio_date', [
                    '2025-12-16 00:00:00',
                    '2025-12-23 23:59:59', // Ajustar según el período real
                ])
                ->where('t.paid', true)
                ->where('t.voided', false)
                ->where('t.total_price', '>', 0)
                ->sum('tid.amount');

            $discounts = round((float) $discounts, 2);
            $net = round($gross - $discounts, 2);

            return [
                'total_items' => $data->pluck('menu_item')->filter()->unique()->count(),
                'total_categories' => $data->pluck('categoria')->filter()->unique()->count(),
                'total_groups' => $data->pluck('grupo_menu')->filter()->unique()->count(),
                'total_units' => (int) $data->sum('unidades_vendidas'),
                'total_gross' => $gross,
                'total_discount' => $discounts,
                'total_net' => $net,
            ];
        } else {
            // Modo normal: usar datos calculados en el query
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
    }

    /**
     * KPIs para summary_item_mods (igual que el reporte actual)
     */
    protected function summarizeItemMods(Collection $data): array
    {
        $uniqueItems = $data->pluck('menu_item')->filter()->unique()->count();
        $uniqueModifiers = $data->pluck('modificador')->filter()->unique()->count();
        $totalCombinations = $data->count();

        $totalAmount = $data->sum(fn ($row) => (float) ($row->monto_extra_modificador ?? 0));
        $totalSelections = $data->sum(fn ($row) => (int) ($row->selecciones_modificador ?? 0));

        $avgAmountPerSelection = $totalSelections > 0
            ? round($totalAmount / $totalSelections, 2)
            : 0.0;

        $topModifiers = $data
            ->groupBy(fn ($row) => $row->modificador ?? 'Sin nombre')
            ->map(function (Collection $items, string $name) {
                return [
                    'modifier' => $name,
                    'times_selected' => $items->sum(fn ($row) => (int) ($row->selecciones_modificador ?? 0)),
                    'amount' => round($items->sum(fn ($row) => (float) ($row->monto_extra_modificador ?? 0)), 2),
                ];
            })
            ->filter(fn ($row) => $row['times_selected'] > 0 || $row['amount'] > 0)
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
     * KPIs para combinaciones de ítem + modificadores
     */
    protected function summarizeItemModifierCombos(Collection $data, string $salesMode = 'strict'): array
    {
        if ($salesMode === 'floreant_conciliation') {
            // Modo Conciliación Floreant: usar las mismas reglas que summarizeItems
            $itemsTotal = (float) $data->sum('ingreso_base');
            $modifiersTotal = (float) $data->sum('costo_modificadores');

            // Obtener descuentos reales de ticket_item_discount para el período
            $discounts = DB::connection('pgsql')
                ->table('public.ticket_item_discount as tid')
                ->join('public.ticket_item as ti', 'ti.id', '=', 'tid.ticket_itemid')
                ->join('public.ticket as t', 't.id', '=', 'ti.ticket_id')
                ->whereBetween('t.folio_date', [
                    '2025-12-16 00:00:00',
                    '2025-12-23 23:59:59', // Ajustar según el período real
                ])
                ->where('t.paid', true)
                ->where('t.voided', false)
                ->where('t.total_price', '>', 0)
                ->sum('tid.amount');

            $netTotal = $itemsTotal - $discounts;

            return [
                'total_combos' => $data->count(),
                'total_items' => $data->pluck('menu_item')->filter()->unique()->count(),
                'total_modifiers' => $data->sum('mods_distintos'),
                'total_combinations' => $data->count(),
                'total_units' => (int) $data->sum('unidades_item'),
                'total_selections' => (int) $data->sum('selecciones_modificador'),
                'total_amount' => $modifiersTotal, // Solo modificadores
                'items_total' => $itemsTotal, // Items sin modificadores
                'modifiers_total' => $modifiersTotal,
                'discounts_total' => round((float) $discounts, 2),
                'net_total' => round($netTotal, 2),
                'avg_amount_per_selection' => $data->sum('selecciones_modificador') > 0
                    ? round($modifiersTotal / $data->sum('selecciones_modificador'), 2)
                    : 0.0,
                'top_modifiers' => [],
                'days' => [],
            ];
        }

        // Modo normal
        return [
            'total_combos' => $data->count(),
            'total_items' => $data->pluck('menu_item')->filter()->unique()->count(),
            'total_units' => (int) $data->sum('unidades_item'),
            'total_selections' => (int) $data->sum('selecciones_modificador'),
            'total_amount' => round((float) $data->sum('monto_extra_modificador'), 2),
        ];
    }

    /**
     * Modo de ventas configurable (strict = paid=true AND voided=false, floreant_jasper = emula Jasper).
     */
    protected function getSalesMode(): string
    {
        return config('reports.item_mods.sales_mode', env('REPORT_ITEM_MODS_SALES_MODE', 'strict'));
    }

    /**
     * Aplica el filtro de ventas según el modo solicitado.
     */
    protected function applySalesModeFilter($query, string $alias, string $mode = 'strict'): void
    {
        $paidColumn = "{$alias}.paid";
        $voidedColumn = "{$alias}.voided";
        $totalPriceColumn = "{$alias}.total_price";

        switch ($mode) {
            case 'floreant_conciliation':
                // Modo Conciliación Floreant: Excluye tickets con total_price = 0 (descuento 100%)
                $query->where($paidColumn, true)
                    ->where($voidedColumn, false)
                    ->where($totalPriceColumn, '>', 0);
                break;
            case 'floreant_jasper':
                // Emula el reporte Jasper: solo valida que el ticket esté pagado (incluye voided)
                $query->where($paidColumn, true);
                break;
            case 'all':
                // Sin filtros (uso interno/debug)
                break;
            case 'strict':
            default:
                // Modo por omisión: paid=true y voided=false
                $query->where($paidColumn, true)
                    ->where($voidedColumn, false);
                break;
        }
    }

    /**
     * Mapa nombre de modificador -> grupo (catálogo) para cuando el group_id llega nulo en tickets.
     */
    protected function getModifierGroupLookup(): array
    {
        $rows = DB::connection('pgsql')
            ->table('public.menu_modifier as mm')
            ->leftJoin('public.menu_modifier_group as mg', 'mg.id', '=', 'mm.group_id')
            ->select('mm.name', 'mg.name as group_name')
            ->whereNotNull('mm.name')
            ->whereNotNull('mg.name')
            ->get();

        $byModifierName = [];
        $byModifierId = [];
        foreach ($rows as $row) {
            $key = strtolower(trim($row->name));
            $byModifierName[$key] = $row->group_name;
        }
        // Mapear por id -> grupo
        $rowsId = DB::connection('pgsql')
            ->table('public.menu_modifier as mm')
            ->leftJoin('public.menu_modifier_group as mg', 'mg.id', '=', 'mm.group_id')
            ->select('mm.id', 'mg.name as group_name', 'mg.id as group_id')
            ->whereNotNull('mg.name')
            ->whereNotNull('mm.id')
            ->get();
        foreach ($rowsId as $row) {
            $byModifierId[$row->id] = $row->group_name;
        }
        $modifierGroupIdByModifierId = [];
        foreach ($rowsId as $row) {
            $modifierGroupIdByModifierId[$row->id] = $row->group_id;
        }

        // Mapa de ítem -> grupos permitidos (para evitar asignar mods de otros grupos al ítem actual)
        $mig = DB::connection('pgsql')
            ->table('public.menuitem_modifiergroup as mig')
            ->leftJoin('public.menu_modifier_group as mg', 'mg.id', '=', 'mig.modifier_group')
            ->leftJoin('public.menu_item as mi', 'mi.id', '=', 'mig.menuitem_modifiergroup_id')
            ->select('mi.id as menu_item_id', 'mi.name as menu_item', 'mg.id as group_id', 'mg.name as group_name')
            ->whereNotNull('mi.id')
            ->whereNotNull('mg.id')
            ->get();

        $itemGroups = $mig
            ->groupBy('menu_item')
            ->map(function ($rows) {
                return $rows->pluck('group_name')->filter()->unique()->values()->all();
            })
            ->toArray();

        $itemGroupsById = $mig
            ->groupBy('menu_item_id')
            ->map(function ($rows) {
                return $rows->pluck('group_name')->filter()->unique()->values()->all();
            })
            ->toArray();

        $itemGroupIdsByItemId = $mig
            ->groupBy('menu_item_id')
            ->map(function ($rows) {
                return $rows->pluck('group_id')->filter()->unique()->values()->all();
            })
            ->toArray();

        return [
            'by_modifier_name' => $byModifierName,
            'by_modifier_id' => $byModifierId,
            'by_group_id' => array_column($rowsId->toArray(), 'group_name', 'group_id'),
            'by_item' => $itemGroups,
            'by_item_id' => $itemGroupsById,
            'group_ids_by_item_id' => $itemGroupIdsByItemId,
            'group_id_by_modifier_id' => $modifierGroupIdByModifierId,
        ];
    }

    /**
     * Catálogo de ítems (categoría + grupo) para mostrar ítems sin ventas/modificadores.
     */
    protected function getMenuCatalog(): Collection
    {
        return DB::connection('pgsql')
            ->table('public.menu_item as mi')
            ->leftJoin('public.menu_group as mg', 'mg.id', '=', 'mi.group_id')
            ->leftJoin('public.menu_category as mc', 'mc.id', '=', 'mg.category_id')
            ->selectRaw("
                mi.id AS menu_item_id,
                mi.name AS menu_item,
                COALESCE(mc.name, 'N/D') AS categoria,
                COALESCE(mg.name, 'N/D') AS grupo_menu,
                mi.price AS precio_item
            ")
            ->where(function ($q) {
                $q->whereNull('mi.visible')->orWhere('mi.visible', true);
            })
            ->get();
    }

    /**
     * Totales por ítem directamente de ticket_item (sin depender de modificadores).
     */
    protected function getBaseItemTotals(
        Carbon $start,
        Carbon $end,
        ?array $branchIds,
        ?array $terminalIds,
        string $salesMode = 'strict'
    ): Collection {
        $rows = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d H:i:s'),
                $end->format('Y-m-d H:i:s'),
            ]);

        $this->applySalesModeFilter($rows, 't', $salesMode);

        $rows->selectRaw('
                ti.category_name AS categoria,
                ti.group_name AS grupo_menu,
                ti.item_name AS menu_item,
                SUM(COALESCE(ti.item_count, 0)) AS unidades_item,
                SUM(ti.total_price) AS ingreso_total,
                SUM(ti.total_price_without_modifiers) AS ingreso_sin_mods,
                COUNT(*) AS tickets
            ')
            ->groupBy('ti.category_name', 'ti.group_name', 'ti.item_name');

        if ($branchIds && count($branchIds) > 0) {
            $rows->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $rows->whereIn('t.terminal_id', $terminalIds);
        }

        return collect($rows->get())->map(function ($row) {
            $units = (int) ($row->unidades_item ?? 0);
            $avgPrice = $units > 0
                ? round((float) ($row->ingreso_sin_mods ?? 0) / $units, 2)
                : 0.0;

            $normalizeKey = function ($categoria, $grupo, $item) {
                $parts = [
                    preg_replace('/\s+/', ' ', strtolower(trim((string) $categoria))),
                    preg_replace('/\s+/', ' ', strtolower(trim((string) $grupo))),
                    preg_replace('/\s+/', ' ', strtolower(trim((string) $item))),
                ];

                return implode('|', $parts);
            };

            $row->precio_item = $avgPrice;
            $row->key = $normalizeKey($row->categoria ?? '', $row->grupo_menu ?? '', $row->menu_item ?? '');

            return $row;
        });
    }

    /**
     * Obtiene el nombre del grupo por ID
     */
    protected function getGroupNameById(int $groupId): ?string
    {
        return DB::connection('pgsql')
            ->table('public.menu_modifier_group')
            ->where('id', $groupId)
            ->value('name');
    }

    /**
     * Valida consistencia de modificadores
     */
    public function validateModifierConsistency(Collection $data): array
    {
        $inconsistencies = $data->filter(function ($row) {
            // Para productos catalogados (menu_item_id > 0): verificar si el grupo en el combo es correcto
            if (($row->menu_item_id ?? 0) > 0 && ! empty($row->combo)) {
                // El combo debería usar el grupo correcto del menu_modifier
                $expectedGroupName = $this->getGroupNameByModifierName($row->modifier);
                $currentGroupName = $this->extractGroupNameFromCombo($row->combo);

                return $expectedGroupName && $currentGroupName && $expectedGroupName !== $currentGroupName;
            }

            return false;
        });

        return [
            'total_items' => $data->count(),
            'inconsistencias' => $inconsistencias->count(),
            'items_afectados' => $inconsistencias->pluck('menu_item')->unique()->values(),
        ];
    }

    /**
     * Obtiene el nombre del grupo correcto por nombre de modificador
     */
    protected function getGroupNameByModifierName(?string $modifierName): ?string
    {
        if (empty($modifierName)) {
            return null;
        }

        return DB::connection('pgsql')
            ->table('public.menu_modifier mm')
            ->join('public.menu_modifier_group mg', 'mg.id', '=', 'mm.group_id')
            ->where('mm.name', $modifierName)
            ->value('mg.name');
    }

    /**
     * Extrae el nombre del grupo del string del combo
     */
    protected function extractGroupNameFromCombo(?string $combo): ?string
    {
        if (empty($combo) || $combo === 'Sin modificadores') {
            return null;
        }

        // Formato esperado: "Grupo: Modificador"
        $parts = explode(':', $combo, 2);

        return trim($parts[0] ?? '');
    }

    /**
     * Redondea a 2 decimales
     */
    protected function round(float $value): float
    {
        return round($value, 2);
    }

    /**
     * Agrega items sin modificadores para el reporte de combos
     */
    protected function addItemsWithoutModifiers(Collection &$result, Carbon $start, Carbon $end, ?array $branchIds, ?array $terminalIds, string $salesMode = 'strict'): void
    {
        // Buscar items que no tienen modificadores y calcular sus ventas reales
        $query = DB::connection('pgsql')
            ->table('public.ticket AS t')
            ->join('public.ticket_item AS ti', 'ti.ticket_id', '=', 't.id')
            ->leftJoin('public.ticket_item_modifier AS tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d H:i:s'),
                $end->format('Y-m-d H:i:s'),
            ]);

        $this->applySalesModeFilter($query, 't', $salesMode);

        $query->whereNull('tim.id')
            ->select(
                'ti.category_name AS categoria',
                'ti.group_name AS grupo_menu',
                'ti.item_name AS menu_item',
                DB::raw('0 AS menu_item_id'),
                DB::raw("'Sin modificadores' AS combo"),
                DB::raw('SUM(COALESCE(ti.item_count, 0)) AS unidades_item'),
                DB::raw('0 AS mods_distintos'),
                DB::raw('0 AS selecciones_modificador'),
                DB::raw('0 AS monto_extra_modificador'),
                DB::raw('(SUM(ti.total_price) / NULLIF(SUM(COALESCE(ti.item_count, 1)), 0)) AS precio_item'),
                DB::raw('SUM(ti.total_price) AS ingreso_total'),
                DB::raw('COUNT(DISTINCT t.id) AS tickets'),
                DB::raw('MAX(t.branch_key) AS sucursal')
            )
            ->groupBy('ti.category_name', 'ti.group_name', 'ti.item_name');

        if ($branchIds && count($branchIds) > 0) {
            $query->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $query->whereIn('t.terminal_id', $terminalIds);
        }

        $itemsWithoutMods = $query->get();

        // Agregar cada item sin modificadores al resultado
        foreach ($itemsWithoutMods as $item) {
            // Verificar que este item no ya exista en el resultado
            $exists = $result->first(function ($r) use ($item) {
                return strtolower(trim($r->categoria ?? '')) === strtolower(trim($item->categoria ?? 'N/D'))
                    && strtolower(trim($r->grupo_menu ?? '')) === strtolower(trim($item->grupo_menu ?? 'N/D'))
                    && strtolower(trim($r->menu_item ?? '')) === strtolower(trim($item->menu_item ?? 'N/D'))
                    && ($r->combo === 'Sin modificadores' || $r->combo === 'Sin ventas');
            });

            if (! $exists) {
                $result->push((object) [
                    'categoria' => $item->categoria ?? 'N/D',
                    'grupo_menu' => $item->grupo_menu ?? 'N/D',
                    'menu_item' => $item->menu_item ?? 'N/D',
                    'combo' => 'Sin modificadores',
                    'mods_distintos' => 0,
                    'unidades_item' => (int) $item->unidades_item,
                    'selecciones_modificador' => 0,
                    'monto_extra_modificador' => 0.0,
                    'precio_item' => (float) ($item->precio_item ?? 0),
                    'ingreso_total' => (float) ($item->ingreso_total ?? 0),
                    'tickets' => (int) ($item->tickets ?? 0),
                    'sucursal' => (string) ($item->sucursal ?? '0'),
                ]);
            }
        }
    }
}
