@extends('layouts.terrena')

@section('title', 'Inventario - TerrenaPOS')
@section('page-title')
  <i class="fa-solid fa-boxes-stacked"></i> <span class="label">Inventario</span>
@endsection

@section('content')
<div class="dashboard-grid">

  {{-- Filtros --}}
  <div class="card shadow-sm border-0 mb-3">
    <div class="card-body">
      <form class="row g-2 align-items-end" id="formFiltros">
        <div class="col-12 col-md-4">
          <label class="form-label small">Buscar producto / SKU</label>
          <input type="text" id="filterBuscar" class="form-control form-control-sm" placeholder="Ej. 'Leche 1.5L' o 'SKU-0001'">
        </div>
        <div class="col-6 col-md-2">
          <label class="form-label small">Sucursal</label>
          <select id="filterSucursal" class="form-select form-select-sm">
            <option value="">Todas las sucursales</option>
          </select>
        </div>
        <div class="col-6 col-md-2">
          <label class="form-label small">Categoría</label>
          <select id="filterCategoria" class="form-select form-select-sm">
            <option value="">Todas las categorías</option>
          </select>
        </div>
        <div class="col-6 col-md-2">
          <label class="form-label small">Estado</label>
          <select id="filterEstado" class="form-select form-select-sm">
            <option value="all">Todos</option>
            <option value="active">Activos</option>
            <option value="inactive">Inactivos</option>
            <option value="low_stock">Bajo stock</option>
            <option value="expiring">Por caducar</option>
          </select>
        </div>
        <div class="col-6 col-md-2 text-end">
          <div class="d-grid d-md-flex gap-2">
            <button id="btnAplicarFiltros" class="btn btn-sm text-white" style="background:var(--green-dark)" type="button">Filtrar</button>
            <button class="btn btn-sm btn-outline-secondary" type="button">Exportar</button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <div class="d-flex flex-wrap gap-2 justify-content-between align-items-center small mb-3">
    <span class="text-muted">Catálogos relacionados:</span>
    <div class="d-flex flex-wrap gap-2">
      <a class="text-decoration-none link-secondary" href="{{ route('cat.almacenes') }}">Almacenes</a>
      <a class="text-decoration-none link-secondary" href="{{ route('cat.sucursales') }}">Sucursales</a>
      <a class="text-decoration-none link-secondary" href="{{ route('cat.unidades') }}">Unidades</a>
      <a class="text-decoration-none link-secondary" href="{{ route('cat.stockpolicy') }}">Políticas de stock</a>
    </div>
  </div>

  {{-- KPIs mini --}}
  <div class="row g-3 mb-2">
    <div class="col-6 col-md-3">
      <div class="card border-0 shadow-sm">
        <div class="card-body">
          <div class="small text-muted">Ítems distintos</div>
          <div class="h4 m-0" id="kpiTotalItems">0</div>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="card border-0 shadow-sm">
        <div class="card-body">
          <div class="small text-muted">Valor inventario</div>
          <div class="h4 m-0" id="kpiInventoryValue">$0.00</div>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="card border-0 shadow-sm">
        <div class="card-body">
          <div class="small text-muted">Bajo stock</div>
          <div class="h4 m-0" id="kpiLowStock">0</div>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3">
      <div class="card border-0 shadow-sm">
        <div class="card-body">
          <div class="small text-muted">Con caducidad próxima</div>
          <div class="h4 m-0" id="kpiExpiring">0</div>
        </div>
      </div>
    </div>
  </div>

  {{-- Acciones rápidas --}}
  <div class="d-flex flex-wrap gap-2 justify-content-between mb-2">
    <div class="small text-muted d-flex align-items-center gap-2">
      <span class="badge rounded-pill text-bg-light">Vista: Stock</span>
    </div>
    <div class="d-flex gap-2">
      <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="modal" data-bs-target="#modalKardex">
        Ver Kardex
      </button>
      <button class="btn btn-sm btn-primary" type="button" data-bs-toggle="offcanvas" data-bs-target="#offcanvasMovimiento">
        Movimiento rápido
      </button>
    </div>
  </div>

  {{-- Tabla de stock --}}
  <div class="card shadow-sm border-0">
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-sm align-middle mb-0">
          <thead class="table-light">
            <tr>
              <th>SKU</th>
              <th>Producto</th>
              <th>Categoría</th>
              <th class="text-end">Existencia</th>
              <th>UDM</th>
              <th class="text-end">Costo</th>
              <th class="text-end">Valor Total</th>
              <th>Estado</th>
              <th class="text-end">Acciones</th>
            </tr>
          </thead>
          <tbody id="stockTableBody">
            <tr>
              <td colspan="9" class="text-center py-4">
                <div class="spinner-border spinner-border-sm text-primary me-2"></div>
                Cargando inventario...
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    {{-- Pie de tabla: paginación --}}
    <div class="card-footer bg-white">
      <div id="stockPagination"></div>
    </div>
  </div>

  {{-- Offcanvas: Movimiento rápido --}}
  <div class="offcanvas offcanvas-end" tabindex="-1" id="offcanvasMovimiento" style="max-width:420px">
    <div class="offcanvas-header">
      <h5 class="offcanvas-title">Movimiento rápido</h5>
      <button type="button" class="btn-close" data-bs-dismiss="offcanvas"></button>
    </div>
    <div class="offcanvas-body">
      <form id="formMovimiento">
        <input type="hidden" id="movItemId" name="item_id">

        <div class="mb-2">
          <label class="form-label small">Tipo de movimiento *</label>
          <select id="movTipo" name="tipo" class="form-select form-select-sm" required>
            <option value="">Seleccione...</option>
          </select>
        </div>

        <div class="mb-2">
          <label class="form-label small">Cantidad *</label>
          <input type="number" name="cantidad" step="0.001" min="0.001" class="form-control form-control-sm text-end" required>
        </div>

        <div class="mb-2">
          <label class="form-label small">Sucursal *</label>
          <select id="movSucursal" name="sucursal_id" class="form-select form-select-sm" required>
            <option value="">Seleccione...</option>
          </select>
        </div>

        <div class="mb-2">
          <label class="form-label small">Costo unitario (opcional)</label>
          <input type="number" name="costo_unit" step="0.0001" min="0" class="form-control form-control-sm text-end" placeholder="0.0000">
          <div class="form-text">Para entradas/ajustes de costo</div>
        </div>

        <div class="mb-2">
          <label class="form-label small">Razón / Notas</label>
          <textarea name="razon" class="form-control form-control-sm" rows="2" placeholder="Detalle del movimiento..."></textarea>
        </div>

        <div class="d-grid">
          <button type="submit" class="btn btn-sm btn-primary">
            <i class="fa-solid fa-save me-2"></i>Guardar
          </button>
        </div>
      </form>
    </div>
  </div>

  {{-- Modal: Kardex --}}
  <div class="modal fade" id="modalKardex" tabindex="-1">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
      <div class="modal-content">
        <div class="modal-header bg-primary bg-opacity-10">
          <h5 class="modal-title">
            <i class="fa-solid fa-chart-line me-2"></i>
            Kardex — <span class="item-name"></span>
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="table-responsive">
            <table class="table table-sm align-middle mb-0">
              <thead class="table-light">
                <tr>
                  <th>Fecha</th>
                  <th>Hora</th>
                  <th>Tipo</th>
                  <th class="text-end">Entrada</th>
                  <th class="text-end">Salida</th>
                  <th class="text-end">Saldo</th>
                  <th>Referencia</th>
                </tr>
              </thead>
              <tbody id="kardexTableBody">
                <tr>
                  <td colspan="7" class="text-center py-4">
                    <div class="spinner-border spinner-border-sm"></div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-sm btn-outline-secondary" data-bs-dismiss="modal">Cerrar</button>
        </div>
      </div>
    </div>
  </div>

</div>

@push('styles')
<style>
  @media (max-width: 575.98px) {
    .card .card-body .form-label { margin-bottom: .25rem; }
    .btn-group-sm > .btn, .btn-sm { padding: .35rem .5rem; }
  }
</style>
@endpush

@push('scripts')
<script src="{{ asset('assets/js/inventario.js') }}"></script>
@endpush
@endsection
