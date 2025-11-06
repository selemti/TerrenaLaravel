@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Detalle de Ventas',
    'pageTitle' => 'Detalle de Ventas',
])

@php
    use Carbon\Carbon;

    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
    $formatQty = fn ($value) => number_format((float) $value, 2);
    $branchFilter = $branchFilter ?? [];
    $terminalFilter = $terminalFilter ?? [];
    $adjustmentsSummary = collect($adjustmentsSummary ?? []);
@endphp

@section('content')
<section class="report-shell">
    <style>
        .report-chip {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            border-radius: 999px;
            padding: 0.15rem 0.65rem;
            font-size: 0.75rem;
            border: 1px solid rgba(0, 0, 0, 0.08);
            background: #f8fafc;
        }

        .cursor-pointer {
            cursor: pointer;
        }
    </style>

    <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-list text-primary me-2"></i>
                Detalle de ventas por item
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}
            </p>
            <p class="text-muted small mb-0">
                Sucursales:
                {{ !empty($branchFilter) ? implode(', ', $branchFilter) : 'Todas' }}
                · Terminales:
                {{ !empty($terminalFilter) ? implode(', ', $terminalFilter) : 'Todas' }}
            </p>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Items distintos</div>
                    <div class="h5 mb-0">{{ $summaryMetrics['items'] ?? 0 }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Líneas totales</div>
                    <div class="h5 mb-0">{{ $summaryMetrics['lines'] ?? 0 }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Cantidad consolidada</div>
                    <div class="h5 mb-0">{{ $formatQty($summaryMetrics['qty'] ?? 0) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Venta neta</div>
                    <div class="h5 mb-0">{{ $formatMoney($summaryMetrics['neto'] ?? 0) }}</div>
                    <div class="small text-muted">Descuentos: {{ $formatMoney($summaryMetrics['discount'] ?? 0) }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.sales.detail') }}" class="row g-3 align-items-end">
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Desde</label>
                    <input type="date"
                           name="start"
                           class="form-control"
                           value="{{ request('start', $startDate->format('Y-m-d')) }}"
                           required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Hasta</label>
                    <input type="date"
                           name="end"
                           class="form-control"
                           value="{{ request('end', $endDate->format('Y-m-d')) }}"
                           required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Sucursales</label>
                    <x-ui.compact-multi-select
                        name="branch[]"
                        :options="$branchOptions"
                        placeholder="Selecciona sucursales"
                        search-placeholder="Buscar sucursal"
                        clear-label="Limpiar"
                        done-label="Hecho"
                        empty-message="Sin sucursales disponibles." />
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Terminales</label>
                    <x-ui.compact-multi-select
                        name="terminal[]"
                        :options="$terminalOptions"
                        placeholder="Selecciona terminales"
                        search-placeholder="Buscar terminal"
                        clear-label="Limpiar"
                        done-label="Hecho"
                        empty-message="Sin terminales disponibles." />
                </div>
                <div class="col-12 d-flex flex-wrap gap-2 justify-content-end pt-2">
                    <button type="submit" class="btn btn-primary">
                        <i class="fa-solid fa-magnifying-glass me-1"></i> Aplicar filtros
                    </button>
                    <a href="{{ route('reports.sales.detail') }}" class="btn btn-outline-secondary">
                        <i class="fa-solid fa-rotate-left me-1"></i> Limpiar
                    </a>
                </div>
                <div class="col-12 text-md-end small text-muted">
                    Generado: <strong>{{ $generatedAt->format('d/m/Y H:i') }}</strong>
                </div>
            </form>
        </div>
    </div>

    @if(!empty($branchColors))
        <div class="d-flex flex-wrap gap-2 mb-4">
            @foreach($branchColors as $key => $color)
                <span class="report-chip">
                    <span class="report-dot" style="background-color: {{ $color }}"></span>
                    {{ $branchLabels[$key] ?? $key }}
                </span>
            @endforeach
        </div>
    @endif

    <div class="card border-0 shadow-sm mb-4">
        <div class="card-header bg-white d-flex justify-content-between align-items-center">
            <h5 class="mb-0 fw-semibold">
                <i class="fa-solid fa-layer-group me-2 text-primary"></i>
                Items consolidados
            </h5>
            <span class="text-muted small">
                Haz clic en una fila para ver los tickets asociados.
            </span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive" data-item-table>
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Item</th>
                            <th>Sucursal</th>
                            <th class="text-end">Cant.</th>
                            <th class="text-end">Venta neta</th>
                            <th class="text-end">Descuento</th>
                            <th class="text-end">Precio prom.</th>
                            <th class="text-end">Precio POS</th>
                            <th class="text-end">Tickets</th>
                            <th>Modificadores</th>
                            <th>Terminales</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($items as $item)
                            @php
                                $modifiersSummary = is_array($item['modifiers_summary'] ?? null)
                                    ? $item['modifiers_summary']
                                    : [];
                                $topModifiers = array_slice($modifiersSummary, 0, 3);
                                $remainingModifiers = max(0, count($modifiersSummary) - count($topModifiers));
                                $modifiersGroups = is_array($item['modifiers_groups'] ?? null)
                                    ? $item['modifiers_groups']
                                    : [];
                            @endphp
                            <tr
                                class="cursor-pointer @if($item['has_adjustments']) table-warning @endif"
                                data-item-row
                                data-details='@json($item['details'])'
                                data-item-name="{{ $item['item_name'] }}"
                                data-branch-label="{{ $item['branch_label'] }}"
                                data-branch-color="{{ $item['branch_color'] }}"
                                data-total-qty="{{ $item['total_qty'] }}"
                                data-total-neto="{{ $item['total_neto'] }}"
                                data-total-discount="{{ $item['total_discount'] }}"
                                data-average-unit="{{ $item['average_unit'] }}"
                                data-ticket-count="{{ $item['ticket_count'] }}"
                                data-line-count="{{ $item['line_count'] }}"
                                data-terminals='@json($item['terminals'])'
                                data-dates='@json($item['dates'])'
                                data-has-adjustments="{{ $item['has_adjustments'] ? 'true' : 'false' }}"
                                data-has-derived="{{ $item['has_derived_qty'] ? 'true' : 'false' }}"
                            >
                                <td class="fw-semibold text-truncate">
                                    {{ $item['item_name'] }}
                                    @if(!empty($item['has_derived_qty']))
                                        <span class="badge bg-info-subtle text-info border border-info-subtle ms-2">Cant. derivada</span>
                                    @endif
                                    @if(!empty($item['has_adjustments']))
                                        <span class="badge bg-warning-subtle text-warning border border-warning-subtle ms-1">Ajustes</span>
                                    @endif
                                </td>
                                <td>
                                    <span class="report-dot me-2" style="background-color: {{ $item['branch_color'] }}"></span>
                                    {{ $item['branch_label'] }}
                                </td>
                                <td class="text-end">{{ $formatQty($item['total_qty']) }}</td>
                                <td class="text-end">{{ $formatMoney($item['total_neto']) }}</td>
                                <td class="text-end text-danger">{{ $formatMoney($item['total_discount']) }}</td>
                                <td class="text-end text-muted">{{ $formatMoney($item['average_unit']) }}</td>
                                <td class="text-end text-muted">
                                    @isset($item['menu_price'])
                                        {{ $formatMoney($item['menu_price']) }}
                                    @else
                                        —
                                    @endisset
                                </td>
                                <td class="text-end">{{ number_format($item['ticket_count']) }}</td>
                                <td class="text-muted small">
                                    @if(!empty($topModifiers))
                                        @foreach($topModifiers as $modifier)
                                            <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle me-1"
                                                  title="{{ ($modifier['group_name'] ?? 'Sin grupo') }} · {{ $formatMoney($modifier['total'] ?? 0) }}">
                                                {{ $modifier['name'] }}
                                                @if(!empty($modifier['count']))
                                                    <span class="fw-semibold">x{{ number_format($modifier['count'], 0) }}</span>
                                                @endif
                                            </span>
                                        @endforeach
                                        @if($remainingModifiers > 0)
                                            <span class="badge bg-light text-muted border border-light-subtle">+{{ $remainingModifiers }}</span>
                                        @endif
                                    @else
                                        <span class="text-muted">—</span>
                                    @endif
                                </td>
                                <td class="text-muted small">
                                    {{ implode(', ', $item['terminals']) ?: '—' }}
                                </td>
                            </tr>
                            @php
                                $modifiersCombos = is_array($item['modifiers_combos'] ?? null)
                                    ? $item['modifiers_combos']
                                    : [];
                            @endphp
                            @if(!empty($modifiersSummary) || !empty($modifiersGroups) || !empty($modifiersCombos))
                            <tr class="bg-body-tertiary">
                                <td colspan="9" class="py-2">
                                    <div class="row g-3 align-items-start">
                                        <div class="col-xl-4 col-lg-6">
                                            <h6 class="fw-semibold mb-2 text-primary">Top modificadores</h6>
                                            @php $modifiersSummary = $modifiersSummary ?? []; @endphp
                                            @if(!empty($modifiersSummary))
                                                <ul class="list-unstyled small mb-0">
                                                    @foreach(array_slice($modifiersSummary, 0, 6) as $modifier)
                                                        <li class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-1">
                                                            <div>
                                                                <span class="fw-semibold">{{ $modifier['name'] }}</span>
                                                                <span class="text-muted">({{ $modifier['group_name'] ?? 'Sin grupo' }})</span>
                                                            </div>
                                                            <div class="text-nowrap">
                                                                @if(!empty($modifier['tickets']))
                                                                    <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle me-1">{{ number_format($modifier['tickets']) }} tickets</span>
                                                                @endif
                                                                <span class="badge bg-info-subtle text-info border border-info-subtle me-1">x{{ number_format($modifier['count'] ?? 0, 0) }}</span>
                                                                <span class="text-success fw-semibold">{{ $formatMoney($modifier['total'] ?? 0) }}</span>
                                                            </div>
                                                        </li>
                                                    @endforeach
                                                    @if($remainingModifiers > 0)
                                                        <li class="text-muted">+ {{ $remainingModifiers }} modificadores adicionales</li>
                                                    @endif
                                                </ul>
                                            @else
                                                <p class="text-muted small mb-0">Sin modificadores registrados.</p>
                                            @endif
                                        </div>
                                        <div class="col-xl-4 col-lg-6">
                                            <h6 class="fw-semibold mb-2 text-primary">Resumen por grupo</h6>
                                            @php $modifiersGroups = is_array($item['modifiers_groups'] ?? null) ? $item['modifiers_groups'] : []; @endphp
                                            @if(!empty($modifiersGroups))
                                                <ul class="list-unstyled small mb-0">
                                                    @foreach(array_slice($modifiersGroups, 0, 4) as $group)
                                                        <li class="mb-1">
                                                            <div class="d-flex justify-content-between align-items-center">
                                                                <span class="fw-semibold">{{ $group['group_name'] }}</span>
                                                                <div class="text-nowrap">
                                                                    <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle me-1">{{ number_format($group['count'] ?? 0, 0) }} mods</span>
                                                                    @if(!empty($group['tickets']))
                                                                        <span class="badge bg-light text-muted border border-light-subtle me-1">{{ number_format($group['tickets']) }} tickets</span>
                                                                    @endif
                                                                    <span class="text-success fw-semibold">{{ $formatMoney($group['total'] ?? 0) }}</span>
                                                                </div>
                                                            </div>
                                                            @if(!empty($group['modifiers']))
                                                                <div class="text-muted ms-2 mt-1">
                                                                    @foreach($group['modifiers'] as $groupModifier)
                                                                        <span class="badge bg-light text-muted border border-light-subtle me-1">{{ $groupModifier['name'] }}@if(!empty($groupModifier['count'])) x{{ number_format($groupModifier['count'], 0) }}@endif</span>
                                                                    @endforeach
                                                                </div>
                                                            @endif
                                                        </li>
                                                    @endforeach
                                                </ul>
                                            @else
                                                <p class="text-muted small mb-0">Sin agrupaciones disponibles.</p>
                                            @endif
                                        </div>
                                        <div class="col-xl-4">
                                            <h6 class="fw-semibold mb-2 text-primary">Combinaciones frecuentes</h6>
                                            @if(!empty($modifiersCombos))
                                                <ul class="list-unstyled small mb-0">
                                                    @foreach(array_slice($modifiersCombos, 0, 5) as $combo)
                                                        <li class="d-flex justify-content-between align-items-center gap-2 mb-1">
                                                            <span class="fw-semibold">{{ $combo['combo'] }}</span>
                                                            <div class="text-nowrap">
                                                                <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle me-1">{{ number_format($combo['lines']) }} líneas</span>
                                                                @if(!empty($combo['tickets']))
                                                                    <span class="badge bg-light text-muted border border-light-subtle me-1">{{ number_format($combo['tickets']) }} tickets</span>
                                                                @endif
                                                                <span class="text-success fw-semibold">{{ $formatMoney($combo['total_neto']) }}</span>
                                                            </div>
                                                        </li>
                                                    @endforeach
                                                </ul>
                                            @else
                                                <p class="text-muted small mb-0">Aún no se registran combinaciones para este periodo.</p>
                                            @endif
                                        </div>
                                    </div>
                                </td>
                            </tr>
                            @endif
                        @empty
                            <tr>
                                <td colspan="9" class="text-center text-muted py-4">
                                    No se encontraron items para los filtros seleccionados.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                    @if($items->isNotEmpty())
                        <tfoot class="table-light">
                            <tr class="fw-semibold">
                                <td colspan="2">Totales</td>
                                <td class="text-end">{{ $formatQty($summaryMetrics['qty'] ?? 0) }}</td>
                                <td class="text-end">{{ $formatMoney($summaryMetrics['neto'] ?? 0) }}</td>
                                <td class="text-end text-danger">{{ $formatMoney($summaryMetrics['discount'] ?? 0) }}</td>
                                <td></td>
                                <td colspan="4"></td>
                            </tr>
                        </tfoot>
                    @endif
                </table>
            </div>
        </div>
    </div>

    @if($adjustments->isNotEmpty())
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-header bg-white d-flex justify-content-between align-items-center">
                <h5 class="mb-0 fw-semibold text-warning">
                    <i class="fa-solid fa-triangle-exclamation me-2"></i>
                    Líneas sin cantidad (ajustes / modificadores)
                </h5>
                <span class="text-muted small">{{ $adjustments->count() }} registros detectados</span>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-sm mb-0 align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Sucursal</th>
                                <th>Item</th>
                                <th class="text-end">Líneas</th>
                                <th class="text-end">Tickets</th>
                                <th class="text-end">Neto</th>
                                <th class="text-end">Descuento</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($adjustmentsSummary as $summary)
                                <tr>
                                    <td>
                                        <span class="report-dot me-2" style="background-color: {{ $summary['branch_color'] }}"></span>
                                        {{ $summary['branch_label'] }}
                                    </td>
                                    <td class="text-truncate">{{ $summary['item_name'] }}</td>
                                    <td class="text-end">{{ number_format($summary['lines']) }}</td>
                                    <td class="text-end">{{ number_format($summary['tickets']) }}</td>
                                    <td class="text-end">{{ $formatMoney($summary['total_neto']) }}</td>
                                    <td class="text-end text-danger">{{ $formatMoney($summary['total_discount']) }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="6" class="text-center text-muted py-4">
                                        No se encontraron ajustes en esta vista.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @endif

</section>

<div class="offcanvas offcanvas-end" tabindex="-1" id="itemDetailDrawer" aria-labelledby="itemDetailDrawerLabel">
    <div class="offcanvas-header">
        <div>
            <h5 class="offcanvas-title mb-0" id="itemDetailDrawerLabel" data-detail-title>Detalle de item</h5>
            <p class="small text-muted mb-0" data-detail-meta></p>
        </div>
        <button type="button" class="btn-close text-reset" data-bs-dismiss="offcanvas" aria-label="Cerrar"></button>
    </div>
    <div class="offcanvas-body">
        <div class="alert alert-warning d-none" role="alert" data-detail-alert>
            Este item incluye líneas sin cantidad registrada. Revisa los tickets para validar ajustes o modificadores.
        </div>
                <div class="table-responsive">
            <table class="table table-sm align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Fecha</th>
                                <th>Ticket</th>
                                <th>Terminal</th>
                                <th class="text-end">Cant.</th>
                                <th class="text-end">Unitario</th>
                                <th class="text-end">Precio POS</th>
                                <th class="text-end">Desc.</th>
                                <th class="text-end">Neto</th>
                                <th>Modificadores</th>
                            </tr>
                        </thead>
                <tbody data-detail-table-body></tbody>
            </table>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', function () {
    var table = document.querySelector('[data-item-table]');
    var drawerEl = document.getElementById('itemDetailDrawer');

    if (!table || !drawerEl || !window.bootstrap) {
        return;
    }

    var drawer = bootstrap.Offcanvas.getOrCreateInstance(drawerEl);
    var detailTitle = drawerEl.querySelector('[data-detail-title]');
    var detailMeta = drawerEl.querySelector('[data-detail-meta]');
    var detailAlert = drawerEl.querySelector('[data-detail-alert]');
    var detailBody = drawerEl.querySelector('[data-detail-table-body]');
    var numberFormatter = new Intl.NumberFormat('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    table.addEventListener('click', function (event) {
        var row = event.target.closest('[data-item-row]');
        if (!row) {
            return;
        }

        var details = [];
        try {
            details = JSON.parse(row.getAttribute('data-details') || '[]');
        } catch (error) {
            console.error('No se pudo parsear el detalle del item', error);
            details = [];
        }

        detailBody.innerHTML = '';
        var derivedCount = 0;
        var missingCount = 0;
        var itemCountFallback = 0;

        if (!Array.isArray(details) || details.length === 0) {
            detailBody.innerHTML = '<tr><td colspan="9" class="text-center text-muted py-3">Sin líneas disponibles.</td></tr>';
        } else {
            details.forEach(function (line) {
                var qtySource = (line.qty_source || 'view_qty').toLowerCase();
                var rawQty = Number(line.raw_qty ?? 0);
                var qty = Number(line.qty ?? 0);
                var menuPriceLine = Number(line.menu_price ?? 0);
                var modifiers = Array.isArray(line.modifiers) ? line.modifiers : [];

                var qtyBadge = '';
                var qtyTitleParts = [];

                switch (qtySource) {
                    case 'derived_amount':
                        derivedCount++;
                        qtyBadge = '<span class="badge bg-info-subtle text-info ms-2">Derivada</span>';
                        qtyTitleParts.push('Cantidad calculada a partir de importes');
                        if (!isNaN(rawQty)) {
                            qtyTitleParts.push('Cantidad original registrada: ' + numberFormatter.format(rawQty));
                        }
                        break;
                    case 'item_count':
                        itemCountFallback++;
                        qtyBadge = '<span class="badge bg-secondary-subtle text-secondary ms-2">Item count</span>';
                        qtyTitleParts.push('Cantidad tomada de item_count');
                        break;
                    case 'item_quantity':
                        if (rawQty !== qty) {
                            qtyTitleParts.push('Cantidad ajustada respecto al POS');
                        }
                        break;
                    case 'none':
                        missingCount++;
                        qtyBadge = '<span class="badge bg-warning-subtle text-warning ms-2">Sin cantidad</span>';
                        qtyTitleParts.push('La línea no registra cantidad en el POS');
                        break;
                    default:
                        if (rawQty !== qty) {
                            qtyTitleParts.push('Cantidad ajustada');
                        }
                        break;
                }

                var qtyTitle = qtyTitleParts.length
                    ? ' title="' + qtyTitleParts.join('. ') + '."'
                    : '';

                var tr = document.createElement('tr');
                tr.innerHTML = [
                    '<td>' + (line.folio_date || '—') + '</td>',
                    '<td>' + (line.ticket_id || '—') + '</td>',
                    '<td>' + (line.terminal_id || '—') + '</td>',
                    '<td class="text-end"' + qtyTitle + '>' + numberFormatter.format(qty) + qtyBadge + '</td>',
                    '<td class="text-end">' + formatMoney(line.unit_price) + '</td>',
                    '<td class="text-end">' + formatMoney(menuPriceLine) + '</td>',
                    '<td class="text-end text-danger">' + formatMoney(line.line_discount) + '</td>',
                    '<td class="text-end">' + formatMoney(line.line_neto) + '</td>',
                    '<td>' + formatModifiers(modifiers) + '</td>',
                ].join('');
                detailBody.appendChild(tr);
            });
        }

        var itemName = row.getAttribute('data-item-name') || 'Item';
        var branchLabel = row.getAttribute('data-branch-label') || '';
        var branchColor = row.getAttribute('data-branch-color') || '#2563eb';
        var totalQty = Number(row.getAttribute('data-total-qty') || 0);
        var totalNeto = Number(row.getAttribute('data-total-neto') || 0);
        var totalDiscount = Number(row.getAttribute('data-total-discount') || 0);
        var avgUnit = Number(row.getAttribute('data-average-unit') || 0);
        var ticketCount = Number(row.getAttribute('data-ticket-count') || 0);
        var lineCount = Number(row.getAttribute('data-line-count') || 0);
        var menuPrice = Number(row.getAttribute('data-menu-price') || 0);
        var terminals = [];
        var dates = [];

        try { terminals = JSON.parse(row.getAttribute('data-terminals') || '[]'); } catch (error) { terminals = []; }
        try { dates = JSON.parse(row.getAttribute('data-dates') || '[]'); } catch (error) { dates = []; }

        detailTitle.innerHTML = '<span class="report-dot me-2" style="background-color: ' + branchColor + '"></span>' + itemName;
        detailMeta.textContent = [
            branchLabel,
            'Cantidad: ' + numberFormatter.format(totalQty),
            'Venta neta: ' + formatMoney(totalNeto),
            'Descuento: ' + formatMoney(totalDiscount),
            'Precio prom.: ' + formatMoney(avgUnit),
            menuPrice ? 'Precio POS: ' + formatMoney(menuPrice) : null,
            'Tickets: ' + ticketCount,
            'Líneas: ' + lineCount,
            derivedCount > 0 ? 'Cant. derivadas: ' + derivedCount : null,
            itemCountFallback > 0 ? 'Desde item_count: ' + itemCountFallback : null,
            missingCount > 0 ? 'Líneas sin cantidad: ' + missingCount : null,
            terminals.length ? 'Terminales: ' + terminals.join(', ') : null,
            dates.length ? 'Fechas: ' + dates.join(' / ') : null,
        ].filter(Boolean).join(' · ');

        if (row.getAttribute('data-has-adjustments') === 'true' || missingCount > 0) {
            detailAlert.classList.remove('d-none');
        } else {
            detailAlert.classList.add('d-none');
        }

        drawer.show();
    });

    function formatMoney(value) {
        return '$' + numberFormatter.format(Number(value || 0));
    }

    function formatModifiers(modifiers) {
        if (!Array.isArray(modifiers) || modifiers.length === 0) {
            return '<span class="text-muted">—</span>';
        }

        return modifiers.map(function (modifier) {
            var name = (modifier.name || 'Sin nombre').trim() || 'Sin nombre';
            var groupName = (modifier.group_name || '').trim();
            var count = Number(modifier.count || 0);
            var lines = Number(modifier.lines || 0);
            var total = Number(modifier.total || 0);
            var tickets = Number(modifier.tickets || 0);
            var badges = [];

            if (groupName) {
                badges.push('<span class="badge bg-light text-muted border border-light-subtle me-1">' + escapeHtml(groupName) + '</span>');
            }

            if (count) {
                badges.push('<span class="badge bg-info-subtle text-info border border-info-subtle me-1">x' + numberFormatter.format(count) + '</span>');
            } else if (lines) {
                badges.push('<span class="badge bg-info-subtle text-info border border-info-subtle me-1">' + lines + ' línea' + (lines === 1 ? '' : 's') + '</span>');
            }

            if (tickets) {
                badges.push('<span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle me-1">' + numberFormatter.format(tickets) + ' tickets</span>');
            }

            if (total) {
                badges.push('<span class="text-success fw-semibold me-1">' + formatMoney(total) + '</span>');
            }

            return '<div class="d-flex align-items-center flex-wrap gap-1"><span class="fw-semibold">' + escapeHtml(name) + '</span>' + badges.join('') + '</div>';
        }).join('<br>');
    }
});
</script>
@endpush
