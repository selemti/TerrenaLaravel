@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Ítems y modificadores v2.0',
    'pageTitle' => 'Ítems y modificadores v2.0',
])

@php
    use Carbon\Carbon;

    $branchFilter = $branchFilter ?? [];
    $terminalFilter = $terminalFilter ?? [];
    $branchColors = $branchColors ?? [];
    $branchLabels = $branchLabels ?? [];
    $view = $view ?? 'item_mod_combos';
    $groupByDay = $groupByDay ?? false;
    $includeEmpty = $includeEmpty ?? ($view === 'item_mod_combos');
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

        /* Estilos para la nueva jerarquía */
        .hierarchy-level {
            border-left: 3px solid #dee2e6;
            margin-left: 1rem;
            padding-left: 1rem;
        }

        .level-category {
            border-left-color: #0d6efd;
        }

        .level-group {
            border-left-color: #198754;
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
        }

        .expand-icon {
            transition: transform 0.2s ease;
            cursor: pointer;
        }

        .expand-icon.rotated {
            transform: rotate(90deg);
        }

        .combo-signature {
            max-width: 300px;
            word-break: break-word;
        }

        .metric-badge {
            background: #e9ecef;
            color: #495057;
            padding: 0.25rem 0.5rem;
            border-radius: 0.375rem;
            font-size: 0.875rem;
            font-weight: 500;
        }

        /* Simple fix para ancho de tabla */
        .card-body .table-mods-v2 {
            width: 100%;
        }
    </style>

    <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-bowl-food text-primary me-2"></i>
                Ítems con modificadores v2.0
                <span class="badge bg-info ms-2">Nueva Versión</span>
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}
            </p>
            <p class="text-muted small mb-0">
                Sucursales:
                {{ !empty($branchFilter) ? implode(', ', $branchFilter) : 'Todas' }}
            </p>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0 small">
                    <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Inicio</a></li>
                    <li class="breadcrumb-item">Reportes</li>
                    <li class="breadcrumb-item active" aria-current="page">Ítems + modificadores v2.0</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <a href="{{ route('reports.sales.mods', array_filter([
                'start_date' => $startDate->format('Y-m-d'),
                'end_date' => $endDate->format('Y-m-d'),
                'view' => $view,
                'branch' => $branchFilter,
            ])) }}" class="btn btn-outline-secondary">
                <i class="fa-solid fa-arrow-left me-1"></i>
                Volver a v1.0
            </a>
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.sales.mods') }}" class="row g-3 align-items-end">
                <div class="col-md-2">
                    <label class="form-label fw-semibold">Desde</label>
                    <input type="date"
                           name="start_date"
                           class="form-control"
                           max="{{ now()->format('Y-m-d') }}"
                           value="{{ request('start_date', $startDate->format('Y-m-d')) }}"
                           required>
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold">Hasta</label>
                    <input type="date"
                           name="end_date"
                           class="form-control"
                           max="{{ now()->format('Y-m-d') }}"
                           value="{{ request('end_date', $endDate->format('Y-m-d')) }}"
                           required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Vista</label>
                    <select name="view" class="form-select">
                        <option value="item_mod_combos" {{ $view === 'item_mod_combos' ? 'selected' : '' }}>Combinaciones Ítem + Modificadores v2.0</option>
                        <option value="legacy" {{ $view === 'legacy' ? 'selected' : '' }}>Combinaciones Ítem + Modificadores v1.0</option>
                        <option value="summary_item_mods" {{ $view === 'summary_item_mods' ? 'selected' : '' }}>Resumen Ítems + Mods</option>
                        <option value="summary_items" {{ $view === 'summary_items' ? 'selected' : '' }}>Resumen por Ítem</option>
                        <option value="detail" {{ $view === 'detail' ? 'selected' : '' }}>Detalle por Ticket</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold">Sucursales</label>
                    <x-ui.compact-multi-select
                        name="branch[]"
                        :options="$branchOptions"
                        placeholder="Todas"
                        search-placeholder="Buscar sucursal"
                        clear-label="Limpiar"
                        done-label="Hecho"
                        empty-message="Sin sucursales disponibles." />
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold">Terminales</label>
                    <x-ui.compact-multi-select
                        name="terminal[]"
                        :options="$terminalOptions"
                        placeholder="Todas"
                        search-placeholder="Buscar terminal"
                        clear-label="Limpiar"
                        done-label="Hecho"
                        empty-message="Sin terminales disponibles." />
                </div>
                <div class="col-12 d-flex flex-wrap gap-4 pt-2">
                    <div class="form-check">
                        <input type="checkbox"
                               class="form-check-input"
                               id="group_by_day"
                               name="group_by_day"
                               value="1"
                               {{ $groupByDay ? 'checked' : '' }}>
                        <label class="form-check-label small" for="group_by_day">
                            Por día
                        </label>
                    </div>
                    <div class="form-check">
                        <input type="checkbox"
                               class="form-check-input"
                               id="include_empty"
                               name="include_empty"
                               value="1"
                               {{ $includeEmpty ? 'checked' : '' }}>
                        <label class="form-check-label small" for="include_empty">
                            Incluir ítems sin ventas/mods
                        </label>
                    </div>
                </div>
                <!-- Controles para modo de ventas y totales -->
                <div class="col-md-4">
                    <label class="form-label fw-semibold">Modo de Ventas</label>
                    <select name="sales_mode" class="form-select">
                        <option value="strict" {{ $salesMode === 'strict' ? 'selected' : '' }}>Estricto (pagado + no anulado)</option>
                        <option value="floreant_jasper" {{ $salesMode === 'floreant_jasper' ? 'selected' : '' }}>Floreant Jasper (pagado)</option>
                        <option value="voided_paid_only" {{ $salesMode === 'voided_paid_only' ? 'selected' : '' }}>Solo Pagados Anulados</option>
                        <option value="floreant_conciliation" {{ $salesMode === 'floreant_conciliation' ? 'selected' : '' }}>Conciliación Floreant</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <label class="form-label fw-semibold">Fórmula de Totales</label>
                    <select name="totals_mode" class="form-select">
                        <option value="items_net_plus_mods_net" {{ $totalsMode === 'items_net_plus_mods_net' ? 'selected' : '' }}>Items + Mods Net</option>
                        <option value="ticket_total" {{ $totalsMode === 'ticket_total' ? 'selected' : '' }}>Total de Tickets</option>
                        <option value="payments_net" {{ $totalsMode === 'payments_net' ? 'selected' : '' }}>Total de Pagos</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <label class="form-label fw-semibold">Incluir Desc. 100%</label>
                    <select name="include_100_discount" class="form-select">
                        <option value="0" {{ !$include100Discount ? 'selected' : '' }}>Excluir</option>
                        <option value="1" {{ $include100Discount ? 'selected' : '' }}>Incluir</option>
                    </select>
                </div>

                <div class="col-12 d-flex flex-wrap gap-2 justify-content-end pt-2">
                    <button type="submit" class="btn btn-primary">
                        <i class="fa-solid fa-magnifying-glass me-1"></i> Aplicar filtros
                    </button>
                    <a href="{{ route('reports.sales.mods') }}" class="btn btn-outline-secondary">
                        <i class="fa-solid fa-rotate-left me-1"></i> Limpiar
                    </a>
                </div>
                <div class="col-md-6 small text-muted">
                    <p class="mb-0">
                        <strong>Controles de Reporte:</strong><br>
                        <small>
                            • <strong>Modo Ventas:</strong> Define qué tickets incluir (pagados, anulados, etc.)<br>
                            • <strong>Fórmula Totales:</strong> Cómo calcular los totales finales<br>
                            • <strong>Desc. 100%:</strong> Incluir/excluir tickets con 100% de descuento
                        </small>
                    </p>
                </div>
                <div class="col-md-6 text-md-end small text-muted">
                    Generado: <strong>{{ $generatedAt->format('d/m/Y H:i') }}</strong>
                    @if(isset($salesMode))
                    <br><small>Modo: {{ $salesMode }} | Fórmula: {{ $totalsMode }}</small>
                    @endif
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

    @php $dayCount = count($summary['days'] ?? []); @endphp

    @if($rows->isEmpty())
        <div class="alert alert-info shadow-sm">
            <div class="d-flex align-items-center">
                <i class="fa-solid fa-circle-info fa-2x me-3 text-info"></i>
                <div>
                    <h5 class="alert-heading mb-1">Sin datos disponibles</h5>
                    <p class="mb-0">No se encontraron registros para el rango y filtros seleccionados.</p>
                </div>
            </div>
        </div>
    @else
        {{-- KPIs según la vista --}}
        @if($view === 'item_mod_combos')
            @include('reports.sales.partials.mods-kpis-combos-v2')
        @elseif($view === 'summary_items')
            @include('reports.sales.partials.mods-kpis-items')
        @elseif($view === 'detail')
            @include('reports.sales.partials.mods-kpis-detail')
        @else
            @include('reports.sales.partials.mods-kpis-modifiers')
        @endif

        {{-- Tabla según la vista --}}
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-header bg-white">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-table me-2 text-secondary"></i>
                    @if($view === 'item_mod_combos')
                        Combinaciones Ítem + Modificadores v2.0
                        <span class="badge bg-success ms-2">Mejorada</span>
                    @elseif($view === 'summary_items')
                        Resumen por Ítem
                    @elseif($view === 'summary_item_mods')
                        Resumen Ítems + Modificadores
                    @elseif($view === 'detail')
                        Detalle por Ticket
                    @else
                        Detalle por ítem y modificador (Legacy)
                    @endif
                </h5>
            </div>
            <div class="card-body p-0">
                @if($view === 'item_mod_combos')
                    @include('reports.sales.partials.mods-table-combos-v2-fixed')
                    {{-- Updated: {{ now()->format('Y-m-d H:i:s') }} --}}
                @elseif($view === 'summary_items')
                    @include('reports.sales.partials.mods-table-items')
                @elseif($view === 'summary_item_mods')
                    @include('reports.sales.partials.mods-table-item-mods')
                @elseif($view === 'detail')
                    @include('reports.sales.partials.mods-table-detail')
                @else
                    @include('reports.sales.partials.mods-table-legacy')
                @endif
            </div>
        </div>
    @endif

    <script>
    // Función para expandir/colapsar niveles jerárquicos
    document.addEventListener('DOMContentLoaded', function() {
        function rotateIcon(el) {
            const icon = el.querySelector('.expand-icon');
            if (icon) icon.classList.toggle('rotated');
        }

        function toggleBySelector(rows) {
            if (!rows || rows.length === 0) return;
            const isHidden = Array.from(rows).every(r => r.style.display === 'none');
            rows.forEach(r => r.style.display = isHidden ? 'table-row' : 'none');
        }

        function toggleCollapse(element, targetId) {
            if (!targetId) return;

            if (targetId.startsWith('cat-')) {
                const rows = document.querySelectorAll(`[data-category="${targetId}"]`);
                toggleBySelector(rows);
                rotateIcon(element);
                return;
            }

            if (targetId.startsWith('group-')) {
                const rows = document.querySelectorAll(`[data-group="${targetId}"]`);
                toggleBySelector(rows);
                rotateIcon(element);
                return;
            }

            const target = document.getElementById(targetId);
            if (target) {
                const isHidden = target.style.display === 'none' || getComputedStyle(target).display === 'none';
                target.style.display = isHidden ? 'table-row' : 'none';
                rotateIcon(element);
            }
        }

        document.querySelectorAll('[data-collapse-target]').forEach(element => {
            element.style.cursor = 'pointer';
            element.addEventListener('click', function(e) {
                if (e.target.closest('button')) return;
                e.preventDefault();
                e.stopPropagation();
                const targetId = this.getAttribute('data-collapse-target');
                toggleCollapse(this, targetId);
            });
        });

        // Inicializar tooltips de Bootstrap
        const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    });
    </script>
</section>
@endsection
