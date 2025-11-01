@php
    use Illuminate\Support\Str;
@endphp

<div>
    <div class="container-fluid py-4">
        <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center mb-4 gap-3">
            <div>
                <h2 class="h3 mb-0">Dashboard de Reportes</h2>
                <p class="text-muted mb-0">Resumen ejecutivo con KPIs de ventas, producción e inventario.</p>
            </div>
            <div class="btn-group">
                <button wire:click="export('csv')" type="button" class="btn btn-outline-primary btn-sm" wire:loading.attr="disabled">
                    <i class="fas fa-file-csv me-1"></i> CSV
                </button>
                <button wire:click="export('pdf')" type="button" class="btn btn-outline-danger btn-sm" wire:loading.attr="disabled">
                    <i class="fas fa-file-pdf me-1"></i> PDF
                </button>
            </div>
        </div>

        <div class="card mb-4 shadow-sm">
            <div class="card-body">
                <div class="row g-3 align-items-end">
                    <div class="col-md-3">
                        <label class="form-label">Rango de fechas</label>
                        <select class="form-select" wire:model.live="dateRange">
                            <option value="today">Hoy</option>
                            <option value="yesterday">Ayer</option>
                            <option value="last_7_days">Últimos 7 días</option>
                            <option value="last_30_days">Últimos 30 días</option>
                            <option value="this_month">Este mes</option>
                            <option value="last_month">Mes anterior</option>
                        </select>
                    </div>
                    <div class="col-md-6 text-md-end text-muted small">
                        <div>Desde <strong>{{ $fechaDesde->format('d/m/Y H:i') }}</strong></div>
                        <div>Hasta <strong>{{ $fechaHasta->format('d/m/Y H:i') }}</strong></div>
                    </div>
                    <div class="col-md-3 text-md-end">
                        <div class="dropdown">
                            <button class="btn btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">
                                <i class="fas fa-star me-1 text-warning"></i> Favoritos
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end">
                                @forelse($favorites as $favorite)
                                    <li>
                                        <a class="dropdown-item" href="#" wire:click="toggleFavorite('{{ $favorite['key'] }}')">
                                            <i class="fas fa-star text-warning me-2"></i>{{ $favorite['label'] }}
                                        </a>
                                    </li>
                                @empty
                                    <li><span class="dropdown-item-text text-muted">Sin favoritos guardados</span></li>
                                @endforelse
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-3 mb-4">
            @php
                $kpiIcons = [
                    'ventas_totales' => 'fa-dollar-sign',
                    'produccion_total' => 'fa-industry',
                    'compras_totales' => 'fa-cart-shopping',
                    'inventario_actual' => 'fa-warehouse',
                    'merma_promedio' => 'fa-triangle-exclamation',
                    'costo_receta_promedio' => 'fa-utensils',
                    'rotacion_inventario' => 'fa-arrows-rotate',
                    'eficiencia_produccion' => 'fa-bolt',
                ];
            @endphp

            @foreach($kpis as $key => $value)
                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="card shadow-sm h-100 border-0">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start">
                                <div>
                                    <p class="text-muted text-uppercase small mb-1">{{ Str::headline(str_replace('_', ' ', $key)) }}</p>
                                    <h4 class="fw-semibold mb-0">
                                        @if(Str::contains($key, ['ventas', 'compras', 'inventario', 'costo']))
                                            ${{ number_format($value, 2) }}
                                        @elseif(Str::contains($key, ['merma', 'eficiencia']))
                                            {{ number_format($value, 1) }}%
                                        @else
                                            {{ number_format($value, 1) }}
                                        @endif
                                    </h4>
                                </div>
                                <span class="badge rounded-circle bg-primary-subtle text-primary">
                                    <i class="fas {{ $kpiIcons[$key] ?? 'fa-chart-line' }}"></i>
                                </span>
                            </div>
                            <button class="btn btn-link p-0 mt-3 text-decoration-none" wire:click="toggleFavorite('{{ $key }}')">
                                <i class="fas fa-star me-1 text-warning"></i>
                                Guardar como favorito
                            </button>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>

        <div class="row g-3">
            <div class="col-12 col-xl-6">
                <div class="card shadow-sm h-100">
                    <div class="card-header bg-white d-flex justify-content-between align-items-center">
                        <h6 class="mb-0 text-primary">Ventas por día</h6>
                        <small class="text-muted">Ticket POS</small>
                    </div>
                    <div class="card-body">
                        <canvas id="ventasPorDiaChart" height="260" wire:ignore></canvas>
                    </div>
                </div>
            </div>
            <div class="col-12 col-xl-6">
                <div class="card shadow-sm h-100">
                    <div class="card-header bg-white d-flex justify-content-between align-items-center">
                        <h6 class="mb-0 text-primary">Top productos vendidos</h6>
                        <small class="text-muted">Ticket POS</small>
                    </div>
                    <div class="card-body">
                        <canvas id="topProductosChart" height="260" wire:ignore></canvas>
                    </div>
                </div>
            </div>
            <div class="col-12 col-xl-6">
                <div class="card shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h6 class="mb-0 text-primary">Mermas por motivo</h6>
                    </div>
                    <div class="card-body">
                        <canvas id="mermasChart" height="260" wire:ignore></canvas>
                    </div>
                </div>
            </div>
            <div class="col-12 col-xl-6">
                <div class="card shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h6 class="mb-0 text-primary">Valor de stock por almacén</h6>
                    </div>
                    <div class="card-body">
                        <canvas id="stockAlmacenChart" height="260" wire:ignore></canvas>
                    </div>
                </div>
            </div>
        </div>
    </div>

    @push('scripts')
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
        <script>
            document.addEventListener('livewire:init', () => {
                let ventasChart;
                let productosChart;
                let mermasChart;
                let stockChart;

                const buildCharts = (payload) => {
                    const charts = payload.charts ?? {};
                    const ventasCtx = document.getElementById('ventasPorDiaChart');
                    const productosCtx = document.getElementById('topProductosChart');
                    const mermasCtx = document.getElementById('mermasChart');
                    const stockCtx = document.getElementById('stockAlmacenChart');

                    if (ventasCtx) {
                        ventasChart?.destroy();
                        ventasChart = new Chart(ventasCtx, {
                            type: 'line',
                            data: {
                                labels: (charts.ventas_por_dia ?? []).map(item => item.fecha),
                                datasets: [{
                                    label: 'Ventas ($)',
                                    data: (charts.ventas_por_dia ?? []).map(item => item.total),
                                    borderColor: '#2563eb',
                                    backgroundColor: 'rgba(37, 99, 235, 0.15)',
                                    tension: 0.3,
                                }]
                            },
                            options: { responsive: true, maintainAspectRatio: false }
                        });
                    }

                    if (productosCtx) {
                        productosChart?.destroy();
                        productosChart = new Chart(productosCtx, {
                            type: 'bar',
                            data: {
                                labels: (charts.top_productos ?? []).map(item => item.producto),
                                datasets: [{
                                    label: 'Cantidad vendida',
                                    data: (charts.top_productos ?? []).map(item => item.cantidad),
                                    backgroundColor: '#0ea5e9',
                                }]
                            },
                            options: { responsive: true, maintainAspectRatio: false, indexAxis: 'y' }
                        });
                    }

                    if (mermasCtx) {
                        mermasChart?.destroy();
                        mermasChart = new Chart(mermasCtx, {
                            type: 'pie',
                            data: {
                                labels: (charts.mermas_por_categoria ?? []).map(item => item.motivo),
                                datasets: [{
                                    data: (charts.mermas_por_categoria ?? []).map(item => item.total),
                                    backgroundColor: ['#f87171', '#fbbf24', '#34d399', '#60a5fa', '#a855f7', '#f97316'],
                                }]
                            },
                            options: { responsive: true, maintainAspectRatio: false }
                        });
                    }

                    if (stockCtx) {
                        stockChart?.destroy();
                        stockChart = new Chart(stockCtx, {
                            type: 'bar',
                            data: {
                                labels: (charts.stock_por_almacen ?? []).map(item => item.almacen),
                                datasets: [{
                                    label: 'Valor ($)',
                                    data: (charts.stock_por_almacen ?? []).map(item => item.valor),
                                    backgroundColor: '#22c55e',
                                }]
                            },
                            options: { responsive: true, maintainAspectRatio: false }
                        });
                    }
                };

                Livewire.on('dashboard-data-updated', ({ data }) => buildCharts(data));
                setTimeout(() => buildCharts({ charts: @json($charts) }), 200);
            });
        </script>
    @endpush
</div>
