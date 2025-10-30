@extends('layouts.terrena')

@section('title', 'Módulo reubicado')
@section('page-title')
  <i class="fa-solid fa-clock-rotate-left me-2"></i> Modo Histórico Ligero
@endsection

@section('content')
<div class="container py-4">
  <div class="alert alert-warning d-flex align-items-center" role="alert">
    <i class="fa-solid fa-triangle-exclamation fa-lg me-3"></i>
    <div>
      Este módulo fue reubicado o está en pausa mientras terminamos la migración.
      Los accesos legacy se auditan y redirigen automáticamente.
    </div>
  </div>

  <div class="row g-4">
    <div class="col-lg-8">
      <div class="card shadow-sm border-0 h-100">
        <div class="card-body">
          <h5 class="card-title">Módulo reubicado / en pausa</h5>
          <p class="text-muted mb-4">
            Usa los accesos vigentes para continuar con las operaciones. Cualquier intento
            de entrar por rutas antiguas queda registrado como evento LEGACY_REDIRECT.
          </p>
          <div class="d-flex flex-wrap gap-2">
            <a href="{{ route('inventory.items.new') }}" class="btn btn-primary">
              <i class="fa-solid fa-box-open me-1"></i> Alta de Insumos
            </a>
            <a href="{{ route('inventory.items.index') }}" class="btn btn-outline-primary">
              <i class="fa-solid fa-boxes-stacked me-1"></i> Catálogo de Inventario
            </a>
            <a href="{{ route('audit.log.index') }}" class="btn btn-outline-secondary">
              <i class="fa-solid fa-clipboard-list me-1"></i> Auditoría Operativa
            </a>
          </div>
        </div>
      </div>
    </div>

    <div class="col-lg-4">
      <div class="card shadow-sm border-0 h-100">
        <div class="card-body">
          <h6 class="text-uppercase text-muted mb-3">Notas operativas</h6>
          <ul class="list-unstyled small mb-0">
            <li class="mb-2">
              <i class="fa-solid fa-circle-check text-success me-2"></i>
              Los intentos fuera del catálogo generan LEGACY_MISSING y redirigen a esta pantalla.
            </li>
            <li class="mb-2">
              <i class="fa-solid fa-circle-info text-primary me-2"></i>
              Mantén la documentación actualizada con los enlaces activos.
            </li>
            <li>
              <i class="fa-solid fa-clock-rotate-left text-warning me-2"></i>
              {{-- TODO: definir fecha de retiro definitivo del modo histórico --}}
              Comunica cualquier dependencia pendiente antes del retiro.
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</div>
@endsection
