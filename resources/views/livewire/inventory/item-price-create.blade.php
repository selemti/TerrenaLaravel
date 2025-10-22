<div>
  @if($open)
    <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
      <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
          <form wire:submit.prevent="save">
            <div class="modal-header">
              <h5 class="modal-title">
                <i class="fa-solid fa-tags me-2"></i>Registrar precio de proveedor
              </h5>
              <button type="button" class="btn-close" wire:click="close" aria-label="Cerrar"></button>
            </div>
            <div class="modal-body">
              <div class="mb-3">
                <label class="form-label">Buscar ítem</label>
                <input type="text" class="form-control" placeholder="Filtrar por código o nombre"
                       wire:model.debounce.400ms="itemSearch">
              </div>
              <div class="mb-3">
                <label class="form-label">Ítem</label>
                <select class="form-select" wire:model="itemId">
                  <option value="">-- Selecciona un ítem --</option>
                  @foreach($itemOptions as $option)
                    <option value="{{ $option['id'] }}">
                      {{ $option['id'] }} · {{ $option['name'] }}
                      @if($option['item_code'])
                        ({{ $option['item_code'] }})
                      @endif
                    </option>
                  @endforeach
                </select>
                @error('item_id') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="mb-3">
                <label class="form-label">Buscar proveedor</label>
                <input type="text" class="form-control" placeholder="Filtrar por nombre o clave"
                       wire:model.debounce.400ms="vendorSearch" {{ $itemId ? '' : 'disabled' }}>
              </div>
              <div class="mb-3">
                <label class="form-label">Proveedor</label>
                <select class="form-select" wire:model="vendorId" {{ $itemId ? '' : 'disabled' }}>
                  <option value="">-- Selecciona un proveedor --</option>
                  @foreach($vendorOptions as $option)
                    <option value="{{ $option['id'] }}">
                      {{ $option['name'] }}
                      @if($option['preferente'])
                        · Preferente
                      @endif
                    </option>
                  @endforeach
                </select>
                @error('vendor_id') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
              <div class="row g-3">
                <div class="col-md-4">
                  <label class="form-label">Precio</label>
                  <input type="number" step="0.01" min="0" class="form-control" wire:model.lazy="price">
                  @error('price') <div class="text-danger small">{{ $message }}</div> @enderror
                </div>
                <div class="col-md-4">
                  <label class="form-label">Cantidad por pack</label>
                  <input type="number" step="0.0001" min="0" class="form-control" wire:model.lazy="packQty">
                  @error('pack_qty') <div class="text-danger small">{{ $message }}</div> @enderror
                </div>
                <div class="col-md-4">
                  <label class="form-label">Unidad del pack</label>
                  <input type="text" class="form-control text-uppercase" maxlength="16" wire:model.lazy="packUom">
                  @error('pack_uom') <div class="text-danger small">{{ $message }}</div> @enderror
                </div>
              </div>
              <div class="row g-3 mt-2">
                <div class="col-md-6">
                  <label class="form-label">Vigente desde</label>
                  <input type="datetime-local" class="form-control" wire:model="effectiveFrom">
                  @error('effective_from') <div class="text-danger small">{{ $message }}</div> @enderror
                </div>
                <div class="col-md-6">
                  <label class="form-label">Fuente</label>
                  <input type="text" class="form-control" wire:model.lazy="source" maxlength="50">
                  @error('source') <div class="text-danger small">{{ $message }}</div> @enderror
                </div>
              </div>
              <div class="mt-3">
                <label class="form-label">Notas</label>
                <textarea class="form-control" rows="2" wire:model.lazy="notes" placeholder="Observaciones del precio"></textarea>
                @error('notes') <div class="text-danger small">{{ $message }}</div> @enderror
              </div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-outline-secondary" wire:click="close">Cancelar</button>
              <button type="submit" class="btn btn-primary">
                <i class="fa-solid fa-floppy-disk me-1"></i>Guardar precio
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    <div class="modal-backdrop fade show"></div>
  @endif
</div>
