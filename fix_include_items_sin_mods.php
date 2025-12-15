<?php

// Fix para ItemModsReportService - Método fetchItemModifierCombos
// Se necesita reemplazar el método existente con esta versión corregida

$fix = <<<'PHP'
    /**
     * Vista C: Combinaciones de Ítem + Modificadores
     *
     * Devuelve cada combinación única de (menú item + lista de modificadores) con sus totales.
     * INCLUYE items sin modificadores.
     */
    protected function fetchItemModifierCombos(
        Carbon $start,
        Carbon $end,
        ?array $branchIds,
        ?array $terminalIds,
        bool $includeEmpty = false
    ): Collection {
        $groupLookup = $this->getModifierGroupLookup();

        // CONSULTA PRINCIPAL - Trae todos los items (CON y SIN modificadores)
        $rows = DB::connection('pgsql')
            ->table('public.ticket as t')
            ->join('public.ticket_item as ti', 'ti.ticket_id', '=', 't.id')
            ->leftJoin('public.ticket_item_modifier as tim', 'tim.ticket_item_id', '=', 'ti.id')
            ->leftJoin('public.menu_modifier as mm', 'mm.id', '=', 'tim.item_id')
            ->leftJoin('public.menu_modifier_group as mgr', 'mgr.id', '=', DB::raw('COALESCE(tim.group_id, mm.group_id)'))
            ->whereBetween('t.closing_date', [
                $start->format('Y-m-d 00:00:00'),
                $end->format('Y-m-d 23:59:59')
            ])
            ->where('t.paid', true)
            ->where('t.voided', false)
            ->selectRaw("
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
                ti.total_price_without_modifiers AS total_sin_mods,
                ti.item_count AS unidades_item,
                ti.total_price AS ingreso_total_item,
                ti.discount AS descuento_item,
                tim.modifier_name AS modificador,
                tim.modifier_price AS precio_modificador,
                tim.item_count AS cantidad_modificador,
                tim.item_id AS tim_item_id,
                tim.group_id AS tim_group_id,
                mgr.name AS grupo_modificador
            ")
            ->orderBy('ti.category_name')
            ->orderBy('ti.group_name')
            ->orderBy('ti.item_name');

        if ($branchIds && count($branchIds) > 0) {
            $rows->whereIn('t.branch_key', $branchIds);
        }

        if ($terminalIds && count($terminalIds) > 0) {
            $rows->whereIn('t.terminal_id', $terminalIds);
        }

        $base = collect($rows->get());

        // Agrupar por línea de ticket y construir firma de modificadores ordenada
        $byTicketItem = $base->groupBy('ticket_item_id')->map(function (Collection $mods) use ($groupLookup) {
            $first = $mods->first();
            $branchSet = $mods->pluck('sucursal')->filter()->unique();
            $resolvedGroupLookupName = $groupLookup['by_modifier_name'];
            $resolvedGroupNameById = $groupLookup['by_group_id'];
            $itemId = $first->menu_item_id ?? null;
            $itemAllowedGroups = $groupLookup['by_item'][$first->menu_item] ?? [];
            $itemAllowedGroupsById = $groupLookup['by_item_id'][$itemId ?? null] ?? [];
            $itemAllowedGroupIds = $groupLookup['group_ids_by_item_id'][$itemId ?? null] ?? [];
            $groupIdByModifierId = $groupLookup['group_id_by_modifier_id'];

            // CORRECCIÓN: Procesar TODOS los items, incluso los que no tienen modificadores
            $modifiers = $mods
                ->filter(fn ($row) => !empty($row->modificador)) // Solo modificar items que sí tienen mods
                ->map(function ($row) use ($resolvedGroupLookupName, $resolvedGroupNameById, $itemAllowedGroups, $itemAllowedGroupsById, $itemAllowedGroupIds, $groupIdByModifierId) {
                    $groupName = $row->grupo_modificador ?? null;
                    $timGroupId = $row->tim_group_id ?? null;
                    $timModifierId = $row->tim_item_id ?? null;

                    if ($timModifierId) {
                        $modGroupId = $groupIdByModifierId[$timModifierId] ?? null;
                        if ($modGroupId) {
                            if (empty($itemAllowedGroupIds) || in_array((int) $modGroupId, $itemAllowedGroupIds, true)) {
                                $groupName = $resolvedGroupNameById[$modGroupId] ?? null;
                            }
                        }
                    }

                    if (!$groupName && $timGroupId) {
                        if (empty($itemAllowedGroupIds) || in_array((int) $timGroupId, $itemAllowedGroupIds, true)) {
                            $groupName = $resolvedGroupNameById[$timGroupId] ?? null;
                        }
                    }

                    if (!$groupName && $row->modificador) {
                        $lookupKey = strtolower(trim($row->modificador));
                        $mapped = $resolvedGroupLookupName[$lookupKey] ?? null;
                        $allowed = !empty($itemAllowedGroups) ? in_array($mapped, $itemAllowedGroups, true) : true;
                        $allowedById = !empty($itemAllowedGroupsById) ? in_array($mapped, $itemAllowedGroupsById, true) : true;
                        if ($allowed && $allowedById) {
                            $groupName = $mapped;
                        }
                    }

                    return (object) [
                        'group' => $groupName ?? 'Sin grupo',
                        'name' => $row->modificador ?? '',
                        'price' => (float) ($row->precio_modificador ?? 0),
                        'count' => (int) ($row->cantidad_modificador ?? 0),
                    ];
                })
                ->groupBy(fn ($m) => strtolower(trim(($m->group ?? '') . '::' . ($m->name ?? ''))))
                ->map(function (Collection $modsGrouped) {
                    $first = $modsGrouped->first();
                    $totalCount = $modsGrouped->sum('count');
                    $totalAmount = $modsGrouped->sum(fn ($m) => $m->price * $m->count);
                    return [
                        'group' => $first->group ?? 'Sin grupo',
                        'name' => $first->name ?? '—',
                        'count' => $totalCount,
                        'price' => $totalCount > 0 ? ($modsGrouped->sum('price') / $modsGrouped->count()) : 0,
                        'amount' => $totalAmount,
                    ];
                })
                ->values();

            // Firma de combinación - Si no hay modificadores, firma vacía
            $modsSignature = $modifiers->isNotEmpty()
                ? $modifiers
                    ->map(fn ($m) => strtolower(trim(($m['group'] ?? '') . '::' . ($m['name'] ?? ''))))
                    ->filter()
                    ->sort()
                    ->values()
                    ->all()
                : [];

            $signature = strtolower(trim((string) ($first->menu_item ?? ''))) . '||' . implode('||', $modsSignature);

            // CORRECCIÓN: Label apropiado para items sin modificadores
            $comboLabel = $modifiers->isEmpty()
                ? 'Sin modificadores'
                : $modifiers
                    ->map(function ($m) {
                        $label = $m['name'] ?? '—';
                        if (!empty($m['group'])) {
                            $label = "{$m['group']}: {$label}";
                        }
                        return $label;
                    })
                    ->unique()
                    ->values()
                    ->implode(' | ');

            $unidades = (int) ($first->unidades_item ?? 0);
            if ($unidades === 0 && $modifiers->isNotEmpty()) {
                $unidades = $modifiers->sum('count');
            }

            $precioBase = (float) ($first->precio_item ?? 0);
            if ($precioBase === 0 && $unidades > 0) {
                $precioBase = (float) ((($first->total_sin_mods ?? 0) / $unidades));
            }
            if ($precioBase === 0 && $unidades > 0) {
                $precioBase = (float) ((($first->ingreso_total_item ?? 0) / $unidades));
            }
            if ($precioBase === 0) {
                $precioBase = 1;
            }

            $ingresoBase = $precioBase * $unidades;
            $ingresoMods = $modifiers->sum('amount');
            $ingresoTotal = $ingresoBase + $ingresoMods;

            return (object) [
                'signature' => $signature,
                'combo' => $comboLabel,
                'mods_distintos' => $modifiers->pluck('name')->filter()->unique()->count(),
                'selecciones_modificador' => $modifiers->sum('count'),
                'monto_extra_modificador' => $ingressoMods,
                'categoria' => $first->categoria,
                'grupo_menu' => $first->grupo_menu,
                'menu_item' => $first->menu_item,
                'unidades_item' => $unidades,
                'precio_item' => $precioBase,
                'ingreso_total' => $ingresoTotal,
                'tickets' => 1,
                'sucursal' => $branchSet->first() ?? 'Sin sucursal',
                'mods' => $modifiers,
            ];
        });

        // Agrupar por firma de combinación
        $aggregated = [];
        $byTicketItem->each(function ($item) use (&$aggregated) {
            $key = $item->signature;
            if (!isset($aggregated[$key])) {
                $aggregated[$key] = (object) [
                    'categoria' => $item->categoria,
                    'grupo_menu' => $item->grupo_menu,
                    'menu_item' => $item->menu_item,
                    'combo' => $item->combo,
                    'mods_distintos' => $item->mods_distintos,
                    'unidades_item' => 0,
                    'selecciones_modificador' => 0,
                    'monto_extra_modificador' => 0,
                    'precio_item' => $item->precio_item,
                    'ingreso_total' => 0,
                    'tickets' => 0,
                    'sucursal' => $item->sucursal,
                ];
            }
            $aggregated[$key]->unidades_item += $item->unidades_item;
            $aggregated[$key]->selecciones_modificador += $item->selecciones_modificador;
            $aggregated[$key]->monto_extra_modificador += $item->monto_extra_modificador;
            $aggregated[$key]->ingreso_total += $item->ingreso_total;
            $aggregated[$key]->tickets += $item->tickets;
        });

        // Convertir a colección y ordenar
        $result = collect(array_values($aggregated))
            ->sortBy('categoria')
            ->thenBy('grupo_menu')
            ->thenBy('menu_item')
            ->thenBy('combo');

        // CORRECCIÓN: NO filtrar items sin modificadores
        if ($includeEmpty) {
            $items = $result->pluck('menu_item')->unique();
            $all = $this->fetchSummaryItems($start, $end, $branchIds, $terminalIds);
            $missing = $all->filter(fn ($row) => !$items->contains($row->menu_item));
            $missing->each(function ($row) use (&$result) {
                $result->push((object) [
                    'categoria' => $row->categoria,
                    'grupo_menu' => $row->grupo_menu,
                    'menu_item' => $row->menu_item,
                    'combo' => 'Sin modificadores',
                    'mods_distintos' => 0,
                    'unidades_item' => $row->unidades_vendidas,
                    'selecciones_modificador' => 0,
                    'monto_extra_modificador' => 0,
                    'precio_item' => $row->precio_item,
                    'ingreso_total' => $row->ingreso_neto_item,
                    'tickets' => 1,
                    'sucursal' => 'Sin sucursal',
                ]);
            });
        }

        return $result;
    }
PHP;

echo "COPY&PASTE este método para reemplazar el método fetchItemModifierCombos() existente en:\n";
echo "app/Services/Reports/ItemModsReportService.php\n\n";
echo "Cambios principales:\n";
echo "1. NO usa ->whereNotNull('tim.modifier_name')\n";
echo "2. NO filtra al final los items sin modificadores\n";
echo "3. Maneja correctamente items con y sin modificadores\n";
echo "4. Usa 'Sin modificadores' como label para items sin mods\n\n";
echo "El método empieza aproximadamente en la línea 169 del archivo.\n";