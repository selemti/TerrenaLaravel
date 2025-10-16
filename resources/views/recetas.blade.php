@extends('layouts.terrena')

@section('title', 'Recetas & Costos - TerrenaPOS')
@section('page-title')
  <i class="fa-solid fa-bowl-food"></i> <span class="label">Recetas & Costos</span>
@endsection

@section('content')
<div class="dashboard-grid">

  <div class="container py-3" id="recetas-root">
    <div class="row g-3">
      
      {{-- Costeo de platillos --}}
      <div class="col-12 col-md-6 col-lg-4">
        <a class="text-decoration-none" href="{{ url('/recipes') }}">
          <div class="card h-100 shadow-sm">
            <div class="card-body">
              <h5 class="card-title">
                <i class="fa-solid fa-weight-scale me-2"></i>Costeo de platillos
              </h5>
              <p class="text-muted small mb-0">
                Crear/editar recetas, ingredientes, modificadores y costos (WAC, promedio).
              </p>
            </div>
          </div>
        </a>
      </div>

      {{-- Unidades de medida --}}
      <div class="col-12 col-md-6 col-lg-4">
        <a class="text-decoration-none" href="{{ url('/catalogos/unidades') }}">
          <div class="card h-100 shadow-sm">
            <div class="card-body">
              <h5 class="card-title">
                <i class="fa-solid fa-weight-scale me-2"></i> Unidades de medida
              </h5>
              <p class="text-muted small mb-0">
                Catálogo de unidades base y equivalencias (g, kg, ml, L, porción, etc.).
              </p>
            </div>
          </div>
        </a>
      </div>

      {{-- Conversiones --}}
      <div class="col-12 col-md-6 col-lg-4">
        <a class="text-decoration-none" href="{{ url('/catalogos/uom') }}">
          <div class="card h-100 shadow-sm">
            <div class="card-body">
              <h5 class="card-title">
                <i class="fa-solid fa-arrows-rotate me-2"></i> Conversiones
              </h5>
              <p class="text-muted small mb-0">
                Reglas de conversión entre unidades (ej. 1 caja = 12 piezas = 2.4 kg).
              </p>
            </div>
          </div>
        </a>
      </div>

      {{-- Modificadores --}}
      <div class="col-12 col-md-6 col-lg-4">
        <a class="text-decoration-none" href="{{ url('/recetas/modificadores') }}">
          <div class="card h-100 shadow-sm">
            <div class="card-body">
              <h5 class="card-title">
                <i class="fa-solid fa-plus-minus me-2"></i> Modificadores
              </h5>
              <p class="text-muted small mb-0">
                Grupos (obligatorios/opcionales), costos, impacto de inventario y sub-recetas.
              </p>
            </div>
          </div>
        </a>
      </div>

      {{-- Parámetros de costeo --}}
      <div class="col-12 col-md-6 col-lg-4">
        <a class="text-decoration-none" href="{{ url('/recetas/parametros') }}">
          <div class="card h-100 shadow-sm">
            <div class="card-body">
              <h5 class="card-title">
                <i class="fa-solid fa-sliders me-2"></i> Parámetros de costeo
              </h5>
              <p class="text-muted small mb-0">
                IVA/impuestos (si aplica), reglas de redondeo, márgenes objetivo.
              </p>
            </div>
          </div>
        </a>
      </div>

    </div>
  </div>

</div>
@endsection