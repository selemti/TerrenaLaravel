<div class="container py-4">
  <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
    <h1 class="h4 mb-0">
      <i class="bi bi-pencil-square me-2"></i>
      {{ $isNew ? 'Nueva receta' : 'Editar receta' }}
    </h1>
    <div class="d-flex gap-2">
      <a class="btn btn-outline-secondary btn-sm" href="{{ route('rec.index') }}">
        <i class="bi bi-arrow-left me-1"></i> Volver
      </a>
      <button
        class="btn btn-primary btn-sm"
        wire:click="save"
        wire:loading.attr="disabled"
        wire:target="save"
      >
        <span wire:loading wire:target="save">
          <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
          Guardando...
        </span>
        <span wire:loading.remove wire:target="save">
          <i class="bi bi-save me-1"></i> Guardar
        </span>
      </button>
    </div>
  </div>

  @if (session('ok'))
    <div class="alert alert-success small">{{ session('ok') }}</div>
  @endif

  <div class="card shadow-sm mb-4">
    <div class="card-body">
      <div class="row g-3">
        <div class="col-md-3">
          <label class="form-label">ID Receta</label>
          <input
            type="text"
            class="form-control form-control-sm @error('form.id') is-invalid @enderror"
            wire:model.live="form.id"
            {{ $isNew ? '' : 'readonly' }}
          >
          @error('form.id') <div class="invalid-feedback">{{ $message }}</div> @enderror
          <div class="form-text">
            Usa prefijos <code>REC-</code> o <code>SUB-</code>. Para modificadores utiliza <code>REC-MOD-xxxxx</code>.
          </div>
        </div>
        @if($isNew)
          <div class="col-md-2">
            <label class="form-label">Prefijo</label>
            <div class="input-group input-group-sm">
              <select class="form-select" wire:model.live="idPrefix">
                <option value="REC">REC (plato)</option>
                <option value="SUB">SUB (sub-receta)</option>
              </select>
              <button class="btn btn-outline-primary" type="button" wire:click="regenerateId">
                <i class="bi bi-arrow-repeat"></i>
              </button>
            </div>
          </div>
        @endif
        <div class="col-md-4">
          <label class="form-label">Nombre del plato <span class="text-danger">*</span>
            <small class="text-muted">({{ strlen($form['nombre_plato']) }}/100)</small>
          </label>
          <input
            type="text"
            class="form-control form-control-sm @error('form.nombre_plato') is-invalid @enderror"
            wire:model.live="form.nombre_plato"
            maxlength="100"
          >
          @error('form.nombre_plato') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">PLU / Código POS</label>
          <input
            type="text"
            class="form-control form-control-sm @error('form.codigo_plato_pos') is-invalid @enderror"
            wire:model.live="form.codigo_plato_pos"
            maxlength="20"
          >
          @error('form.codigo_plato_pos') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Categoría</label>
          <input
            type="text"
            class="form-control form-control-sm @error('form.categoria_plato') is-invalid @enderror"
            wire:model.live="form.categoria_plato"
            maxlength="50"
          >
          @error('form.categoria_plato') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Porciones estándar <span class="text-danger">*</span></label>
          <input
            type="number"
            step="0.01"
            class="form-control form-control-sm @error('form.porciones_standard') is-invalid @enderror"
            wire:model.live="form.porciones_standard"
            min="0.01"
          >
          @error('form.porciones_standard') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Tiempo preparación (min)</label>
          <input
            type="number"
            class="form-control form-control-sm @error('form.tiempo_preparacion_min') is-invalid @enderror"
            wire:model.live="form.tiempo_preparacion_min"
            min="0"
          >
          @error('form.tiempo_preparacion_min') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Costo estándar por porción</label>
          <div class="input-group input-group-sm">
            <span class="input-group-text">MX$</span>
            <input
              type="number"
              step="0.01"
              class="form-control @error('form.costo_standard_porcion') is-invalid @enderror"
              wire:model.live="form.costo_standard_porcion"
              min="0"
            >
          </div>
          @error('form.costo_standard_porcion') <div class="invalid-feedback d-block">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Precio sugerido</label>
          <div class="input-group input-group-sm">
            <span class="input-group-text">MX$</span>
            <input
              type="number"
              step="0.01"
              class="form-control @error('form.precio_venta_sugerido') is-invalid @enderror"
              wire:model.live="form.precio_venta_sugerido"
              min="0"
            >
          </div>
          @error('form.precio_venta_sugerido') <div class="invalid-feedback d-block">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Costo estimado actual</label>
          <div class="border rounded px-3 py-2 bg-light">
            <div class="fw-semibold">MX$ {{ number_format($costo_estimado, 2) }}</div>
            <small class="text-muted">Calculado con costos promedio de ingredientes.</small>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="card shadow-sm">
    <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h2 class="h6 mb-0"><i class="bi bi-list-check me-2"></i> Ingredientes / Sub-recetas</h2>
      <button class="btn btn-outline-primary btn-sm" wire:click="addIngredientRow" type="button">
        <i class="bi bi-plus-circle me-1"></i> Agregar fila
      </button>
    </div>
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th style="width:20%">Item / Sub-receta</th>
            <th style="width:12%" class="text-end">Cantidad</th>
            <th style="width:12%">UM</th>
            <th style="width:12%" class="text-end">Merma %</th>
            <th>Notas</th>
            <th style="width:10%" class="text-center">Orden</th>
            <th style="width:8%"></th>
          </tr>
        </thead>
        <tbody>
        @forelse($ingredients as $index => $row)
          <tr>
            <td>
              <input
                type="text"
                class="form-control form-control-sm @error('ingredients.' . $index . '.item_id') is-invalid @enderror"
                placeholder="ID de insumo o receta (ej. REC-00032)"
                wire:model.live="ingredients.{{ $index }}.item_id"
                maxlength="30"
              >
              @error('ingredients.' . $index . '.item_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </td>
            <td>
              <input
                type="number"
                step="0.0001"
                class="form-control form-control-sm text-end @error('ingredients.' . $index . '.cantidad') is-invalid @enderror"
                wire:model.live="ingredients.{{ $index }}.cantidad"
                min="0"
              >
              @error('ingredients.' . $index . '.cantidad') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </td>
            <td>
              <input
                type="text"
                class="form-control form-control-sm @error('ingredients.' . $index . '.unidad_medida') is-invalid @enderror"
                wire:model.live="ingredients.{{ $index }}.unidad_medida"
                maxlength="10"
              >
              @error('ingredients.' . $index . '.unidad_medida') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </td>
            <td>
              <input
                type="number"
                step="0.01"
                class="form-control form-control-sm text-end @error('ingredients.' . $index . '.merma_porcentaje') is-invalid @enderror"
                wire:model.live="ingredients.{{ $index }}.merma_porcentaje"
                min="0"
                max="99.99"
              >
              @error('ingredients.' . $index . '.merma_porcentaje') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </td>
            <td>
              <input
                type="text"
                class="form-control form-control-sm"
                placeholder="Notas / instrucciones"
                wire:model.live="ingredients.{{ $index }}.instrucciones_especificas"
              >
            </td>
            <td>
              <input
                type="number"
                class="form-control form-control-sm text-center"
                wire:model.live="ingredients.{{ $index }}.orden"
                min="1"
              >
            </td>
            <td class="text-center">
              <button class="btn btn-sm btn-outline-danger" wire:click="removeIngredientRow({{ $index }})" type="button">
                <i class="bi bi-trash"></i>
              </button>
            </td>
          </tr>
        @empty
          <tr><td colspan="7" class="text-muted text-center py-3">Sin ingredientes. Usa "Agregar fila" para comenzar.</td></tr>
        @endforelse
        </tbody>
      </table>
    </div>
    <div class="card-footer text-muted small">
      Captura los IDs tal como aparecen en inventario o utiliza <code>REC-MOD-xxxxx</code> para sub-recetas de modificadores.
    </div>
  </div>
</div>
