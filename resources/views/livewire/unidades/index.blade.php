@extends('layouts.terrena', ['active' => 'dashboard'])
@section('title', 'Unidades de medida')

@section('content')
<div class="content-wrapper px-3 py-3">

  <div class="d-flex align-items-center justify-content-between mb-3">
    <h1 class="page-title"><i class="fa-solid fa-ruler me-2"></i> Unidades de medida</h1>
    <div class="d-flex gap-2">
      <input type="search" class="form-control" placeholder="Buscar..."
             wire:model.live.debounce.300ms="search" style="max-width: 260px">
      <button class="btn btn-primary" wire:click="create">
        <i class="fa-solid fa-plus me-1"></i> Nueva
      </button>
    </div>
  </div>

  @if (session('ok'))
    <div class="alert alert-success py-2">{{ session('ok') }}</div>
  @endif

  <div class="card shadow-sm">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th style="width:120px">Clave</th>
            <th>Nombre</th>
            <th style="width:120px">Activo</th>
            <th style="width:160px"></th>
          </tr>
        </thead>
        <tbody>
          @forelse($rows as $r)
            <tr>
              <td class="fw-semibold">{{ $r->clave }}</td>
              <td>{{ $r->nombre }}</td>
              <td>{!! $r->activo ? '<span class="badge text-bg-success">Sí</span>' : '<span class="badge text-bg-secondary">No</span>' !!}</td>
              <td class="text-end">
                <button class="btn btn-sm btn-outline-primary" wire:click="edit({{ $r->id }})">Editar</button>
                <button class="btn btn-sm btn-outline-danger" wire:click="delete({{ $r->id }})"
                        onclick="return confirm('¿Eliminar unidad?')">Borrar</button>
              </td>
            </tr>
          @empty
            <tr><td colspan="4" class="text-center text-muted py-4">Sin resultados</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
    <div class="card-body">{{ $rows->links() }}</div>
  </div>

</div>

{{-- Modal Bootstrap (wire:ignore.self para que Livewire no lo re-renderice completo) --}}
<div class="modal fade" id="unidadModal" tabindex="-1" aria-hidden="true" wire:ignore.self>
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">{{ $editId ? 'Editar unidad' : 'Nueva unidad' }}</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="mb-3">
          <label class="form-label">Clave</label>
          <input type="text" class="form-control @error('clave') is-invalid @enderror"
                 wire:model.live="clave" maxlength="16">
          @error('clave')<div class="invalid-feedback">{{ $message }}</div>@enderror
        </div>
        <div class="mb-3">
          <label class="form-label">Nombre</label>
          <input type="text" class="form-control @error('nombre') is-invalid @enderror"
                 wire:model.live="nombre" maxlength="64">
          @error('nombre')<div class="invalid-feedback">{{ $message }}</div>@enderror
        </div>
        <div class="form-check">
          <input class="form-check-input" type="checkbox" id="chkActivo" wire:model.live="activo">
          <label class="form-check-label" for="chkActivo">Activo</label>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
        <button class="btn btn-primary" wire:click="save">Guardar</button>
      </div>
    </div>
  </div>
</div>

@push('scripts')
<script>
  // Inicializa Modal cuando Bootstrap está disponible
  function initUnidadModal() {
    const el = document.getElementById('unidadModal');
    if (!el || !window.bootstrap?.Modal) return;
    if (!window.__unidadModal) window.__unidadModal = new window.bootstrap.Modal(el);
  }
  document.addEventListener('DOMContentLoaded', initUnidadModal);
  document.addEventListener('livewire:initialized', initUnidadModal);
  document.addEventListener('livewire:navigated', initUnidadModal);

  window.addEventListener('show-modal', () => window.__unidadModal?.show());
  window.addEventListener('hide-modal', () => window.__unidadModal?.hide());
</script>
@endpush
@endsection
