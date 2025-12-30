@php
    use Illuminate\Support\Str;
@endphp

@push('styles')
<style>
/* Estilos generales */
.table-clean {
    font-size: 0.875rem;
    border-collapse: separate;
    border-spacing: 0;
}

.table-clean thead th {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    font-weight: 600;
    border: none;
    padding: 1rem;
    position: sticky;
    top: 0;
    z-index: 10;
}

.table-clean tbody tr {
    transition: all 0.2s ease;
}

.table-clean tbody tr:hover {
    background-color: #f8f9fa;
    transform: scale(1.01);
}

/* Categorías */
.category-header {
    background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
    color: white !important;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
}

.category-header:hover {
    background: linear-gradient(135deg, #218838 0%, #1ea085 100%);
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(40, 167, 69, 0.3);
}

.category-header td {
    padding: 1rem !important;
    border: none !important;
}

/* Items principales */
.item-row {
    background-color: white;
    border-left: 4px solid #667eea;
}

.item-row td {
    padding: 0.75rem 0.5rem;
    vertical-align: middle;
}

.item-name {
    font-weight: 600;
    color: #212529;
}

/* Badges */
.badge-category {
    background-color: #6c757d;
    color: white;
    font-size: 0.7rem;
    padding: 0.25rem 0.5rem;
    border-radius: 0.25rem;
}

.badge-group {
    background-color: #17a2b8;
    color: white;
    font-size: 0.7rem;
    padding: 0.25rem 0.5rem;
    border-radius: 0.25rem;
}

/* Columnas específicas */
.col-units {
    min-width: 80px;
    text-align: center;
    font-weight: 600;
    color: #495057;
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

/* Tabla de modificadores */
.modifiers-section {
    background-color: #f8f9fa;
    border-radius: 0.5rem;
    margin: 0.5rem 0;
    overflow: hidden;
}

.modifiers-table {
    font-size: 0.85rem;
    background-color: white;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.modifiers-table thead th {
    background: linear-gradient(135deg, #6c757d 0%, #495057 100%);
    color: white;
    font-size: 0.8rem;
    padding: 0.6rem;
    border: none;
}

.modifiers-table tbody td {
    padding: 0.6rem;
    border-top: 1px solid #dee2e6;
}

/* Combinación de modificadores */
.modifier-entry {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    flex-wrap: wrap;
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
}

.modifier-name {
    color: #495057;
    font-weight: 500;
}

.modifier-separator {
    color: #adb5bd;
    font-weight: 600;
    margin: 0 0.3rem;
}

/* Sin modificadores */
.no-modifiers {
    color: #6c757d;
    font-style: italic;
}

/* Mejor vendido */
.badge-best {
    background: linear-gradient(45deg, #28a745, #20c997) !important;
    color: white !important;
    font-weight: 600;
    box-shadow: 0 2px 4px rgba(40, 167, 69, 0.3);
}

/* Estadísticas */
.mod-stats {
    font-family: 'Courier New', monospace;
    font-size: 0.9rem;
    font-weight: 600;
}

/* Animaciones */
.fade-in {
    animation: fadeIn 0.3s ease-in;
}

@keyframes fadeIn {
    from { opacity: 0; transform: translateY(-10px); }
    to { opacity: 1; transform: translateY(0); }
}

/* Responsive */
@media (max-width: 768px) {
    .table-clean { font-size: 0.75rem; }
    .modifiers-table { font-size: 0.7rem; }
    .modifier-entry { flex-direction: column; align-items: flex-start; }
}
</style>
@endpush

@php
    // Agrupar por categoría para estructura principal
    $groupedByCategory = $rows->groupBy(function($row) {
        return $row->categoria ?? 'Sin Categoría';
    })->sortKeys();

    // Separar items con y sin modificadores para cada categoría
    function separateItems($items) {
        $withModifiers = $items->filter(fn($row) => !empty($row->combo));
        $withoutModifiers = $items->filter(fn($row) => empty($row->combo));

        // Agrupar items con modificadores por menu_item
        $withModifiers = $withModifiers->groupBy('menu_item');

        // Agrupar items sin modificadores por menu_item
        $withoutModifiers = $withoutModifiers->groupBy('menu_item');

        return [
            'with_modifiers' => $withModifiers,
            'without_modifiers' => $withoutModifiers
        ];
    }
@endphp

<div class="table-responsive">
    <table class="table table-hover align-middle mb-0 table-clean">
        <thead class="table-dark">
            <tr>
                <th style="width: 12rem;">Categoría</th>
                <th style="width: 10rem;">Grupo</th>
                <th>Menú Item</th>
                <th class="text-center col-units">Unidades</th>
                <th class="text-end col-income">Ingreso</th>
                <th class="col-actions"></th>
            </tr>
        </thead>
        <tbody>
        @foreach($groupedByCategory as $categoria => $categoryItems)
            @php
                $separated = separateItems($categoryItems);
                $totalCategoryUnits = $categoryItems->sum('unidades_item');
                $totalCategoryIncome = $categoryItems->sum('ingreso_total');
                $categoryId = 'cat-' . Str::slug($categoria) . '-' . uniqid();
            @endphp

            {{-- Fila de categoría --}}
            <tr class="category-header" data-bs-toggle="collapse" data-bs-target="#{{ $categoryId }}" aria-expanded="true">
                <td colspan="6">
                    <div class="d-flex justify-content-between align-items-center">
                        <div class="d-flex align-items-center">
                            <i class="fas fa-chevron-down me-2 transition-icon"></i>
                            <span class="fw-bold fs-6">{{ strtoupper($categoria) }}</span>
                        </div>
                        <div class="d-flex align-items-center gap-3">
                            <span class="small">
                                <i class="fas fa-box me-1"></i>
                                {{ number_format($totalCategoryUnits) }} unids
                            </span>
                            <span class="small">
                                <i class="fas fa-dollar-sign me-1"></i>
                                ${{ number_format($totalCategoryIncome, 2) }}
                            </span>
                        </div>
                    </div>
                </td>
            </tr>

            {{-- Contenido de la categoría --}}
            <tr class="collapse show" id="{{ $categoryId }}">
                <td colspan="6" class="p-0">
                    <div class="p-3">
                        {{-- Items CON modificadores --}}
                        @if($separated['with_modifiers']->isNotEmpty())
                            <h6 class="mb-3 text-muted">
                                <i class="fas fa-sliders-h me-2"></i>
                                Items con Modificadores
                            </h6>

                            @foreach($separated['with_modifiers'] as $menuItem => $modifiersList)
                                @php
                                    $itemTotalUnits = $modifiersList->sum('unidades_item');
                                    $itemTotalIncome = $modifiersList->sum('ingreso_total');
                                    $itemId = 'item-mods-' . Str::slug($categoria.'-'.$menuItem) . '-' . uniqid();
                                @endphp

                                <div class="mb-4">
                                    {{-- Fila principal del item --}}
                                    <table class="table table-sm mb-0">
                                        <tbody>
                                            <tr class="item-row fade-in">
                                                <td>
                                                    <span class="badge-category">{{ $categoria }}</span>
                                                </td>
                                                <td>
                                                    <span class="badge-group">{{ $modifiersList->first()->grupo_menu ?? 'N/D' }}</span>
                                                </td>
                                                <td class="item-name fw-bold">{{ $menuItem }}</td>
                                                <td class="text-center fw-bold">{{ number_format($itemTotalUnits) }}</td>
                                                <td class="text-end fw-bold text-success">${{ number_format($itemTotalIncome, 2) }}</td>
                                                <td>
                                                    <button class="btn btn-link btn-sm p-0 text-muted" data-bs-toggle="collapse" data-bs-target="#{{ $itemId }}" title="Ver combinaciones">
                                                        <i class="fas fa-chevron-down"></i>
                                                    </button>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>

                                    {{-- Combinaciones de modificadores --}}
                                    <div class="collapse show" id="{{ $itemId }}">
                                        <div class="modifiers-section ms-4">
                                            <div class="table-responsive">
                                                <table class="table table-sm modifiers-table">
                                                    <thead>
                                                        <tr>
                                                            <th style="width: 45%;">Combinación</th>
                                                            <th class="text-center" style="width: 18%;">Unidades</th>
                                                            <th class="text-center" style="width: 18%;">Tickets</th>
                                                            <th class="text-end" style="width: 19%;">Extra</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        @foreach($modifiersList->sortByDesc('unidades_item')->values() as $index => $combo)
                                                            @php
                                                                $badge = $index === 0 ? 'Más vendida' : null;
                                                                $modifierParts = [];

                                                                if (!empty($combo->combo)) {
                                                                    $parts = explode('::', $combo->combo);
                                                                    foreach ($parts as $part) {
                                                                        if (strpos($part, ': ') !== false) {
                                                                            list($group, $name) = explode(': ', $part, 2);
                                                                            $modifierParts[] = (object)[
                                                                                'group' => trim($group),
                                                                                'name' => trim($name)
                                                                            ];
                                                                        }
                                                                    }
                                                                }
                                                            @endphp
                                                            <tr class="{{ $index === 0 ? 'table-success' : '' }}">
                                                                <td>
                                                                    @if(!empty($modifierParts))
                                                                        <div class="modifier-entry">
                                                                            @foreach($modifierParts as $i => $mod)
                                                                                @if($i > 0)<span class="modifier-separator">+</span>@endif
                                                                                <span class="modifier-group">{{ $mod->group }}</span>
                                                                                <span class="modifier-name">{{ $mod->name }}</span>
                                                                            @endforeach
                                                                        </div>
                                                                    @else
                                                                        <span class="no-modifiers">Sin modificadores específicos</span>
                                                                    @endif
                                                                    @if($badge)
                                                                        <span class="badge badge-best ms-2">{{ $badge }}</span>
                                                                    @endif
                                                                </td>
                                                                <td class="text-center mod-stats">{{ number_format($combo->unidades_item) }}</td>
                                                                <td class="text-center mod-stats">{{ number_format($combo->tickets) }}</td>
                                                                <td class="text-end fw-semibold mod-stats">${{ number_format($combo->monto_extra_modificador, 2) }}</td>
                                                            </tr>
                                                        @endforeach
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            @endforeach
                        @endif

                        {{-- Items SIN modificadores --}}
                        @if($separated['without_modifiers']->isNotEmpty())
                            @if($separated['with_modifiers']->isNotEmpty())
                                <hr class="my-4">
                                <h6 class="mb-3 text-muted">
                                    <i class="fas fa-utensils me-2"></i>
                                    Items sin Modificadores
                                </h6>
                            @endif

                            <table class="table table-sm">
                                <tbody>
                                    @foreach($separated['without_modifiers'] as $menuItem => $itemData)
                                        @php
                                            $item = $itemData->first();
                                        @endphp
                                        <tr class="item-row fade-in">
                                            <td>
                                                <span class="badge-category">{{ $categoria }}</span>
                                            </td>
                                            <td>
                                                <span class="badge-group">{{ $item->grupo_menu ?? 'N/D' }}</span>
                                            </td>
                                            <td class="item-name">{{ $menuItem }}</td>
                                            <td class="text-center fw-bold">{{ number_format($item->unidades_item) }}</td>
                                            <td class="text-end fw-bold text-success">${{ number_format($item->ingreso_total, 2) }}</td>
                                            <td>
                                                <span class="text-muted small" title="Sin modificadores">
                                                    <i class="fas fa-ban"></i>
                                                </span>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        @endif

                        @if($separated['with_modifiers']->isEmpty() && $separated['without_modifiers']->isEmpty())
                            <div class="text-center text-muted py-3">
                                <i class="fas fa-info-circle me-2"></i>
                                No hay datos disponibles para esta categoría
                            </div>
                        @endif
                    </div>
                </td>
            </tr>
        @endforeach

        @if($groupedByCategory->isEmpty())
            <tr>
                <td colspan="6" class="text-center py-5">
                    <i class="fas fa-exclamation-triangle fa-3x text-warning mb-3"></i>
                    <h5>No hay datos disponibles</h5>
                    <p class="text-muted">No se encontraron registros en el rango de fechas seleccionado.</p>
                </td>
            </tr>
        @endif
        </tbody>
    </table>
</div>

{{-- JavaScript para animaciones --}}
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Animar iconos de colapso
    document.querySelectorAll('[data-bs-toggle="collapse"]').forEach(function(trigger) {
        trigger.addEventListener('show.bs.collapse', function () {
            const icon = this.querySelector('i');
            if (icon && icon.classList.contains('fa-chevron-right')) {
                icon.classList.remove('fa-chevron-right');
                icon.classList.add('fa-chevron-down');
            }
        });

        trigger.addEventListener('hide.bs.collapse', function () {
            const icon = this.querySelector('i');
            if (icon && icon.classList.contains('fa-chevron-down')) {
                icon.classList.remove('fa-chevron-down');
                icon.classList.add('fa-chevron-right');
            }
        });
    });
});
</script>