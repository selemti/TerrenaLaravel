@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Ítems y modificadores',
    'pageTitle' => 'Ítems y modificadores',
])

@php use Carbon\Carbon; @endphp

@section('content')
<section class="report-shell">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-bowl-food text-primary me-2"></i>
                Ítems con modificadores
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}
            </p>
            <p class="text-muted small mb-0">
                Sucursal: {{ $branch ? strtoupper($branch) : 'Todas' }}
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
                'branch' => $branch,
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
                @if($branch)
                    <input type="hidden" name="branch" value="{{ $branch }}">
                @endif
                <button type="submit" class="btn btn-outline-danger">
                    <i class="fa-solid fa-file-pdf me-1"></i> PDF
                </button>
            </form>
            <form method="GET" action="{{ route('reports.sales.mods.export.xlsx') }}" class="d-inline">
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
            <form method="GET" action="{{ route('reports.sales.mods') }}" class="row g-3 align-items-end">
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
                <div class="col-md-3 d-flex gap-2">
                    <button type="submit" class="btn btn-primary flex-fill">
                        <i class="fa-solid fa-magnifying-glass me-1"></i> Buscar
                    </button>
                    <a href="{{ route('reports.sales.mods') }}" class="btn btn-outline-secondary flex-fill">
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
        <div class="alert alert-info shadow-sm">
            <div class="d-flex align-items-center">
                <i class="fa-solid fa-circle-info fa-2x me-3 text-info"></i>
                <div>
                    <h5 class="alert-heading mb-1">Sin combinaciones registradas</h5>
                    <p class="mb-0">No se detectaron modificadores para el rango seleccionado.</p>
                </div>
            </div>
        </div>
    @else
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Ítems únicos</p>
                        <h3 class="fw-bold mb-0">{{ $summary['total_items'] }}</h3>
                        <span class="text-muted small">Productos con modificadores</span>
                        <div class="text-muted small mt-2">{{ $dayCount === 1 ? '1 día analizado' : $dayCount . ' días en rango' }}</div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Modificadores únicos</p>
                        <h3 class="fw-bold mb-0">{{ $summary['total_modifiers'] }}</h3>
                        <span class="text-muted small">Extras aplicados</span>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Monto adicional</p>
                        <h3 class="fw-bold mb-0">${{ number_format($summary['total_amount'], 2) }}</h3>
                        <span class="text-muted small">Ingreso extra obtenido</span>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-body">
                        <p class="text-muted mb-1 small">Promedio por selección</p>
                        <h3 class="fw-bold mb-0">${{ number_format($summary['avg_amount_per_selection'], 2) }}</h3>
                        <span class="text-muted small">{{ number_format($summary['total_selections']) }} selecciones</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-3 mb-4">
            <div class="col-lg-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h5 class="mb-0 fw-semibold">
                            <i class="fa-solid fa-star text-warning me-2"></i>
                            Top modificadores por monto
                        </h5>
                    </div>
                    <div class="card-body">
                        <ol class="list-group list-group-numbered list-group-flush">
                            @forelse($summary['top_modifiers'] as $modifier)
                                <li class="list-group-item d-flex justify-content-between align-items-start">
                                    <div class="me-auto">
                                        <div class="fw-semibold">{{ $modifier['modifier'] }}</div>
                                        <span class="text-muted small">{{ number_format($modifier['times_selected']) }} selecciones</span>
                                    </div>
                                    <span class="badge bg-primary-subtle text-primary">
                                        ${{ number_format($modifier['amount'], 2) }}
                                    </span>
                                </li>
                            @empty
                                <li class="list-group-item text-muted">Sin información relevante</li>
                            @endforelse
                        </ol>
                    </div>
                </div>
            </div>
            <div class="col-lg-8">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h5 class="mb-0 fw-semibold">
                            <i class="fa-solid fa-table me-2 text-secondary"></i>
                            Detalle por ítem y modificador
                        </h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Fecha</th>
                                        <th>Ítem</th>
                                        <th>Modificador</th>
                                        <th class="text-end">Cantidad ítem</th>
                                        <th class="text-end">Selecciones</th>
                                        <th class="text-end">Monto extra</th>
                                        <th>Sucursal</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($rows as $row)
                                        <tr>
                                            <td>{{ isset($row->report_date) ? Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                                            <td class="fw-semibold">{{ $row->item_name ?? '—' }}</td>
                                            <td>{{ $row->modifier_name ?? '—' }}</td>
                                            <td class="text-end">{{ number_format((float) ($row->qty_item ?? 0), 2) }}</td>
                                            <td class="text-end">{{ number_format((int) ($row->mods_count ?? 0)) }}</td>
                                            <td class="text-end">${{ number_format((float) ($row->mods_total_amount ?? 0), 2) }}</td>
                                            <td>{{ $row->branch_key ?? '—' }}</td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    @endif
</section>
@endsection
