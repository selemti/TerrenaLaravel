<div class="container-fluid px-0">
    @if (session('ok'))
      <div class="alert alert-success alert-dismissible fade show" role="alert">
        <i class="fa-solid fa-circle-check me-2"></i>{{ session('ok') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    <div class="row g-3">
      <div class="col-lg-4">
        <div class="card shadow-sm">
          <div class="card-header bg-white">
            <strong>{{ $editId ? 'Editar sucursal' : 'Nueva sucursal' }}</strong>
          </div>
          <div class="card-body">
            <div class="mb-3">
              <label class="form-label">Clave</label>
              <input type="text" class="form-control @error('clave') is-invalid @enderror"
                     wire:model.defer="clave" maxlength="16">
              @error('clave')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="mb-3">
              <label class="form-label">Nombre</label>
              <input type="text" class="form-control @error('nombre') is-invalid @enderror"
                     wire:model.defer="nombre" maxlength="120">
              @error('nombre')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="mb-3">
              <label class="form-label">Ubicación</label>
              <input type="text" class="form-control" wire:model.defer="ubicacion" maxlength="160">
            </div>
            <div class="form-check mb-3">
              <input class="form-check-input" type="checkbox" id="sucursalActiva" wire:model.defer="activo">
              <label class="form-check-label" for="sucursalActiva">Activa</label>
            </div>
          </div>
          <div class="card-footer d-flex gap-2">
            <button class="btn btn-primary flex-grow-1" wire:click="save">
              <i class="fa-regular fa-floppy-disk me-1"></i> Guardar
            </button>
            <button class="btn btn-outline-secondary" wire:click="create">
              <i class="fa-regular fa-circle-xmark me-1"></i> Cancelar
            </button>
          </div>
        </div>
      </div>

      <div class="col-lg-8">
        <div class="card shadow-sm">
          <div class="card-body">
            <div class="row g-2 align-items-end">
              <div class="col-md-8">
                <label class="form-label small text-muted mb-1">Buscar</label>
                <div class="input-group input-group-sm">
                  <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
                  <input type="search" class="form-control" placeholder="Clave, nombre o ubicación"
                         wire:model.live.debounce.400ms="search">
                </div>
              </div>
              <div class="col-md-4 text-md-end">
                <label class="form-label small text-muted mb-1 d-block">&nbsp;</label>
                <button class="btn btn-sm btn-outline-secondary" wire:click="create">
                  <i class="fa-solid fa-plus me-1"></i> Nueva
                </button>
              </div>
            </div>
          </div>
          <div class="table-responsive">
            <table class="table table-striped table-sm align-middle mb-0">
              <thead class="table-light">
              <tr>
                <th>Clave</th>
                <th>Nombre</th>
                <th>Ubicación</th>
                <th class="text-center">Activa</th>
                <th class="text-end">Acciones</th>
              </tr>
              </thead>
              <tbody>
              @forelse($rows as $row)
                <tr>
                  <td class="fw-semibold">{{ $row->clave }}</td>
                  <td>{{ $row->nombre }}</td>
                  <td>{{ $row->ubicacion ?? '—' }}</td>
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
                            onclick="return confirm('¿Eliminar sucursal?')">
                      <i class="fa-regular fa-trash-can"></i>
                    </button>
                  </td>
                </tr>
              @empty
                <tr>
                  <td colspan="5" class="text-center text-muted py-4">Sin registros.</td>
                </tr>
              @endforelse
              </tbody>
            </table>
          </div>
          <div class="card-footer bg-white py-2">
            {{ $rows->links() }}
          </div>
        </div>
      </div>
    </div>
  </div>
