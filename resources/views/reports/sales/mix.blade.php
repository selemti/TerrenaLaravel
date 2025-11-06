@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Mix de ventas',
    'pageTitle' => 'Mix de ventas',
])

@php use Carbon\Carbon; @endphp

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

    @php
        $branchLegend = isset($branchLegend) ? collect($branchLegend) : collect();
        $branchColors = $branchColors ?? [];
        $selectedBranches = $selectedBranches ?? [];
    @endphp

    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-chart-pie text-primary me-2"></i>
                Mix de ventas por forma de pago
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} —
                {{ $endDate->format('d/m/Y') }}
            </p>
            <p class="text-muted small mb-0">
                Sucursal: {{ $branch ? strtoupper($branch) : 'Todas' }}
            </p>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0 small">
                    <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Inicio</a></li>
                    <li class="breadcrumb-item">Reportes</li>
                    <li class="breadcrumb-item active" aria-current="page">Mix de ventas</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <a href="{{ route('reports.sales.mods', array_filter([
                'start_date' => $startDate->format('Y-m-d'),
                'end_date' => $endDate->format('Y-m-d'),
                'branch' => $branch,
            ])) }}"
               class="btn btn-outline-secondary">
                <i class="fa-solid fa-link me-1"></i>
                Ver ítems + modificadores
            </a>
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
            <form method="GET" action="{{ route('reports.sales.mix.export.pdf') }}" class="d-inline">
                <input type="hidden" name="start_date" value="{{ $startDate->format('Y-m-d') }}">
                <input type="hidden" name="end_date" value="{{ $endDate->format('Y-m-d') }}">
                @if($branch)
                    <input type="hidden" name="branch" value="{{ $branch }}">
                @endif
                <button type="submit" class="btn btn-outline-danger">
                    <i class="fa-solid fa-file-pdf me-1"></i> PDF
                </button>
            </form>
            <form method="GET" action="{{ route('reports.sales.mix.export.xlsx') }}" class="d-inline">
                <input type="hidden" name="start_date" value="{{ $startDate->format('Y-m-d') }}">
                <input type="hidden" name="end_date" value="{{ $endDate->format('Y-m-d') }}">
                @if($branch)
                    <input type="hidden" name="branch" value="{{ $branch }}">
                @endif
                <button type="submit" class="btn btn-success">
                    <i class="fa-solid fa-file-excel me-1"></i> Excel
                </button>
            </form>
            @if($branchLegend->isNotEmpty())
                <div class="d-flex flex-wrap gap-2 mt-3">
                    @foreach($branchLegend as $legend)
                        <span class="report-chip">
                            <span class="report-dot" style="background-color: {{ $legend['color'] }}"></span>
                            {{ $legend['label'] }}
                        </span>
                    @endforeach
                </div>
            @endif
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.sales.mix') }}" class="row g-3 align-items-end">
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Desde</label>
                    <input type="date"
                           name="start_date"
                           class="form-control"
                           max="{{ now()->format('Y-m-d') }}"
                           value="{{ request('start_date', $startDate->format('Y-m-d')) }}"
                           required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Hasta</label>
                    <input type="date"
                           name="end_date"
                           class="form-control"
                           max="{{ now()->format('Y-m-d') }}"
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
                <div class="col-md-3 d-flex gap-2">
                    <button type="submit" class="btn btn-primary flex-fill">
                        <i class="fa-solid fa-magnifying-glass me-1"></i> Buscar
                    </button>
                    <a href="{{ route('reports.sales.mix') }}" class="btn btn-outline-secondary flex-fill">
                        <i class="fa-solid fa-rotate-left me-1"></i> Limpiar
                    </a>
                </div>
                <div class="col-12 text-md-end small text-muted">
                    Generado: <strong>{{ $generatedAt->format('d/m/Y H:i') }}</strong>
                </div>
            </form>
        </div>
    </div>

    @if($rows->isEmpty())
        <div class="alert alert-warning shadow-sm">
            <div class="d-flex align-items-center">
                <i class="fa-solid fa-circle-info fa-2x me-3 text-warning"></i>
                <div>
                    <h5 class="alert-heading mb-1">Sin datos disponibles</h5>
                    <p class="mb-0">No se registraron ventas para el rango seleccionado.</p>
                </div>
            </div>
        </div>
    @else
        @php $dayCount = count($summary['days'] ?? []); @endphp
        <div class="row g-3 mb-4">
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="rounded-circle bg-primary bg-opacity-10 p-3 me-3">
                                <i class="fa-solid fa-coins text-primary fa-lg"></i>
                            </div>
                            <div>
                                <p class="text-muted mb-1 small">Ventas totales</p>
                                <h3 class="fw-bold mb-0">${{ number_format($summary['total_general'], 2) }}</h3>
                                <span class="badge bg-primary-subtle text-primary mt-1">100%</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="rounded-circle bg-success bg-opacity-10 p-3 me-3">
                                <i class="fa-solid fa-wallet text-success fa-lg"></i>
                            </div>
                            <div>
                                <p class="text-muted mb-1 small">Formas de pago activas</p>
                                <h3 class="fw-bold mb-0">{{ $summary['metrics']['total_methods'] ?? 0 }}</h3>
                                <span class="text-muted small">Incluye pagos digitales y vales</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="rounded-circle bg-info bg-opacity-10 p-3 me-3">
                                <i class="fa-solid fa-store text-info fa-lg"></i>
                            </div>
                            <div>
                                <p class="text-muted mb-1 small">Sucursales activas</p>
                                <h3 class="fw-bold mb-0">{{ $summary['metrics']['total_branches'] ?? 0 }}</h3>
                                <span class="text-muted small">
                                    {{ $dayCount > 1 ? $dayCount . ' días analizados' : 'Un solo día' }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4">
            <div class="col-lg-7">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h5 class="mb-0 fw-semibold">
                            <i class="fa-solid fa-money-check-dollar me-2 text-primary"></i>
                            Distribución por forma de pago
                        </h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Forma</th>
                                        <th class="text-end">Monto</th>
                                        <th class="text-end">Participación</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($summary['payments'] as $payment)
                                        <tr>
                                            <td class="fw-semibold">{{ $payment['label'] ?? $payment['key'] }}</td>
                                            <td class="text-end">${{ number_format($payment['amount'] ?? 0, 2) }}</td>
                                            <td class="text-end">
                                                <span class="badge bg-primary-subtle text-primary">
                                                    {{ number_format($payment['percentage'] ?? 0, 2) }}%
                                                </span>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-5">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h5 class="mb-0 fw-semibold">
                            <i class="fa-solid fa-building me-2 text-info"></i>
                            Participación por sucursal
                        </h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-striped mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Sucursal</th>
                                        <th class="text-end">Monto</th>
                                        <th class="text-end">Participación</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($summary['branches'] as $row)
                                        @php
                                            $branchKey = strtoupper((string) ($row['key'] ?? ''));
                                            $legend = isset($branchLegend) ? $branchLegend->firstWhere('key', $branchKey) : null;
                                            $color = $legend['color'] ?? ($branchColors[$branchKey] ?? '#2563eb');
                                            $label = $legend['label'] ?? ($row['label'] ?? ($branchKey ?: '—'));
                                            $isSelected = !empty($selectedBranches) && in_array($branchKey, $selectedBranches, true);
                                        @endphp
                                        <tr @class(['table-info' => $isSelected])>
                                            <td>
                                                @if($branchKey !== '')
                                                    <span class="report-dot me-2" style="background-color: {{ $color }}"></span>
                                                @endif
                                                {{ $label }}
                                            </td>
                                            <td class="text-end">${{ number_format($row['amount'] ?? 0, 2) }}</td>
                                            <td class="text-end">
                                                {{ number_format($row['percentage'] ?? 0, 2) }}%
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        @php
            $gross = $adjustments['gross'] ?? 0.0;
            $discount = $adjustments['discount'] ?? 0.0;
            $net = $adjustments['net'] ?? 0.0;
            $tips = $adjustments['tips'] ?? 0.0;
            $service = $adjustments['service'] ?? 0.0;
            $operated = $adjustments['total_with_charges'] ?? 0.0;
            $mixTotal = $summary['total_general'] ?? 0.0;
            $mixGap = $operated - $mixTotal;
        @endphp
        <div class="card border-0 shadow-sm mt-4">
            <div class="card-header bg-white">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-receipt me-2 text-warning"></i>
                    Resumen financiero complementario
                </h5>
            </div>
            <div class="card-body">
                <div class="row g-4">
                    <div class="col-lg-6">
                        <div class="table-responsive">
                            <table class="table table-sm mb-0">
                                <tbody>
                                <tr>
                                    <th>Venta bruta</th>
                                    <td class="text-end">${{ number_format($gross, 2) }}</td>
                                </tr>
                                <tr>
                                    <th>Descuentos</th>
                                    <td class="text-end text-danger">-${{ number_format($discount, 2) }}</td>
                                </tr>
                                <tr>
                                    <th>Venta neta</th>
                                    <td class="text-end fw-semibold">${{ number_format($net, 2) }}</td>
                                </tr>
                                <tr>
                                    <th>Propinas</th>
                                    <td class="text-end text-success">+${{ number_format($tips, 2) }}</td>
                                </tr>
                                <tr>
                                    <th>Cargos por servicio</th>
                                    <td class="text-end text-success">+${{ number_format($service, 2) }}</td>
                                </tr>
                                <tr class="table-light">
                                    <th>Total operado (neto + extras)</th>
                                    <td class="text-end fw-semibold">${{ number_format($operated, 2) }}</td>
                                </tr>
                                <tr>
                                    <th>Diferencia vs mix</th>
                                    <td class="text-end {{ abs($mixGap) < 0.05 ? 'text-muted' : 'text-danger fw-semibold' }}">
                                        {{ $mixGap >= 0 ? '+' : '' }}${{ number_format($mixGap, 2) }}
                                    </td>
                                </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <p class="text-muted small mb-2">Notas rápidas</p>
                        <ul class="list-unstyled small mb-0">
                            <li class="mb-2">
                                <i class="fa-solid fa-info-circle me-2 text-secondary"></i>
                                Usa este bloque para contrastar descuentos y cargos extra contra el total del mix.
                            </li>
                            <li class="mb-2">
                                <i class="fa-solid fa-coins me-2 text-secondary"></i>
                                Las salidas de efectivo y retiros se analizan a detalle en <a href="{{ route('reports.sales.drawer') }}">Cajón vs efectivo</a>.
                            </li>
                            <li>
                                <i class="fa-solid fa-scale-balanced me-2 text-secondary"></i>
                                Si la diferencia no es cero, revisa tickets con ajustes o terminales con discrepancias.
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>

        <div class="card border-0 shadow-sm mt-4">
            <div class="card-header bg-white">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-table me-2 text-secondary"></i>
                    Detalle de registros
                </h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-sm mb-0 align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Fecha</th>
                                <th>Sucursal</th>
                                <th class="text-end">Efectivo</th>
                                <th class="text-end">Crédito</th>
                                <th class="text-end">Débito</th>
                                <th class="text-end">Otras</th>
                                <th class="text-end">Venta neta</th>
                            </tr>
                        </thead>
                        <tbody>
                            @php $currentMonth = null; @endphp
                            @foreach($pivotRows as $r)
                                @php
                                    $dateObj = isset($r['report_date']) && $r['report_date'] ? Carbon::parse($r['report_date']) : $startDate;
                                    $monthKey = $dateObj->format('Y-m');
                                @endphp
                                @if(count($summary['days'] ?? []) > 1 && $currentMonth !== $monthKey)
                                    @php $currentMonth = $monthKey; @endphp
                                    <tr class="table-secondary">
                                        <td colspan="7" class="fw-semibold">
                                            {{ $dateObj->translatedFormat('F Y') }}
                                        </td>
                                    </tr>
                                @endif
                                @php
                                    $branchKey = strtoupper((string) ($r['branch_key'] ?? ''));
                                    $legend = isset($branchLegend) ? $branchLegend->firstWhere('key', $branchKey) : null;
                                    $color = $legend['color'] ?? ($branchColors[$branchKey] ?? '#2563eb');
                                    $label = $legend['label'] ?? ($r['branch_key'] ?? '—');
                                    $rowSelected = !empty($selectedBranches) && in_array($branchKey, $selectedBranches, true);
                                @endphp
                                <tr @class(['table-info' => $rowSelected])>
                                    <td>{{ $dateObj->format('d/m/Y') }}</td>
                                    <td>
                                        @if($branchKey !== '')
                                            <span class="report-dot me-2" style="background-color: {{ $color }}"></span>
                                        @endif
                                        {{ $label }}
                                    </td>
                                    <td class="text-end">${{ number_format((float)($r['cash'] ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float)($r['credit'] ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float)($r['debit'] ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float)($r['other'] ?? 0), 2) }}</td>
                                    <td class="text-end fw-semibold">${{ number_format((float)($r['net'] ?? 0), 2) }}</td>
                                </tr>
                            @endforeach
                            @if(!empty($pivotRows))
                                <tr class="table-light fw-semibold">
                                    <td colspan="2" class="text-end">Totales</td>
                                    <td class="text-end">${{ number_format((float)($pivotTotals['cash'] ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float)($pivotTotals['credit'] ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float)($pivotTotals['debit'] ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float)($pivotTotals['other'] ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float)($pivotTotals['net'] ?? 0), 2) }}</td>
                                </tr>
                            @endif
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="card border-0 shadow-sm mt-4">
            <div class="card-header bg-white">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-building me-2 text-secondary"></i>
                    Detalle por sucursal (formas de pago)
                </h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-sm mb-0 align-middle">
                        <thead class="table-light">
                        <tr>
                            <th>Sucursal</th>
                            <th class="text-end">Efectivo</th>
                            <th class="text-end">Crédito</th>
                            <th class="text-end">Débito</th>
                            <th class="text-end">Otras</th>
                            <th class="text-end">Venta neta</th>
                        </tr>
                        </thead>
                        <tbody>
                        @foreach($branchPivot ?? [] as $bp)
                            @php
                                $branchKey = strtoupper((string) ($bp['branch_key'] ?? ''));
                                $legend = isset($branchLegend) ? $branchLegend->firstWhere('key', $branchKey) : null;
                                $color = $legend['color'] ?? ($branchColors[$branchKey] ?? '#2563eb');
                                $label = $legend['label'] ?? ($bp['branch_key'] ?? '—');
                                $rowSelected = !empty($selectedBranches) && in_array($branchKey, $selectedBranches, true);
                            @endphp
                            <tr @class(['table-info' => $rowSelected])>
                                <td>
                                    @if($branchKey !== '')
                                        <span class="report-dot me-2" style="background-color: {{ $color }}"></span>
                                    @endif
                                    {{ $label }}
                                </td>
                                <td class="text-end">${{ number_format((float)($bp['cash'] ?? 0), 2) }}</td>
                                <td class="text-end">${{ number_format((float)($bp['credit'] ?? 0), 2) }}</td>
                                <td class="text-end">${{ number_format((float)($bp['debit'] ?? 0), 2) }}</td>
                                <td class="text-end">${{ number_format((float)($bp['other'] ?? 0), 2) }}</td>
                                <td class="text-end fw-semibold">${{ number_format((float)($bp['net'] ?? 0), 2) }}</td>
                            </tr>
                        @endforeach
                        @if(!empty($branchPivot))
                            <tr class="table-light fw-semibold">
                                <td class="text-end">Totales</td>
                                <td class="text-end">${{ number_format((float)($branchTotals['cash'] ?? 0), 2) }}</td>
                                <td class="text-end">${{ number_format((float)($branchTotals['credit'] ?? 0), 2) }}</td>
                                <td class="text-end">${{ number_format((float)($branchTotals['debit'] ?? 0), 2) }}</td>
                                <td class="text-end">${{ number_format((float)($branchTotals['other'] ?? 0), 2) }}</td>
                                <td class="text-end">${{ number_format((float)($branchTotals['net'] ?? 0), 2) }}</td>
                            </tr>
                        @endif
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @endif
</section>

<style>
@media print {
    form, button, .btn, nav, .breadcrumb, .sidebar, header {
        display: none !important;
    }
    .card {
        box-shadow: none !important;
        border: 1px solid #d1d5db !important;
    }
    body {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }
}
</style>
@endsection
