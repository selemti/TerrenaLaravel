<div>
    @if (session('ok'))
      <div class="alert alert-success alert-dismissible fade show position-fixed top-0 end-0 m-3" role="alert" style="z-index:1055;">
        <i class="fa-solid fa-circle-check me-2"></i>{{ session('ok') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    {{-- Alerta de POS Locations no vinculadas --}}
    @if($unlinkedPosLocations->isNotEmpty())
      <div class="alert alert-warning alert-dismissible fade show shadow-sm mb-3" role="alert">
        <div class="d-flex align-items-start">
          <div class="flex-shrink-0">
            <i class="fa-solid fa-link-slash fa-2x text-warning me-3"></i>
          </div>
          <div class="flex-grow-1">
            <h6 class="alert-heading mb-2">
              <i class="fa-solid fa-cash-register me-1"></i>
              Locations del POS sin vincular ({{ $unlinkedPosLocations->count() }})
            </h6>
            <p class="mb-3 small">
              Se detectaron <strong>{{ $unlinkedPosLocations->count() }}</strong> ubicaciones (locations) en el sistema POS que aún no están vinculadas a ninguna sucursal.
              Estas locations fueron creadas en terminales del POS Floreant pero no tienen correspondencia en el catálogo de sucursales.
            </p>
            <div class="list-group list-group-flush">
              @foreach($unlinkedPosLocations as $unlinked)
                <div class="list-group-item list-group-item-warning px-0 py-2 border-0">
                  <div class="row align-items-center g-2">
                    <div class="col-md-4">
                      <span class="badge bg-dark me-2">
                        <i class="fa-solid fa-location-dot me-1"></i>{{ $unlinked['location'] }}
                      </span>
                      <small class="text-muted">
                        ({{ $unlinked['terminal_count'] }} {{ $unlinked['terminal_count'] === 1 ? 'terminal' : 'terminales' }})
                      </small>
                    </div>
                    <div class="col-md-8 text-md-end">
                      <button class="btn btn-sm btn-success me-1"
                              wire:click="linkPosLocation('{{ $unlinked['location'] }}')"
                              title="Crear sucursal automáticamente">
                        <i class="fa-solid fa-wand-magic-sparkles me-1"></i>
                        Vincular automáticamente
                      </button>
                      <button class="btn btn-sm btn-outline-success"
                              wire:click="createWithPosLocation('{{ $unlinked['location'] }}')"
                              title="Crear sucursal con datos personalizados">
                        <i class="fa-solid fa-link me-1"></i>
                        Vincular manualmente
                      </button>
                    </div>
                  </div>
                </div>
              @endforeach
            </div>
            <hr class="my-2">
            <p class="mb-0 small">
              <i class="fa-solid fa-lightbulb me-1 text-warning"></i>
              <strong>Recomendación:</strong> Usa "Vincular automáticamente" para crear rápidamente una sucursal con nombre sugerido,
              o "Vincular manualmente" si prefieres personalizar el nombre y otros datos antes de guardar.
            </p>
          </div>
        </div>
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
              <input type="search" class="form-control" placeholder="Clave, nombre, ubicación o POS"
                     wire:model.live.debounce.400ms="search">
            </div>
          </div>
          <div class="col-md-4 text-md-end">
            <label class="form-label small text-muted mb-1 d-block">&nbsp;</label>
            <button class="btn btn-sm btn-primary" wire:click="create">
              <i class="fa-solid fa-plus me-1"></i> Nueva sucursal
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
            <th>POS Location</th>
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
              <td>
                @if($row->pos_location)
                  <span class="badge bg-info">
                    <i class="fa-solid fa-cash-register me-1"></i>{{ $row->pos_location }}
                  </span>
                  <small class="text-muted ms-1">({{ $row->terminales->count() }} terminales)</small>
                @else
                  <span class="text-muted">—</span>
                @endif
              </td>
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

    <div class="modal fade" id="modalSucursal" tabindex="-1" aria-labelledby="modalSucursalLabel" aria-hidden="true" wire:ignore.self>
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
          <form wire:submit.prevent="save">
            <div class="modal-header bg-primary bg-opacity-10">
              <h5 class="modal-title" id="modalSucursalLabel">
                <i class="fa-solid fa-store me-2"></i>
                {{ $editId ? 'Editar sucursal' : 'Nueva sucursal' }}
              </h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
            </div>
            <div class="modal-body">
              @if($editId)
              <div class="mb-3">
                <label class="form-label">Clave</label>
                <input type="text" class="form-control @error('clave') is-invalid @enderror"
                       wire:model.defer="clave" maxlength="16">
                @error('clave')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              @else
              <div class="alert alert-info mb-3">
                <i class="fa-solid fa-wand-magic-sparkles me-2"></i>
                <small>La <strong>clave</strong> se generará automáticamente basándose en el nombre de la sucursal.</small>
              </div>
              @endif
              <div class="mb-3">
                <label class="form-label">Nombre</label>
                <input type="text" class="form-control @error('nombre') is-invalid @enderror"
                       wire:model.defer="nombre" maxlength="120" required>
                @error('nombre')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="mb-3">
                <label class="form-label">Ubicación</label>
                <input type="text" class="form-control" wire:model.defer="ubicacion" maxlength="160">
              </div>
              <div class="mb-3">
                <label class="form-label">
                  POS Location
                  <i class="fa-solid fa-circle-info text-muted ms-1" data-bs-toggle="tooltip"
                     title="Mapear esta sucursal con una ubicación de terminal POS"></i>
                </label>
                <select class="form-select @error('pos_location') is-invalid @enderror" wire:model.defer="pos_location">
                  <option value="">— Sin mapear —</option>
                  @foreach($posLocations as $location)
                    <option value="{{ $location }}">
                      {{ $location }}
                      ({{ \App\Models\Catalogs\Sucursal::getTerminalCountByLocation($location) }} terminales)
                    </option>
                  @endforeach
                </select>
                @error('pos_location')<div class="invalid-feedback">{{ $message }}</div>@enderror
                <small class="form-text text-muted">
                  <i class="fa-solid fa-lightbulb me-1"></i>
                  Selecciona la ubicación del POS (sistema Floreant) que corresponde a esta sucursal
                </small>
              </div>
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="sucursalActiva" wire:model.defer="activo">
                <label class="form-check-label" for="sucursalActiva">Sucursal activa</label>
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
    const modalEl = document.getElementById('modalSucursal');
    const modal = new bootstrap.Modal(modalEl);

    document.querySelectorAll('.alert-dismissible').forEach(alert => {
      setTimeout(() => {
        const instance = bootstrap.Alert.getOrCreateInstance(alert);
        instance.close();
      }, 3000);
    });

    Livewire.on('toggle-sucursal-modal', (payload) => {
      const open = typeof payload === 'object' && payload !== null && 'open' in payload ? payload.open : !!payload;
      open ? modal.show() : modal.hide();
    });

    modalEl.addEventListener('hidden.bs.modal', () => {
      Livewire.dispatch('sucursal-modal-closed');
    });
  });
</script>
@endpush
