@extends('layouts.terrena', ['active' => 'recetas'])
@section('title', 'Conversión de Unidades')

@section('content')
<div class="container py-3">
  <div class="d-flex align-items-center justify-content-between mb-3">
    <h1 class="h4 mb-0">
      <i class="fa-solid fa-right-left me-2"></i> Conversión de Unidades
    </h1>
    <div class="d-flex gap-2">
      <input type="text" class="form-control form-control-sm" placeholder="Buscar..." wire:model.live.debounce.400ms="search">
      <button class="btn btn-success btn-sm" wire:click="new">
        <i class="fa-solid fa-plus me-1"></i> Nuevo
      </button>
    </div>
  </div>

  @if(session('ok'))
    <div class="alert alert-success py-1 small">{{ session('ok') }}</div>
  @endif

  {{-- Formulario (crear/editar) --}}
  @if($showForm ?? false)
  <div class="card shadow-sm mb-3">
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-4">
          <label class="form-label">Unidad origen</label>
          <input type="text" class="form-control @error('u_origen') is-invalid @enderror"
                 wire:model.defer="u_origen" placeholder="Ej. kg">
          @error('u_origen') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-4">
          <label class="form-label">Unidad destino</label>
          <input type="text" class="form-control @error('u_destino') is-invalid @enderror"
                 wire:model.defer="u_destino" placeholder="Ej. g">
          @error('u_destino') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-4">
          <label class="form-label">Factor</label>
          <input type="number" step="any" class="form-control @error('factor') is-invalid @enderror"
                 wire:model.defer="factor" placeholder="Ej. 1000">
          @error('factor') <div class="invalid-feedback">{{ $message }}</div> @enderror
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
            <th>Origen</th>
            <th>Destino</th>
            <th class="text-end" style="width:180px">Factor</th>
            <th class="text-end" style="width:140px">Acciones</th>
          </tr>
        </thead>
        <tbody>
          @forelse($conversions as $conv)
            <tr>
              <td>{{ $conv->u_origen }}</td>
              <td>{{ $conv->u_destino }}</td>
              <td class="text-end">{{ rtrim(rtrim(number_format($conv->factor, 6, '.', ''), '0'), '.') }}</td>
              <td class="text-end">
                <button class="btn btn-outline-secondary btn-sm" wire:click="edit({{ $conv->id }})">Editar</button>
                <button class="btn btn-outline-danger btn-sm" wire:click="confirmDelete({{ $conv->id }})">Eliminar</button>
              </td>
            </tr>
          @empty
            <tr><td colspan="4" class="text-muted">Sin resultados.</td></tr>
          @endforelse
        </tbody>
      </table>
    </div>
    @if(method_exists($conversions, 'links'))
      <div class="card-footer py-2">{{ $conversions->links() }}</div>
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
        ¿Eliminar esta conversión?
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" wire:click="cancelDelete">Cancelar</button>
        <button class="btn btn-danger" wire:click="delete">Eliminar</button>
      </div>
    </div>
  </div>
</div>
@endsection
