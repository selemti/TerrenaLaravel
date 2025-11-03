# 📊 PROMPT QWEN - REPORTES: DASHBOARD + EXPORTACIONES (SEMANA 6)

**Proyecto**: TerrenaLaravel ERP
**Módulo**: Reportes y Analytics - Dashboard Completo
**Fase**: 2 - Semana 6
**Duración**: 6 horas
**Agent**: Qwen (Frontend Developer)
**Fecha**: Diciembre 6-12, 2025

---

## 🎯 OBJETIVO

Crear un dashboard de reportes interactivo con KPIs, gráficas y exportaciones:

1. ✅ Dashboard principal con KPIs clave
2. ✅ Gráficas interactivas (Chart.js)
3. ✅ Exportaciones CSV y PDF
4. ✅ Drill-down jerárquico
5. ✅ Sistema de favoritos

**Success Criteria**:
- Dashboard funcional con 8-10 KPIs principales
- 5 gráficas interactivas (línea, barras, pie, etc.)
- Exportación CSV/PDF funcionando
- Responsive design
- Performance <2s para cargar dashboard

---

## 📊 CONTEXTO

### ✅ Datos Disponibles en BD
- **mov_inv** - Kardex de inventario con todos los movimientos
- **production_orders** - Órdenes de producción con costos
- **recipe_cost_snapshots** - Historial de costos de recetas
- **purchase_orders** - Órdenes de compra
- **ticket** - Ventas del POS

### ⚠️ Falta Implementar
- Dashboard component
- KPI cards
- Charts con Chart.js
- Export functionality
- Favoritos system

---

## 📋 PLAN DE TRABAJO (6 HORAS)

### BLOQUE 1: Dashboard Principal + KPIs (2h)

#### Tarea 1.1: Componente Reports/Dashboard (1h 30min)

**Archivo**: `app/Livewire/Reports/Dashboard.php`

**Implementación**:

```php
<?php

namespace App\Livewire\Reports;

use Livewire\Component;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class Dashboard extends Component
{
    public $dateRange = 'last_30_days';
    public $fechaDesde;
    public $fechaHasta;

    // KPIs
    public $totalVentas = 0;
    public $totalProduccion = 0;
    public $totalCompras = 0;
    public $inventarioActual = 0;
    public $mermaPromedio = 0;
    public $costoPromedioRecetas = 0;
    public $rotacionInventario = 0;
    public $eficienciaProduccion = 0;

    // Data para gráficas
    public $ventasPorDia = [];
    public $topProductos = [];
    public $costosRecetas = [];
    public $mermasPorCategoria = [];
    public $inventarioPorAlmacen = [];

    protected $listeners = ['refreshDashboard' => 'loadData'];

    public function mount()
    {
        $this->setDateRange();
        $this->loadData();
    }

    public function updatedDateRange()
    {
        $this->setDateRange();
        $this->loadData();
    }

    protected function setDateRange()
    {
        switch ($this->dateRange) {
            case 'today':
                $this->fechaDesde = now()->startOfDay();
                $this->fechaHasta = now()->endOfDay();
                break;
            case 'yesterday':
                $this->fechaDesde = now()->subDay()->startOfDay();
                $this->fechaHasta = now()->subDay()->endOfDay();
                break;
            case 'last_7_days':
                $this->fechaDesde = now()->subDays(6)->startOfDay();
                $this->fechaHasta = now()->endOfDay();
                break;
            case 'last_30_days':
                $this->fechaDesde = now()->subDays(29)->startOfDay();
                $this->fechaHasta = now()->endOfDay();
                break;
            case 'this_month':
                $this->fechaDesde = now()->startOfMonth();
                $this->fechaHasta = now()->endOfMonth();
                break;
            case 'last_month':
                $this->fechaDesde = now()->subMonth()->startOfMonth();
                $this->fechaHasta = now()->subMonth()->endOfMonth();
                break;
            default:
                $this->fechaDesde = now()->subDays(29)->startOfDay();
                $this->fechaHasta = now()->endOfDay();
        }
    }

    public function loadData()
    {
        $this->loadKPIs();
        $this->loadChartData();
    }

    protected function loadKPIs()
    {
        // KPI 1: Total Ventas (desde POS)
        $this->totalVentas = DB::connection('pgsql')
            ->table('public.ticket')
            ->whereBetween('create_date', [$this->fechaDesde, $this->fechaHasta])
            ->where('voided', false)
            ->sum('total_price') ?? 0;

        // KPI 2: Total Producción (órdenes completadas)
        $this->totalProduccion = DB::connection('pgsql')
            ->table('selemti.production_orders')
            ->whereBetween('completado_en', [$this->fechaDesde, $this->fechaHasta])
            ->where('estado', 'COMPLETADA')
            ->sum('cantidad_producida') ?? 0;

        // KPI 3: Total Compras (recepciones)
        $this->totalCompras = DB::connection('pgsql')
            ->table('selemti.recepcion_cab')
            ->whereBetween('fecha_recepcion', [$this->fechaDesde, $this->fechaHasta])
            ->sum('total') ?? 0;

        // KPI 4: Inventario Actual (valor total)
        $this->inventarioActual = DB::connection('pgsql')
            ->table('selemti.vw_stock_valorizado')
            ->sum('valor_total') ?? 0;

        // KPI 5: Merma Promedio (producción)
        $this->mermaPromedio = DB::connection('pgsql')
            ->table('selemti.production_orders')
            ->whereBetween('completado_en', [$this->fechaDesde, $this->fechaHasta])
            ->where('estado', 'COMPLETADA')
            ->avg('merma_porcentaje') ?? 0;

        // KPI 6: Costo Promedio Recetas
        $this->costoPromedioRecetas = DB::connection('pgsql')
            ->table('selemti.receta_cab')
            ->where('activo', true)
            ->avg('costo_standard_porcion') ?? 0;

        // KPI 7: Rotación de Inventario (días)
        $this->rotacionInventario = $this->calculateInventoryTurnover();

        // KPI 8: Eficiencia de Producción (%)
        $this->eficienciaProduccion = $this->calculateProductionEfficiency();
    }

    protected function loadChartData()
    {
        // Gráfica 1: Ventas por Día
        $this->ventasPorDia = DB::connection('pgsql')
            ->table('public.ticket')
            ->selectRaw('DATE(create_date) as fecha, SUM(total_price) as total')
            ->whereBetween('create_date', [$this->fechaDesde, $this->fechaHasta])
            ->where('voided', false)
            ->groupBy('fecha')
            ->orderBy('fecha')
            ->get()
            ->map(function ($row) {
                return [
                    'fecha' => Carbon::parse($row->fecha)->format('d/m'),
                    'total' => (float) $row->total,
                ];
            })
            ->toArray();

        // Gráfica 2: Top 10 Productos Vendidos
        $this->topProductos = DB::connection('pgsql')
            ->table('public.ticket_item')
            ->selectRaw('item_name, SUM(qty) as total_qty')
            ->whereBetween('created_at', [$this->fechaDesde, $this->fechaHasta])
            ->groupBy('item_name')
            ->orderByDesc('total_qty')
            ->limit(10)
            ->get()
            ->map(function ($row) {
                return [
                    'producto' => $row->item_name,
                    'cantidad' => (float) $row->total_qty,
                ];
            })
            ->toArray();

        // Gráfica 3: Evolución de Costos de Recetas (últimos 5 snapshots)
        $this->costosRecetas = DB::connection('pgsql')
            ->table('selemti.recipe_cost_snapshots')
            ->selectRaw('recipe_id, snapshot_date, cost_per_portion')
            ->whereBetween('snapshot_date', [$this->fechaDesde, $this->fechaHasta])
            ->orderByDesc('snapshot_date')
            ->limit(20)
            ->get()
            ->groupBy('recipe_id')
            ->map(function ($snapshots, $recipeId) {
                return [
                    'recipe_id' => $recipeId,
                    'data' => $snapshots->map(function ($s) {
                        return [
                            'fecha' => Carbon::parse($s->snapshot_date)->format('d/m'),
                            'costo' => (float) $s->cost_per_portion,
                        ];
                    })->toArray(),
                ];
            })
            ->take(5)
            ->toArray();

        // Gráfica 4: Mermas por Categoría
        $this->mermasPorCategoria = DB::connection('pgsql')
            ->table('selemti.merma_log')
            ->selectRaw('merma_clase, SUM(cantidad) as total')
            ->whereBetween('created_at', [$this->fechaDesde, $this->fechaHasta])
            ->groupBy('merma_clase')
            ->get()
            ->map(function ($row) {
                return [
                    'categoria' => $row->merma_clase ?? 'N/A',
                    'total' => (float) $row->total,
                ];
            })
            ->toArray();

        // Gráfica 5: Stock por Almacén
        $this->inventarioPorAlmacen = DB::connection('pgsql')
            ->table('selemti.vw_stock_valorizado')
            ->selectRaw('almacen_nombre, SUM(valor_total) as total')
            ->groupBy('almacen_nombre')
            ->get()
            ->map(function ($row) {
                return [
                    'almacen' => $row->almacen_nombre ?? 'N/A',
                    'valor' => (float) $row->total,
                ];
            })
            ->toArray();
    }

    protected function calculateInventoryTurnover(): float
    {
        // Rotación = Costo de Ventas / Inventario Promedio
        // Simplificado para el ejemplo
        return 45.5; // TODO: Implementar cálculo real
    }

    protected function calculateProductionEfficiency(): float
    {
        $planned = DB::connection('pgsql')
            ->table('selemti.production_orders')
            ->whereBetween('completado_en', [$this->fechaDesde, $this->fechaHasta])
            ->sum('cantidad_planeada') ?? 0;

        $produced = DB::connection('pgsql')
            ->table('selemti.production_orders')
            ->whereBetween('completado_en', [$this->fechaDesde, $this->fechaHasta])
            ->sum('cantidad_producida') ?? 0;

        if ($planned > 0) {
            return ($produced / $planned) * 100;
        }

        return 0;
    }

    public function export($type)
    {
        // TODO: Implementar exportación
        session()->flash('ok', "Exportando reporte en formato {$type}...");
    }

    public function render()
    {
        return view('livewire.reports.dashboard')
            ->layout('layouts.terrena', ['active' => 'reportes']);
    }
}
```

---

**Vista**: `resources/views/livewire/reports/dashboard.blade.php`

```blade
<div>
    <div class="container-fluid py-4">
        {{-- Header --}}
        <div class="row mb-3">
            <div class="col-md-6">
                <h2>Dashboard de Reportes</h2>
            </div>
            <div class="col-md-6 text-end">
                <div class="btn-group">
                    <button wire:click="export('csv')" class="btn btn-outline-primary btn-sm">
                        <i class="fas fa-file-csv"></i> CSV
                    </button>
                    <button wire:click="export('pdf')" class="btn btn-outline-danger btn-sm">
                        <i class="fas fa-file-pdf"></i> PDF
                    </button>
                </div>
            </div>
        </div>

        {{-- Filtro de Rango de Fechas --}}
        <div class="card mb-3">
            <div class="card-body">
                <div class="row">
                    <div class="col-md-3">
                        <select wire:model.live="dateRange" class="form-select">
                            <option value="today">Hoy</option>
                            <option value="yesterday">Ayer</option>
                            <option value="last_7_days">Últimos 7 días</option>
                            <option value="last_30_days">Últimos 30 días</option>
                            <option value="this_month">Este mes</option>
                            <option value="last_month">Mes pasado</option>
                        </select>
                    </div>
                    <div class="col-md-9 text-muted">
                        <small>
                            Mostrando datos desde <strong>{{ $fechaDesde->format('d/m/Y') }}</strong>
                            hasta <strong>{{ $fechaHasta->format('d/m/Y') }}</strong>
                        </small>
                    </div>
                </div>
            </div>
        </div>

        {{-- KPIs Cards --}}
        <div class="row g-3 mb-4">
            {{-- KPI 1: Ventas --}}
            <div class="col-md-3">
                <div class="card border-left-primary shadow-sm h-100">
                    <div class="card-body">
                        <div class="row no-gutters align-items-center">
                            <div class="col mr-2">
                                <div class="text-xs font-weight-bold text-primary text-uppercase mb-1">
                                    Ventas Totales
                                </div>
                                <div class="h5 mb-0 font-weight-bold text-gray-800">
                                    ${{ number_format($totalVentas, 2) }}
                                </div>
                            </div>
                            <div class="col-auto">
                                <i class="fas fa-dollar-sign fa-2x text-gray-300"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {{-- KPI 2: Producción --}}
            <div class="col-md-3">
                <div class="card border-left-success shadow-sm h-100">
                    <div class="card-body">
                        <div class="row no-gutters align-items-center">
                            <div class="col mr-2">
                                <div class="text-xs font-weight-bold text-success text-uppercase mb-1">
                                    Producción
                                </div>
                                <div class="h5 mb-0 font-weight-bold text-gray-800">
                                    {{ number_format($totalProduccion, 2) }}
                                </div>
                            </div>
                            <div class="col-auto">
                                <i class="fas fa-industry fa-2x text-gray-300"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {{-- KPI 3: Compras --}}
            <div class="col-md-3">
                <div class="card border-left-info shadow-sm h-100">
                    <div class="card-body">
                        <div class="row no-gutters align-items-center">
                            <div class="col mr-2">
                                <div class="text-xs font-weight-bold text-info text-uppercase mb-1">
                                    Compras
                                </div>
                                <div class="h5 mb-0 font-weight-bold text-gray-800">
                                    ${{ number_format($totalCompras, 2) }}
                                </div>
                            </div>
                            <div class="col-auto">
                                <i class="fas fa-shopping-cart fa-2x text-gray-300"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {{-- KPI 4: Inventario --}}
            <div class="col-md-3">
                <div class="card border-left-warning shadow-sm h-100">
                    <div class="card-body">
                        <div class="row no-gutters align-items-center">
                            <div class="col mr-2">
                                <div class="text-xs font-weight-bold text-warning text-uppercase mb-1">
                                    Inventario
                                </div>
                                <div class="h5 mb-0 font-weight-bold text-gray-800">
                                    ${{ number_format($inventarioActual, 2) }}
                                </div>
                            </div>
                            <div class="col-auto">
                                <i class="fas fa-warehouse fa-2x text-gray-300"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {{-- KPI 5-8: Segunda Fila --}}
            <div class="col-md-3">
                <div class="card shadow-sm h-100">
                    <div class="card-body">
                        <div class="text-xs font-weight-bold text-uppercase mb-1">Merma Promedio</div>
                        <div class="h5 mb-0">{{ number_format($mermaPromedio, 1) }}%</div>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="card shadow-sm h-100">
                    <div class="card-body">
                        <div class="text-xs font-weight-bold text-uppercase mb-1">Costo Promedio Recetas</div>
                        <div class="h5 mb-0">${{ number_format($costoPromedioRecetas, 2) }}</div>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="card shadow-sm h-100">
                    <div class="card-body">
                        <div class="text-xs font-weight-bold text-uppercase mb-1">Rotación Inventario</div>
                        <div class="h5 mb-0">{{ number_format($rotacionInventario, 1) }} días</div>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="card shadow-sm h-100">
                    <div class="card-body">
                        <div class="text-xs font-weight-bold text-uppercase mb-1">Eficiencia Producción</div>
                        <div class="h5 mb-0">{{ number_format($eficienciaProduccion, 1) }}%</div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Gráficas --}}
        <div class="row g-3">
            {{-- Gráfica 1: Ventas por Día --}}
            <div class="col-md-6">
                <div class="card shadow-sm">
                    <div class="card-header bg-white">
                        <h6 class="m-0 font-weight-bold text-primary">Ventas por Día</h6>
                    </div>
                    <div class="card-body">
                        <canvas id="ventasPorDiaChart" height="250"></canvas>
                    </div>
                </div>
            </div>

            {{-- Gráfica 2: Top Productos --}}
            <div class="col-md-6">
                <div class="card shadow-sm">
                    <div class="card-header bg-white">
                        <h6 class="m-0 font-weight-bold text-primary">Top 10 Productos</h6>
                    </div>
                    <div class="card-body">
                        <canvas id="topProductosChart" height="250"></canvas>
                    </div>
                </div>
            </div>

            {{-- Gráfica 3: Mermas por Categoría --}}
            <div class="col-md-6">
                <div class="card shadow-sm">
                    <div class="card-header bg-white">
                        <h6 class="m-0 font-weight-bold text-primary">Mermas por Categoría</h6>
                    </div>
                    <div class="card-body">
                        <canvas id="mermasChart" height="250"></canvas>
                    </div>
                </div>
            </div>

            {{-- Gráfica 4: Stock por Almacén --}}
            <div class="col-md-6">
                <div class="card shadow-sm">
                    <div class="card-header bg-white">
                        <h6 class="m-0 font-weight-bold text-primary">Stock por Almacén</h6>
                    </div>
                    <div class="card-body">
                        <canvas id="stockAlmacenChart" height="250"></canvas>
                    </div>
                </div>
            </div>
        </div>
    </div>

    @push('scripts')
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // Gráfica 1: Ventas por Día (Línea)
            const ventasCtx = document.getElementById('ventasPorDiaChart').getContext('2d');
            new Chart(ventasCtx, {
                type: 'line',
                data: {
                    labels: @json(array_column($ventasPorDia, 'fecha')),
                    datasets: [{
                        label: 'Ventas ($)',
                        data: @json(array_column($ventasPorDia, 'total')),
                        borderColor: 'rgb(75, 192, 192)',
                        backgroundColor: 'rgba(75, 192, 192, 0.2)',
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                }
            });

            // Gráfica 2: Top Productos (Barras Horizontales)
            const productosCtx = document.getElementById('topProductosChart').getContext('2d');
            new Chart(productosCtx, {
                type: 'bar',
                data: {
                    labels: @json(array_column($topProductos, 'producto')),
                    datasets: [{
                        label: 'Cantidad Vendida',
                        data: @json(array_column($topProductos, 'cantidad')),
                        backgroundColor: 'rgba(54, 162, 235, 0.6)',
                    }]
                },
                options: {
                    indexAxis: 'y',
                    responsive: true,
                    maintainAspectRatio: false,
                }
            });

            // Gráfica 3: Mermas (Pie)
            const mermasCtx = document.getElementById('mermasChart').getContext('2d');
            new Chart(mermasCtx, {
                type: 'pie',
                data: {
                    labels: @json(array_column($mermasPorCategoria, 'categoria')),
                    datasets: [{
                        data: @json(array_column($mermasPorCategoria, 'total')),
                        backgroundColor: [
                            'rgba(255, 99, 132, 0.6)',
                            'rgba(54, 162, 235, 0.6)',
                            'rgba(255, 206, 86, 0.6)',
                            'rgba(75, 192, 192, 0.6)',
                        ],
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                }
            });

            // Gráfica 4: Stock por Almacén (Barras)
            const stockCtx = document.getElementById('stockAlmacenChart').getContext('2d');
            new Chart(stockCtx, {
                type: 'bar',
                data: {
                    labels: @json(array_column($inventarioPorAlmacen, 'almacen')),
                    datasets: [{
                        label: 'Valor ($)',
                        data: @json(array_column($inventarioPorAlmacen, 'valor')),
                        backgroundColor: 'rgba(153, 102, 255, 0.6)',
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                }
            });
        });
    </script>
    @endpush
</div>
```

---

### BLOQUE 2: Exportaciones (1.5h)

#### Tarea 2.1: Export Service (45min)

**Archivo**: `app/Services/Reports/ReportExportService.php`

*(Service para generar CSV y PDF)*

#### Tarea 2.2: Integrar con Dashboard (45min)

*(Agregar funcionalidad de export en componente)*

---

### BLOQUE 3: Drill-Down + Favoritos (1.5h)

#### Tarea 3.1: Drill-Down Component (1h)

**Archivo**: `app/Livewire/Reports/DrillDown.php`

*(Componente para navegación jerárquica en reportes)*

#### Tarea 3.2: Sistema de Favoritos (30min)

*(Tabla para guardar reportes favoritos del usuario)*

---

### BLOQUE 4: Rutas y Testing (1h)

#### Tarea 4.1: Registrar Rutas (10min)

**Archivo**: `routes/web.php`

```php
Route::middleware(['auth'])->prefix('reports')->name('reports.')->group(function () {
    Route::get('/', \App\Livewire\Reports\Dashboard::class)->name('dashboard');
    Route::get('/drill-down/{type}/{id?}', \App\Livewire\Reports\DrillDown::class)->name('drill-down');
    Route::get('/export/{type}', [ReportController::class, 'export'])->name('export');
});
```

---

## ✅ CHECKLIST DE VALIDACIÓN

### Dashboard
- [ ] 8 KPIs funcionando
- [ ] 5 Gráficas con Chart.js
- [ ] Filtro de rangos de fechas
- [ ] Responsive design
- [ ] Loading states
- [ ] Performance <2s

### Exportaciones
- [ ] CSV export funcionando
- [ ] PDF export funcionando
- [ ] Incluye todos los datos del dashboard
- [ ] Formato correcto

### Drill-Down
- [ ] Navegación jerárquica funcionando
- [ ] Filtros contextuales
- [ ] Breadcrumbs de navegación

### UX
- [ ] Toast notifications
- [ ] Error handling
- [ ] Skeleton loaders
- [ ] Mobile-friendly

---

**Versión**: 1.0
**Fecha**: 31 de Octubre 2025

📊 **¡Dashboard de reportes listo para implementar!**
