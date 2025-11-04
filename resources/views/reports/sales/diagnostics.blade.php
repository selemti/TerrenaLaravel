@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Diagnósticos diarios',
    'pageTitle' => 'Diagnósticos diarios',
])

@php
    use Carbon\Carbon;

    $diagLabels = [
        'vw_diag_neto_vs_cobros' => 'Neto vs cobros',
        'vw_diag_discount_header_vs_lines' => 'Descuentos encabezado vs líneas',
        'vw_diag_paid_but_no_payments' => 'Tickets pagados sin pagos',
        'vw_diag_unnormalized_payments' => 'Pagos sin normalizar',
        'vw_diag_service_charge_vs_paid' => 'Servicio vs pagos',
        'vw_diag_drawer_vs_cash_transactions' => 'Cajón vs efectivo',
        'vw_diag_orphans_tickets' => 'Tickets huérfanos',
        'vw_diag_orphans_tx' => 'Transacciones huérfanas',
        'vw_diag_high_discounts' => 'Descuentos altos',
    ];
@endphp

@section('content')
<section class="report-shell">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-stethoscope text-primary me-2"></i>
                Diagnósticos diarios
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}
            </p>
            <p class="text-muted small mb-0">
                Severidad: {{ $severity ?? 'Todas' }}
            </p>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0 small">
                    <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Inicio</a></li>
                    <li class="breadcrumb-item">Reportes</li>
                    <li class="breadcrumb-item active" aria-current="page">Diagnósticos diarios</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
            <form method="GET" action="{{ route('reports.sales.diagnostics.export.pdf') }}" class="d-inline">
                <input type="hidden" name="start_date" value="{{ $startDate->format('Y-m-d') }}">
                <input type="hidden" name="end_date" value="{{ $endDate->format('Y-m-d') }}">
                @if($severity)
                    <input type="hidden" name="severity" value="{{ $severity }}">
                @endif
                <button type="submit" class="btn btn-outline-danger">
                    <i class="fa-solid fa-file-pdf me-1"></i> PDF
                </button>
            </form>
            <form method="GET" action="{{ route('reports.sales.diagnostics.export.xlsx') }}" class="d-inline">
                <input type="hidden" name="start_date" value="{{ $startDate->format('Y-m-d') }}">
                <input type="hidden" name="end_date" value="{{ $endDate->format('Y-m-d') }}">
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
            <form method="GET" action="{{ route('reports.sales.diagnostics') }}" class="row g-3 align-items-end">
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
                    <a href="{{ route('reports.sales.diagnostics') }}" class="btn btn-outline-secondary flex-fill">
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
        <div class="alert alert-success shadow-sm">
            <div class="d-flex align-items-center">
                <i class="fa-solid fa-circle-check fa-2x me-3 text-success"></i>
                <div>
                    <h5 class="alert-heading mb-1">Sin hallazgos relevantes</h5>
                    <p class="mb-0">No se registraron incidencias en el rango seleccionado.</p>
                </div>
            </div>
        </div>
    @else
        <div class="row g-3 mb-4">
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Total de verificaciones</p>
                        <h3 class="fw-bold mb-0">{{ number_format($summary['total_checks']) }}</h3>
                        <span class="text-muted small">
                            {{ number_format($summary['entry_count']) }} vistas en {{ count($summary['days'] ?? []) }} días
                        </span>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Coincidencias con filtros</p>
                        <h3 class="fw-bold mb-0">{{ number_format($summary['filtered_count']) }}</h3>
                        <span class="text-muted small">Severidad aplicada: {{ $summary['severity_filter'] ?? 'todas' }}</span>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Total filas afectadas</p>
                        <h3 class="fw-bold mb-0">{{ number_format($summary['total_rows_affected']) }}</h3>
                        <span class="text-muted small">Registros que requieren revisión</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-3 mb-4">
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted small mb-2">Distribución por severidad</p>
                        <div class="d-flex align-items-center justify-content-between mb-2">
                            <span class="badge bg-danger-subtle text-danger">Críticas</span>
                            <span class="fw-semibold">{{ number_format($summary['critical_count']) }}</span>
                        </div>
                        <div class="d-flex align-items-center justify-content-between mb-2">
                            <span class="badge bg-warning-subtle text-warning">Advertencias</span>
                            <span class="fw-semibold">{{ number_format($summary['warning_count']) }}</span>
                        </div>
                        <div class="d-flex align-items-center justify-content-between">
                            <span class="badge bg-success-subtle text-success">Informativas</span>
                            <span class="fw-semibold">{{ number_format($summary['info_count']) }}</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-8">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h5 class="mb-0 fw-semibold">
                            <i class="fa-solid fa-list-check me-2 text-primary"></i>
                            Resumen de vistas monitorizadas
                        </h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Vista / flujo</th>
                                        <th>Fecha</th>
                                        <th class="text-center">Severidad</th>
                                        <th class="text-end">Filas detectadas</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($summary['views'] as $viewRow)
                                        @php
                                            $badgeClass = match($viewRow['severity']) {
                                                'CRITICAL' => 'bg-danger-subtle text-danger',
                                                'WARN' => 'bg-warning-subtle text-warning',
                                                default => 'bg-success-subtle text-success',
                                            };
                                        @endphp
                                        <tr>
                                            <td class="fw-semibold">
                                                {{ $viewRow['view'] }}
                                                <small class="text-muted d-block">{{ $viewRow['raw_view'] }}</small>
                                            </td>
                                            <td>{{ $viewRow['report_date'] ? Carbon::parse($viewRow['report_date'])->format('d/m/Y') : '—' }}</td>
                                            <td class="text-center">
                                                <span class="badge {{ $badgeClass }}">{{ $viewRow['severity'] }}</span>
                                            </td>
                                            <td class="text-end">{{ number_format($viewRow['count']) }}</td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="card border-0 shadow-sm">
            <div class="card-header bg-white">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-table-list me-2 text-secondary"></i>
                    Detalle completo
                </h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-sm align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Fecha</th>
                                <th>Vista origen</th>
                                <th class="text-center">Severidad</th>
                                <th class="text-end">Filas afectadas</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($rows as $row)
                                @php
                                    $severityLabel = strtoupper((string) ($row->severity ?? 'INFO'));
                                    $badgeClass = match($severityLabel) {
                                        'CRITICAL' => 'bg-danger-subtle text-danger',
                                        'WARN' => 'bg-warning-subtle text-warning',
                                        default => 'bg-success-subtle text-success',
                                    };
                                @endphp
                                <tr>
                                    <td>{{ isset($row->report_date) ? Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                                    <td>
                                        {{ $diagLabels[$row->source_view ?? ''] ?? ($row->source_view ?? '—') }}
                                        <small class="text-muted d-block">{{ $row->source_view ?? '—' }}</small>
                                    </td>
                                    <td class="text-center">
                                        <span class="badge {{ $badgeClass }}">{{ $severityLabel }}</span>
                                    </td>
                                    <td class="text-end">{{ number_format((int) ($row->rows ?? 0)) }}</td>
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
