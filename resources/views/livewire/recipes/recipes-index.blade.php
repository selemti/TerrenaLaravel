@extends('layouts.terrena', ['active' => 'recetas'])
@section('title', 'Recetas')

@section('content')
<div class="container py-3">
  <div class="d-flex align-items-center justify-content-between mb-3">
    <h1 class="h4 mb-0">
      <i class="fa-solid fa-bowl-food me-2"></i> Recetas
    </h1>
    <div class="d-flex gap-2">
      <input type="text" class="form-control form-control-sm" placeholder="Buscar receta..." wire:model.live.debounce.400ms="search">
      <a class="btn btn-success btn-sm" href="{{ url('/recetas/nueva') }}">
        <i class="fa-solid fa-plus me-1"></i> Nueva
      </a>
    </div>
  </div>

  @if(session('ok'))
    <div class="alert alert-success py-1 small">{{ session('ok') }}</div>
  @endif

  <div class="card shadow-sm">
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th style="width:120px">Código</th>
            <th>Nombre</th>
            <th style="width:140px" class="text-end">Rendimiento</th>
            <th style="width:90px">Unidad</th>
            <th style="width:140px" class="text-end">Costo</th>
            <th style="width:140px" class="text-end">Acciones</th>
          </tr>
        </thead>
        <tbody>
          @forelse($recipes as $r)
            <tr>
              <td class="font-monospace">{{ $r->codigo ?? $r->id }}</td>
              <td>{{ $r->nombre }}</td>
              <td class="text-end">
                {{ rtrim(rtrim(number_format($r->rendimiento ?? 1, 4, '.', ''), '0'), '.') }}
              </td>
              <td>{{ $r->unidad ?? 'pz' }}</td>
              <td class="text-end">
                MX$ {{ number_format((float)($r->costo ?? 0), 2) }}
              </td>
              <td class="text-end">
                <a class="btn btn-outline-secondary btn-sm" href="{{ url('/recetas/editar/'.($r->codigo ?? $r->id)) }}">
                  Editar
                </a>
                <button class="btn btn-outline-danger btn-sm"
                        wire:click="confirmDelete({{ $r->id }})">
                  Eliminar
                </button>
              </td>
            </tr>
          @empty
            <tr><td colspan="6" class="text-muted">Sin resultados.</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
    @if(method_exists($recipes, 'links'))
      <div class="card-footer py-2">
        {{ $recipes->links() }}
      </div>
    @endif
  </div>
</div>

{{-- Modal confirmar eliminación --}}
<div class="modal fade @if($confirmingDelete) show d-block @endif"
     tabindex="-1" role="dialog" @if($confirmingDelete) style="background: rgba(0,0,0,.3)" @endif>
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Confirmar</h5>
        <button type="button" class="btn-close" aria-label="Cerrar" wire:click="cancelDelete"></button>
      </div>
      <div class="modal-body">
        ¿Eliminar la receta seleccionada?
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" wire:click="cancelDelete">Cancelar</button>
        <button class="btn btn-danger" wire:click="delete">Eliminar</button>
      </div>
    </div>
  </div>
</div>
@endsection
