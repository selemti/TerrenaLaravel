@extends('layouts.terrena')

@section('title', 'Dashboard - TerrenaPOS')
@section('page-title')
  <i class="fa-solid fa-gauge"></i> <span class="label">Dashboard</span>
@endsection

@section('content')
<div class="dashboard-grid">

  {{-- Filtros --}}
  <div class="filters-bar mb-3">
    <div class="d-flex align-items-center gap-2">
      <i class="fa-solid fa-filter text-muted"></i><strong>Filtros:</strong>
    </div>
    <div class="d-flex align-items-center gap-2 flex-wrap flex-md-nowrap">
      <label class="text-muted small">Desde</label>
      <input id="start-date" type="date" class="form-control form-control-sm">
      <label class="text-muted small ms-sm-2">Hasta</label>
      <input id="end-date" type="date" class="form-control form-control-sm">
      <button id="apply-filters" type="button" class="btn btn-filter btn-sm">
        <i class="fa-solid fa-check me-1"></i>Aplicar
      </button>
    </div>
  </div>

  {{-- KPIs (5 columnas en desktop) --}}
  <div class="kpi-grid mb-3">
    <div class="card-kpi">
      <h5 class="card-title"><i class="fa-solid fa-sack-dollar"></i> Ventas de hoy</h5>
      <div class="kpi-value" id="kpi-sales-today">—</div>
      <div class="text-muted small">Total vendido en el rango seleccionado</div>
    </div>
    <div class="card-kpi">
      <h5 class="card-title"><i class="fa-solid fa-star"></i> Producto estrella</h5>
      <div class="kpi-value" id="kpi-star-product">—</div>
      <div class="text-muted small">Ventas: <strong id="kpi-star-sales">—</strong></div>
    </div>
    <div class="card-kpi">
      <h5 class="card-title"><i class="fa-solid fa-tags"></i> Productos vendidos</h5>
      <div class="kpi-value" id="kpi-items-sold">0</div>
      <div class="text-muted small">Items vendidos en el rango</div>
    </div>
    <div class="card-kpi">
      <h5 class="card-title"><i class="fa-solid fa-receipt"></i> Ticket promedio</h5>
      <div class="kpi-value" id="kpi-avg-ticket">—</div>
      <div class="text-muted small">Promedio por ticket emitido</div>
    </div>
    <div class="card-kpi">
      <h5 class="card-title"><i class="fa-solid fa-bell"></i> Alertas</h5>
      <div class="kpi-value" id="kpi-alerts">0</div>
      <div class="text-muted small">
        <a class="link-more" href="{{ url('/reportes') }}">Ver todas <i class="fa-solid fa-chevron-right"></i></a>
      </div>
    </div>
  </div>

  <div class="row g-3">
    {{-- Tendencia de ventas --}}
    <div class="col-12 col-xl-7">
      <div class="chart-container">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="card-title mb-0"><i class="fa-solid fa-chart-line"></i> Tendencia de ventas (7 días)</h5>
          <a class="link-more" href="{{ url('/reportes') }}">Ver detalle <i class="fa-solid fa-chevron-right"></i></a>
        </div>
        <div class="chart-wrapper">
          <canvas id="salesTrendChart"></canvas>
        </div>
      </div>
    </div>

    {{-- Estatus de cajas --}}
    <div class="col-12 col-xl-5">
      <div class="card-vo">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="card-title mb-0"><i class="fa-solid fa-cash-register"></i> Estatus de cajas</h5>
          <a href="{{ url('/caja/cortes') }}" class="link-more small">Ir a cortes <i class="fa-solid fa-chevron-right ms-1"></i></a>
        </div>
        <div class="table-responsive">
          <table class="table table-sm mb-0 align-middle">
            <thead>
              <tr><th>Sucursal</th><th>Estatus</th><th class="text-end">Vendido</th></tr>
            </thead>
            <tbody id="kpi-registers">
              <tr><td colspan="3" class="text-center text-muted small">Cargando datos...</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    {{-- Ventas por hora --}}
    <div class="col-12 col-xl-7">
      <div class="chart-container">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="card-title mb-0"><i class="fa-solid fa-business-time"></i> Ventas por hora</h5>
          <a class="link-more" href="{{ url('/reportes') }}">Ver todo <i class="fa-solid fa-chevron-right"></i></a>
        </div>
        <div class="chart-wrapper">
          <canvas id="salesByHourChart"></canvas>
        </div>
      </div>
    </div>

    {{-- Formas de pago --}}
    <div class="col-12 col-xl-5">
      <div class="chart-container">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="card-title mb-0"><i class="fa-solid fa-circle-notch"></i> Formas de pago</h5>
          <a class="link-more" href="{{ url('/reportes') }}">Ver todo <i class="fa-solid fa-chevron-right"></i></a>
        </div>
        <div class="chart-wrapper">
          <canvas id="paymentChart"></canvas>
        </div>
      </div>
    </div>

    {{-- Ventas por sucursal (apilada por tipo) --}}
    <div class="col-12 col-xl-7">
      <div class="chart-container">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="card-title mb-0"><i class="fa-solid fa-store"></i> Ventas por sucursal (por tipo)</h5>
          <a class="link-more" href="{{ url('/reportes') }}">Ver todo <i class="fa-solid fa-chevron-right"></i></a>
        </div>
        <div class="chart-wrapper">
          <canvas id="branchPaymentsChart"></canvas>
        </div>
      </div>
    </div>

    {{-- Top 5 productos --}}
    <div class="col-12 col-xl-5">
      <div class="chart-container">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="card-title mb-0"><i class="fa-solid fa-ranking-star"></i> Top 5 de productos</h5>
          <a class="link-more" href="{{ url('/reportes') }}">Ver todo <i class="fa-solid fa-chevron-right"></i></a>
        </div>
        <div class="chart-wrapper">
          <canvas id="topProductsChart"></canvas>
        </div>
      </div>
    </div>

    {{-- Actividad reciente --}}
    <div class="col-12 col-xl-7">
      <div class="card-vo">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="card-title mb-0"><i class="fa-regular fa-clock"></i> Actividad reciente</h5>
          <a class="link-more" href="{{ url('/reportes') }}">Ver todo <i class="fa-solid fa-chevron-right"></i></a>
        </div>
        <ul id="activity-list" class="list-unstyled mb-0">
          {{-- Se llena por JS --}}
        </ul>
      </div>
    </div>

    {{-- Órdenes recientes --}}
    <div class="col-12 col-xl-5">
      <div class="card-vo">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="card-title mb-0"><i class="fa-solid fa-list-check"></i> Órdenes recientes</h5>
          <a class="link-more" href="{{ url('/reportes') }}">Ver todo <i class="fa-solid fa-chevron-right"></i></a>
        </div>
        <div class="table-responsive">
          <table class="table table-sm align-middle mb-0">
            <thead>
              <tr><th>#Ticket</th><th>Sucursal</th><th>Hora</th><th class="text-end">Total</th></tr>
            </thead>
            <tbody id="orders-table">
              {{-- Se llena por JS --}}
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </div>
</div>
@endsection

@push('scripts')
<script>
// Inicializa las gráficas cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
  // Verifica que terrena.js se haya cargado
  if (window.Terrena && typeof Terrena.initDashboardCharts === 'function') {
    Terrena.initDashboardCharts();
  } else {
    console.warn('terrena.js no se ha cargado correctamente');
  }
});
</script>
@endpush
