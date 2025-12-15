@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Ítems y modificadores',
    'pageTitle' => 'Ítems y modificadores',
])

@php
    use Carbon\Carbon;

    $branchFilter = $branchFilter ?? [];
    $terminalFilter = $terminalFilter ?? [];
    $branchColors = $branchColors ?? [];
    $branchLabels = $branchLabels ?? [];
    $view = $view ?? 'legacy';
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
    </style>

    <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-bowl-food text-primary me-2"></i>
                Ítems con modificadores
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
                    <li class="breadcrumb-item active" aria-current="page">Ítems + modificadores</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <a href="{{ route('reports.sales.mix', array_filter([
                'start_date' => $startDate->format('Y-m-d'),
                'end_date' => $endDate->format('Y-m-d'),
                'branch' => $branchFilter,
            ])) }}" class="btn btn-outline-secondary">
                <i class="fa-solid fa-arrow-left me-1"></i>
                Volver a mix de ventas
            </a>
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
            <form method="GET" action="{{ route('reports.sales.mods.export.pdf') }}" class="d-inline">
                <input type="hidden" name="start_date" value="{{ $startDate->format('Y-m-d') }}">
                <input type="hidden" name="end_date" value="{{ $endDate->format('Y-m-d') }}">
                <input type="hidden" name="view" value="{{ $view }}">
                @if($groupByDay)
                    <input type="hidden" name="group_by_day" value="1">
                @endif
                @foreach($branchFilter as $value)
                    <input type="hidden" name="branch[]" value="{{ $value }}">
                @endforeach
                @foreach($terminalFilter as $value)
                    <input type="hidden" name="terminal[]" value="{{ $value }}">
                @endforeach
                @if($includeEmpty)
                    <input type="hidden" name="include_empty" value="1">
                @endif
                <button type="submit" class="btn btn-outline-danger">
                    <i class="fa-solid fa-file-pdf me-1"></i> PDF
                </button>
            </form>
            <form method="GET" action="{{ route('reports.sales.mods.export.xlsx') }}" class="d-inline">
                <input type="hidden" name="start_date" value="{{ $startDate->format('Y-m-d') }}">
                <input type="hidden" name="end_date" value="{{ $endDate->format('Y-m-d') }}">
                <input type="hidden" name="view" value="{{ $view }}">
                @if($groupByDay)
                    <input type="hidden" name="group_by_day" value="1">
                @endif
                @foreach($branchFilter as $value)
                    <input type="hidden" name="branch[]" value="{{ $value }}">
                @endforeach
                @foreach($terminalFilter as $value)
                    <input type="hidden" name="terminal[]" value="{{ $value }}">
                @endforeach
                @if($includeEmpty)
                    <input type="hidden" name="include_empty" value="1">
                @endif
                <button type="submit" class="btn btn-success">
                    <i class="fa-solid fa-file-excel me-1"></i> Excel
                </button>
            </form>
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
                        <option value="legacy" {{ $view === 'legacy' ? 'selected' : '' }}>Legacy (función original)</option>
                        <option value="summary_item_mods" {{ $view === 'summary_item_mods' ? 'selected' : '' }}>Resumen Ítems + Mods</option>
                        <option value="summary_items" {{ $view === 'summary_items' ? 'selected' : '' }}>Resumen por Ítem</option>
                        <option value="item_mod_combos" {{ $view === 'item_mod_combos' ? 'selected' : '' }}>Combinaciones Ítem + Modificadores</option>
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
                <div class="col-12 d-flex flex-wrap gap-2 justify-content-end pt-2">
                    <button type="submit" class="btn btn-primary">
                        <i class="fa-solid fa-magnifying-glass me-1"></i> Aplicar filtros
                    </button>
                    <a href="{{ route('reports.sales.mods') }}" class="btn btn-outline-secondary">
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
        @if($view === 'summary_items')
            @include('reports.sales.partials.mods-kpis-items')
        @elseif($view === 'item_mod_combos')
            @include('reports.sales.partials.mods-kpis-combos')
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
                    @if($view === 'summary_items')
                        Resumen por Ítem
                    @elseif($view === 'summary_item_mods')
                        Resumen Ítems + Modificadores
                    @elseif($view === 'item_mod_combos')
                        Combinaciones Ítem + Modificadores
                    @elseif($view === 'detail')
                        Detalle por Ticket
                    @else
                        Detalle por ítem y modificador (Legacy)
                    @endif
                </h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    @if($view === 'summary_items')
                        @include('reports.sales.partials.mods-table-items')
                    @elseif($view === 'summary_item_mods')
                        @include('reports.sales.partials.mods-table-item-mods')
                    @elseif($view === 'item_mod_combos')
                        @include('reports.sales.partials.mods-table-combos')
                    @elseif($view === 'detail')
                        @include('reports.sales.partials.mods-table-detail')
                    @else
                        @include('reports.sales.partials.mods-table-legacy')
                    @endif
                </div>
            </div>
        </div>
    @endif
</section>
@endsection
