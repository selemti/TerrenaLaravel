@php
    use Illuminate\Support\Str;
@endphp

<div>
        <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center mb-4 gap-3">
            <div>
                <h2 class="h3 mb-0">Dashboard de Reportes</h2>
                <p class="text-muted mb-0">Resumen ejecutivo con KPIs de ventas, producción e inventario.</p>
                <div class="d-flex gap-2 mt-2">
                    <div class="dropdown">
                        <button class="btn btn-outline-secondary btn-sm dropdown-toggle" type="button" data-bs-toggle="dropdown">
                            <i class="fas fa-cog me-1"></i>Personalizar
                        </button>
                        <ul class="dropdown-menu">
                            <li>
                                <label class="dropdown-item">
                                    <input type="checkbox" class="me-2" wire:model.live="dashboardLayout.summary" value="1">
                                    Resumen de datos
                                </label>
                            </li>
                            <li>
                                <label class="dropdown-item">
                                    <input type="checkbox" class="me-2" wire:model.live="dashboardLayout.kpis" value="1">
                                    KPIs
                                </label>
                            </li>
                            <li>
                                <label class="dropdown-item">
                                    <input type="checkbox" class="me-2" wire:model.live="dashboardLayout.ventas_por_dia" value="1">
                                    Ventas por día
                                </label>
                            </li>
                            <li>
                                <label class="dropdown-item">
                                    <input type="checkbox" class="me-2" wire:model.live="dashboardLayout.top_productos" value="1">
                                    Top productos vendidos
                                </label>
                            </li>
                            <li>
                                <label class="dropdown-item">
                                    <input type="checkbox" class="me-2" wire:model.live="dashboardLayout.mermas_por_categoria" value="1">
                                    Mermas por motivo
                                </label>
                            </li>
                            <li>
                                <label class="dropdown-item">
                                    <input type="checkbox" class="me-2" wire:model.live="dashboardLayout.stock_por_almacen" value="1">
                                    Valor de stock por almacén
                                </label>
                            </li>
                            <li><hr class="dropdown-divider"></li>
                            <li>
                                <button class="dropdown-item" wire:click="resetLayout">
                                    <i class="fas fa-redo me-1"></i>Restablecer diseño
                                </button>
                            </li>
                        </ul>
                    </div>
                    
                    <div class="dropdown">
                        <button class="btn btn-outline-info btn-sm dropdown-toggle" type="button" data-bs-toggle="dropdown">
                            <i class="fas fa-sync-alt me-1"></i>
                            @if($autoRefreshEnabled)
                                <span>Auto: {{ $refreshInterval/60 }} min</span>
                            @else
                                Actualización
                            @endif
                        </button>
                        <ul class="dropdown-menu">
                            <li>
                                <label class="dropdown-item">
                                    <input type="checkbox" class="me-2" wire:click="toggleAutoRefresh" @checked($autoRefreshEnabled)>
                                    Actualización automática
                                </label>
                            </li>
                            <li><hr class="dropdown-divider"></li>
                            <li>
                                <label class="dropdown-item">
                                    <small class="d-block">Intervalo (minutos):</small>
                                    <select class="form-select form-select-sm mt-1" wire:model.live="refreshInterval">
                                        <option value="60">1 minuto</option>
                                        <option value="300">5 minutos</option>
                                        <option value="600">10 minutos</option>
                                        <option value="900">15 minutos</option>
                                        <option value="1800">30 minutos</option>
                                    </select>
                                </label>
                            </li>
                            <li><hr class="dropdown-divider"></li>
                            <li>
                                <button class="dropdown-item" wire:click="loadData">
                                    <i class="fas fa-sync me-1"></i>Actualizar ahora
                                </button>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="d-flex gap-2">
                <div class="btn-group">
                    <button wire:click="export('csv')" type="button" class="btn btn-outline-primary btn-sm" wire:loading.attr="disabled">
                        <i class="fas fa-file-csv me-1"></i> CSV
                    </button>
                    <button wire:click="export('pdf')" type="button" class="btn btn-outline-danger btn-sm" wire:loading.attr="disabled">
                        <i class="fas fa-file-pdf me-1"></i> PDF
                    </button>
                </div>
                <a href="{{ route('reports.sales.mods', [
                    'start_date' => $fechaDesde?->format('Y-m-d'),
                    'end_date' => $fechaHasta?->format('Y-m-d'),
                ]) }}" class="btn btn-outline-secondary btn-sm">
                    <i class="fa-solid fa-bowl-food me-1"></i> Ítems + modificadores
                </a>
            </div>
        </div>

        @if($dashboardLayout['summary'])
        <div class="row g-3 mb-4">
            <div class="col-12 col-md-6 col-xl-3">
                <div class="card bg-light h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <p class="text-muted text-uppercase small mb-1">Ventas totales</p>
                                <h4 class="fw-semibold mb-0">${{ number_format($summary['ventas_totales'], 2) }}</h4>
                            </div>
                            <span class="badge rounded-circle bg-primary-subtle text-primary">
                                <i class="fas fa-dollar-sign"></i>
                            </span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-12 col-md-6 col-xl-3">
                <div class="card bg-light h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <p class="text-muted text-uppercase small mb-1">Transacciones</p>
                                <h4 class="fw-semibold mb-0">{{ number_format($summary['transacciones']) }}</h4>
                            </div>
                            <span class="badge rounded-circle bg-primary-subtle text-primary">
                                <i class="fas fa-receipt"></i>
                            </span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-12 col-md-6 col-xl-3">
                <div class="card bg-light h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <p class="text-muted text-uppercase small mb-1">Productos vendidos</p>
                                <h4 class="fw-semibold mb-0">{{ number_format($summary['productos_vendidos']) }}</h4>
                            </div>
                            <span class="badge rounded-circle bg-primary-subtle text-primary">
                                <i class="fas fa-box"></i>
                            </span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-12 col-md-6 col-xl-3">
                <div class="card bg-light h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <p class="text-muted text-uppercase small mb-1">Ticket promedio</p>
                                <h4 class="fw-semibold mb-0">${{ number_format($summary['ticket_promedio'], 2) }}</h4>
                            </div>
                            <span class="badge rounded-circle bg-primary-subtle text-primary">
                                <i class="fas fa-calculator"></i>
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        @endif

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
                            <option value="custom">Personalizado</option>
                        </select>
                    </div>
                    <div class="col-md-3" wire:show="dateRange === 'custom'">
                        <label class="form-label">Fecha desde</label>
                        <input type="date" class="form-control" wire:model.live="fechaDesdePersonalizada" />
                    </div>
                    <div class="col-md-3" wire:show="dateRange === 'custom'">
                        <label class="form-label">Fecha hasta</label>
                        <input type="date" class="form-control" wire:model.live="fechaHastaPersonalizada" />
                    </div>
                    <div class="col-md-3 text-md-end text-muted small">
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
                                        <a class="dropdown-item" href="#" wire:click="goToFavoriteReport('{{ $favorite['key'] }}')">
                                            <i class="fas fa-star text-warning me-2"></i>{{ $favorite['label'] }}
                                            <button class="btn btn-sm btn-outline-danger float-end" wire:click.stop="toggleFavorite('{{ $favorite['key'] }}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
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
                    'tickets_totales' => 'fa-receipt',
                    'productos_distintos_vendidos' => 'fa-boxes',
                ];
            @endphp

            @if($dashboardLayout['kpis'])
            @foreach($kpis as $key => $value)
                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="card shadow-sm h-100 border-0" 
                         data-kpi="{{ $key }}"
                         @if($key === 'ventas_totales') 
                           wire:click="goToSalesReport" 
                           style="cursor: pointer;" 
                         @endif>
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
                            @if($key === 'ventas_totales')
                                <small class="text-muted">Haz clic para ver detalles</small>
                            @endif
                        </div>
                    </div>
                </div>
            @endforeach
            @endif
        </div>

        <div class="row g-3">
            @if($dashboardLayout['ventas_por_dia'])
            <div class="col-12 col-xl-6">
                <div class="card shadow-sm h-100" style="cursor: pointer;" wire:click="goToSalesReport">
                    <div class="card-header bg-white d-flex justify-content-between align-items-center">
                        <h6 class="mb-0 text-primary">Ventas por día</h6>
                        <small class="text-muted">Ticket POS</small>
                    </div>
                    <div class="card-body">
                        @if($charts['ventas_por_dia']['empty'])
                            <div class="text-center my-5">
                                <i class="fas fa-chart-line fa-2x text-muted mb-2"></i>
                                <p class="text-muted">{{ $charts['ventas_por_dia']['message'] }}</p>
                            </div>
                        @else
                            <canvas id="ventasPorDiaChart" height="260" wire:ignore></canvas>
                        @endif
                    </div>
                </div>
            </div>
            @endif
            @if($dashboardLayout['top_productos'])
            <div class="col-12 col-xl-6">
                <div class="card shadow-sm h-100">
                    <div class="card-header bg-white d-flex justify-content-between align-items-center">
                        <h6 class="mb-0 text-primary">Top productos vendidos</h6>
                        <small class="text-muted">Ticket POS</small>
                    </div>
                    <div class="card-body">
                        @if($charts['top_productos']['empty'])
                            <div class="text-center my-5">
                                <i class="fas fa-box fa-2x text-muted mb-2"></i>
                                <p class="text-muted">{{ $charts['top_productos']['message'] }}</p>
                            </div>
                        @else
                            <canvas id="topProductosChart" height="260" wire:ignore></canvas>
                        @endif
                    </div>
                </div>
            </div>
            @endif
            @if($dashboardLayout['mermas_por_categoria'])
            <div class="col-12 col-xl-6">
                <div class="card shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h6 class="mb-0 text-primary">Mermas por motivo</h6>
                    </div>
                    <div class="card-body">
                        @if($charts['mermas_por_categoria']['empty'])
                            <div class="text-center my-5">
                                <i class="fas fa-exclamation-triangle fa-2x text-muted mb-2"></i>
                                <p class="text-muted">{{ $charts['mermas_por_categoria']['message'] }}</p>
                            </div>
                        @else
                            <canvas id="mermasChart" height="260" wire:ignore></canvas>
                        @endif
                    </div>
                </div>
            </div>
            @endif
            @if($dashboardLayout['stock_por_almacen'])
            <div class="col-12 col-xl-6">
                <div class="card shadow-sm h-100">
                    <div class="card-header bg-white">
                        <h6 class="mb-0 text-primary">Valor de stock por almacén</h6>
                    </div>
                    <div class="card-body">
                        @if($charts['stock_por_almacen']['empty'])
                            <div class="text-center my-5">
                                <i class="fas fa-warehouse fa-2x text-muted mb-2"></i>
                                <p class="text-muted">{{ $charts['stock_por_almacen']['message'] }}</p>
                            </div>
                        @else
                            <canvas id="stockAlmacenChart" height="260" wire:ignore></canvas>
                        @endif
                    </div>
                </div>
            </div>
            @endif
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

                    if (ventasCtx && !charts.ventas_por_dia?.empty) {
                        ventasChart?.destroy();
                        ventasChart = new Chart(ventasCtx, {
                            type: 'line',
                            data: {
                                labels: (charts.ventas_por_dia?.data ?? []).map(item => item.fecha),
                                datasets: [{
                                    label: 'Ventas ($)',
                                    data: (charts.ventas_por_dia?.data ?? []).map(item => item.total),
                                    borderColor: '#2563eb',
                                    backgroundColor: 'rgba(37, 99, 235, 0.15)',
                                    tension: 0.3,
                                }]
                            },
                            options: { 
                                responsive: true, 
                                maintainAspectRatio: false,
                                onClick: (event, elements) => {
                                    if (elements.length > 0) {
                                        const chartData = charts.ventas_por_dia.data;
                                        const elementIndex = elements[0].index;
                                        const clickedData = chartData[elementIndex];
                                        
                                        Livewire.dispatch('on-chart-click', { 
                                            chartKey: 'ventas_por_dia', 
                                            data: clickedData 
                                        });
                                    }
                                }
                            }
                        });
                    }

                    if (productosCtx && !charts.top_productos?.empty) {
                        productosChart?.destroy();
                        productosChart = new Chart(productosCtx, {
                            type: 'bar',
                            data: {
                                labels: (charts.top_productos?.data ?? []).map(item => item.producto),
                                datasets: [{
                                    label: 'Cantidad vendida',
                                    data: (charts.top_productos?.data ?? []).map(item => item.cantidad),
                                    backgroundColor: '#0ea5e9',
                                }]
                            },
                            options: { 
                                responsive: true, 
                                maintainAspectRatio: false, 
                                indexAxis: 'y',
                                onClick: (event, elements) => {
                                    if (elements.length > 0) {
                                        const chartData = charts.top_productos.data;
                                        const elementIndex = elements[0].index;
                                        const clickedData = chartData[elementIndex];
                                        
                                        Livewire.dispatch('on-chart-click', { 
                                            chartKey: 'top_productos', 
                                            data: clickedData 
                                        });
                                    }
                                }
                            }
                        });
                    }

                    if (mermasCtx && !charts.mermas_por_categoria?.empty) {
                        mermasChart?.destroy();
                        mermasChart = new Chart(mermasCtx, {
                            type: 'pie',
                            data: {
                                labels: (charts.mermas_por_categoria?.data ?? []).map(item => item.motivo),
                                datasets: [{
                                    data: (charts.mermas_por_categoria?.data ?? []).map(item => item.total),
                                    backgroundColor: ['#f87171', '#fbbf24', '#34d399', '#60a5fa', '#a855f7', '#f97316'],
                                }]
                            },
                            options: { 
                                responsive: true, 
                                maintainAspectRatio: false,
                                onClick: (event, elements) => {
                                    if (elements.length > 0) {
                                        const chartData = charts.mermas_por_categoria.data;
                                        const elementIndex = elements[0].index;
                                        const clickedData = {
                                            motivo: chartData[elementIndex]?.motivo,
                                            total: chartData[elementIndex]?.total
                                        };
                                        
                                        Livewire.dispatch('on-chart-click', { 
                                            chartKey: 'mermas_por_categoria', 
                                            data: clickedData 
                                        });
                                    }
                                }
                            }
                        });
                    }

                    if (stockCtx && !charts.stock_por_almacen?.empty) {
                        stockChart?.destroy();
                        stockChart = new Chart(stockCtx, {
                            type: 'bar',
                            data: {
                                labels: (charts.stock_por_almacen?.data ?? []).map(item => item.almacen),
                                datasets: [{
                                    label: 'Valor ($)',
                                    data: (charts.stock_por_almacen?.data ?? []).map(item => item.valor),
                                    backgroundColor: '#22c55e',
                                }]
                            },
                            options: { 
                                responsive: true, 
                                maintainAspectRatio: false,
                                onClick: (event, elements) => {
                                    if (elements.length > 0) {
                                        const chartData = charts.stock_por_almacen.data;
                                        const elementIndex = elements[0].index;
                                        const clickedData = chartData[elementIndex];
                                        
                                        Livewire.dispatch('on-chart-click', { 
                                            chartKey: 'stock_por_almacen', 
                                            data: clickedData 
                                        });
                                    }
                                }
                            }
                        });
                    }
                };

                Livewire.on('dashboard-data-updated', ({ data }) => buildCharts(data));
                setTimeout(() => buildCharts({ charts: @json($charts) }), 200);
            });
            
            let autoRefreshInterval = null;
            
            Livewire.on('start-auto-refresh', (event) => {
                // Limpiar cualquier intervalo anterior
                if (autoRefreshInterval) {
                    clearInterval(autoRefreshInterval);
                }
                
                // Crear nuevo intervalo
                autoRefreshInterval = setInterval(() => {
                    Livewire.dispatch('auto-refresh');
                }, event.detail.interval);
            });
            
            Livewire.on('stop-auto-refresh', () => {
                if (autoRefreshInterval) {
                    clearInterval(autoRefreshInterval);
                    autoRefreshInterval = null;
                }
            });
            
            Livewire.on('scroll-to-kpi', (key) => {
                const element = document.querySelector(`[data-kpi="${key}"]`);
                if (element) {
                    element.scrollIntoView({ behavior: 'smooth' });
                    element.classList.add('bg-warning-subtle');
                    setTimeout(() => {
                        element.classList.remove('bg-warning-subtle');
                    }, 2000);
                }
            });
        </script>
    @endpush
</div>
