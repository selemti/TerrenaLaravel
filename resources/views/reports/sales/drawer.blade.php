@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Cajón vs efectivo',
    'pageTitle' => 'Cajón vs efectivo',
])

@php use Carbon\Carbon; @endphp

@section('content')
<section class="report-shell">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-cash-register text-primary me-2"></i>
                Cajón vs efectivo
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}
            </p>
            <p class="text-muted small mb-0">
                Sucursal: {{ $branch ? strtoupper($branch) : 'Todas' }} · Severidad: {{ $severity ?? 'Todas' }}
            </p>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0 small">
                    <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Inicio</a></li>
                    <li class="breadcrumb-item">Reportes</li>
                    <li class="breadcrumb-item active" aria-current="page">Cajón vs efectivo</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
            <form method="GET" action="{{ route('reports.sales.drawer.export.pdf') }}" class="d-inline">
                <input type="hidden" name="start_date" value="{{ $startDate->format('Y-m-d') }}">
                <input type="hidden" name="end_date" value="{{ $endDate->format('Y-m-d') }}">
                @if($branch)
                    <input type="hidden" name="branch" value="{{ $branch }}">
                @endif
                @if($severity)
                    <input type="hidden" name="severity" value="{{ $severity }}">
                @endif
                <button type="submit" class="btn btn-outline-danger">
                    <i class="fa-solid fa-file-pdf me-1"></i> PDF
                </button>
            </form>
            <form method="GET" action="{{ route('reports.sales.drawer.export.xlsx') }}" class="d-inline">
                <input type="hidden" name="start_date" value="{{ $startDate->format('Y-m-d') }}">
                <input type="hidden" name="end_date" value="{{ $endDate->format('Y-m-d') }}">
                @if($branch)
                    <input type="hidden" name="branch" value="{{ $branch }}">
                @endif
                @if($severity)
                    <input type="hidden" name="severity" value="{{ $severity }}">
                @endif
                <button type="submit" class="btn btn-success">
                    <i class="fa-solid fa-file-excel me-1"></i> Excel
                </button>
            </form>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.sales.drawer') }}" class="row g-3 align-items-end">
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
                            <option value="{{ $option['key'] }}" @selected($branch === $option['key'])>
                                {{ $option['label'] }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Severidad</label>
                    <select name="severity" class="form-select">
                        <option value="">Todas</option>
                        <option value="CRITICAL" @selected($severity === 'CRITICAL')>Crítica</option>
                        <option value="WARN" @selected($severity === 'WARN')>Advertencia</option>
                        <option value="INFO" @selected($severity === 'INFO')>Informativa</option>
                    </select>
                </div>
                <div class="col-md-3 d-flex gap-2">
                    <button type="submit" class="btn btn-primary flex-fill">
                        <i class="fa-solid fa-magnifying-glass me-1"></i> Buscar
                    </button>
                    <a href="{{ route('reports.sales.drawer') }}" class="btn btn-outline-secondary flex-fill">
                        <i class="fa-solid fa-rotate-left me-1"></i> Limpiar
                    </a>
                </div>
                <div class="col-12 text-md-end small text-muted">
                    Generado: <strong>{{ $generatedAt->format('d/m/Y H:i') }}</strong>
                </div>
            </form>
        </div>
    </div>

    @php $dayCount = count($summary['days'] ?? []); @endphp

    @if($rows->isEmpty())
        <div class="alert alert-success shadow-sm">
            <div class="d-flex align-items-center">
                <i class="fa-solid fa-circle-check fa-2x me-3 text-success"></i>
                <div>
                    <h5 class="alert-heading mb-1">Sin discrepancias</h5>
                    <p class="mb-0">No se encontraron diferencias para el rango seleccionado.</p>
                </div>
            </div>
        </div>
    @else
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Terminales evaluadas</p>
                        <h3 class="fw-bold mb-0">{{ $summary['total_terminals'] }}</h3>
                        <span class="badge bg-primary-subtle text-primary mt-1">{{ $summary['discrepancies_count'] }} con discrepancia</span>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Efectivo esperado</p>
                        <h3 class="fw-bold mb-0">${{ number_format($summary['total_expected'], 2) }}</h3>
                        <span class="text-muted small">Consolidado del rango</span>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Efectivo registrado</p>
                        <h3 class="fw-bold mb-0">${{ number_format($summary['total_registered'], 2) }}</h3>
                        <span class="text-muted small">Cortes capturados</span>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Diferencia neta</p>
                        @php
                            $difference = $summary['total_difference'];
                            $diffBadge = $difference == 0 ? 'bg-success-subtle text-success' : ($difference > 0 ? 'bg-warning-subtle text-warning' : 'bg-danger-subtle text-danger');
                        @endphp
                        <h3 class="fw-bold mb-0">${{ number_format($difference, 2) }}</h3>
                        <span class="badge {{ $diffBadge }} mt-1">
                            {{ $difference == 0 ? 'Cuadre perfecto' : 'Revisión requerida' }}
                        </span>
                        <div class="text-muted small mt-2">{{ $dayCount > 1 ? $dayCount . ' días analizados' : 'Un solo día' }}</div>
                    </div>
                </div>
            </div>
        </div>

        <div class="card border-0 shadow-sm mb-4">
            <div class="card-header bg-white">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-traffic-light text-danger me-2"></i>
                    Severidad por terminal
                </h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Fecha</th>
                                <th>Terminal</th>
                                <th>Sucursal</th>
                                <th class="text-end">Esperado</th>
                                <th class="text-end">Registrado</th>
                                <th class="text-end">Diferencia</th>
                                <th class="text-center">Severidad</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($rows as $row)
                                @php
                                    $severityLabel = strtoupper((string) ($row->severidad ?? 'INFO'));
                                    $severityClasses = [
                                        'CRITICAL' => 'bg-danger-subtle text-danger',
                                        'WARN' => 'bg-warning-subtle text-warning',
                                        'INFO' => 'bg-success-subtle text-success',
                                    ];
                                @endphp
                                <tr>
                                    <td>{{ isset($row->report_date) ? Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                                    <td class="fw-semibold">{{ $row->terminal ?? $row->terminal_name ?? '—' }}</td>
                                    <td>{{ $row->branch_key ?? $row->branch ?? $row->sucursal ?? '—' }}</td>
                                    <td class="text-end">${{ number_format((float) ($row->efectivo_esperado ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float) ($row->efectivo_registrado ?? 0), 2) }}</td>
                                    <td class="text-end">${{ number_format((float) ($row->diferencia ?? 0), 2) }}</td>
                                    <td class="text-center">
                                        <span class="badge {{ $severityClasses[$severityLabel] ?? 'bg-secondary' }}">
                                            {{ $severityLabel }}
                                        </span>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="card border-0 shadow-sm">
            <div class="card-header bg-white">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-building text-info me-2"></i>
                    Resumen por sucursal
                </h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-striped mb-0 align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Sucursal</th>
                                <th class="text-end">Esperado</th>
                                <th class="text-end">Registrado</th>
                                <th class="text-end">Diferencia</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($summary['branches'] as $branchRow)
                                <tr>
                                    <td>{{ $branchRow['label'] ?? $branchRow['key'] }}</td>
                                    <td class="text-end">${{ number_format($branchRow['expected'] ?? 0, 2) }}</td>
                                    <td class="text-end">${{ number_format($branchRow['registered'] ?? 0, 2) }}</td>
                                    <td class="text-end">${{ number_format($branchRow['difference'] ?? 0, 2) }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @endif
</section>
@endsection
