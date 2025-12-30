@extends('layouts.terrena')

@section('title', 'Reporte de Productos Vendidos')

@section('page-title')
    <div class="d-flex align-items-center justify-content-between mb-2">
        <div class="d-flex align-items-center gap-2">
            <h2 class="mb-0"><i class="fa-solid fa-chart-line me-2"></i> Reporte de Productos Vendidos</h2>
        </div>
    </div>
@endsection

@push('styles')
<style>
    /* Estilos adicionales si se necesitan */
</style>
@endpush

@section('content')
    {{-- Mensaje informativo del período --}}
    <div class="alert alert-info d-flex align-items-center" role="alert">
        <div class="flex-grow-1">
            <strong>Período del reporte:</strong> {{ $startDate->format('d/m/Y') }} al {{ $endDate->format('d/m/Y') }}
        </div>
    </div>

    {{-- Dashboard KPIs --}}
    <div class="row g-3 mb-4">
        {{-- Items Net (Excluyendo descuentos 100%) --}}
        <div class="col-md-3">
            <div class="card h-100 border-warning">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">🍽️ Items Net (sin 100%)</p>
                            <h4 class="mb-0 fw-bold">{{ $jasperTotals['items_neto_excluding100_formateado'] ?? '$0.00' }}</h4>
                            <small class="text-warning">JasperReports: $42,926.50</small>
                            @if(isset($jasperTotals['diferencia_items']) && abs($jasperTotals['diferencia_items']) > 0)
                                <br><small class="text-info">Diferencia: ${{ number_format(abs($jasperTotals['diferencia_items']), 2) }}</small>
                            @endif
                            <br><small class="text-muted">Tickets: {{ $jasperTotals['tickets_excluding100'] ?? 0 }}</small>
                        </div>
                        <div class="text-warning">
                            <i class="fa-solid fa-utensils fa-2x"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Modificadores (JasperReports) --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">⚙️ Modificadores</p>
                            <h4 class="mb-0 fw-bold">{{ $jasperTotals['modificadores_formateado'] ?? '$0.00' }}</h4>
                            <small class="text-info">Adiciones y extras</small>
                        </div>
                        <div class="text-warning">
                            <i class="fa-solid fa-cog fa-2x"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Gran Total Comparativo --}}
        <div class="col-md-3">
            <div class="card h-100 bg-success text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-white-50 mb-1 small">💎 Gran Total</p>
                            <h3 class="mb-0 fw-bold">{{ $jasperTotals['gran_total_excluding100_formateado'] ?? '$0.00' }}</h3>
                            <small>Nuestro cálculo</small>
                            <br><small class="text-white-50">JasperReports: {{ $jasperTotals['gran_total_jasper_formateado'] ?? '$0.00' }}</small>
                        </div>
                        <div class="text-white">
                            <i class="fa-solid fa-chart-line fa-2x"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Tickets --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">🎫 Tickets</p>
                            <h3 class="mb-0 fw-bold">{{ number_format($summary['total_tickets'] ?? 0) }}</h3>
                        </div>
                        <div class="text-info">
                            <i class="fa-solid fa-receipt fa-2x"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Secondary KPIs --}}
    <div class="row g-3 mb-4">
        {{-- Unidades Vendidas --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">📦 Unidades Vendidas</p>
                            <h3 class="mb-0 fw-bold">{{ number_format($summary['total_unidades'] ?? 0) }}</h3>
                        </div>
                        <div class="text-primary">
                            <i class="fa-solid fa-box fa-2x"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Ingreso Total (Legacy) --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">💰 Ingreso Items</p>
                            <h3 class="mb-0 fw-bold">${{ number_format($summary['total_ingresos'] ?? 0, 2) }}</h3>
                        </div>
                        <div class="text-success">
                            <i class="fa-solid fa-dollar-sign fa-2x"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Productos Únicos --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">🛍️ Productos Únicos</p>
                            <h3 class="mb-0 fw-bold">{{ number_format($summary['productos_unicos'] ?? 0) }}</h3>
                        </div>
                        <div class="text-info">
                            <i class="fa-solid fa-chart-pie fa-2x"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Promedio por Ticket --}}
        <div class="col-md-3">
            <div class="card h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="text-muted mb-1 small">📊 Promedio/Ticket</p>
                            <h3 class="mb-0 fw-bold">${{ number_format(($summary['total_tickets'] ?? 0) > 0 ? ($jasperTotals['gran_total'] ?? 0) / ($summary['total_tickets'] ?? 1) : 0, 2) }}</h3>
                        </div>
                        <div class="text-secondary">
                            <i class="fa-solid fa-calculator fa-2x"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Filtros y acciones --}}
    <div class="card mb-4">
        <div class="card-body">
            <form id="filterForm" class="row g-3 align-items-end">
                <div class="col-md-4">
                    <label for="startDate" class="form-label">Fecha Inicio</label>
                    <input type="date" class="form-control" id="startDate" name="start_date" value="{{ $startDate?->format('Y-m-d') }}">
                </div>
                <div class="col-md-4">
                    <label for="endDate" class="form-label">Fecha Fin</label>
                    <input type="date" class="form-control" id="endDate" name="end_date" value="{{ $endDate?->format('Y-m-d') }}">
                </div>
                <div class="col-md-4">
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">
                            <i class="fa-solid fa-search me-2"></i> Aplicar Filtros
                        </button>
                        <div class="dropdown">
                            <button class="btn btn-outline-primary dropdown-toggle" type="button" data-bs-toggle="dropdown">
                                <i class="fa-solid fa-download me-2"></i> Exportar
                            </button>
                            <ul class="dropdown-menu">
                                <li>
                                    <a class="dropdown-item" href="#" onclick="exportReport('pdf')">
                                        <i class="fa-solid fa-file-pdf me-2"></i>PDF
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="#" onclick="exportReport('excel')">
                                        <i class="fa-solid fa-file-excel me-2"></i>Excel
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="#" onclick="exportReport('csv')">
                                        <i class="fa-solid fa-file-csv me-2"></i>CSV
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>

    {{-- Tabla de resultados --}}
    @if($data->isEmpty())
        <div class="card">
            <div class="card-body text-center py-5">
                <i class="fa-solid fa-chart-line fa-3x text-muted mb-3"></i>
                <h5 class="text-muted">No hay datos de ventas para este período</h5>
                <p class="text-muted">No se encontraron registros de productos vendidos en las fechas seleccionadas.</p>
            </div>
        </div>
    @else
        <div class="card">
            <div class="card-header bg-dark text-white">
                <h6 class="mb-0">
                    <i class="fa-solid fa-table me-2"></i>
                    Productos Vendidos
                </h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="bg-dark text-white">
                            <tr>
                                <th>{{ request()->input('group_by', 'product') == 'product' ? 'Producto' : (request()->input('group_by') == 'category' ? 'Categoría' : 'Mes') }}</th>
                                <th class="text-end">Unidades</th>
                                <th class="text-end">Ingreso</th>
                                <th class="text-end">Tickets</th>
                                @if(request()->input('group_by') == 'product')
                                    <th class="text-end">Precio Promedio</th>
                                @endif
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($data as $row)
                                <tr>
                                    <td>{{ $row->producto ?? $row->categoria ?? $row->mes_formateado ?? 'N/D' }}</td>
                                    <td class="text-end">{{ number_format($row->unidades_vendidas ?? 0) }}</td>
                                    <td class="text-end">${{ number_format($row->ingreso_total ?? 0, 2) }}</td>
                                    <td class="text-end">{{ number_format($row->tickets_totales ?? 0) }}</td>
                                    @if(request()->input('group_by') == 'product')
                                        <td class="text-end">${{ number_format($row->precio_promedio ?? 0, 2) }}</td>
                                    @endif
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @endif

@endsection

@push('scripts')
<script>
function exportReport(format) {
    const url = new URL(window.location);
    url.pathname = url.pathname.replace('/reports/products', `/reports/products/export${format}`);
    url.searchParams.set('start_date', document.getElementById('startDate').value);
    url.searchParams.set('end_date', document.getElementById('endDate').value);

    const groupBy = '{{ request()->input('group_by', 'product') }}';
    url.searchParams.set('group_by', groupBy);

    window.open(url.toString(), '_blank');
}

document.getElementById('filterForm').addEventListener('submit', function(e) {
    e.preventDefault();
    const formData = new FormData(this);
    const url = new URL(window.location);

    for (let [key, value] of formData.entries()) {
        if (value) {
            url.searchParams.set(key, value);
        } else {
            url.searchParams.delete(key);
        }
    }

    window.location = url.toString();
});
</script>
@endpush