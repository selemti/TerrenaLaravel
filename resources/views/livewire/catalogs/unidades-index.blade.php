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
            <strong>{{ $editingId ? 'Editar unidad' : 'Nueva unidad' }}</strong>
          </div>
          <div class="card-body">
            <div class="mb-3">
              <label class="form-label">Código</label>
              <input type="text" class="form-control @error('form.codigo') is-invalid @enderror"
                     wire:model.defer="form.codigo" maxlength="10">
              @error('form.codigo')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="mb-3">
              <label class="form-label">Nombre</label>
              <input type="text" class="form-control @error('form.nombre') is-invalid @enderror"
                     wire:model.defer="form.nombre" maxlength="50">
              @error('form.nombre')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="row g-3">
              <div class="col-6">
                <label class="form-label">Tipo</label>
                <select class="form-select @error('form.tipo') is-invalid @enderror" wire:model.defer="form.tipo">
                  <option value="PESO">PESO</option>
                  <option value="VOLUMEN">VOLUMEN</option>
                  <option value="UNIDAD">UNIDAD</option>
                  <option value="TIEMPO">TIEMPO</option>
                </select>
                @error('form.tipo')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="col-6">
                <label class="form-label">Categoría</label>
                <select class="form-select @error('form.categoria') is-invalid @enderror" wire:model.defer="form.categoria">
                  <option value="">(ninguna)</option>
                  <option value="METRICO">MÉTRICO</option>
                  <option value="IMPERIAL">IMPERIAL</option>
                  <option value="CULINARIO">CULINARIO</option>
                </select>
                @error('form.categoria')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
            </div>
            <div class="row g-3 mt-1">
              <div class="col-6">
                <label class="form-label">Factor base</label>
                <input type="number" step="0.000001" min="0.000001"
                       class="form-control @error('form.factor_conversion_base') is-invalid @enderror"
                       wire:model.defer="form.factor_conversion_base">
                @error('form.factor_conversion_base')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
              <div class="col-6">
                <label class="form-label">Decimales</label>
                <input type="number" min="0" max="6"
                       class="form-control @error('form.decimales') is-invalid @enderror"
                       wire:model.defer="form.decimales">
                @error('form.decimales')<div class="invalid-feedback">{{ $message }}</div>@enderror
              </div>
            </div>
            <div class="form-check mt-3">
              <input class="form-check-input" type="checkbox" id="chkBase" wire:model.defer="form.es_base">
              <label class="form-check-label" for="chkBase">Unidad base</label>
            </div>
          </div>
          <div class="card-footer d-flex gap-2">
            <button class="btn btn-primary flex-grow-1" wire:click="save">
              <i class="fa-regular fa-floppy-disk me-1"></i> Guardar
            </button>
            <button class="btn btn-outline-secondary" wire:click="createNew">
              <i class="fa-regular fa-circle-xmark me-1"></i> Cancelar
            </button>
          </div>
        </div>
      </div>

      <div class="col-lg-8">
        <div class="card shadow-sm">
          <div class="card-body">
            <div class="row g-2 align-items-end">
              <div class="col-md-4">
                <label class="form-label small text-muted mb-1">Búsqueda</label>
                <input type="search" class="form-control form-control-sm" placeholder="Código o nombre"
                       wire:model.live.debounce.400ms="q">
              </div>
              <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Tipo</label>
                <select class="form-select form-select-sm" wire:model.live="tipo">
                  <option value="">Todos</option>
                  <option value="PESO">PESO</option>
                  <option value="VOLUMEN">VOLUMEN</option>
                  <option value="UNIDAD">UNIDAD</option>
                  <option value="TIEMPO">TIEMPO</option>
                </select>
              </div>
              <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Categoría</label>
                <select class="form-select form-select-sm" wire:model.live="categoria">
                  <option value="">Todas</option>
                  <option value="METRICO">MÉTRICO</option>
                  <option value="IMPERIAL">IMPERIAL</option>
                  <option value="CULINARIO">CULINARIO</option>
                </select>
              </div>
              <div class="col-md-2">
                <label class="form-label small text-muted mb-1">Por página</label>
                <select class="form-select form-select-sm" wire:model.live="perPage">
                  <option value="10">10</option>
                  <option value="25">25</option>
                  <option value="50">50</option>
                  <option value="100">100</option>
                </select>
              </div>
            </div>
          </div>
          <div class="table-responsive">
            <table class="table table-striped table-sm align-middle mb-0">
              <thead class="table-light">
              <tr>
                <th>Código</th>
                <th>Nombre</th>
                <th>Tipo</th>
                <th>Categoría</th>
                <th class="text-center">Base</th>
                <th class="text-end">Factor</th>
                <th class="text-center">Dec</th>
                <th class="text-end">Acciones</th>
              </tr>
              </thead>
              <tbody>
              @forelse($rows as $row)
                <tr>
                  <td class="fw-semibold">{{ $row->codigo }}</td>
                  <td>{{ $row->nombre }}</td>
                  <td>{{ $row->tipo ?? '—' }}</td>
                  <td>{{ $row->categoria ?? '—' }}</td>
                  <td class="text-center">
                    @if($row->es_base)
                      <span class="badge bg-success">Sí</span>
                    @else
                      <span class="badge bg-secondary">No</span>
                    @endif
                  </td>
                  <td class="text-end">{{ number_format((float) $row->factor_conversion_base, 6) }}</td>
                  <td class="text-center">{{ $row->decimales }}</td>
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
                  <td colspan="8" class="text-center text-muted py-4">Sin resultados.</td>
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
