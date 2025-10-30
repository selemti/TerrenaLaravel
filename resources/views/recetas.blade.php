@extends('layouts.terrena')

@section('title', 'Recetas & Costos - TerrenaPOS')
@section('page-title')
  <i class="fa-solid fa-bowl-food"></i> <span class="label">Recetas & Costos</span>
@endsection

@section('content')
<div class="dashboard-grid">

  <div class="container py-3">
    <div class="card shadow-sm border-0 mb-4">
      <div class="card-body">
        <h5 class="card-title"><i class="fa-solid fa-circle-info me-2"></i>Módulo en preparación</h5>
        <p class="text-muted">
          Estamos consolidando el hub de recetas y costeo. Por ahora puedes ingresar directamente a los módulos activos.
        </p>
        <div class="d-flex flex-wrap gap-2">
          <a class="btn btn-outline-primary" href="{{ route('rec.index') }}">
            <i class="fa-solid fa-bowl-food me-1"></i> Editor de recetas
          </a>
          <a class="btn btn-outline-secondary" href="{{ route('cat.unidades') }}">
            <i class="fa-solid fa-ruler me-1"></i> Unidades de medida
          </a>
          <a class="btn btn-outline-secondary" href="{{ route('cat.uom') }}">
            <i class="fa-solid fa-arrows-rotate me-1"></i> Conversiones
          </a>
          <a class="btn btn-outline-secondary disabled" href="#" tabindex="-1" aria-disabled="true">
            <i class="fa-solid fa-plus-minus me-1"></i> Modificadores (próximamente)
          </a>
          <a class="btn btn-outline-secondary disabled" href="#" tabindex="-1" aria-disabled="true">
            <i class="fa-solid fa-sliders me-1"></i> Parámetros de costeo (próximamente)
          </a>
        </div>
        {{-- TODO: enlazar a modificadores / parámetros en Sprint 2.6 --}}
      </div>
    </div>
  </div>
</div>
@endsection
