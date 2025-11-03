<div>
    @if (session('ok'))
      <div class="alert alert-success alert-dismissible fade show position-fixed top-0 end-0 m-3" role="alert" style="z-index:1055;">
        <i class="fa-solid fa-circle-check me-2"></i>{{ session('ok') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    <div class="card shadow-sm border-0">
      <div class="card-body">
        <div class="row g-2 align-items-end">
          <div class="col-md-6">
            <label class="form-label small text-muted mb-1">Búsqueda</label>
            <div class="input-group input-group-sm">
              <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
              <input type="search" class="form-control" placeholder="Clave o nombre" wire:model.live.debounce.400ms="search">
            </div>
          </div>
          <div class="col-md-3">
            <label class="form-label small text-muted mb-1">Categoría</label>
            <select class="form-select form-select-sm" wire:model.live="categoria">
              <option value="">Todas</option>
              <option value="BASE">Base (KG, L, PZ)</option>
              <option value="COCINA">Cocina (Recetas)</option>
              <option value="COMPRA">Compra (Empaques)</option>
              <option value="PORCION">Porción (Servicio)</option>
            </select>
          </div>
          <div class="col-md-3 text-md-end">
            <label class="form-label small text-muted mb-1">&nbsp;</label>
            <button class="btn btn-sm btn-primary w-100" wire:click="createNew">
              <i class="fa-solid fa-plus me-1"></i> Nueva unidad
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
            <th>Categoría</th>
            <th class="text-center">Activa</th>
            <th class="text-end">Acciones</th>
          </tr>
          </thead>
          <tbody>
          @forelse($rows as $row)
            <tr>
              <td class="fw-semibold">{{ $row->clave }}</td>
              <td>{{ $row->nombre }}</td>
              <td>
                @if($row->categoria)
                  @php
                    $badgeClass = match($row->categoria) {
                      'BASE' => 'bg-primary',
                      'COCINA' => 'bg-info',
                      'COMPRA' => 'bg-success',
                      'PORCION' => 'bg-warning text-dark',
                      default => 'bg-secondary'
                    };
                  @endphp
                  <span class="badge {{ $badgeClass }}">{{ $row->categoria }}</span>
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
                        onclick="return confirm('¿Eliminar unidad?')">
                  <i class="fa-regular fa-trash-can"></i>
                </button>
              </td>
            </tr>
          @empty
            <tr>
              <td colspan="5" class="text-center text-muted py-4">Sin resultados.</td>
            </tr>
          @endforelse
          </tbody>
        </table>
      </div>
      <div class="card-footer bg-white py-2">
        {{ $rows->links() }}
      </div>
    </div>

    {{-- Modal de creación / edición --}}
    <div class="modal fade" id="modalUnidad" tabindex="-1" aria-labelledby="modalUnidadLabel" aria-hidden="true" wire:ignore.self>
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
          <form wire:submit.prevent="save">
            <div class="modal-header bg-primary bg-opacity-10">
              <h5 class="modal-title" id="modalUnidadLabel">
                <i class="fa-solid fa-ruler me-2"></i>
                {{ $editingId ? 'Editar unidad' : 'Nueva unidad' }}
              </h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
            </div>
            <div class="modal-body">
              <div class="mb-3">
                <label class="form-label">Clave <span class="text-danger">*</span></label>
                <input type="text" class="form-control @error('form.clave') is-invalid @enderror"
                       wire:model.defer="form.clave" maxlength="16" required>
                @error('form.clave')<div class="invalid-feedback">{{ $message }}</div>@enderror
                <small class="form-text text-muted">
                  <i class="fa-solid fa-lightbulb me-1"></i>
                  Código único para identificar la unidad (ej: KG, L, PZ, TAZA)
                </small>
              </div>
              <div class="mb-3">
                <label class="form-label">Nombre <span class="text-danger">*</span></label>
                <input type="text" class="form-control @error('form.nombre') is-invalid @enderror"
                       wire:model.defer="form.nombre" maxlength="64" required>
                @error('form.nombre')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="mb-3">
                <label class="form-label">Categoría <span class="text-danger">*</span></label>
                <select class="form-select @error('form.categoria') is-invalid @enderror" wire:model.defer="form.categoria" required>
                  <option value="">-- Seleccione --</option>
                  <option value="BASE">Base (Inventario normalizado)</option>
                  <option value="COCINA">Cocina (Recetas)</option>
                  <option value="COMPRA">Compra (Empaques)</option>
                  <option value="PORCION">Porción (Servicio)</option>
                </select>
                @error('form.categoria')<div class="invalid-feedback">{{ $message }}</div>@enderror
                <small class="form-text text-muted">
                  <i class="fa-solid fa-circle-info me-1"></i>
                  <strong>BASE:</strong> Solo KG, L, PZ.
                  <strong>COCINA:</strong> Para recetas.
                  <strong>COMPRA:</strong> Empaques.
                  <strong>PORCION:</strong> Servicio.
                </small>
              </div>
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="unidadActiva" wire:model.defer="form.activo">
                <label class="form-check-label" for="unidadActiva">Unidad activa</label>
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
    const modalEl = document.getElementById('modalUnidad');
    const modal = new bootstrap.Modal(modalEl);

    document.querySelectorAll('.alert-dismissible').forEach(alert => {
      setTimeout(() => {
        const instance = bootstrap.Alert.getOrCreateInstance(alert);
        instance.close();
      }, 3000);
    });

    Livewire.on('toggle-unidad-modal', (payload) => {
      const open = typeof payload === 'object' && payload !== null && 'open' in payload ? payload.open : !!payload;
      open ? modal.show() : modal.hide();
    });

    modalEl.addEventListener('hidden.bs.modal', () => {
      Livewire.dispatch('unidad-modal-closed');
    });
  });
</script>
@endpush
