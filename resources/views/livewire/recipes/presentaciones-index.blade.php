@extends('layouts.terrena', ['active' => 'recetas'])
@section('title', 'Presentaciones')

@section('content')
<div class="container py-3">
  <div class="d-flex align-items-center justify-content-between mb-3">
    <h1 class="h4 mb-0">
      <i class="fa-solid fa-mug-hot me-2"></i> Presentaciones
    </h1>
    <div class="d-flex gap-2">
      <input type="text" class="form-control form-control-sm" placeholder="Buscar..." wire:model.live.debounce.400ms="search">
      <button class="btn btn-success btn-sm" wire:click="new">
        <i class="fa-solid fa-plus me-1"></i> Nueva
      </button>
    </div>
  </div>

  @if(session('ok'))
    <div class="alert alert-success py-1 small">{{ session('ok') }}</div>
  @endif

  {{-- Formulario crear/editar --}}
  @if($showForm ?? false)
  <div class="card shadow-sm mb-3">
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-5">
          <label class="form-label">Producto</label>
          <input type="text" class="form-control @error('producto') is-invalid @enderror"
                 wire:model.defer="producto" placeholder="Ej. Café Latte">
          @error('producto') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Tamaño</label>
          <input type="text" class="form-control @error('tamano') is-invalid @enderror"
                 wire:model.defer="tamano" placeholder="12oz">
          @error('tamano') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-2">
          <label class="form-label">Unidad</label>
          <input type="text" class="form-control @error('unidad') is-invalid @enderror"
                 wire:model.defer="unidad" placeholder="pz">
          @error('unidad') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-2">
          <label class="form-label">Precio</label>
          <input type="number" step="any" class="form-control @error('precio') is-invalid @enderror"
                 wire:model.defer="precio" placeholder="0.00">
          @error('precio') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-12 d-flex justify-content-end gap-2">
          <button class="btn btn-secondary" wire:click="cancel"><i class="fa-solid fa-xmark me-1"></i> Cancelar</button>
          <button class="btn btn-primary" wire:click="save"><i class="fa-regular fa-floppy-disk me-1"></i> Guardar</button>
        </div>
      </div>
    </div>
  </div>
  @endif

  {{-- Tabla --}}
  <div class="card shadow-sm">
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th>Producto</th>
            <th style="width:120px">Tamaño</th>
            <th style="width:100px">Unidad</th>
            <th style="width:140px" class="text-end">Precio</th>
            <th style="width:140px" class="text-end">Acciones</th>
          </tr>
        </thead>
        <tbody>
          @forelse($presentations as $p)
            <tr>
              <td>{{ $p->producto }}</td>
              <td>{{ $p->tamano }}</td>
              <td>{{ $p->unidad }}</td>
              <td class="text-end">MX$ {{ number_format((float)($p->precio ?? 0), 2) }}</td>
              <td class="text-end">
                <button class="btn btn-outline-secondary btn-sm" wire:click="edit({{ $p->id }})">Editar</button>
                <button class="btn btn-outline-danger btn-sm" wire:click="confirmDelete({{ $p->id }})">Eliminar</button>
              </td>
            </tr>
          @empty
            <tr><td colspan="5" class="text-muted">Sin resultados.</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
    @if(method_exists($presentations, 'links'))
      <div class="card-footer py-2">{{ $presentations->links() }}</div>
    @endif
  </div>
</div>

{{-- Modal confirmar eliminación --}}
<div class="modal fade @if($confirmingDelete) show d-block @endif"
     tabindex="-1" role="dialog" @if($confirmingDelete) style="background: rgba(0,0,0,.3)" @endif>
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header"><h5 class="modal-title">Confirmar</h5>
        <button type="button" class="btn-close" aria-label="Cerrar" wire:click="cancelDelete"></button>
      </div>
      <div class="modal-body">
        ¿Eliminar la presentación seleccionada?
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" wire:click="cancelDelete">Cancelar</button>
        <button class="btn btn-danger" wire:click="delete">Eliminar</button>
      </div>
    </div>
  </div>
</div>
@endsection
