@extends('layouts.terrena')

@section('page-title', 'Mix de Ventas')

@section('content')
  {{-- Header Profesional --}}
  <div class="row mb-4">
    <div class="col">
      <div class="d-flex justify-content-between align-items-start">
        <div>
          <h2 class="fw-bold mb-1">
            <i class="fa-solid fa-chart-pie text-primary me-2"></i>
            Mix de Ventas por Forma de Pago
          </h2>
          <nav aria-label="breadcrumb">
            <ol class="breadcrumb mb-0">
              <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Inicio</a></li>
              <li class="breadcrumb-item"><a href="#">Reportes</a></li>
              <li class="breadcrumb-item active">Mix de Ventas</li>
            </ol>
          </nav>
        </div>
        <div class="d-flex gap-2">
          <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
            <i class="fa-solid fa-print me-1"></i>Imprimir
          </button>
          <button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#exportModal">
            <i class="fa-solid fa-file-export me-1"></i>Exportar
          </button>
        </div>
      </div>
    </div>
  </div>

  {{-- Filtros --}}
  <div class="card shadow-sm mb-4">
    <div class="card-body">
      <form method="GET" action="{{ route('reports.sales.mix') }}" class="row g-3 align-items-end">
        <div class="col-md-3">
          <label class="form-label fw-semibold">
            <i class="fa-solid fa-calendar me-1"></i>Fecha
          </label>
          <input type="date" name="date" class="form-control" 
                 value="{{ $date->format('Y-m-d') }}" 
                 max="{{ now()->format('Y-m-d') }}"
                 required>
        </div>
        <div class="col-md-3">
          <label class="form-label fw-semibold">
            <i class="fa-solid fa-store me-1"></i>Sucursal
          </label>
          <select name="branch" class="form-select">
            <option value="">Todas las sucursales</option>
            @foreach($totals['by_branch'] as $branch => $amount)
              <option value="{{ $branch }}">{{ $branch }}</option>
            @endforeach
          </select>
        </div>
        <div class="col-md-2">
          <button type="submit" class="btn btn-primary w-100">
            <i class="fa-solid fa-search me-1"></i>Buscar
          </button>
        </div>
        <div class="col-md-2">
          <a href="{{ route('reports.sales.mix') }}" class="btn btn-outline-secondary w-100">
            <i class="fa-solid fa-rotate-right me-1"></i>Limpiar
          </a>
        </div>
      </form>
    </div>
  </div>

  @if(empty($data))
    <div class="alert alert-warning shadow-sm">
      <div class="d-flex align-items-center">
        <i class="fa-solid fa-triangle-exclamation fa-2x me-3"></i>
        <div>
          <h5 class="alert-heading mb-1">No se encontraron datos</h5>
          <p class="mb-0">No hay ventas registradas para la fecha seleccionada.</p>
        </div>
      </div>
    </div>
  @else
    {{-- KPIs Cards --}}
    <div class="row g-3 mb-4">
      <div class="col-xl-3 col-md-6">
        <div class="card border-0 shadow-sm">
          <div class="card-body">
            <div class="d-flex align-items-center">
              <div class="flex-shrink-0">
                <div class="bg-primary bg-opacity-10 rounded-3 p-3">
                  <i class="fa-solid fa-dollar-sign fa-2x text-primary"></i>
                </div>
              </div>
              <div class="flex-grow-1 ms-3">
                <p class="text-muted mb-1 small">Ventas Totales</p>
                <h3 class="mb-0 fw-bold">${{ number_format($totals['total_general'], 2) }}</h3>
                <small class="text-success">
                  <i class="fa-solid fa-arrow-up me-1"></i>100%
                </small>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-xl-3 col-md-6">
        <div class="card border-0 shadow-sm">
          <div class="card-body">
            <div class="d-flex align-items-center">
              <div class="flex-shrink-0">
                <div class="bg-success bg-opacity-10 rounded-3 p-3">
                  <i class="fa-solid fa-wallet fa-2x text-success"></i>
                </div>
              </div>
              <div class="flex-grow-1 ms-3">
                <p class="text-muted mb-1 small">Formas de Pago</p>
                <h3 class="mb-0 fw-bold">{{ count($totals['by_payment']) }}</h3>
                <small class="text-muted">Activas</small>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-xl-3 col-md-6">
        <div class="card border-0 shadow-sm">
          <div class="card-body">
            <div class="d-flex align-items-center">
              <div class="flex-shrink-0">
                <div class="bg-info bg-opacity-10 rounded-3 p-3">
                  <i class="fa-solid fa-building fa-2x text-info"></i>
                </div>
              </div>
              <div class="flex-grow-1 ms-3">
                <p class="text-muted mb-1 small">Sucursales</p>
                <h3 class="mb-0 fw-bold">{{ count($totals['by_branch']) }}</h3>
                <small class="text-muted">Reportando</small>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-xl-3 col-md-6">
        <div class="card border-0 shadow-sm">
          <div class="card-body">
            <div class="d-flex align-items-center">
              <div class="flex-shrink-0">
                <div class="bg-warning bg-opacity-10 rounded-3 p-3">
                  <i class="fa-solid fa-money-bill-wave fa-2x text-warning"></i>
                </div>
              </div>
              <div class="flex-grow-1 ms-3">
                <p class="text-muted mb-1 small">Efectivo</p>
                <h3 class="mb-0 fw-bold">${{ number_format($totals['by_payment']['CASH'] ?? 0, 2) }}</h3>
                <small class="text-muted">
                  {{ $totals['total_general'] > 0 ? number_format((($totals['by_payment']['CASH'] ?? 0) / $totals['total_general']) * 100, 1) : 0 }}%
                </small>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      {{-- Tabla Detallada --}}
      <div class="col-xl-7 mb-4">
        <div class="card border-0 shadow-sm">
          <div class="card-header bg-white border-bottom py-3">
            <h5 class="mb-0 fw-bold">
              <i class="fa-solid fa-table me-2 text-primary"></i>
              Detalle por Forma de Pago
            </h5>
          </div>
          <div class="card-body p-0">
            <div class="table-responsive">
              <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                  <tr>
                    <th class="border-0">Forma de Pago</th>
                    <th class="border-0 text-end">Monto</th>
                    <th class="border-0 text-end">Porcentaje</th>
                    <th class="border-0" style="width: 150px;">Distribución</th>
                  </tr>
                </thead>
                <tbody>
                  @foreach($totals['by_payment'] as $payment => $amount)
                    @php
                      $percentage = $totals['total_general'] > 0 
                        ? round(($amount / $totals['total_general']) * 100, 2) 
                        : 0;
                      $config = match($payment) {
                        'CASH' => ['color' => 'success', 'icon' => 'money-bill-wave', 'label' => 'Efectivo'],
                        'CREDIT_CARD' => ['color' => 'primary', 'icon' => 'credit-card', 'label' => 'Tarjeta Crédito'],
                        'DEBIT_CARD' => ['color' => 'info', 'icon' => 'credit-card', 'label' => 'Tarjeta Débito'],
                        'TRANSFER' => ['color' => 'warning', 'icon' => 'exchange-alt', 'label' => 'Transferencia'],
                        default => ['color' => 'secondary', 'icon' => 'question', 'label' => $payment]
                      };
                    @endphp
                    <tr>
                      <td>
                        <div class="d-flex align-items-center">
                          <div class="bg-{{ $config['color'] }} bg-opacity-10 rounded p-2 me-2">
                            <i class="fa-solid fa-{{ $config['icon'] }} text-{{ $config['color'] }}"></i>
                          </div>
                          <span class="fw-semibold">{{ $config['label'] }}</span>
                        </div>
                      </td>
                      <td class="text-end">
                        <span class="fw-bold">${{ number_format($amount, 2) }}</span>
                      </td>
                      <td class="text-end">
                        <span class="badge bg-{{ $config['color'] }} bg-opacity-10 text-{{ $config['color'] }}">
                          {{ number_format($percentage, 1) }}%
                        </span>
                      </td>
                      <td>
                        <div class="progress" style="height: 8px;">
                          <div class="progress-bar bg-{{ $config['color'] }}" 
                               role="progressbar" 
                               style="width: {{ $percentage }}%"
                               aria-valuenow="{{ $percentage }}" 
                               aria-valuemin="0" 
                               aria-valuemax="100">
                          </div>
                        </div>
                      </td>
                    </tr>
                  @endforeach
                </tbody>
                <tfoot class="table-light">
                  <tr>
                    <td class="fw-bold border-0">TOTAL</td>
                    <td class="text-end fw-bold border-0">${{ number_format($totals['total_general'], 2) }}</td>
                    <td class="text-end border-0">
                      <span class="badge bg-dark">100%</span>
                    </td>
                    <td class="border-0"></td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        </div>
      </div>

      {{-- Gráfico de Dona (Chart.js) --}}
      <div class="col-xl-5 mb-4">
        <div class="card border-0 shadow-sm">
          <div class="card-header bg-white border-bottom py-3">
            <h5 class="mb-0 fw-bold">
              <i class="fa-solid fa-chart-pie me-2 text-primary"></i>
              Distribución Visual
            </h5>
          </div>
          <div class="card-body">
            <canvas id="paymentChart" height="300"></canvas>
          </div>
        </div>
      </div>
    </div>

    {{-- Tabla por Sucursal (si aplica) --}}
    @if(count($totals['by_branch']) > 1)
      <div class="row">
        <div class="col-12">
          <div class="card border-0 shadow-sm">
            <div class="card-header bg-white border-bottom py-3">
              <h5 class="mb-0 fw-bold">
                <i class="fa-solid fa-building me-2 text-info"></i>
                Detalle por Sucursal
              </h5>
            </div>
            <div class="card-body p-0">
              <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                  <thead class="table-light">
                    <tr>
                      <th class="border-0">Sucursal</th>
                      <th class="border-0 text-end">Monto</th>
                      <th class="border-0 text-end">Participación</th>
                    </tr>
                  </thead>
                  <tbody>
                    @foreach($totals['by_branch'] as $branch => $amount)
                      @php
                        $percentage = $totals['total_general'] > 0 
                          ? round(($amount / $totals['total_general']) * 100, 2) 
                          : 0;
                      @endphp
                      <tr>
                        <td>
                          <div class="d-flex align-items-center">
                            <div class="bg-info bg-opacity-10 rounded p-2 me-2">
                              <i class="fa-solid fa-store text-info"></i>
                            </div>
                            <span class="fw-semibold">{{ $branch }}</span>
                          </div>
                        </td>
                        <td class="text-end">
                          <span class="fw-bold">${{ number_format($amount, 2) }}</span>
                        </td>
                        <td class="text-end">
                          <span class="badge bg-info bg-opacity-10 text-info">
                            {{ number_format($percentage, 1) }}%
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
      </div>
    @endif
  @endif

{{-- Modal de Exportación --}}
<div class="modal fade" id="exportModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">
          <i class="fa-solid fa-file-export me-2"></i>
          Exportar Reporte
        </h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <p class="text-muted">Selecciona el formato de exportación:</p>
        <div class="d-grid gap-2">
          <button class="btn btn-success btn-lg" onclick="alert('Exportar a Excel - Próximamente')">
            <i class="fa-solid fa-file-excel me-2"></i>
            Exportar a Excel
          </button>
          <button class="btn btn-danger btn-lg" onclick="alert('Exportar a PDF - Próximamente')">
            <i class="fa-solid fa-file-pdf me-2"></i>
            Exportar a PDF
          </button>
          <button class="btn btn-secondary btn-lg" onclick="alert('Exportar a CSV - Próximamente')">
            <i class="fa-solid fa-file-csv me-2"></i>
            Exportar a CSV
          </button>
        </div>
      </div>
    </div>
  </div>
</div>

{{-- Chart.js (ya incluido en layout terrena) --}}
<script>
document.addEventListener('DOMContentLoaded', function() {
  const ctx = document.getElementById('paymentChart');
  if (!ctx) return;
  
  const data = {
    labels: [
      @foreach($totals['by_payment'] as $payment => $amount)
        '{{ match($payment) {
          "CASH" => "Efectivo",
          "CREDIT_CARD" => "T. Crédito",
          "DEBIT_CARD" => "T. Débito",
          "TRANSFER" => "Transferencia",
          default => $payment
        } }}',
      @endforeach
    ],
    datasets: [{
      data: [
        @foreach($totals['by_payment'] as $payment => $amount)
          {{ $amount }},
        @endforeach
      ],
      backgroundColor: [
        @foreach($totals['by_payment'] as $payment => $amount)
          '{{ match($payment) {
            "CASH" => "rgba(25, 135, 84, 0.8)",
            "CREDIT_CARD" => "rgba(13, 110, 253, 0.8)",
            "DEBIT_CARD" => "rgba(13, 202, 240, 0.8)",
            "TRANSFER" => "rgba(255, 193, 7, 0.8)",
            default => "rgba(108, 117, 125, 0.8)"
          } }}',
        @endforeach
      ],
      borderWidth: 0
    }]
  };

  new Chart(ctx, {
    type: 'doughnut',
    data: data,
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'bottom',
          labels: {
            padding: 15,
            font: { size: 12, weight: '500' }
          }
        },
        tooltip: {
          callbacks: {
            label: function(context) {
              let label = context.label || '';
              let value = context.parsed || 0;
              let total = context.dataset.data.reduce((a, b) => a + b, 0);
              let percentage = ((value / total) * 100).toFixed(1);
              return label + ': $' + value.toLocaleString('es-MX', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
              }) + ' (' + percentage + '%)';
            }
          }
        }
      }
    }
  });
});
</script>

{{-- Estilos para impresión --}}
<style>
@media print {
  .btn, .modal, nav, .sidebar, .breadcrumb {
    display: none !important;
  }
  .card {
    break-inside: avoid;
    box-shadow: none !important;
    border: 1px solid #dee2e6 !important;
  }
  body {
    print-color-adjust: exact;
    -webkit-print-color-adjust: exact;
  }
  .container-fluid {
    padding: 0 !important;
  }
}

/* Mejoras visuales */
.card {
  transition: transform 0.2s, box-shadow 0.2s;
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15) !important;
}

.table tbody tr:hover {
  background-color: rgba(0, 0, 0, 0.02);
}

.progress {
  background-color: rgba(0, 0, 0, 0.05);
}
</style>
@endsection
