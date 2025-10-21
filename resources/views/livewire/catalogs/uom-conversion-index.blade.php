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

    <div class="alert alert-info mb-3">
      <i class="fa-solid fa-arrows-turn-to-dots me-2"></i>
      <strong>Tip:</strong> Para una caja de 12 piezas (cada pieza = 1 litro), define la unidad "CAJA12" y la unidad "PZA".
      Registra la conversión <strong>CAJA12 → PZA</strong> con factor <strong>12</strong>; si necesitas la inversa, agrega <strong>PZA → CAJA12</strong> con factor <strong>0.083333</strong> (1/12).
      Después vincula <strong>PZA → LT</strong> con factor <strong>1</strong> o el equivalente que uses como base.
    </div>

    <div class="card shadow-sm border-0">
      <div class="card-body d-flex flex-wrap align-items-end gap-2">
        <div class="flex-grow-1">
          <label class="form-label small text-muted mb-1">Buscar</label>
          <div class="input-group input-group-sm">
            <span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span>
            <input type="search" class="form-control" placeholder="Unidad origen o destino" wire:model.live.debounce.400ms="search">
          </div>
        </div>
        <div>
          <label class="form-label small text-muted mb-1 d-block">&nbsp;</label>
          <button class="btn btn-sm btn-primary" wire:click="create" @disabled(!($tableReady && $unitsReady))>
            <i class="fa-solid fa-plus me-1"></i> Nueva conversión
          </button>
        </div>
      </div>
      <div class="table-responsive">
        <table class="table table-striped table-sm align-middle mb-0">
          <thead class="table-light">
          <tr>
            <th>Origen</th>
            <th>Destino</th>
            <th>Factor</th>
            <th class="text-end">Acciones</th>
          </tr>
          </thead>
          <tbody>
          @forelse($rows as $row)
            <tr>
              <td>
                <strong>{{ $row->origenKey ?? ('ID '.$row->origen_id) }}</strong>
                @if($row->origenName && $row->origenName !== ($row->origenKey ?? ''))
                  <div class="text-muted small">{{ $row->origenName }}</div>
                @endif
              </td>
              <td>
                <strong>{{ $row->destinoKey ?? ('ID '.$row->destino_id) }}</strong>
                @if($row->destinoName && $row->destinoName !== ($row->destinoKey ?? ''))
                  <div class="text-muted small">{{ $row->destinoName }}</div>
                @endif
              </td>
              <td>{{ number_format($row->factor, 6) }}</td>
              <td class="text-end">
                <button class="btn btn-sm btn-outline-primary me-1" wire:click="edit({{ $row->id }})">
                  <i class="fa-regular fa-pen-to-square"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger"
                        wire:click="delete({{ $row->id }})"
                        onclick="return confirm('¿Eliminar conversión?')">
                  <i class="fa-regular fa-trash-can"></i>
                </button>
              </td>
            </tr>
          @empty
            <tr>
              <td colspan="4" class="text-center text-muted py-4">Sin registros.</td>
            </tr>
          @endforelse
          </tbody>
        </table>
      </div>
      <div class="card-footer bg-white py-2">
        {{ $rows->links() }}
      </div>
    </div>

    <div class="modal fade" id="modalUom" tabindex="-1" aria-labelledby="modalUomLabel" aria-hidden="true" wire:ignore.self>
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg">
          <form wire:submit.prevent="save">
            <div class="modal-header bg-primary bg-opacity-10">
              <h5 class="modal-title" id="modalUomLabel">
                <i class="fa-solid fa-arrows-rotate me-2"></i>
                {{ $editId ? 'Editar conversión' : 'Nueva conversión' }}
              </h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
            </div>
            <div class="modal-body">
              <div class="mb-3">
                <label class="form-label">Unidad origen</label>
                <select class="form-select @error('origen_id') is-invalid @enderror" wire:model.defer="origen_id">
                  <option value="">-- Selecciona --</option>
                  @foreach ($unitOptions as $option)
                    <option value="{{ $option->id }}">{{ $option->label }}</option>
                  @endforeach
                </select>
                @error('origen_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
                @if($unitOptions->isEmpty())
                  <div class="form-text">No hay unidades registradas. <a href="{{ route('cat.unidades') }}" class="link-primary">Crear unidad</a>.</div>
                @else
                  <div class="form-text">¿Falta alguna? <a href="{{ route('cat.unidades') }}" class="link-primary">Gestionar unidades</a>.</div>
                @endif
              </div>
              <div class="mb-3">
                <label class="form-label">Unidad destino</label>
                <select class="form-select @error('destino_id') is-invalid @enderror" wire:model.defer="destino_id">
                  <option value="">-- Selecciona --</option>
                  @foreach ($unitOptions as $option)
                    <option value="{{ $option->id }}">{{ $option->label }}</option>
                  @endforeach
                </select>
                @error('destino_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
                @if($unitOptions->isEmpty())
                  <div class="form-text">Debes agregar unidades antes de crear conversiones.</div>
                @endif
              </div>
              <div class="mb-3">
                <label class="form-label">Factor</label>
                <input type="number" step="0.000001" min="0.000001" class="form-control @error('factor') is-invalid @enderror"
                       wire:model.defer="factor">
                @error('factor')<div class="invalid-feedback">{{ $message }}</div>@enderror
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
    const modalEl = document.getElementById('modalUom');
    const modal = new bootstrap.Modal(modalEl);

    document.querySelectorAll('.alert-dismissible').forEach(alert => {
      setTimeout(() => {
        const instance = bootstrap.Alert.getOrCreateInstance(alert);
        instance.close();
      }, 3500);
    });

    Livewire.on('toggle-uom-modal', (payload) => {
      const open = typeof payload === 'object' && payload !== null && 'open' in payload ? payload.open : !!payload;
      open ? modal.show() : modal.hide();
    });

    modalEl.addEventListener('hidden.bs.modal', () => {
      Livewire.dispatch('uom-modal-closed');
    });
  });
</script>
@endpush
