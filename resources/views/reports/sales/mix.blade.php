@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Mix de ventas',
    'pageTitle' => 'Mix de ventas',
])

@php use Carbon\Carbon; @endphp

@section('content')
<section class="report-shell">
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
                    <label class="form-label fw-semibold">Sucursal</label>
                    <select name="branch" class="form-select">
                        <option value="">Todas las sucursales</option>
                        @foreach($branches as $option)
                            <option value="{{ $option['key'] }}"
                                @selected($branch === $option['key'])>
                                {{ $option['label'] }}
                            </option>
                        @endforeach
                    </select>
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
                                        <tr>
                                            <td>{{ $row['label'] ?? $row['key'] }}</td>
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
                                <th>Forma de pago</th>
                                <th class="text-end">Monto</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($rows as $row)
                                <tr>
                                    <td>{{ isset($row->report_date) ? Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                                    <td>{{ $row->branch_key ?? $row->branch ?? $row->branch_name ?? '—' }}</td>
                                    <td>{{ $row->normalized_payment ?? $row->payment_method ?? '—' }}</td>
                                    <td class="text-end">${{ number_format((float) ($row->total ?? 0), 2) }}</td>
                                </tr>
                            @endforeach
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
