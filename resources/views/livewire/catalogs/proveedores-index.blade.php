<div>
    @if ($tableNotice !== '')
      <div class="alert alert-warning alert-dismissible fade show position-fixed top-0 end-0 m-3" role="alert" style="z-index:1055;">
        <i class="fa-solid fa-triangle-exclamation me-2"></i>{{ $tableNotice }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    @if (session('ok'))
      <div class="alert alert-success alert-dismissible fade show position-fixed top-0 end-0 m-3" role="alert" style="z-index:1055; margin-top:4rem;">
        <i class="fa-solid fa-circle-check me-2"></i>{{ session('ok') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif
    @if (session('warn'))
      <div class="alert alert-warning alert-dismissible fade show position-fixed top-0 end-0 m-3" role="alert" style="z-index:1055; margin-top:8rem;">
        <i class="fa-solid fa-circle-info me-2"></i>{{ session('warn') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    <div class="card shadow-sm border-0">
      <div class="card-body">
        <div class="row g-2 align-items-end">
          <div class="col-md-8">
            <label class="form-label small text-muted mb-1">Buscar</label>
            <div class="input-group input-group-sm">
              <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
              <input type="search" class="form-control" placeholder="RFC, nombre o correo"
                     wire:model.live.debounce.400ms="search">
            </div>
          </div>
          <div class="col-md-4 text-md-end">
            <label class="form-label small text-muted mb-1 d-block">&nbsp;</label>
            <button class="btn btn-sm btn-primary" wire:click="create" @disabled(! $tableReady)>
              <i class="fa-solid fa-plus me-1"></i> Nuevo proveedor
            </button>
          </div>
        </div>
      </div>
      <div class="table-responsive">
        <table class="table table-striped table-sm align-middle mb-0">
          <thead class="table-light">
          <tr>
            <th>RFC</th>
            <th>Nombre</th>
            <th>Teléfono</th>
            <th>Correo</th>
            <th class="text-center">Activo</th>
            <th class="text-end">Acciones</th>
          </tr>
          </thead>
          <tbody>
          @forelse($rows as $row)
            <tr>
              <td class="fw-semibold">{{ $row->rfc }}</td>
              <td>{{ $row->nombre }}</td>
              <td>{{ $row->telefono ?? '—' }}</td>
              <td>{{ $row->email ?? '—' }}</td>
              <td class="text-center">
                @if($row->activo)
                  <span class="badge bg-success">Sí</span>
                @else
                  <span class="badge bg-secondary">No</span>
                @endif
              </td>
              <td class="text-end">
                <button class="btn btn-sm btn-outline-primary me-1" wire:click="edit({{ $row->id }})">
                  <i class="fa-regular fa-pen-to-square"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger"
                        wire:click="delete({{ $row->id }})"
                        onclick="return confirm('¿Eliminar proveedor?')">
                  <i class="fa-regular fa-trash-can"></i>
                </button>
              </td>
            </tr>
          @empty
            <tr>
              <td colspan="6" class="text-center text-muted py-4">Sin registros.</td>
            </tr>
          @endforelse
          </tbody>
        </table>
      </div>
      <div class="card-footer bg-white py-2">
        {{ $rows->links() }}
      </div>
    </div>

    {{-- Modal --}}
    <div class="modal fade" id="modalProveedor" tabindex="-1" aria-labelledby="modalProveedorLabel" aria-hidden="true" wire:ignore.self>
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
          <form wire:submit.prevent="save">
            <div class="modal-header bg-primary bg-opacity-10">
              <h5 class="modal-title" id="modalProveedorLabel">
                <i class="fa-solid fa-truck-field me-2"></i>
                {{ $editId ? 'Editar proveedor' : 'Nuevo proveedor' }}
              </h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
            </div>
            <div class="modal-body">
              <div class="mb-3">
                <label class="form-label">RFC</label>
                <input type="text" class="form-control @error('rfc') is-invalid @enderror"
                       wire:model.defer="rfc" maxlength="20">
                @error('rfc')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="mb-3">
                <label class="form-label">Nombre</label>
                <input type="text" class="form-control @error('nombre') is-invalid @enderror"
                       wire:model.defer="nombre" maxlength="120">
                @error('nombre')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="mb-3">
                <label class="form-label">Teléfono</label>
                <input type="text" class="form-control" wire:model.defer="telefono" maxlength="30">
              </div>
              <div class="mb-3">
                <label class="form-label">Correo</label>
                <input type="email" class="form-control @error('email') is-invalid @enderror"
                       wire:model.defer="email" maxlength="120">
                @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="proveedorActivo" wire:model.defer="activo">
                <label class="form-check-label" for="proveedorActivo">Proveedor activo</label>
              </div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal" wire:click="closeModal">
                Cancelar
              </button>
              <button type="submit" class="btn btn-primary">
                <i class="fa-regular fa-floppy-disk me-1"></i> Guardar cambios
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
</div>

@push('scripts')
<script>
  document.addEventListener('DOMContentLoaded', () => {
    if (!window.bootstrap) return;
    const modalEl = document.getElementById('modalProveedor');
    const modal = new bootstrap.Modal(modalEl);

    document.querySelectorAll('.alert-dismissible').forEach(alert => {
      setTimeout(() => {
        const instance = bootstrap.Alert.getOrCreateInstance(alert);
        instance.close();
      }, 3500);
    });

    Livewire.on('toggle-proveedor-modal', (payload) => {
      const open = typeof payload === 'object' && payload !== null && 'open' in payload ? payload.open : !!payload;
      open ? modal.show() : modal.hide();
    });

    modalEl.addEventListener('hidden.bs.modal', () => {
      Livewire.dispatch('proveedor-modal-closed');
    });
  });
</script>
@endpush
