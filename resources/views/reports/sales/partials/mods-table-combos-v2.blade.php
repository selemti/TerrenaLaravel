@php
    use Illuminate\Support\Str;

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

        // Inicializar estructura si no existe
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

        // Agregar item
        $itemKey = $item . '|' . ($row->combo ?? '');
        if (!isset($agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$itemKey])) {
            $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$itemKey] = [
                'row' => $row,
                'combos' => []
            ];
        }

        // Agregar combo
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['items'][$itemKey]['combos'][] = $row;

        // Actualizar totales de grupo
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->base += $row->ingreso_base;
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->mods += $row->costo_modificadores;
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->total += $row->ingreso_total;
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->unidades += $row->unidades_item;
        $agrupadoPorCategoria[$categoria]['grupos'][$grupo]['totales']->tickets += $row->tickets;

        // Actualizar totales de categoría
        $agrupadoPorCategoria[$categoria]['totales']->base += $row->ingreso_base;
        $agrupadoPorCategoria[$categoria]['totales']->mods += $row->costo_modificadores;
        $agrupadoPorCategoria[$categoria]['totales']->total += $row->ingreso_total;
        $agrupadoPorCategoria[$categoria]['totales']->unidades += $row->unidades_item;
        $agrupadoPorCategoria[$categoria]['totales']->tickets += $row->tickets;

        // Actualizar totales generales
        $totalGeneral->base += $row->ingreso_base;
        $totalGeneral->mods += $row->costo_modificadores;
        $totalGeneral->total += $row->ingreso_total;
        $totalGeneral->unidades += $row->unidades_item;
        $totalGeneral->tickets += $row->tickets;
    }

    // Contar items y combos únicos
    $totalGeneral->items = $rows->unique('menu_item')->count();
    $totalGeneral->combos = $rows->unique('combo')->count();
@endphp

<!-- Tabla Jerárquica Mejorada -->
<table class="table table-hover table-mods-v2">
    <thead class="table-dark">
        <tr>
            <th width="35%">Ítem / Combinación</th>
            <th width="8%" class="text-center">Unidades</th>
            <th width="8%" class="text-center">Tickets</th>
            <th width="12%" class="text-end">Base</th>
            <th width="12%" class="text-end">Mods +$</th>
            <th width="15%" class="text-end">Total</th>
            <th width="10%" class="text-center">#Mods</th>
            <th width="8%"></th>
        </tr>
    </thead>
    <tbody>
        @foreach ($agrupadoPorCategoria as $categoria)
            <!-- Header de Categoría -->
            <tr class="category-header level-category" data-collapse-target="categoria-{{ Str::slug($categoria['nombre']) }}">
                <td colspan="8">
                    <div class="d-flex justify-content-between align-items-center">
                        <div class="d-flex align-items-center">
                            <i class="fas fa-chevron-right expand-icon me-2"></i>
                            <strong class="h6 mb-0">
                                📁 {{ $categoria['nombre'] }}
                            </strong>
                            <span class="badge bg-light text-dark ms-2">
                                {{ count($categoria['grupos']) }} grupos
                            </span>
                        </div>
                        <div class="metric-badges d-flex gap-2">
                            <span class="metric-badge">
                                ${{ number_format($categoria['totales']->base, 0) }}
                                <small class="text-muted">+</small>
                                ${{ number_format($categoria['totales']->mods, 0) }}
                                <small class="text-muted">=</small>
                                ${{ number_format($categoria['totales']->total, 0) }}
                            </span>
                            <span class="metric-badge">
                                {{ $categoria['totales']->unidades }}u
                                <small class="text-muted">|</small>
                                {{ $categoria['totales']->tickets }}t
                            </span>
                        </div>
                    </div>
                </td>
            </tr>

            <!-- Contenido de Categoría -->
            <tr class="collapse-content" id="categoria-{{ Str::slug($categoria['nombre']) }}" style="display: none;">
                <td colspan="8">
                    <div class="hierarchy-level level-category">

                        @foreach ($categoria['grupos'] as $grupo)
                            <!-- Header de Grupo -->
                            <div class="group-header level-group p-3 bg-light mb-2 rounded cursor-pointer"
                                 data-collapse-target="grupo-{{ Str::slug($categoria['nombre']) }}-{{ Str::slug($grupo['nombre']) }}">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div class="d-flex align-items-center">
                                        <i class="fas fa-chevron-right expand-icon me-2"></i>
                                        <strong>
                                            📂 {{ $grupo['nombre'] }}
                                        </strong>
                                        <span class="badge bg-success text-white ms-2">
                                            {{ count($grupo['items']) }} ítems
                                        </span>
                                    </div>
                                    <div class="metric-badges d-flex gap-2">
                                        <span class="badge bg-light text-dark">
                                            ${{ number_format($grupo['totales']->base, 0) }}
                                            <small class="text-warning">+${{ number_format($grupo['totales']->mods, 0) }}</small>
                                        </span>
                                        <span class="badge bg-light text-dark">
                                            {{ $grupo['totales']->unidades }}u | {{ $grupo['totales']->tickets }}t
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <!-- Contenido de Grupo -->
                            <div id="grupo-{{ Str::slug($categoria['nombre']) }}-{{ Str::slug($grupo['nombre']) }}"
                                 class="hierarchy-level level-group" style="display: none;">

                                @foreach ($grupo['items'] as $itemKey => $itemData)
                                    @php
                                        $mainRow = $itemData['row'];
                                        $combos = $itemData['combos'];
                                    @endphp

                                    <!-- Fila Principal del Ítem -->
                                    <tr class="item-row" data-collapse-target="item-{{ Str::slug($mainRow->menu_item) }}-{{ $loop->index }}">
                                        <td>
                                            <div class="d-flex align-items-center">
                                                <i class="fas fa-chevron-right expand-icon me-2"></i>
                                                <div>
                                                    <div class="item-name">{{ $mainRow->menu_item }}</div>
                                                    <div>
                                                        <span class="category-badge me-1">{{ $mainRow->categoria }}</span>
                                                        <span class="group-badge">{{ $mainRow->grupo_menu }}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="text-center fw-semibold">{{ $mainRow->unidades_item }}</td>
                                        <td class="text-center">
                                            {{ $mainRow->tickets }}
                                            <div class="small text-muted">tickets</div>
                                        </td>
                                        <td class="text-end">
                                            ${{ number_format($mainRow->ingreso_base, 2) }}
                                            <div class="small text-muted">base</div>
                                        </td>
                                        <td class="text-end">
                                            @if($mainRow->costo_modificadores > 0)
                                                <span class="text-warning">+${{ number_format($mainRow->costo_modificadores, 2) }}</span>
                                            @else
                                                <span class="text-muted">+$0.00</span>
                                            @endif
                                            <div class="small text-muted">mods</div>
                                        </td>
                                        <td class="text-end fw-bold">
                                            ${{ number_format($mainRow->ingreso_total, 2) }}
                                            <div class="small text-muted">total</div>
                                        </td>
                                        <td class="text-center">
                                            {{ $mainRow->mods_distintos }}
                                            <div class="small text-muted">mods</div>
                                        </td>
                                        <td class="text-center">
                                            <button class="btn btn-sm btn-outline-primary"
                                                    data-bs-toggle="tooltip"
                                                    title="Ver tickets de este ítem">
                                                <i class="fas fa-search"></i>
                                            </button>
                                        </td>
                                    </tr>

                                    <!-- Subtabla de Combinaciones -->
                                    <tr id="item-{{ Str::slug($mainRow->menu_item) }}-{{ $loop->index }}" class="collapse-content" style="display: none;">
                                        <td colspan="8">
                                            <div class="hierarchy-level modifiers-table p-3 mb-3">

                                                @foreach ($combos as $comboIndex => $combo)
                                                    <div class="combo-signature mb-2">
                                                        <div class="d-flex justify-content-between align-items-center">
                                                            <div>
                                                                <strong>Combinación {{ $comboIndex + 1 }}:</strong>

                                                                <!-- Modificadores como Chips -->
                                                                @php
                                                                    $modsArray = [];
                                                                    if (is_string($combo->combo)) {
                                                                        $parts = explode(' | ', $combo->combo);
                                                                        foreach ($parts as $part) {
                                                                            if (strpos($part, ':') !== false) {
                                                                                list($grupo, $mod) = explode(': ', $part, 2);
                                                                                $costo = 0;
                                                                                if (preg_match('/\+\$(\d+\.?\d*)/', $mod, $matches)) {
                                                                                    $costo = floatval($matches[1]);
                                                                                    $mod = preg_replace('/\s*\+\$\d+\.?\d*/', '', $mod);
                                                                                }
                                                                                $modsArray[] = (object) [
                                                                                    'grupo' => trim($grupo),
                                                                                    'nombre' => trim($mod),
                                                                                    'costo' => $costo
                                                                                ];
                                                                            }
                                                                        }
                                                                    }
                                                                @endphp

                                                                @foreach ($modsArray as $mod)
                                                                    @if($mod->costo > 0)
                                                                        <span class="modifier-chip has-cost">
                                            {{ $mod->grupo }}: {{ $mod->nombre }} +${{ number_format($mod->costo, 0) }}
                                        </span>
                                                                    @else
                                                                        <span class="modifier-chip">
                                            {{ $mod->grupo }}: {{ $mod->nombre }}
                                        </span>
                                                                    @endif
                                                                @endforeach
                                                            </div>

                                                            <div class="d-flex gap-3 align-items-center">
                                                                <span class="badge bg-light text-dark">
                                                                    {{ $combo->unidades_item }} unidades
                                                                </span>
                                                                <span class="badge bg-light text-dark">
                                                                    {{ $combo->tickets }} tickets
                                                                </span>
                                                                @if($combo->selecciones_modificador > 0)
                                                                    <span class="badge bg-info text-white">
                                                                        {{ $combo->selecciones_modificador }} mods
                                                                    </span>
                                                                @endif
                                                                @if($combo->costo_modificadores > 0)
                                                                    <span class="badge bg-warning text-dark">
                                                                        +${{ number_format($combo->costo_modificadores, 2) }}
                                                                    </span>
                                                                @endif
                                                                <button class="btn btn-xs btn-outline-secondary"
                                                                        data-bs-toggle="tooltip"
                                                                        title="Ver tickets de esta combinación">
                                                                    <i class="fas fa-receipt"></i>
                                                                </button>
                                                            </div>
                                                        </div>
                                                    </div>
                                                @endforeach

                                            </div>
                                        </td>
                                    </tr>
                                @endforeach

                            </div>
                        @endforeach
                    </div>
                </td>
            </tr>
        @endforeach
    </tbody>

    <!-- Footer con Totales Generales -->
    <tfoot class="table-dark">
        <tr>
            <th>
                <strong>TOTALES GENERALES</strong>
                <div class="small text-muted">{{ $totalGeneral->items }} ítems | {{ $totalGeneral->combos }} combos</div>
            </th>
            <th class="text-center">
                <strong>{{ $totalGeneral->unidades }}</strong>
                <div class="small text-muted">unidades</div>
            </th>
            <th class="text-center">
                <strong>{{ $totalGeneral->tickets }}</strong>
                <div class="small text-muted">tickets</div>
            </th>
            <th class="text-end">
                <strong>${{ number_format($totalGeneral->base, 2) }}</strong>
                <div class="small text-muted">base</div>
            </th>
            <th class="text-end">
                <strong>+${{ number_format($totalGeneral->mods, 2) }}</strong>
                <div class="small text-muted">mods</div>
            </th>
            <th class="text-end">
                <strong>${{ number_format($totalGeneral->total, 2) }}</strong>
                <div class="small text-muted">total</div>
            </th>
            <th colspan="2"></th>
        </tr>
    </tfoot>
</table>


<style>
.table-mods-v2 {
    font-size: 0.875rem;
}

.table-mods-v2 thead th {
    background-color: #343a40 !important;
    border-bottom: 2px solid #dee2e6;
    font-weight: 600;
    white-space: nowrap;
}

.category-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    cursor: pointer;
    transition: all 0.3s ease;
}

.category-header:hover {
    background: linear-gradient(135deg, #5a67d8 0%, #6b4a9b 100%) !important;
}

.expand-icon {
    transition: transform 0.2s ease;
    min-width: 16px;
}

.expand-icon.rotated {
    transform: rotate(90deg);
}

.item-row {
    background-color: white;
}

.item-row:hover {
    background-color: #f8f9fa;
}

.hierarchy-level {
    border-left: 3px solid #dee2e6;
    margin-left: 1rem;
    padding-left: 1rem;
}

.level-category {
    border-left-color: #0d6efd !important;
    margin-left: 0;
    padding-left: 0.5rem;
}

.level-group {
    border-left-color: #198754 !important;
}

.modifier-chip {
    display: inline-block;
    background: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 0.375rem;
    padding: 0.125rem 0.5rem;
    margin: 0.125rem;
    font-size: 0.75rem;
    color: #495057;
}

.modifier-chip.has-cost {
    background: #fff3cd;
    border-color: #ffc107;
    color: #856404;
    font-weight: 500;
}

.metric-badges {
    display: flex;
    gap: 0.5rem;
}

.metric-badge {
    background: #e9ecef;
    color: #495057;
    padding: 0.25rem 0.5rem;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    font-weight: 500;
    white-space: nowrap;
}

.category-badge, .group-badge {
    background-color: #6c757d;
    color: white;
    font-size: 0.7rem;
    padding: 0.2rem 0.4rem;
    border-radius: 0.25rem;
    margin-right: 0.25rem;
}

.group-badge {
    background-color: #17a2b8;
}

.combo-signature {
    background-color: #f8f9fa;
    border-radius: 0.5rem;
    padding: 0.75rem;
    border-left: 4px solid #6c757d;
}

.item-name {
    font-weight: 600;
    color: #212529;
    font-size: 0.95rem;
}

.btn-xs {
    padding: 0.125rem 0.375rem;
    font-size: 0.75rem;
    line-height: 1.2;
}
</style>