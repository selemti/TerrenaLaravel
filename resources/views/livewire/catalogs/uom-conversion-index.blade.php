<div class="container-fluid px-0">
    @if ($tableNotice !== '')
      <div class="alert alert-warning alert-dismissible fade show" role="alert">
        <i class="fa-solid fa-triangle-exclamation me-2"></i>{{ $tableNotice }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif
    @if (session('ok'))
      <div class="alert alert-success alert-dismissible fade show" role="alert">
        <i class="fa-solid fa-circle-check me-2"></i>{{ session('ok') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif
    @if (session('warn'))
      <div class="alert alert-warning alert-dismissible fade show" role="alert">
        <i class="fa-solid fa-circle-info me-2"></i>{{ session('warn') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
      </div>
    @endif

    <div class="row g-3">
      <div class="col-lg-4">
        <div class="card shadow-sm">
          <div class="card-header bg-white">
            <strong>{{ $editId ? 'Editar conversión' : 'Nueva conversión' }}</strong>
          </div>
          <div class="card-body">
            <div class="mb-3">
              <label class="form-label">Unidad origen</label>
              <select class="form-select @error('origen_id') is-invalid @enderror"
                      wire:model.defer="origen_id">
                <option value="">-- Selecciona --</option>
                @foreach ($unitOptions as $option)
                  <option value="{{ $option->id }}">{{ $option->label }}</option>
                @endforeach
              </select>
              @error('origen_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="mb-3">
              <label class="form-label">Unidad destino</label>
              <select class="form-select @error('destino_id') is-invalid @enderror"
                      wire:model.defer="destino_id">
                <option value="">-- Selecciona --</option>
                @foreach ($unitOptions as $option)
                  <option value="{{ $option->id }}">{{ $option->label }}</option>
                @endforeach
              </select>
              @error('destino_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="mb-3">
              <label class="form-label">Factor</label>
              <input type="number" step="0.000001" min="0.000001"
                     class="form-control @error('factor') is-invalid @enderror"
                     wire:model.defer="factor">
              @error('factor')<div class="invalid-feedback">{{ $message }}</div>@enderror
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
                  <input type="search" class="form-control" placeholder="Unidad origen o destino"
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
                    {{ $row->origenKey ?? '—' }}
                    @if($row->origenName)
                      <span class="text-muted">{{ $row->origenName }}</span>
                    @endif
                  </td>
                  <td>
                    {{ $row->destinoKey ?? '—' }}
                    @if($row->destinoName)
                      <span class="text-muted">{{ $row->destinoName }}</span>
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
      </div>
    </div>
  </div>
