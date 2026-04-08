@php
    use Illuminate\Support\Str;

    $normalizeMods = function ($comboRow) {
        $mods = collect();

        if (isset($comboRow->mods) && is_iterable($comboRow->mods)) {
            $mods = collect($comboRow->mods)->map(function ($mod) {
                return [
                    'group' => $mod['group'] ?? $mod->group ?? $mod['group_modificador'] ?? $mod->group_modificador ?? $mod['grupo_modificador'] ?? $mod->grupo_modificador ?? null,
                    'name' => $mod['name'] ?? $mod->name ?? $mod['modificador'] ?? $mod->modificador ?? $mod['nombre'] ?? $mod->nombre ?? null,
                    'price' => (float) ($mod['price'] ?? $mod->price ?? $mod['precio'] ?? $mod->precio ?? 0),
                ];
            });
        } elseif (isset($comboRow->mods_detalle) && is_iterable($comboRow->mods_detalle)) {
            $mods = collect($comboRow->mods_detalle)->map(function ($mod) {
                return [
                    'group' => $mod['grupo'] ?? $mod->grupo ?? null,
                    'name' => $mod['nombre'] ?? $mod->nombre ?? null,
                    'price' => (float) ($mod['costo_total'] ?? $mod->costo_total ?? 0),
                ];
            });
        } elseif (isset($comboRow->modifiers) && is_iterable($comboRow->modifiers)) {
            $mods = collect($comboRow->modifiers)->map(function ($mod) {
                return [
                    'group' => $mod->grupo_modificador ?? $mod->grupo ?? null,
                    'name' => $mod->modificador ?? $mod->nombre ?? null,
                    'price' => (float) ($mod->precio_modificador ?? $mod->precio ?? 0),
                ];
            });
        } elseif (!empty($comboRow->combo) && is_string($comboRow->combo)) {
            $parts = preg_split('/\\s*·\\s*/', $comboRow->combo);
            $mods = collect($parts)->map(function ($part) {
                $group = null;
                $name = trim($part);
                if (str_contains($part, ':')) {
                    [$group, $namePart] = array_pad(explode(':', $part, 2), 2, '');
                    $group = trim($group);
                    $name = trim($namePart);
                }
                return [
                    'group' => $group,
                    'name' => $name,
                    'price' => 0.0,
                ];
            });
        }

        return $mods
            ->filter(fn ($m) => !empty($m['name']))
            ->map(function ($m) {
                return [
                    'group' => trim($m['group'] ?? 'Sin grupo'),
                    'name' => trim($m['name'] ?? ''),
                    'price' => round((float) ($m['price'] ?? 0), 2),
                ];
            })
            ->sortBy(fn ($m) => strtolower(($m['group'] ?? '') . '|' . ($m['name'] ?? '')))
            ->values();
    };

    $buildSignature = function ($mods) {
        if ($mods->isEmpty()) {
            return 'Sin modificadores';
        }

        return $mods
            ->map(fn ($m) => ($m['group'] ?: 'Sin grupo') . ': ' . $m['name'])
            ->implode(' · ');
    };

    $comboExtra = function ($comboRow) {
        if (isset($comboRow->costo_modificadores)) {
            return (float) $comboRow->costo_modificadores;
        }
        if (isset($comboRow->monto_extra_modificador)) {
            return (float) $comboRow->monto_extra_modificador;
        }
        return 0.0;
    };

    // Agrupar datos por categoría → grupo → item para la jerarquía
    $agrupadoPorCategoria = [];
    $totalGeneral = (object) [
        'base' => 0,
        'mods' => 0,
        'total' => 0,
        'unidades' => 0,
        'tickets' => 0,
        'items' => 0,
        'combos' => 0
    ];

    foreach ($rows as $row) {
        $categoria = $row->categoria ?? 'Sin categoría';
        $grupo = $row->grupo_menu ?? 'Sin grupo';
        $item = $row->menu_item;

        if (!isset($agrupadoPorCategoria[$categoria])) {
            $agrupadoPorCategoria[$categoria] = [
                'nombre' => $categoria,
                'grupos' => [],
                'totales' => (object) [
                    'base' => 0,
                    'mods' => 0,
                    'total' => 0,
                    'unidades' => 0,
                    'tickets' => 0,
                    'items' => 0,
                    'combos' => 0
                ]
            ];
        }

        if (!isset($agrupadoPorCategoria[$categoria]['grupos'][$grupo])) {
            $agrupadoPorCategoria[$categoria]['grupos'][$grupo] = [
                'nombre' => $grupo,
                'items' => [],
                'totales' => (object) [
                    'base' => 0,
                    'mods' => 0,
                    'total' => 0,
                    'unidades' => 0,
                    'tickets' => 0,
                    'items' => 0,
                    'combos' => 0
                ]
            ];
        }

        if (!isset($agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item])) {
            $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item] = [
                'first' => $row,
                'combos' => [],
                'totales_item' => (object) [
                    'base' => 0,
                    'mods' => 0,
                    'total' => 0,
                    'unidades' => 0,
                    'tickets' => 0,
                ],
                'mods_set' => [],
                'has_useful_combos' => false,
            ];
        }

        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item]['combos'][] = $row;

        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item]['totales_item']->base += (float) ($row->ingreso_base ?? 0);
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item]['totales_item']->mods += (float) ($row->costo_modificadores ?? $row->monto_extra_modificador ?? 0);
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item]['totales_item']->total += (float) ($row->ingreso_total ?? 0);
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item]['totales_item']->unidades += (int) ($row->unidades_item ?? 0);
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item]['totales_item']->tickets += (int) ($row->tickets ?? 0);

        $modsList = $normalizeMods($row);
        foreach ($modsList as $mod) {
            $key = strtolower(($mod['group'] ?? '') . '|' . ($mod['name'] ?? ''));
            $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$item]['mods_set'][$key] = true;
        }

        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->base += $row->ingreso_base;
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->mods += $row->costo_modificadores;
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->total += $row->ingreso_total;
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->unidades += $row->unidades_item;
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->tickets += $row->tickets;

        $agrupadoPorCategoria[$categoria]['totales']->base += $row->ingreso_base;
        $agrupadoPorCategoria[$categoria]['totales']->mods += $row->costo_modificadores;
        $agrupadoPorCategoria[$categoria]['totales']->total += $row->ingreso_total;
        $agrupadoPorCategoria[$categoria]['totales']->unidades += $row->unidades_item;
        $agrupadoPorCategoria[$categoria]['totales']->tickets += $row->tickets;

        $totalGeneral->base += $row->ingreso_base;
        $totalGeneral->mods += $row->costo_modificadores;
        $totalGeneral->total += $row->ingreso_total;
        $totalGeneral->unidades += $row->unidades_item;
        $totalGeneral->tickets += $row->tickets;
    }

    foreach ($agrupadoPorCategoria as &$categoriaData) {
        $categoriaData['totales']->items = 0;
        $categoriaData['totales']->combos = 0;

        foreach ($categoriaData['grupos'] as &$grupoData) {
            $grupoData['totales']->items = 0;
            $grupoData['totales']->combos = 0;

            foreach ($grupoData['items'] as &$itemData) {
                $totalesItem = $itemData['totales_item'];
                $unidades = max(0, (int) $totalesItem->unidades);

                $summaryRow = (object) [
                    'categoria' => $itemData['first']->categoria ?? $categoriaData['nombre'],
                    'grupo_menu' => $itemData['first']->grupo_menu ?? $grupoData['nombre'],
                    'menu_item' => $itemData['first']->menu_item ?? '',
                    'unidades_item' => $unidades,
                    'tickets' => (int) $totalesItem->tickets,
                    'ingreso_base' => (float) $totalesItem->base,
                    'costo_modificadores' => (float) $totalesItem->mods,
                    'ingreso_total' => (float) $totalesItem->total,
                    'precio_base' => $unidades > 0 ? $totalesItem->base / $unidades : 0,
                    'precio_promedio' => $unidades > 0 ? $totalesItem->total / $unidades : 0,
                    'mods_distintos' => count($itemData['mods_set']),
                ];
                $itemData['row'] = $summaryRow;

                $hasUsefulCombos = collect($itemData['combos'])->contains(function ($combo) use ($buildSignature, $normalizeMods, $comboExtra) {
                    $signature = $buildSignature($normalizeMods($combo));
                    return $signature !== 'Sin modificadores' || $comboExtra($combo) > 0;
                });
                $itemData['has_useful_combos'] = $hasUsefulCombos;

                $grupoData['totales']->items++;
                $grupoData['totales']->combos += count($itemData['combos']);
            }

            $categoriaData['totales']->items += $grupoData['totales']->items;
            $categoriaData['totales']->combos += $grupoData['totales']->combos;
        }

        $totalGeneral->items += $categoriaData['totales']->items;
        $totalGeneral->combos += $categoriaData['totales']->combos;
    }
    unset($categoriaData, $grupoData, $itemData);
@endphp

<table class="table table-mods-v2 table-hover no-stripe">
    <thead class="table-dark sticky-top">
        <tr>
            <th style="width: 28%">Ítem</th>
            <th class="text-end" style="width: 9%">Unidades</th>
            <th class="text-end" style="width: 12%">Base</th>
            <th class="text-end" style="width: 12%">Mods</th>
            <th class="text-end" style="width: 12%">Total</th>
            <th class="text-end small-header" style="width: 10%" data-bs-toggle="tooltip" title="Precio base promedio por unidad">Base/U</th>
            <th class="text-end small-header" style="width: 10%" data-bs-toggle="tooltip" title="Precio promedio real considerando extras">Prom/U</th>
            <th class="text-center" style="width: 7%">Acciones</th>
        </tr>
    </thead>
    <tbody>
        @forelse ($agrupadoPorCategoria as $categoria)
            @php $catId = Str::slug($categoria['nombre'] ?? 'cat'); @endphp
            <tr class="category-header level-category" data-collapse-target="cat-{{ $catId }}">
                <td colspan="8" class="py-2">
                    <div class="d-flex justify-content-between align-items-center">
                        <div class="d-flex align-items-center gap-2">
                            <i class="fas fa-chevron-right expand-icon"></i>
                            <strong class="h6 mb-0">{{ $categoria['nombre'] }}</strong>
                            <span class="badge bg-light text-dark">{{ count($categoria['grupos']) }} grupos</span>
                        </div>
                        <div class="d-flex align-items-center gap-2">
                            <span class="badge bg-success">{{ number_format($categoria['totales']->unidades, 0) }}u</span>
                            <span class="badge bg-info">{{ number_format($categoria['totales']->tickets, 0) }}t</span>
                            <span class="badge bg-primary">${{ number_format($categoria['totales']->total, 2) }}</span>
                        </div>
                    </div>
                </td>
            </tr>

            @foreach ($categoria['grupos'] as $grupo)
                @php $groupId = Str::slug($categoria['nombre'].'-'.$grupo['nombre']); @endphp
                <tr class="group-header level-group" data-category="cat-{{ $catId }}" data-collapse-target="group-{{ $groupId }}" id="group-header-{{ $groupId }}">
                    <td colspan="8" class="py-1">
                        <div class="d-flex justify-content-between align-items-center border-start ps-3">
                            <div class="d-flex align-items-center gap-2">
                                <i class="fas fa-chevron-right expand-icon"></i>
                                <strong>{{ $grupo['nombre'] }}</strong>
                                <span class="badge bg-secondary">{{ count($grupo['items']) }} items</span>
                            </div>
                            <div class="d-flex align-items-center gap-2 small text-muted">
                                <span class="badge bg-success">{{ number_format($grupo['totales']->unidades, 0) }}u</span>
                                <span class="badge bg-info">{{ number_format($grupo['totales']->tickets, 0) }}t</span>
                                <span class="badge bg-primary">${{ number_format($grupo['totales']->total, 2) }}</span>
                            </div>
                        </div>
                    </td>
                </tr>

                @foreach ($grupo['items'] as $itemKey => $itemData)
                    @php
                        $mainRow = $itemData['row'];
                        $combos = $itemData['combos'];
                        $itemId = Str::slug($mainRow->menu_item).'-'.$loop->index;
                        $hasUsefulCombos = $itemData['has_useful_combos'] ?? false;
                    @endphp

                    <tr class="item-row" data-category="cat-{{ $catId }}" data-group="group-{{ $groupId }}" @if($hasUsefulCombos) data-collapse-target="item-{{ $itemId }}" @endif>
                        <td class="py-2">
                            <div class="d-flex align-items-center gap-2 ps-4 border-start">
                                @if($hasUsefulCombos)
                                    <i class="fas fa-chevron-right expand-icon text-muted"></i>
                                @endif
                                <div class="item-name fw-bold">
                                    {{ $mainRow->menu_item }}
                                    @if(!$hasUsefulCombos)
                                        <span class="badge bg-light text-muted border ms-2">Sin mods</span>
                                    @endif
                                </div>
                            </div>
                        </td>
                        <td class="text-end fw-semibold py-2">{{ number_format($mainRow->unidades_item, 0) }}</td>
                        <td class="text-end text-success py-2">${{ number_format($mainRow->ingreso_base, 2) }}</td>
                        <td class="text-end text-warning py-2">${{ number_format($mainRow->costo_modificadores, 2) }}</td>
                        <td class="text-end fw-bold text-primary py-2">${{ number_format($mainRow->ingreso_total, 2) }}</td>
                        <td class="text-end py-2 price-subtle small">${{ number_format($mainRow->precio_base, 2) }}</td>
                        <td class="text-end py-2 price-subtle small">${{ number_format($mainRow->precio_promedio, 2) }}</td>
                        <td class="text-center py-2">
                            @if($hasUsefulCombos)
                                <button class="btn btn-sm btn-outline-primary" data-bs-toggle="tooltip" title="Ver combinaciones">
                                    <i class="fas fa-eye"></i>
                                </button>
                            @else
                                <button class="btn btn-sm btn-outline-secondary" disabled data-bs-toggle="tooltip" title="Sin modificadores">
                                    <i class="fas fa-eye-slash"></i>
                                </button>
                            @endif
                        </td>
                    </tr>

                    @php
                        $comboRows = collect($combos)->map(function ($comboRow) use ($normalizeMods, $buildSignature, $comboExtra) {
                            $modsList = $normalizeMods($comboRow);
                            $signature = $buildSignature($modsList);
                            $extra = $comboExtra($comboRow);

                            $ticketIds = [];
                            if (isset($comboRow->ticket_ids) && is_iterable($comboRow->ticket_ids)) {
                                foreach ($comboRow->ticket_ids as $id) {
                                    $ticketIds[$id] = true;
                                }
                            } elseif (isset($comboRow->ticket_id)) {
                                $ticketIds[$comboRow->ticket_id] = true;
                            }

                            return [
                                'signature' => $signature,
                                'mods' => $modsList->map(function ($m) {
                                    $text = trim(($m['group'] ? $m['group'] . ': ' : '') . ($m['name'] ?? ''));
                                    $costText = $m['price'] > 0 ? ' +$' . number_format($m['price'], 2) : '';
                                    return ['text' => $text . $costText, 'price' => $m['price']];
                                })->values(),
                                'mods_count' => $modsList->count(),
                                'units' => (int) ($comboRow->unidades_item ?? 0),
                                'tickets' => (int) ($comboRow->tickets ?? 0),
                                'ticket_ids' => $ticketIds,
                                'extra' => $extra,
                            ];
                        });

                        $consolidated = [];
                        foreach ($comboRows as $row) {
                            $sig = $row['signature'];
                            if (!isset($consolidated[$sig])) {
                                $consolidated[$sig] = $row;
                                $consolidated[$sig]['ticket_ids'] = $row['ticket_ids'] ?? [];
                                continue;
                            }

                            $consolidated[$sig]['units'] += $row['units'];
                            $consolidated[$sig]['tickets'] += $row['tickets'];
                            $consolidated[$sig]['extra'] += (float) ($row['extra'] ?? 0);
                            $consolidated[$sig]['ticket_ids'] = ($consolidated[$sig]['ticket_ids'] ?? []) + ($row['ticket_ids'] ?? []);
                        }

                        $consolidatedRows = collect($consolidated)
                            ->map(function ($row) {
                                $ticketIds = $row['ticket_ids'] ?? [];
                                $ticketsDistinct = !empty($ticketIds)
                                    ? count($ticketIds)
                                    : $row['tickets'];

                                return [
                                    'signature' => $row['signature'],
                                    'mods' => $row['mods'],
                                    'units' => $row['units'],
                                    'tickets' => $ticketsDistinct,
                                    'extra' => $row['extra'],
                                    'mods_count' => $row['mods_count'],
                                ];
                            })
                            ->sortBy([
                                fn ($r) => -1 * $r['units'],
                                fn ($r) => -1 * ($r['extra'] ?? 0),
                            ])
                            ->values();
                    @endphp

                    @php
                        $onlyNeutral = $consolidatedRows->count() === 1 && ($consolidatedRows->first()['signature'] ?? '') === 'Sin modificadores' && (($consolidatedRows->first()['extra'] ?? null) == 0 || ($consolidatedRows->first()['extra'] ?? null) === null);
                    @endphp

                    @if($hasUsefulCombos && !$onlyNeutral)
                        <tr class="collapse-content combo-row" id="item-{{ $itemId }}" data-category="cat-{{ $catId }}" data-group="group-{{ $groupId }}" style="/* display: none; */">
                            <td colspan="8" class="py-1">
                                <div class="p-2 border-start border-3 bg-white">
                                    <div class="combo-grid">
                                        <div class="combo-grid-row combo-legend text-muted small">
                                            <span class="flex-grow-1">Combinación</span>
                                            <span class="text-end" style="width: 80px;">Unidades</span>
                                            <span class="text-end" style="width: 70px;">Tickets</span>
                                            <span class="text-end" style="width: 70px;">Extra</span>
                                        </div>
                                        @foreach ($consolidatedRows as $combo)
                                            <div class="combo-grid-row py-1">
                                                <div class="flex-grow-1">
                                                    @php $modsCount = $combo['mods_count'] ?? 0; @endphp
                                                    @if($modsCount === 0 || $modsCount >= 3)
                                                        <div class="fw-semibold">{{ $combo['signature'] }}</div>
                                                    @else
                                                        <div class="d-flex flex-wrap gap-1">
                                                            @foreach ($combo['mods'] as $mod)
                                                                <span class="badge bg-light text-dark">{{ $mod['text'] }}</span>
                                                            @endforeach
                                                        </div>
                                                    @endif
                                                </div>
                                                <div class="text-end fw-semibold" style="width: 80px;">{{ number_format($combo['units'], 0) }}</div>
                                                <div class="text-end" style="width: 70px;">{{ number_format($combo['tickets'], 0) }}</div>
                                                <div class="text-end" style="width: 70px;">
                                                    @if($combo['extra'] !== null && $combo['extra'] > 0)
                                                        <span class="text-warning fw-semibold">+${{ number_format($combo['extra'], 2) }}</span>
                                                    @elseif($combo['extra'] !== null)
                                                        +$0.00
                                                    @else
                                                        —
                                                    @endif
                                                </div>
                                            </div>
                                        @endforeach
                                    </div>
                                </div>
                            </td>
                        </tr>
                    @endif
                @endforeach
            @endforeach
        @empty
            <tr>
                <td colspan="8" class="text-center py-5">
                    <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                    <div class="h5 text-muted">No se encontraron datos</div>
                    <p class="text-muted">No hay ítems con modificadores en el rango seleccionado</p>
                </td>
            </tr>
        @endforelse
    </tbody>

    <!-- Footer con Totales Generales -->
    <tfoot class="table-dark">
        <tr class="fw-bold">
            <td>TOTALES GENERALES</td>
            <td class="text-end">{{ number_format($totalGeneral->unidades, 0) }}</td>
            <td class="text-end text-success">${{ number_format($totalGeneral->base, 2) }}</td>
            <td class="text-end text-warning">${{ number_format($totalGeneral->mods, 2) }}</td>
            <td class="text-end text-primary">${{ number_format($totalGeneral->total, 2) }}</td>
            <td class="text-end">-</td>
            <td class="text-end">-</td>
            <td class="text-center">
                <span class="badge bg-success">
                    {{ $totalGeneral->combos }} combos
                </span>
            </td>
        </tr>
    </tfoot>
</table>

<style>
.table-mods-v2 {
    font-size: 0.875rem;
    width: 100%;
}

.table-mods-v2 thead th {
    border-bottom: 2px solid #dee2e6;
    font-weight: 600;
    font-size: 0.8rem;
    text-transform: uppercase;
    letter-spacing: 0.35px;
}

.category-header, .group-header, .item-row {
    cursor: pointer;
    user-select: none;
    transition: background-color 0.2s;
}

.category-header:hover, .group-header:hover {
    background-color: #f8f9fa !important;
}

.expand-icon {
    transition: transform 0.2s ease;
    font-size: 0.8em;
}

.expand-icon.rotated {
    transform: rotate(90deg);
}

.level-category {
    border-left: 5px solid #0d6efd;
    background: #f5f8ff;
}

.level-group {
    border-left: 3px solid #198754;
    background: #f8fffb;
}

.table-mods-v2 td {
    vertical-align: middle;
    padding: 0.35rem 0.4rem;
}

.price-subtle {
    font-size: 0.8rem;
    color: #6c757d;
    font-weight: 400;
}

.small-header {
    font-size: 0.8rem;
}

.combo-grid {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
}

.combo-grid-row {
    display: flex;
    align-items: flex-start;
    gap: 0.5rem;
}

.item-row:hover {
    background: #f8f9fa;
}

.combo-grid-legend {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    border-bottom: 1px solid #e9ecef;
    padding-bottom: 0.35rem;
}

.no-stripe tbody tr:nth-of-type(odd) {
    background-color: transparent;
}

.category-header td {
    background: #f5f8ff;
    font-weight: 700;
}

.group-header td {
    background: #f8fffb;
    padding-left: 0.75rem;
}

.item-row td {
    padding-left: 1rem;
}

.combo-row td {
    background: #fbfbfd;
    font-size: 0.85rem;
}
</style>
