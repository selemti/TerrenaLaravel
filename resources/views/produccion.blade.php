@extends('layouts.terrena')

@php($active = 'produccion')
@section('title', 'Producción (API)')
@section('page-title')
  <i class="fa-solid fa-industry"></i> Producción (API)
@endsection

@section('content')
<div class="container py-4">
  <div class="card shadow-sm border-0 mb-4">
    <div class="card-body">
      <h5 class="card-title"><i class="fa-solid fa-circle-info me-2"></i>Módulo en preparación</h5>
      <p class="text-muted mb-3">
        El flujo interactivo de producción aún no está disponible. Puedes consumir los endpoints API para automatizaciones o integraciones externas.
      </p>

      <div class="table-responsive">
        <table class="table table-sm align-middle">
          <thead class="table-light">
            <tr>
              <th>Acción</th>
              <th>Método</th>
              <th>Endpoint</th>
              <th>Descripción</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Planificar batch</td>
              <td><code>POST</code></td>
              <td><code>/api/production/batch/{batch_id}/plan</code></td>
              <td>Genera batch a partir de receta y cantidad objetivo.</td>
            </tr>
            <tr>
              <td>Consumir insumos</td>
              <td><code>POST</code></td>
              <td><code>/api/production/batch/{batch_id}/consume</code></td>
              <td>Registra consumo teórico/real de insumos.</td>
            </tr>
            <tr>
              <td>Completar batch</td>
              <td><code>POST</code></td>
              <td><code>/api/production/batch/{batch_id}/complete</code></td>
              <td>Marca órdenes como listas para posteo.</td>
            </tr>
            <tr>
              <td>Postear batch</td>
              <td><code>POST</code></td>
              <td><code>/api/production/batch/{batch_id}/post</code></td>
              <td>Genera movimientos de inventario (insumos y PT).</td>
            </tr>
          </tbody>
        </table>
      </div>

      <button class="btn btn-secondary" disabled>
        <i class="fa-solid fa-hammer me-1"></i> Flujo interactivo próximamente
      </button>
    </div>
  </div>

  <div class="alert alert-info">
    Los endpoints requieren autenticación Sanctum y permisos de producción.
    {{-- TODO: Implementar Livewire interactivo en Sprint 2.7 --}}
  </div>
</div>
@endsection
