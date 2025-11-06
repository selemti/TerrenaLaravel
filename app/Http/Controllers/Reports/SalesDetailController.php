<?php

namespace App\Http\Controllers\Reports;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Illuminate\Http\Response;

class SalesDetailController extends BaseReportController
{
    /**
     * Paleta de respaldo cuando no exista color configurado para la sucursal.
     */
    protected array $fallbackPalette = [
        '#2563eb',
        '#16a34a',
        '#f97316',
        '#0ea5e9',
        '#f43f5e',
        '#8b5cf6',
        '#f59e0b',
        '#22c55e',
        '#7c3aed',
        '#ef4444',
        '#0f172a',
    ];

    public function index(Request $request): JsonResponse
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);

        $branchKeys = $rows
            ->map(fn ($row) => strtoupper(trim((string) ($row->branch_key ?? ''))))
            ->filter()
            ->unique()
            ->values();

        $branchColors = $this->prepareBranchColors($branchKeys->all());
        $branchOptions = $this->loadBranchOptions($branchColors, $branches);
        $branchLabels = $branchOptions->keyBy('key')
            ->map(fn (array $opt) => $opt['label'])
            ->toArray();

        $normalized = $this->normalizeRows($rows, $branchColors, $branchLabels);
        $items = $this->buildItemGroups($normalized);
        $adjustments = $this->extractAdjustments($normalized);
        $summary = $this->buildSummary($normalized, $items, $adjustments);
        $adjustmentSummary = $this->summarizeAdjustments($adjustments);

        return response()->json([
            'success' => true,
            'range' => [
                'start' => $start->toDateString(),
                'end' => $end->toDateString(),
            ],
            'branch' => empty($branches) ? null : implode(',', $branches),
            'terminal' => empty($terminals) ? null : implode(',', $terminals),
            'summary' => $summary,
            'items' => $items->values()->all(),
            'adjustments' => $adjustments->values()->all(),
            'adjustments_summary' => $adjustmentSummary->values()->all(),
            'raw' => $normalized->values()->all(),
        ]);
    }

    public function show(Request $request): View
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);

        $branchKeys = $rows
            ->map(fn ($row) => strtoupper(trim((string) ($row->branch_key ?? ''))))
            ->filter()
            ->unique()
            ->values();

        $branchColors = $this->prepareBranchColors($branchKeys->all());
        $branchOptions = $this->loadBranchOptions($branchColors, $branches);
        $branchLabels = $branchOptions->keyBy('key')
            ->map(fn (array $opt) => $opt['label'])
            ->toArray();

        $terminalOptions = $this->loadTerminalOptions($branchColors, $branchLabels, $terminals, $branches);

        $normalized = $this->normalizeRows($rows, $branchColors, $branchLabels);
        $items = $this->buildItemGroups($normalized);
        $adjustments = $this->extractAdjustments($normalized);
        $summary = $this->buildSummary($normalized, $items, $adjustments);
        $adjustmentSummary = $this->summarizeAdjustments($adjustments);

        return view('reports.sales.detail', [
            'active' => 'reportes',
            'startDate' => $start,
            'endDate' => $end,
            'branchFilter' => $branches,
            'terminalFilter' => $terminals,
            'branchOptions' => $branchOptions,
            'terminalOptions' => $terminalOptions,
            'branchColors' => $branchColors,
            'branchLabels' => $branchLabels,
            'items' => $items->values(),
            'adjustments' => $adjustments->values(),
            'adjustmentsSummary' => $adjustmentSummary->values(),
            'summaryMetrics' => $summary,
            'generatedAt' => now('America/Mexico_City'),
        ]);
    }

    public function exportPdf(Request $request): Response
    {
        [$start, $end, $branches, $terminals] = $this->resolveFilters($request);
        $rows = $this->fetch($start, $end, $branches, $terminals);

        $filename = sprintf(
            'reporte_detalle_ventas_%s_%s%s.pdf',
            $start->format('Ymd'),
            $end->format('Ymd'),
            !empty($branches)
                ? '_' . str_replace(' ', '_', strtolower(implode('-', $branches)))
                : ''
        );

        $branchString = empty($branches) ? null : implode(', ', $branches);
        $terminalString = empty($terminals) ? null : implode(', ', $terminals);

        return $this->renderPdf('reports.exports.sales.detail', [
            'startDate' => $start,
            'endDate' => $end,
            'branch' => $branchString,
            'terminal' => $terminalString,
            'rows' => $rows,
            'generatedAt' => now('America/Mexico_City'),
        ], $filename);
    }

    protected function resolveFilters(Request $request): array
    {
        $startInput = $request->input('start') ?? $request->input('start_date');
        $endInput = $request->input('end') ?? $request->input('end_date');

        $start = $startInput
            ? Carbon::parse($startInput, 'America/Mexico_City')
            : now('America/Mexico_City')->startOfDay();
        $end = $endInput
            ? Carbon::parse($endInput, 'America/Mexico_City')
            : $start->copy();

        if ($end->lt($start)) {
            [$start, $end] = [$end, $start];
        }

        $start = $start->startOfDay();
        $end = $end->startOfDay();

        $branches = $this->normalizeFilterList($request->input('branch'), uppercase: true);
        $terminals = $this->normalizeFilterList($request->input('terminal'), uppercase: false);

        return [$start, $end, $branches, $terminals];
    }

    protected function fetch(Carbon $start, Carbon $end, array $branches, array $terminals): Collection
    {
        $sql = "
            SELECT
                d.*,
                ti.item_id AS menu_item_id,
                ti.item_count,
                ti.item_quantity,
                ti.total_price AS ticket_item_total,
                ti.total_price_without_modifiers,
                ti.sub_total,
                ti.sub_total_without_modifiers,
                mi.price AS menu_item_price
            FROM public.vw_report_sales_detail d
            LEFT JOIN public.ticket_item ti ON ti.id = d.ticket_item_id
            LEFT JOIN public.menu_item mi ON mi.id = ti.item_id
            WHERE d.folio_date BETWEEN ? AND ?
        ";
        $bindings = [$start->toDateString(), $end->toDateString()];

        if (!empty($branches)) {
            $sql .= " AND UPPER(branch_key) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindings[] = implode(',', $branches);
        }

        if (!empty($terminals)) {
            $sql .= " AND CAST(terminal_id AS text) IN (SELECT UNNEST(string_to_array(?, ',')))";
            $bindings[] = implode(',', $terminals);
        }

        $rows = DB::connection('pgsql')->select($sql, $bindings);
        return collect($rows);
    }

    protected function normalizeRows(Collection $rows, array $branchColors, array $branchLabels): Collection
    {
        return $rows->map(function (object $row) use ($branchColors, $branchLabels) {
            $branchKey = strtoupper(trim((string) ($row->branch_key ?? 'SIN_SUCURSAL')));
            $itemName = trim((string) ($row->item_name ?? 'SIN REGISTRO'));
            $qty = (float) ($row->qty ?? 0.0);
            $itemQuantity = (float) ($row->item_quantity ?? 0.0);
            $itemCount = (float) ($row->item_count ?? 0.0);
            $unitPrice = (float) ($row->unit_price ?? 0.0);
            $discount = (float) ($row->line_discount ?? 0.0);
            $neto = (float) ($row->line_neto ?? 0.0);
            $lineTotal = (float) ($row->line_total ?? 0.0);
            $ticketItemTotal = (float) ($row->ticket_item_total ?? $lineTotal);
            $totalWithoutMods = (float) ($row->total_price_without_modifiers ?? 0.0);
            $subTotalWithoutMods = (float) ($row->sub_total_without_modifiers ?? 0.0);
            $menuPrice = (float) ($row->menu_item_price ?? 0.0);

            $effectiveQty = $qty;
            $quantitySource = 'view_qty';

            if (abs($effectiveQty) < 0.0001 && abs($itemQuantity) >= 0.0001) {
                $effectiveQty = $itemQuantity;
                $quantitySource = 'item_quantity';
            }

            if (abs($effectiveQty) < 0.0001 && abs($itemCount) >= 0.0001) {
                $effectiveQty = $itemCount;
                $quantitySource = 'item_count';
            }

            if (abs($effectiveQty) < 0.0001 && abs($unitPrice) > 0.0001) {
                $candidateBase = 0.0;

                if (abs($lineTotal) >= 0.0001) {
                    $candidateBase = $lineTotal;
                } elseif (abs($ticketItemTotal) >= 0.0001) {
                    $candidateBase = $ticketItemTotal;
                } elseif (abs($totalWithoutMods) >= 0.0001) {
                    $candidateBase = $totalWithoutMods;
                } elseif (abs($subTotalWithoutMods) >= 0.0001) {
                    $candidateBase = $subTotalWithoutMods;
                } else {
                    $candidateBase = $neto + $discount;
                }

                if (abs($candidateBase) < 0.0001) {
                    $candidateBase = $neto;
                }

                if (abs($candidateBase) >= 0.0001) {
                    $effectiveQty = $candidateBase / $unitPrice;
                    $quantitySource = 'derived_amount';
                }
            }

            $effectiveQty = $this->round($effectiveQty);
            if (abs($effectiveQty) < 0.0001) {
                $quantitySource = 'none';
            }

            return [
                'folio_date' => $row->folio_date
                    ? Carbon::parse($row->folio_date)->format('Y-m-d')
                    : null,
                'menu_item_id' => $row->menu_item_id ? (int) $row->menu_item_id : null,
                'branch_key' => $branchKey,
                'branch_label' => $branchLabels[$branchKey] ?? $branchKey,
                'branch_color' => $branchColors[$branchKey] ?? $this->fallbackPalette[0],
                'terminal_id' => (string) ($row->terminal_id ?? ''),
                'ticket_id' => (string) ($row->ticket_id ?? ''),
                'ticket_item_id' => (string) ($row->ticket_item_id ?? ''),
                'item_name' => $itemName,
                'qty' => $effectiveQty,
                'raw_qty' => $this->round($qty),
                'item_quantity' => $this->round($itemQuantity),
                'item_count' => $this->round($itemCount),
                'qty_source' => $quantitySource,
                'unit_price' => $this->round($unitPrice),
                'line_discount' => $this->round($discount),
                'menu_price' => $this->round($menuPrice),
                'line_neto' => $this->round($neto),
                'line_total' => $this->round($lineTotal),
                'is_adjustment' => abs($effectiveQty) < 0.0001,
            ];
        });
    }

    protected function buildItemGroups(Collection $rows): Collection
    {
        $modifiersMap = $this->loadModifiers($rows->pluck('ticket_item_id'));

        return $rows
            ->groupBy(function (array $row) {
                $menuItemId = $row['menu_item_id'] ?? null;
                return $row['branch_key'].'|'.($menuItemId !== null ? $menuItemId : 'NO_ITEM');
            })
            ->map(function (Collection $items, string $key) use ($modifiersMap) {
                [$branchKey, $menuItemKey] = explode('|', $key, 2);
                $first = $items->first();
                $itemName = $first['item_name'] ?? 'SIN REGISTRO';
                $menuItemId = $first['menu_item_id'] ?? null;

                $totalQty = $items->sum(fn (array $item) => $item['qty']);
                $totalDiscount = $items->sum(fn (array $item) => $item['line_discount']);
                $totalNeto = $items->sum(fn (array $item) => $item['line_neto']);
                $ticketCount = $items->pluck('ticket_id')->filter()->unique()->count();
                $terminalList = $items->pluck('terminal_id')->filter()->unique()->values()->all();
                $dates = $items->pluck('folio_date')->filter()->unique()->sort()->values()->all();
                $averageUnit = $totalQty !== 0.0
                    ? $this->round($totalNeto / max(0.0001, $totalQty))
                    : $this->round($items->average('unit_price'));

                $hasDerivedQty = $items->contains(fn (array $item) => $item['qty_source'] === 'derived_amount');
                $modifierSummary = $this->summarizeModifiers($items, $modifiersMap);
                $modifierGroups = $this->summarizeModifiersByGroup($items, $modifiersMap);
                $modifierCombos = $this->summarizeModifierCombos($items, $modifiersMap);

                return [
                    'group_id' => hash('sha1', $branchKey.'|'.$menuItemKey),
                    'branch_key' => $branchKey,
                    'branch_label' => $first['branch_label'] ?? $branchKey,
                    'branch_color' => $first['branch_color'] ?? $this->fallbackPalette[0],
                    'menu_item_id' => $menuItemId,
                    'item_name' => $itemName,
                    'total_qty' => $this->round($totalQty),
                    'total_discount' => $this->round($totalDiscount),
                    'total_neto' => $this->round($totalNeto),
                    'ticket_count' => $ticketCount,
                    'line_count' => $items->count(),
                    'average_unit' => $averageUnit,
                    'menu_price' => $first['menu_price'] ?? null,
                    'has_adjustments' => $items->contains(fn (array $item) => $item['is_adjustment']),
                    'has_derived_qty' => $hasDerivedQty,
                    'terminals' => $terminalList,
                    'dates' => $dates,
                    'details' => $items->map(function (array $item) use ($modifiersMap) {
                        return [
                            'ticket_item_id' => $item['ticket_item_id'],
                            'folio_date' => $item['folio_date'],
                            'ticket_id' => $item['ticket_id'],
                            'terminal_id' => $item['terminal_id'],
                            'qty' => $item['qty'],
                            'raw_qty' => $item['raw_qty'],
                            'item_quantity' => $item['item_quantity'],
                            'item_count' => $item['item_count'],
                            'qty_source' => $item['qty_source'],
                            'unit_price' => $item['unit_price'],
                            'line_discount' => $item['line_discount'],
                            'line_neto' => $item['line_neto'],
                            'line_total' => $item['line_total'],
                            'menu_price' => $item['menu_price'],
                            'modifiers' => $modifiersMap[$item['ticket_item_id']] ?? [],
                        ];
                    })->values()->all(),
                    'modifiers_summary' => $modifierSummary,
                    'modifiers_groups' => $modifierGroups,
                    'modifiers_combos' => $modifierCombos,
                ];
            })
            ->sort(function (array $a, array $b) {
                $netComparison = $b['total_neto'] <=> $a['total_neto'];
                if ($netComparison !== 0) {
                    return $netComparison;
                }

                return $b['total_qty'] <=> $a['total_qty'];
            })
            ->values();
    }

    protected function loadModifiers(Collection $ticketItemIds): array
    {
        $ids = $ticketItemIds
            ->filter()
            ->unique()
            ->map(fn ($id) => (int) $id)
            ->filter(fn ($id) => $id > 0)
            ->values();

        if ($ids->isEmpty()) {
            return [];
        }

        $result = collect();

        foreach ($ids->chunk(400) as $chunk) {
            $rows = DB::connection('pgsql')
                ->table('public.ticket_item_modifier as tim')
                ->selectRaw(<<<SQL
                    tim.ticket_item_id,
                    COALESCE(mm.name, tim.modifier_name, '') AS modifier_name,
                    COALESCE(tim.item_count, 0) AS modifier_count,
                    COALESCE(tim.total_price, 0) AS modifier_total,
                    COALESCE(mmg_mm.name, mmg_tim.name, 'Sin grupo') AS group_name
                SQL)
                ->leftJoin('public.menu_modifier as mm', 'mm.id', '=', 'tim.item_id')
                ->leftJoin('public.menu_modifier_group as mmg_mm', 'mmg_mm.id', '=', 'mm.group_id')
                ->leftJoin('public.menu_modifier_group as mmg_tim', 'mmg_tim.id', '=', 'tim.group_id')
                ->whereIn('tim.ticket_item_id', $chunk->all())
                ->get();

            foreach ($rows as $row) {
                $ticketItemId = (string) ($row->ticket_item_id ?? '');
                if ($ticketItemId === '') {
                    continue;
                }

                $count = (float) ($row->modifier_count ?? 0);
                if ($count <= 0) {
                    $count = 1.0;
                }

                $result->push([
                    'ticket_item_id' => $ticketItemId,
                    'name' => trim((string) ($row->modifier_name ?? '')),
                    'group_name' => trim((string) ($row->group_name ?? 'Sin grupo')) ?: 'Sin grupo',
                    'count' => $count,
                    'total' => (float) ($row->modifier_total ?? 0),
                ]);
            }
        }

        return $result
            ->groupBy('ticket_item_id')
            ->map(function (Collection $group) {
                return $group
                    ->map(function (array $mod) {
                        return [
                            'name' => $mod['name'] !== '' ? $mod['name'] : 'Sin nombre',
                            'group_name' => $mod['group_name'] ?? 'Sin grupo',
                            'count' => $mod['count'],
                            'total' => $this->round((float) ($mod['total'] ?? 0)),
                        ];
                    })
                    ->values()
                    ->all();
            })
            ->toArray();
    }

    protected function summarizeModifiers(Collection $items, array $modifiersMap): array
    {
        return $items
            ->flatMap(function (array $item) use ($modifiersMap) {
                $ticketItemId = $item['ticket_item_id'] ?? null;
                if (!$ticketItemId || !isset($modifiersMap[$ticketItemId])) {
                    return [];
                }

                $ticketId = $item['ticket_id'] ?? null;

                return collect($modifiersMap[$ticketItemId])->map(function (array $modifier) use ($ticketId) {
                    $count = (float) ($modifier['count'] ?? 0);
                    if ($count <= 0) {
                        $count = 1.0;
                    }

                    return [
                        'name' => $modifier['name'] ?? 'Sin nombre',
                        'group_name' => $modifier['group_name'] ?? 'Sin grupo',
                        'count' => $count,
                        'lines' => 1,
                        'total' => (float) ($modifier['total'] ?? 0),
                        'ticket_id' => $ticketId,
                    ];
                });
            })
            ->groupBy('name')
            ->map(function (Collection $mods, string $name) {
                $groupName = $mods->pluck('group_name')->filter()->first() ?? 'Sin grupo';
                $tickets = $mods->pluck('ticket_id')->filter()->unique()->count();
                $lines = $mods->count();

                return [
                    'name' => $name,
                    'group_name' => $groupName,
                    'count' => $this->round($mods->sum('count')), 
                    'lines' => $lines,
                    'tickets' => $tickets,
                    'total' => $this->round($mods->sum('total')),
                ];
            })
            ->sort(function (array $a, array $b) {
                $countComparison = $b['count'] <=> $a['count'];
                if ($countComparison !== 0) {
                    return $countComparison;
                }

                return $b['total'] <=> $a['total'];
            })
            ->values()
            ->all();
    }

    protected function summarizeModifiersByGroup(Collection $items, array $modifiersMap): array
    {
        return $items
            ->flatMap(function (array $item) use ($modifiersMap) {
                $ticketItemId = $item['ticket_item_id'] ?? null;
                if (!$ticketItemId || !isset($modifiersMap[$ticketItemId])) {
                    return [];
                }

                $ticketId = $item['ticket_id'] ?? null;

                return collect($modifiersMap[$ticketItemId])->map(function (array $modifier) use ($ticketId) {
                    $count = (float) ($modifier['count'] ?? 0);
                    if ($count <= 0) {
                        $count = 1.0;
                    }

                    return [
                        'group_name' => $modifier['group_name'] ?? 'Sin grupo',
                        'name' => $modifier['name'] ?? 'Sin nombre',
                        'count' => $count,
                        'total' => (float) ($modifier['total'] ?? 0),
                        'ticket_id' => $ticketId,
                    ];
                });
            })
            ->groupBy(fn (array $mod) => $mod['group_name'] ?? 'Sin grupo')
            ->map(function (Collection $mods, string $groupName) {
                $tickets = $mods->pluck('ticket_id')->filter()->unique()->count();

                $modifiers = $mods
                    ->groupBy('name')
                    ->map(function (Collection $group) {
                        return [
                            'name' => $group->first()['name'] ?? 'Sin nombre',
                            'count' => $group->sum('count'),
                            'total' => $this->round($group->sum('total')),
                        ];
                    })
                    ->sortByDesc(fn (array $entry) => [$entry['count'], $entry['total']])
                    ->values()
                    ->all();

                return [
                    'group_name' => $groupName ?: 'Sin grupo',
                    'count' => $this->round($mods->sum('count')),
                    'lines' => $mods->count(),
                    'tickets' => $tickets,
                    'total' => $this->round($mods->sum('total')),
                    'modifiers' => array_slice($modifiers, 0, 5),
                ];
            })
            ->sort(function (array $a, array $b) {
                $countComparison = $b['count'] <=> $a['count'];
                if ($countComparison !== 0) {
                    return $countComparison;
                }

                return $b['total'] <=> $a['total'];
            })
            ->values()
            ->all();
    }

    protected function summarizeModifierCombos(Collection $items, array $modifiersMap): array
    {
        return $items
            ->map(function (array $item) use ($modifiersMap) {
                $ticketItemId = $item['ticket_item_id'] ?? null;
                $modifiers = collect($modifiersMap[$ticketItemId] ?? [])
                    ->pluck('name')
                    ->filter()
                    ->map(fn (string $name) => trim($name))
                    ->filter()
                    ->unique()
                    ->sort()
                    ->values()
                    ->all();

                if (empty($modifiers)) {
                    return null;
                }

                $comboName = implode(' + ', $modifiers);

                return [
                    'combo' => $comboName,
                    'ticket_id' => $item['ticket_id'] ?? null,
                    'line_neto' => $item['line_neto'] ?? 0.0,
                ];
            })
            ->filter()
            ->groupBy('combo')
            ->map(function (Collection $group, string $combo) {
                $tickets = $group->pluck('ticket_id')->filter()->unique()->count();
                return [
                    'combo' => $combo,
                    'lines' => $group->count(),
                    'tickets' => $tickets,
                    'total_neto' => $this->round($group->sum('line_neto')),
                ];
            })
            ->sort(function (array $a, array $b) {
                $linesComparison = $b['lines'] <=> $a['lines'];
                if ($linesComparison !== 0) {
                    return $linesComparison;
                }

                return $b['total_neto'] <=> $a['total_neto'];
            })
            ->values()
            ->all();
    }

    protected function extractAdjustments(Collection $rows): Collection
    {
        return $rows
            ->filter(fn (array $row) => $row['is_adjustment'])
            ->sort(function (array $a, array $b) {
                $branchComparison = $a['branch_key'] <=> $b['branch_key'];
                if ($branchComparison !== 0) {
                    return $branchComparison;
                }

                $itemComparison = $a['item_name'] <=> $b['item_name'];
                if ($itemComparison !== 0) {
                    return $itemComparison;
                }

                return $a['ticket_id'] <=> $b['ticket_id'];
            })
            ->values();
    }

    protected function summarizeAdjustments(Collection $adjustments): Collection
    {
        return $adjustments
            ->groupBy(fn (array $row) => $row['branch_key'].'|'.$row['item_name'])
            ->map(function (Collection $group, string $key) {
                [$branchKey, $itemName] = explode('|', $key, 2);
                $first = $group->first();

                return [
                    'group_id' => hash('sha1', 'adj_'.$key),
                    'branch_key' => $branchKey,
                    'branch_label' => $first['branch_label'] ?? $branchKey,
                    'branch_color' => $first['branch_color'] ?? $this->fallbackPalette[0],
                    'item_name' => $itemName,
                    'lines' => $group->count(),
                    'tickets' => $group->pluck('ticket_id')->filter()->unique()->count(),
                    'total_neto' => $this->round($group->sum(fn (array $row) => $row['line_neto'])),
                    'total_discount' => $this->round($group->sum(fn (array $row) => $row['line_discount'])),
                ];
            })
            ->sort(function (array $a, array $b) {
                $lineComparison = $b['lines'] <=> $a['lines'];
                if ($lineComparison !== 0) {
                    return $lineComparison;
                }

                return $b['total_neto'] <=> $a['total_neto'];
            })
            ->values();
    }

    protected function buildSummary(Collection $rows, Collection $items, Collection $adjustments): array
    {
        return [
            'lines' => $rows->count(),
            'items' => $items->count(),
            'tickets' => $rows->pluck('ticket_id')->filter()->unique()->count(),
            'qty' => $this->round($rows->sum(fn (array $row) => $row['qty'])),
            'neto' => $this->round($rows->sum(fn (array $row) => $row['line_neto'])),
            'discount' => $this->round($rows->sum(fn (array $row) => $row['line_discount'])),
            'adjustments' => $adjustments->count(),
        ];
    }

    protected function normalizeFilterList(mixed $value, bool $uppercase = true): array
    {
        if (is_array($value)) {
            $items = $value;
        } elseif (is_string($value) && trim($value) !== '') {
            $items = explode(',', $value);
        } else {
            return [];
        }

        return collect($items)
            ->map(fn ($item) => trim((string) $item))
            ->filter()
            ->map(fn ($item) => $uppercase ? strtoupper($item) : $item)
            ->unique()
            ->values()
            ->all();
    }

    protected function prepareBranchColors(array $branchKeys): array
    {
        $configured = collect(config('reports.branch_colors', []))
            ->mapWithKeys(fn ($color, $key) => [strtoupper((string) $key) => $color])
            ->toArray();

        $palette = config('reports.branch_palette', $this->fallbackPalette);
        if (empty($palette)) {
            $palette = $this->fallbackPalette;
        }

        $colors = $configured;
        $index = 0;

        foreach ($branchKeys as $key) {
            $upper = strtoupper((string) $key);
            if ($upper === '') {
                continue;
            }

            if (!isset($colors[$upper])) {
                $colors[$upper] = $palette[$index % count($palette)];
                $index++;
            }
        }

        return $colors;
    }

    protected function loadBranchOptions(array $branchColors, array $selected): Collection
    {
        try {
            $rows = DB::connection('pgsql')->select("
                SELECT
                    UPPER(COALESCE(clave, '')) AS key,
                    COALESCE(nombre, UPPER(clave)) AS label
                FROM selemti.cat_sucursales
                ORDER BY nombre
            ");
        } catch (\Throwable $e) {
            $rows = [];
        }

        $options = collect($rows)
            ->map(fn (object $row) => [
                'key' => strtoupper(trim((string) ($row->key ?? ''))),
                'label' => trim((string) ($row->label ?? ($row->key ?? ''))),
            ])
            ->filter(fn (array $opt) => $opt['key'] !== '')
            ->keyBy('key');

        $selectedKeys = collect($selected)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->values()
            ->all();

        $allKeys = collect($branchColors)->keys()
            ->merge($options->keys())
            ->unique()
            ->values();

        return $allKeys
            ->map(function (string $key) use ($options, $branchColors, $selectedKeys) {
                $base = $options->get($key, [
                    'key' => $key,
                    'label' => $key,
                ]);

                $color = $branchColors[$key] ?? $this->fallbackPalette[0];

                return array_merge($base, [
                    'value' => $key,
                    'color' => $color,
                    'indicator_color' => $color,
                    'selected' => in_array($key, $selectedKeys, true),
                    'badge' => null,
                    'highlight' => false,
                ]);
            })
            ->sortBy(fn (array $opt) => $opt['label'])
            ->values();
    }

    protected function loadTerminalOptions(
        array $branchColors,
        array $branchLabels,
        array $selectedTerminals,
        array $selectedBranches
    ): Collection {
        try {
            $rows = DB::connection('pgsql')->select("
                SELECT
                    CAST(t.id AS text) AS id,
                    COALESCE(NULLIF(t.name, ''), CONCAT('Terminal ', t.id::text)) AS name,
                    UPPER(COALESCE(s.clave, t.location, '')) AS branch_key,
                    COALESCE(s.nombre, t.location, CONCAT('Terminal ', t.id::text)) AS branch_label
                FROM public.terminal t
                LEFT JOIN selemti.cat_sucursales s ON s.pos_location = t.location
                ORDER BY branch_label, t.id
            ");
        } catch (\Throwable $e) {
            $rows = [];
        }

        $selected = collect($selectedTerminals)
            ->map(fn ($value) => trim((string) $value))
            ->filter()
            ->values()
            ->all();

        $selectedBranchSet = collect($selectedBranches)
            ->map(fn ($value) => strtoupper(trim((string) $value)))
            ->filter()
            ->values()
            ->all();

        return collect($rows)
            ->map(function (object $row) use ($branchColors, $branchLabels, $selected, $selectedBranchSet) {
                $branchKey = strtoupper((string) ($row->branch_key ?? ''));
                $label = trim((string) ($row->branch_label ?? ''));

                $color = $branchColors[$branchKey] ?? $this->fallbackPalette[0];
                $badgeLabel = $branchLabels[$branchKey] ?? ($label ?: $branchKey);

                return [
                    'id' => (string) ($row->id ?? ''),
                    'value' => (string) ($row->id ?? ''),
                    'label' => trim(sprintf(
                        '%s · %s',
                        (string) ($row->id ?? ''),
                        (string) ($row->name ?? $row->id ?? '')
                    )),
                    'branch_key' => $branchKey,
                    'branch_label' => $badgeLabel,
                    'color' => $color,
                    'indicator_color' => null,
                    'selected' => in_array((string) ($row->id ?? ''), $selected, true),
                    'highlight' => $branchKey && in_array($branchKey, $selectedBranchSet, true),
                    'badge' => [
                        'label' => $badgeLabel,
                        'color' => $color,
                        'text_color' => '#ffffff',
                    ],
                ];
            })
            ->filter(fn (array $opt) => $opt['id'] !== '')
            ->values();
    }
}
