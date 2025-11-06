@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Resumen de Ventas',
    'pageTitle' => 'Resumen de Ventas',
])

@php
    use Carbon\Carbon;

    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
    $formatSigned = fn ($value) => ($value < 0 ? '-$' : '$') . number_format(abs((float) $value), 2);
    $selectedBranches = $branchFilter ?? [];
    $selectedTerminals = $terminalFilter ?? [];
@endphp

@section('content')
<style>
    .sales-summary-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        border-radius: 999px;
        padding: 0.15rem 0.65rem;
        font-size: 0.75rem;
        border: 1px solid rgba(0,0,0,0.08);
        background: #f8fafc;
    }
    .sales-summary-table tbody tr:hover {
        background-color: rgba(37,99,235,0.04);
    }
</style>

<section class="report-shell">
    <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-table text-primary me-2"></i>
                Resumen de ventas
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}
            </p>
            <p class="text-muted small mb-0">
                Sucursales:
                {{ !empty($selectedBranches) ? implode(', ', $selectedBranches) : 'Todas' }}
                · Terminales:
                {{ !empty($selectedTerminals) ? implode(', ', $selectedTerminals) : 'Todas' }}
            </p>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <a href="{{ route('reports.sales.summary', [
                    'start_date' => $startDate->format('Y-m-d'),
                    'end_date' => $endDate->format('Y-m-d'),
                    'branch' => $selectedBranches,
                    'terminal' => $selectedTerminals,
                ]) }}" class="btn btn-outline-danger">
                <i class="fa-solid fa-file-pdf me-1"></i> PDF
            </a>
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-4 col-xl-2">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Bruto</div>
                    <div class="h5 mb-0">{{ $formatMoney($totals['bruto']) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl-2">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Descuentos</div>
                    <div class="h5 mb-0 text-danger">{{ $formatSigned(-1 * $totals['descuento']) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl-2">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Anulaciones/Devoluciones</div>
                    <div class="h5 mb-0 text-danger">{{ $formatSigned(-1 * $totals['anulaciones']) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl-2">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Venta neta</div>
                    <div class="h5 mb-0">{{ $formatMoney($totals['neto']) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl-2">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Pagos netos</div>
                    <div class="h5 mb-0">{{ $formatMoney($totals['pagos_netos']) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl-2">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Brecha cobros</div>
                    @php
                        $deltaClass = $totals['delta_pagos'] > 1 ? 'text-danger' : ($totals['delta_pagos'] < -1 ? 'text-success' : 'text-muted');
                    @endphp
                    <div class="h5 mb-0 {{ $deltaClass }}">
                        {{ $formatSigned($totals['delta_pagos']) }}
                    </div>
                    <div class="small text-muted">Pagos vs. neto</div>
                </div>
            </div>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.sales.summary') }}" class="row g-3 align-items-end">
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Desde</label>
                    <input type="date"
                           name="start_date"
                           class="form-control"
                           value="{{ request('start_date', $startDate->format('Y-m-d')) }}"
                           required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Hasta</label>
                    <input type="date"
                           name="end_date"
                           class="form-control"
                           value="{{ request('end_date', $endDate->format('Y-m-d')) }}"
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
                    <a href="{{ route('reports.sales.summary') }}" class="btn btn-outline-secondary">
                        <i class="fa-solid fa-rotate-left me-1"></i> Limpiar
                    </a>
                </div>
            </form>
        </div>
    </div>

    <div class="d-flex flex-wrap gap-2 mb-3">
        @foreach($branchColors as $key => $color)
            <span class="sales-summary-chip">
                <span class="report-dot" style="background-color: {{ $color }}"></span>
                {{ $branchLabels[$key] ?? $key }}
            </span>
        @endforeach
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-sm mb-0 align-middle sales-summary-table">
                    <thead class="table-light">
                        <tr>
                            <th>Fecha</th>
                            <th>Sucursal</th>
                            <th>Terminales</th>
                            <th class="text-end">Tickets</th>
                            <th class="text-end">Bruto</th>
                            <th class="text-end">Descuentos</th>
                            <th class="text-end">Anul./Devol.</th>
                            <th class="text-end">Venta neta</th>
                            <th class="text-end">Pagos netos</th>
                            <th class="text-end">Brecha</th>
                            <th class="text-end">% Ajuste</th>
                            <th class="text-center">Alertas</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($rows as $row)
                            @php
                                $rowDelta = $row['payments_delta'] ?? 0.0;
                                $deltaClass = abs($rowDelta) < 0.5
                                    ? 'text-muted'
                                    : ($rowDelta > 0 ? 'text-danger' : 'text-success');
                                $anomalies = $row['exception_codes_list'] ?? [];
                                $terminalBadges = $row['terminals'] ?? [];
                            @endphp
                            <tr @class(['table-warning' => $row['has_exceptions'] ?? false])>
                                <td>{{ Carbon::parse($row['folio_date'])->format('d/m/Y') }}</td>
                                <td>
                                    <span class="report-dot me-2" style="background-color: {{ $row['branch_color'] }}"></span>
                                    {{ $row['branch_label'] }}
                                </td>
                                <td>
                                    @if(!empty($terminalBadges))
                                        @foreach($terminalBadges as $terminalId)
                                            <span class="badge rounded-pill bg-light text-dark border">{{ $terminalId }}</span>
                                        @endforeach
                                    @else
                                        <span class="text-muted">—</span>
                                    @endif
                                </td>
                                <td class="text-end">
                                    <a href="{{ route('reports.sales.detail', $row['detail_route_params']) }}"
                                       target="_blank"
                                       rel="noopener"
                                       class="link-primary fw-semibold">
                                        {{ number_format($row['tickets']) }}
                                    </a>
                                </td>
                                <td class="text-end">{{ $formatMoney($row['bruto']) }}</td>
                                <td class="text-end text-danger">{{ $formatSigned(-1 * $row['descuento']) }}</td>
                                <td class="text-end text-danger">{{ $formatSigned(-1 * $row['anulaciones']) }}</td>
                                <td class="text-end fw-semibold">{{ $formatMoney($row['neto']) }}</td>
                                <td class="text-end">{{ $formatMoney($row['pagos_netos']) }}</td>
                                <td class="text-end {{ $deltaClass }}">{{ $formatSigned($rowDelta) }}</td>
                                <td class="text-end text-muted">
                                    @if($row['discount_rate'] ?? 0)
                                        {{ number_format($row['discount_rate'], 1) }}%
                                    @else
                                        —
                                    @endif
                                </td>
                                <td class="text-center">
                                    @if(!empty($anomalies))
                                        <span class="badge bg-warning text-dark" title="{{ implode(', ', $anomalies) }}">
                                            <i class="fa-solid fa-triangle-exclamation"></i>
                                        </span>
                                    @else
                                        <span class="text-muted">—</span>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="12" class="text-center text-muted py-4">Sin datos para los filtros seleccionados.</td>
                            </tr>
                        @endforelse
                    </tbody>
                    <tfoot class="table-light">
                        <tr class="fw-semibold">
                            <td colspan="3">Totales</td>
                            <td class="text-end">{{ number_format($totals['tickets']) }}</td>
                            <td class="text-end">{{ $formatMoney($totals['bruto']) }}</td>
                            <td class="text-end text-danger">{{ $formatSigned(-1 * $totals['descuento']) }}</td>
                            <td class="text-end text-danger">{{ $formatSigned(-1 * $totals['anulaciones']) }}</td>
                            <td class="text-end">{{ $formatMoney($totals['neto']) }}</td>
                            <td class="text-end">{{ $formatMoney($totals['pagos_netos']) }}</td>
                            @php
                                $totDeltaClass = abs($totals['delta_pagos']) < 0.5
                                    ? 'text-muted'
                                    : ($totals['delta_pagos'] > 0 ? 'text-danger' : 'text-success');
                            @endphp
                            <td class="text-end {{ $totDeltaClass }}">{{ $formatSigned($totals['delta_pagos']) }}</td>
                            <td class="text-end text-muted">
                                @if($totals['bruto'] > 0)
                                    {{ number_format((($totals['descuento'] + $totals['anulaciones']) / max(0.01, $totals['bruto'])) * 100, 1) }}%
                                @else
                                    —
                                @endif
                            </td>
                            <td></td>
                        </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    </div>
</section>
@endsection
