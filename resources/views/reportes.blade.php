@extends('layouts.terrena')

@php($active = 'reportes')
@section('title', 'Reportes (en preparación)')
@section('page-title')
  <i class="fa-solid fa-chart-line"></i> Reportes
@endsection

@section('content')
<div class="container py-4">
  <div class="card border-0 shadow-sm">
    <div class="card-body">
      <h5 class="card-title"><i class="fa-solid fa-circle-info me-2"></i>Módulo en preparación</h5>
      <p class="text-muted">
        Estamos construyendo el tablero consolidado de reportes. Puedes consultar los KPIs disponibles desde el dashboard principal o descargar información directamente desde el módulo de inventario.
      </p>
      {{-- TODO: enlazar a dashboard de reportes en Sprint 2.6 --}}
      <a href="{{ route('dashboard') }}" class="btn btn-outline-primary">
        <i class="fa-solid fa-desktop me-1"></i> Ir al dashboard principal
      </a>
    </div>
  </div>
</div>
@endsection
