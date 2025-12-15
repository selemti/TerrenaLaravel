@php
    use Illuminate\Support\Str;
@endphp

@push('styles')
<style>
/* Encabezado de categorías */
.category-header {
    cursor: pointer;
    transition: all 0.3s ease;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    color: white !important;
    border: none !important;
}

.category-header:hover {
    background: linear-gradient(135deg, #5a67d8 0%, #6b4a9b 100%) !important;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.category-header .fa-chevron-down {
    transition: transform 0.3s ease;
    color: white !important;
}

.category-header .fa-chevron-right {
    transition: transform 0.3s ease;
    color: white !important;
}

/* Contenido colapsable */
.collapse-content {
    border-left: 4px solid #667eea;
    background-color: #f8f9fa;
}

/* Tabla principal */
.table-mods {
    font-size: 0.875rem;
}

.table-mods thead th {
    background-color: #495057;
    color: white;
    font-weight: 600;
    border: none;
    padding: 0.75rem;
    white-space: nowrap;
}

.table-mods tbody tr {
    transition: background-color 0.2s ease;
}

.table-mods tbody tr:hover {
    background-color: #e9ecef;
}

/* Filas de ítems principales */
.item-row {
    background-color: white;
    border-left: 3px solid #28a745;
}

.item-row td {
    padding: 0.75rem 0.5rem;
    vertical-align: middle;
}

.item-row .item-name {
    font-weight: 600;
    color: #212529;
    font-size: 0.95rem;
}

.item-row .category-badge {
    background-color: #6c757d;
    color: white;
    font-size: 0.7rem;
    padding: 0.2rem 0.4rem;
    border-radius: 0.25rem;
}

.item-row .group-badge {
    background-color: #17a2b8;
    color: white;
    font-size: 0.7rem;
    padding: 0.2rem 0.4rem;
    border-radius: 0.25rem;
}

/* Tabla de modificadores */
.modifiers-table {
    background-color: #f8f9fa;
    border-radius: 0.5rem;
    overflow: hidden;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.modifiers-table thead th {
    background: linear-gradient(135deg, #6c757d 0%, #495057 100%);
    color: white;
    font-size: 0.8rem;
    padding: 0.6rem;
    border: none;
    font-weight: 600;
}

.modifiers-table tbody td {
    padding: 0.6rem;
    font-size: 0.85rem;
    border-top: 1px solid #dee2e6;
}

.modifiers-table tbody tr:hover {
    background-color: #e9ecef;
}

/* Columnas específicas */
.col-units {
    min-width: 80px;
    text-align: center;
    font-weight: 600;
    color: #495057;
}

.col-selections {
    min-width: 90px;
    text-align: center;
    font-weight: 600;
    color: #6f42c1;
}

.col-price {
    min-width: 100px;
    text-align: right;
    font-family: 'Courier New', monospace;
}

.col-income {
    min-width: 120px;
    text-align: right;
    font-weight: 700;
    color: #28a745;
    font-family: 'Courier New', monospace;
}

.col-actions {
    min-width: 50px;
    text-align: center;
}

/* Botones de expansión */
.btn-expand {
    color: #6c757d;
    transition: all 0.2s ease;
}

.btn-expand:hover {
    color: #495057;
    transform: scale(1.1);
}

/* Badges */
.badge-best {
    background: linear-gradient(45deg, #28a745, #20c997) !important;
    color: white !important;
    font-weight: 600;
    box-shadow: 0 2px 4px rgba(40, 167, 69, 0.3);
}

/* Modificadores mejorados */
.modifier-entry {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.modifier-group {
    background: linear-gradient(45deg, #667eea, #764ba2);
    color: white;
    font-size: 0.65rem;
    padding: 0.15rem 0.4rem;
    border-radius: 0.3rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    box-shadow: 0 1px 3px rgba(102, 126, 234, 0.4);
}

.modifier-name {
    color: #495057;
    font-weight: 500;
    font-size: 0.9rem;
}

.modifier-separator {
    color: #adb5bd;
    font-weight: 600;
    margin: 0 0.3rem;
}

.mod-stats {
    font-family: 'Courier New', monospace;
    font-size: 0.9rem;
    font-weight: 600;
}

/* Responsive */
@media (max-width: 1200px) {
    .table-mods {
        font-size: 0.8rem;
    }

    .modifiers-table {
        font-size: 0.75rem;
    }
}

@media (max-width: 768px) {
    .category-header span {
        font-size: 0.7rem !important;
    }

    .table-mods {
        font-size: 0.75rem;
    }

    .modifiers-table {
        font-size: 0.7rem;
    }
}
</style>
@endpush

@php
    // Agrupar por categoría y grupo
    $grouped = $rows->groupBy(fn($row) => $row->categoria ?? 'N/D')
        ->map(function ($catGroup) {
            return $catGroup->groupBy(fn($row) => $row->grupo_menu ?? 'N/D');
        })
        ->sortKeys();
@endphp

{{-- Tabla mejorada con filas expandibles --}}
<div class="table-responsive">
    <table class="table table-hover align-middle mb-0 table-mods">
        <thead class="table-dark">
            <tr>
                <th style="width: 10rem;" title="Categoría del menú">Categoría</th>
                <th style="width: 8rem;" title="Grupo dentro de la categoría">Grupo</th>
                <th title="Producto vendido en el ticket">Menú Item</th>
                <th class="text-center col-units" title="Unidades vendidas del ítem">Unidades</th>
                <th class="text-end col-price" title="Precio promedio por unidad">Precio Prom.</th>
                <th class="text-end col-income" title="Ingreso total del ítem">Ingreso</th>
                <th class="col-actions"></th>
            </tr>
        </thead>
        <tbody>
        @foreach($grouped as $categoria => $grupos)
            @php
                $catUnits = $grupos->flatten()->sum('unidades_item');
                $catIncome = $grupos->flatten()->sum(fn($r) => (float) ($r->ingreso_total ?? 0));
                $catId = 'cat-' . Str::slug($categoria) . '-' . uniqid();
                $isFirstCategory = $loop->first;
            @endphp
            <tr class="category-header" data-bs-toggle="collapse" data-bs-target="#{{ $catId }}" aria-expanded="{{ $isFirstCategory ? 'true' : 'false' }}" aria-controls="{{ $catId }}">
                <td colspan="7">
                    <div class="d-flex justify-content-between align-items-center">
                        <div class="d-flex align-items-center">
                            <i class="fa-solid fa-chevron-down me-2 transition-transform" id="{{ $catId }}-icon"></i>
                            <span class="fw-semibold">{{ strtoupper($categoria) }}</span>
                        </div>
                        <div class="d-flex align-items-center gap-3">
                            <span class="small">
                                <i class="fa-solid fa-box me-1"></i>
                                {{ number_format($catUnits) }} unids
                            </span>
                            <span class="small">
                                <i class="fa-solid fa-dollar-sign me-1"></i>
                                ${{ number_format($catIncome, 2) }}
                            </span>
                        </div>
                    </div>
                </td>
            </tr>

            {{-- Contenido colapsable de la categoría --}}
            <tr class="collapse {{ $isFirstCategory ? 'show' : '' }} collapse-content" id="{{ $catId }}">
                <td colspan="7" class="p-0">
                    <div class="table-responsive">
                        <table class="table table-sm mb-0">
                            <tbody>
                            @foreach($grupos->sortKeys() as $grupoMenu => $items)
                                @php
                                    $itemsByMenu = $items->groupBy(fn($row) => $row->menu_item ?? '—')
                                        ->sortKeys()
                                        ->map(function ($list, $itemName) {
                                            $units = (int) $list->sum('unidades_item');
                                            $extra = (float) $list->sum('monto_extra_modificador');
                                            $income = (float) $list->sum('ingreso_total');
                                            $price = (float) ($list->first()->precio_item ?? 0);

                                            // Si el income del servicio es 0 pero hay extra, usar el cálculo tradicional
                                            if ($income == 0 && $extra > 0) {
                                                $income = round(($price * $units) + $extra, 2);
                                            }

                                            $avg = $units > 0 ? round($income / $units, 2) : 0;

                                            $combos = $list->sortByDesc('unidades_item')->values();

                                            // NO distribuir unidades - mostrar datos reales
                                            $combos = $combos->values();

                                            return [
                                                'name' => $itemName,
                                                'units' => $units,
                                                'extra' => $extra,
                                                'price' => $price,
                                                'income' => $income,
                                                'avg_price' => $avg,
                                                'combos' => $combos,
                                            ];
                                        });
                                @endphp

                                @foreach($itemsByMenu as $itemName => $data)
                                    @php
                                        $rowId = 'combo-' . Str::slug($categoria.'-'.$grupoMenu.'-'.$itemName) . '-' . uniqid();
                                        $hasCombos = $data['combos']->isNotEmpty();

                                        // Solo mostrar collapse si hay modificadores
                                        $showCollapse = $hasCombos;
                                    @endphp

                                    <tr class="item-row">
                                        <td>
                                            <span class="category-badge">{{ strtoupper($categoria) }}</span>
                                        </td>
                                        <td>
                                            <span class="group-badge">{{ $grupoMenu }}</span>
                                        </td>
                                        <td class="item-name">{{ $itemName }}</td>
                                        <td class="text-center col-units">{{ number_format($data['units']) }}</td>
                                        <td class="text-end col-price">${{ number_format($data['avg_price'], 2) }}</td>
                                        <td class="text-end col-income">${{ number_format($data['income'], 2) }}</td>
                                        <td class="col-actions">
                                            @if($showCollapse)
                                                <button class="btn btn-link btn-sm p-0 btn-expand" data-bs-toggle="collapse" data-bs-target="#{{ $rowId }}" aria-expanded="false" aria-controls="{{ $rowId }}" title="Ver modificadores">
                                                    <i class="fa-solid fa-chevron-down"></i>
                                                </button>
                                            @endif
                                        </td>
                                    </tr>

                                    @if($showCollapse)
                                        <tr class="collapse bg-light" id="{{ $rowId }}">
                                            <td colspan="7">
                                                <div class="p-3">
                                                    <h6 class="mb-3 text-muted">
                                                        <i class="fa-solid fa-sliders me-2"></i>
                                                        Combinaciones de Modificadores
                                                        <small class="text-muted ms-2">{{ number_format($data['units']) }} unidades vendidas en {{ count($data['combos']) }} combinaciones</small>
                                                    </h6>
                                                    <div class="table-responsive">
                                                        <table class="table table-sm modifiers-table">
                                                            <thead>
                                                                <tr>
                                                                    <th style="width: 45%;">Combinación</th>
                                                                    <th class="text-center" style="width: 18%;">Tickets</th>
                                                                    <th class="text-center" style="width: 18%;">Selecciones</th>
                                                                    <th class="text-end" style="width: 19%;">Extra</th>
                                                                </tr>
                                                            </thead>
                                                            <tbody>
                                                                @foreach($data['combos'] as $index => $combo)
                                                                    @php
                                                                        $badge = $index === 0 ? 'Más vendida' : null;
                                                                        $modifierParts = [];

                                                                        if (!empty($combo->combo) && $combo->combo !== 'Sin modificadores') {
                                            $parts = explode(' | ', $combo->combo);
                                            foreach ($parts as $part) {
                                                if (strpos($part, ': ') !== false) {
                                                    list($group, $name) = explode(': ', $part, 2);
                                                    $modifierParts[] = (object)[
                                                        'group' => trim($group),
                                                        'name' => trim($name)
                                                    ];
                                                } else {
                                                    // Si no tiene grupo, agregar solo el nombre
                                                    $modifierParts[] = (object)[
                                                        'group' => '',
                                                        'name' => trim($part)
                                                    ];
                                                }
                                            }
                                        }
                                                                    @endphp
                                                                    <tr>
                                                                        <td>
                                                                            @if(!empty($modifierParts))
                                                                                <div class="modifier-entry">
                                                                                    @foreach($modifierParts as $i => $mod)
                                                                                        @if($i > 0)<span class="modifier-separator">|</span>@endif
                                                                                        @if(!empty($mod->group))
                                                                                            <span class="modifier-group">{{ $mod->group }}</span>: <span class="modifier-name">{{ $mod->name }}</span>
                                                                                        @else
                                                                                            <span class="modifier-name">{{ $mod->name }}</span>
                                                                                        @endif
                                                                                    @endforeach
                                                                                </div>
                                                                            @else
                                                                                <span class="modifier-name text-muted">Sin modificadores</span>
                                                                            @endif
                                                                            @if($badge)
                                                                                <span class="badge badge-best ms-2">{{ $badge }}</span>
                                                                            @endif
                                                                        </td>
                                                                        <td class="text-center mod-stats">{{ number_format((int) ($combo->tickets ?? 0)) }}</td>
                                                                        <td class="text-center mod-stats col-selections">{{ number_format((int) ($combo->selecciones_modificador ?? 0)) }}</td>
                                                                        <td class="text-end fw-semibold mod-stats">${{ number_format((float) ($combo->monto_extra_modificador ?? 0), 2) }}</td>
                                                                    </tr>
                                                                @endforeach
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>
                                            </td>
                                        </tr>
                                    @endif
                                @endforeach
                            @endforeach
                            </tbody>
                        </table>
                    </div>
                </td>
            </tr>
        @endforeach
        </tbody>
    </table>
</div>

{{-- JavaScript para animar los iconos de colapso --}}
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Agregar event listeners para las categorías
    document.querySelectorAll('[data-bs-toggle="collapse"][data-bs-target^="#cat-"]').forEach(function(trigger) {
        trigger.addEventListener('show.bs.collapse', function () {
            const icon = document.querySelector(trigger.getAttribute('data-bs-target') + '-icon');
            if (icon) {
                icon.classList.remove('fa-chevron-right');
                icon.classList.add('fa-chevron-down');
            }
        });

        trigger.addEventListener('hide.bs.collapse', function () {
            const icon = document.querySelector(trigger.getAttribute('data-bs-target') + '-icon');
            if (icon) {
                icon.classList.remove('fa-chevron-down');
                icon.classList.add('fa-chevron-right');
            }
        });
    });
});
</script>