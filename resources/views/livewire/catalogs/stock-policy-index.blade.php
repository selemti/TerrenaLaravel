<div>
    @if (session('ok'))
      <div class="alert alert-success alert-dismissible fade show position-fixed top-0 end-0 m-3" role="alert" style="z-index:1055;">
        <i class="fa-solid fa-circle-check me-2"></i>{{ session('ok') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    <div class="card shadow-sm border-0">
      <div class="card-body">
        <div class="d-flex flex-wrap align-items-end gap-2">
          <div class="flex-grow-1">
            <label class="form-label small text-muted mb-1">Buscar</label>
            <div class="input-group input-group-sm">
              <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
              <input type="search" class="form-control" placeholder="Artículo o sucursal"
                     wire:model.live.debounce.400ms="search">
            </div>
          </div>
          <div>
            <label class="form-label small text-muted mb-1 d-block">&nbsp;</label>
            <button class="btn btn-sm btn-primary" wire:click="create">
              <i class="fa-solid fa-plus me-1"></i> Nueva política
            </button>
          </div>
        </div>
      </div>
      <div class="table-responsive">
        <table class="table table-striped table-sm align-middle mb-0">
          <thead class="table-light">
          <tr>
            <th>Artículo</th>
            <th>Sucursal</th>
            <th class="text-end">Mín</th>
            <th class="text-end">Máx</th>
            <th class="text-end">Reorden</th>
            <th class="text-center">Activo</th>
            <th class="text-end">Acciones</th>
          </tr>
          </thead>
          <tbody>
          @forelse($rows as $row)
            <tr>
              <td>{{ $row->item_name }}</td>
              <td>{{ $row->sucursal_name }}</td>
              <td class="text-end">{{ number_format($row->min_qty, 2) }}</td>
              <td class="text-end">{{ number_format($row->max_qty, 2) }}</td>
              <td class="text-end">{{ number_format($row->reorder_qty, 2) }}</td>
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
                        onclick="return confirm('¿Eliminar política?')">
                  <i class="fa-regular fa-trash-can"></i>
                </button>
              </td>
            </tr>
          @empty
            <tr>
              <td colspan="7" class="text-center text-muted py-4">Sin registros.</td>
            </tr>
          @endforelse
          </tbody>
        </table>
      </div>
      <div class="card-footer bg-white py-2">
        {{ $rows->links() }}
      </div>
    </div>

    <div class="modal fade" id="modalStock" tabindex="-1" aria-labelledby="modalStockLabel" aria-hidden="true" wire:ignore.self>
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
          <form wire:submit.prevent="save">
            <div class="modal-header bg-primary bg-opacity-10">
              <h5 class="modal-title" id="modalStockLabel">
                <i class="fa-solid fa-sliders me-2"></i>
                {{ $editId ? 'Editar política' : 'Nueva política' }}
              </h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
            </div>
            <div class="modal-body">
              <div class="mb-3">
                <label class="form-label">Artículo</label>
                <select class="form-select @error('item_id') is-invalid @enderror" wire:model.defer="item_id">
                  <option value="">-- Selecciona --</option>
                  @foreach ($items as $item)
                    <option value="{{ $item->id }}">{{ $item->name }}</option>
                  @endforeach
                </select>
                @error('item_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="mb-3">
                <label class="form-label">Sucursal</label>
                <select class="form-select @error('sucursal_id') is-invalid @enderror" wire:model.defer="sucursal_id">
                  <option value="">-- Selecciona --</option>
                  @foreach ($sucursales as $s)
                    <option value="{{ $s->id }}">{{ $s->name }}</option>
                  @endforeach
                </select>
                @error('sucursal_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="row g-3">
                <div class="col-4">
                  <label class="form-label">Mínimo</label>
                  <input type="number" step="0.0001" min="0"
                         class="form-control @error('min_qty') is-invalid @enderror"
                         wire:model.defer="min_qty">
                  @error('min_qty')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
                <div class="col-4">
                  <label class="form-label">Máximo</label>
                  <input type="number" step="0.0001" min="0"
                         class="form-control @error('max_qty') is-invalid @enderror"
                         wire:model.defer="max_qty">
                  @error('max_qty')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
                <div class="col-4">
                  <label class="form-label">Reorden</label>
                  <input type="number" step="0.0001" min="0"
                         class="form-control @error('reorder_qty') is-invalid @enderror"
                         wire:model.defer="reorder_qty">
                  @error('reorder_qty')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
              </div>
              <div class="form-check mt-3">
                <input class="form-check-input" type="checkbox" id="stockActivo" wire:model.defer="activo">
                <label class="form-check-label" for="stockActivo">Política activa</label>
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
    const modalEl = document.getElementById('modalStock');
    const modal = new bootstrap.Modal(modalEl);

    document.querySelectorAll('.alert-dismissible').forEach(alert => {
      setTimeout(() => {
        const instance = bootstrap.Alert.getOrCreateInstance(alert);
        instance.close();
      }, 3000);
    });

    Livewire.on('toggle-stock-modal', (payload) => {
      const open = typeof payload === 'object' && payload !== null && 'open' in payload ? payload.open : !!payload;
      open ? modal.show() : modal.hide();
    });

    modalEl.addEventListener('hidden.bs.modal', () => {
      Livewire.dispatch('stock-modal-closed');
    });
  });
</script>
@endpush
