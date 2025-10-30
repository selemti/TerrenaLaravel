<div>
    <div class="d-flex align-items-center gap-2 mb-3">
        <i class="fa-solid fa-boxes-stacked fa-lg text-primary"></i>
        <h2 class="h4 mb-0 fw-semibold">Alta de insumo</h2>
    </div>

    @if (session()->has('success'))
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            {{ session('success') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
        </div>
    @endif

    @if (session()->has('warning'))
        <div class="alert alert-warning alert-dismissible fade show" role="alert">
            <i class="fa-solid fa-triangle-exclamation me-1"></i>
            {{ session('warning') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
        </div>
    @elseif(!$authorized)
        <div class="alert alert-warning">
            <i class="fa-solid fa-triangle-exclamation me-1"></i>
            No tienes permiso para dar de alta insumos.
        </div>
    @endif

    @error('form')
        <div class="alert alert-danger">{{ $message }}</div>
    @enderror

    <form wire:submit.prevent="save" class="card shadow-sm">
        <div class="card-body">
            <fieldset class="row g-3" @disabled(!$authorized)>
                <div class="col-md-4">
                    <label class="form-label fw-semibold">Categoría (CAT)</label>
                    <select class="form-select" wire:model.lazy="categoria" required>
                        <option value="">Selecciona…</option>
                        @foreach($categorias as $key => $label)
                            <option value="{{ $key }}">{{ $key }} — {{ $label }}</option>
                        @endforeach
                    </select>
                    @error('categoria')
                        <div class="text-danger small">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-4">
                    <label class="form-label fw-semibold">Subcategoría (SUB)</label>
                    <select class="form-select" wire:model.lazy="subcategoria" @disabled(!$categoria) required>
                        <option value="">Selecciona…</option>
                        @foreach($subcategorias as $key => $label)
                            <option value="{{ $key }}">{{ $key }} — {{ $label }}</option>
                        @endforeach
                    </select>
                    @error('subcategoria')
                        <div class="text-danger small">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-4">
                    <label class="form-label fw-semibold">Unidad de medida (UOM)</label>
                    <select class="form-select" wire:model.lazy="um_id" required>
                        <option value="">Selecciona…</option>
                        @foreach($units as $unit)
                            <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} — {{ $unit['nombre'] }}</option>
                        @endforeach
                    </select>
                    @error('um_id')
                        <div class="text-danger small">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-8">
                    <label class="form-label fw-semibold">Nombre del insumo</label>
                    <input type="text" class="form-control" wire:model.lazy="nombre" maxlength="255" required>
                    @error('nombre')
                        <div class="text-danger small">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-4">
                    <label class="form-label">SKU (opcional)</label>
                    <input type="text" class="form-control" wire:model.lazy="sku" maxlength="120">
                    @error('sku')
                        <div class="text-danger small">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-3">
                    <label class="form-label">Perecible</label>
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" wire:model.lazy="perecible">
                        <label class="form-check-label">Sí caduca</label>
                    </div>
                    @error('perecible')
                        <div class="text-danger small">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-3">
                    <label class="form-label">Merma %</label>
                    <input type="number" min="0" max="100" step="0.001" class="form-control" wire:model.lazy="merma_pct" required>
                    @error('merma_pct')
                        <div class="text-danger small">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-12">
                    <label class="form-label">Meta (JSON opcional)</label>
                    <textarea class="form-control" rows="2" wire:model.lazy="metaInput" placeholder='{"proveedor":"Acme"}'></textarea>
                    @error('metaInput')
                        <div class="text-danger small">{{ $message }}</div>
                    @enderror
                    <small class="text-muted">Usa este campo solo si sabes JSON. Ej.: {"proveedor":"Acme"}</small>
                </div>

                <div class="col-12">
                    <label class="form-label fw-semibold">Código sugerido</label>
                    <input type="text" class="form-control" value="{{ $previewCodigo ?? '' }}" readonly placeholder="Se asignará al guardar (ej. CAT-SUB-00001)">
                    <small class="text-muted">El código definitivo se confirma al guardar.</small>
                </div>
            </fieldset>
        </div>

        <div class="card-footer d-flex justify-content-end gap-2">
            <button type="submit" class="btn btn-success" @disabled(!$authorized)>
                <i class="fa-solid fa-floppy-disk me-1"></i>
                Guardar insumo
            </button>
        </div>
    </form>
</div>
