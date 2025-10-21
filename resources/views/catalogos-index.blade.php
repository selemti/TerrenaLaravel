@extends('layouts.terrena')

@php($active = 'config')
@section('title', 'Catálogos - TerrenaPOS')
@section('page-title')
  <i class="fa-solid fa-book"></i> <span class="label">Catálogos del Sistema</span>
@endsection

@section('content')
<div class="dashboard-grid py-3">

  {{-- Descripción --}}
  <div class="alert alert-info mb-4">
    <i class="fa-solid fa-circle-info me-2"></i>
    <strong>Centro de Catálogos:</strong> Gestiona todos los catálogos maestros del sistema.
    Los cambios aquí afectan a todo el sistema.
  </div>
  {{-- Acciones Rápidas --}}
  <div class="row mt-4">
    <div class="col-12" style="margin-bottom: 1.5rem;">
      <div class="card border-0 shadow-sm bg-light">
        <div class="card-body">
          <h6 class="mb-3"><i class="fa-solid fa-bolt me-2"></i>Acciones Rápidas</h6>
          <div class="d-flex flex-wrap gap-2">
            <a href="{{ route('cat.sucursales') }}" class="btn btn-sm btn-outline-primary">
              <i class="fa-solid fa-plus me-1"></i>Nueva Sucursal
            </a>
            <a href="{{ route('cat.almacenes') }}" class="btn btn-sm btn-outline-success">
              <i class="fa-solid fa-plus me-1"></i>Nuevo Almacén
            </a>
            <a href="{{ route('cat.unidades') }}" class="btn btn-sm btn-outline-info">
              <i class="fa-solid fa-plus me-1"></i>Nueva Unidad
            </a>
            <a href="{{ route('cat.proveedores') }}" class="btn btn-sm btn-outline-danger">
              <i class="fa-solid fa-plus me-1"></i>Nuevo Proveedor
            </a>
            <a href="{{ route('dashboard') }}" class="btn btn-sm btn-outline-secondary ms-auto">
              <i class="fa-solid fa-arrow-left me-1"></i>Volver al Dashboard
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Grid de Catálogos --}}
  <div class="row g-4">

    {{-- Sucursales --}}
    <div class="col-12 col-md-6 col-lg-4">
      <div class="card h-100 border-0 shadow-sm hover-shadow">
        <div class="card-body">
          <div class="d-flex align-items-start mb-3">
            <div class="icon-box bg-primary bg-opacity-10 text-primary me-3">
              <i class="fa-solid fa-store fa-2x"></i>
            </div>
            <div class="flex-grow-1">
              <h5 class="card-title mb-1">Sucursales</h5>
              <p class="text-muted small mb-0">Ubicaciones del negocio</p>
            </div>
          </div>
          <div class="d-flex justify-content-between align-items-center mb-3">
            <span class="badge bg-primary bg-opacity-10 text-primary px-3 py-2">
              <i class="fa-solid fa-database me-1"></i>
              <span id="count-sucursales">--</span> registros
            </span>
          </div>
          <a href="{{ route('cat.sucursales') }}" class="btn btn-outline-primary btn-sm w-100">
            <i class="fa-solid fa-arrow-right me-2"></i>Gestionar Sucursales
          </a>
        </div>
      </div>
    </div>

    {{-- Almacenes --}}
    <div class="col-12 col-md-6 col-lg-4">
      <div class="card h-100 border-0 shadow-sm hover-shadow">
        <div class="card-body">
          <div class="d-flex align-items-start mb-3">
            <div class="icon-box bg-success bg-opacity-10 text-success me-3">
              <i class="fa-solid fa-warehouse fa-2x"></i>
            </div>
            <div class="flex-grow-1">
              <h5 class="card-title mb-1">Almacenes</h5>
              <p class="text-muted small mb-0">Ubicaciones de inventario</p>
            </div>
          </div>
          <div class="d-flex justify-content-between align-items-center mb-3">
            <span class="badge bg-success bg-opacity-10 text-success px-3 py-2">
              <i class="fa-solid fa-database me-1"></i>
              <span id="count-almacenes">--</span> registros
            </span>
          </div>
          <a href="{{ route('cat.almacenes') }}" class="btn btn-outline-success btn-sm w-100">
            <i class="fa-solid fa-arrow-right me-2"></i>Gestionar Almacenes
          </a>
        </div>
      </div>
    </div>

    {{-- Unidades de Medida --}}
    <div class="col-12 col-md-6 col-lg-4">
      <div class="card h-100 border-0 shadow-sm hover-shadow">
        <div class="card-body">
          <div class="d-flex align-items-start mb-3">
            <div class="icon-box bg-info bg-opacity-10 text-info me-3">
              <i class="fa-solid fa-ruler fa-2x"></i>
            </div>
            <div class="flex-grow-1">
              <h5 class="card-title mb-1">Unidades de Medida</h5>
              <p class="text-muted small mb-0">UOM del sistema</p>
            </div>
          </div>
          <div class="d-flex justify-content-between align-items-center mb-3">
            <span class="badge bg-info bg-opacity-10 text-info px-3 py-2">
              <i class="fa-solid fa-database me-1"></i>
              <span id="count-unidades">--</span> registros
            </span>
          </div>
          <a href="{{ route('cat.unidades') }}" class="btn btn-outline-info btn-sm w-100">
            <i class="fa-solid fa-arrow-right me-2"></i>Gestionar Unidades
          </a>
        </div>
      </div>
    </div>

    {{-- Conversiones de Unidades --}}
    <div class="col-12 col-md-6 col-lg-4">
      <div class="card h-100 border-0 shadow-sm hover-shadow">
        <div class="card-body">
          <div class="d-flex align-items-start mb-3">
            <div class="icon-box bg-warning bg-opacity-10 text-warning me-3">
              <i class="fa-solid fa-arrows-rotate fa-2x"></i>
            </div>
            <div class="flex-grow-1">
              <h5 class="card-title mb-1">Conversiones UOM</h5>
              <p class="text-muted small mb-0">Factores de conversión</p>
            </div>
          </div>
          <div class="d-flex justify-content-between align-items-center mb-3">
            <span class="badge bg-warning bg-opacity-10 text-warning px-3 py-2">
              <i class="fa-solid fa-calculator me-1"></i>
              Sistema automático
            </span>
          </div>
          <a href="{{ route('cat.uom') }}" class="btn btn-outline-warning btn-sm w-100">
            <i class="fa-solid fa-arrow-right me-2"></i>Gestionar Conversiones
          </a>
        </div>
      </div>
    </div>

    {{-- Proveedores --}}
    <div class="col-12 col-md-6 col-lg-4">
      <div class="card h-100 border-0 shadow-sm hover-shadow">
        <div class="card-body">
          <div class="d-flex align-items-start mb-3">
            <div class="icon-box bg-danger bg-opacity-10 text-danger me-3">
              <i class="fa-solid fa-truck fa-2x"></i>
            </div>
            <div class="flex-grow-1">
              <h5 class="card-title mb-1">Proveedores</h5>
              <p class="text-muted small mb-0">Suppliers del negocio</p>
            </div>
          </div>
          <div class="d-flex justify-content-between align-items-center mb-3">
            <span class="badge bg-danger bg-opacity-10 text-danger px-3 py-2">
              <i class="fa-solid fa-database me-1"></i>
              <span id="count-proveedores">--</span> registros
            </span>
          </div>
          <a href="{{ route('cat.proveedores') }}" class="btn btn-outline-danger btn-sm w-100">
            <i class="fa-solid fa-arrow-right me-2"></i>Gestionar Proveedores
          </a>
        </div>
      </div>
    </div>

    {{-- Políticas de Stock --}}
    <div class="col-12 col-md-6 col-lg-4">
      <div class="card h-100 border-0 shadow-sm hover-shadow">
        <div class="card-body">
          <div class="d-flex align-items-start mb-3">
            <div class="icon-box bg-secondary bg-opacity-10 text-secondary me-3">
              <i class="fa-solid fa-sliders fa-2x"></i>
            </div>
            <div class="flex-grow-1">
              <h5 class="card-title mb-1">Políticas de Stock</h5>
              <p class="text-muted small mb-0">Mínimos y máximos</p>
            </div>
          </div>
          <div class="d-flex justify-content-between align-items-center mb-3">
            <span class="badge bg-secondary bg-opacity-10 text-secondary px-3 py-2">
              <i class="fa-solid fa-chart-line me-1"></i>
              Alertas automáticas
            </span>
          </div>
          <a href="{{ route('cat.stockpolicy') }}" class="btn btn-outline-secondary btn-sm w-100">
            <i class="fa-solid fa-arrow-right me-2"></i>Gestionar Políticas
          </a>
        </div>
      </div>
    </div>

  </div>


</div>

@push('styles')
<style>
  .icon-box {
    width: 60px;
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 12px;
  }

  .hover-shadow {
    transition: all 0.3s ease;
  }

  .hover-shadow:hover {
    transform: translateY(-4px);
    box-shadow: 0 .5rem 1rem rgba(0,0,0,.15) !important;
  }
</style>
@endpush

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', async () => {
  const apiBase = (window.__API_BASE__ || '') + '/api/catalogs';

  try {
    const [sucursales, almacenes, unidades] = await Promise.all([
      fetch(`${apiBase}/sucursales`).then(r => r.json()).catch(() => null),
      fetch(`${apiBase}/almacenes`).then(r => r.json()).catch(() => null),
      fetch(`${apiBase}/unidades?only_count=1`).then(r => r.json()).catch(() => null),
    ]);

    if (sucursales?.ok) {
      document.getElementById('count-sucursales').textContent = sucursales.data?.length ?? 0;
    }

    if (almacenes?.ok) {
      document.getElementById('count-almacenes').textContent = almacenes.data?.length ?? 0;
    }

    if (unidades?.ok) {
      document.getElementById('count-unidades').textContent = unidades.count ?? unidades.data?.length ?? 0;
    } else {
      document.getElementById('count-unidades').textContent = '--';
    }

    document.getElementById('count-proveedores').textContent = '--';
  } catch (err) {
    console.error('Error loading catalog counts:', err);
  }
});
</script>
@endpush
@endsection
