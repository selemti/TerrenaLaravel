<div class="container py-4">
  <div class="d-flex align-items-center justify-content-between mb-3">
    <h1 class="h4 mb-0">
      <i class="fa-solid fa-pen-to-square me-2"></i>
      {{ $isNew ? 'Nueva receta' : 'Editar receta' }}
    </h1>
    <div class="d-flex gap-2">
      <a class="btn btn-outline-secondary btn-sm" href="{{ route('rec.index') }}">
        <i class="fa-solid fa-arrow-left me-1"></i> Volver
      </a>
      <button class="btn btn-primary btn-sm" wire:click="save">
        <i class="fa-regular fa-floppy-disk me-1"></i> Guardar
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
          <input type="text" class="form-control form-control-sm @error('form.id') is-invalid @enderror"
                 wire:model.defer="form.id" {{ $isNew ? '' : 'readonly' }}>
          @error('form.id') <div class="invalid-feedback">{{ $message }}</div> @enderror
          <div class="form-text">
            Usa el prefijo deseado (p. ej. <code>REC-xxxxx</code> o <code>SUB-xxxxx</code>). Para modificadores se usa <code>REC-MOD-xxxxx</code>.
          </div>
        </div>
        @if($isNew)
        <div class="col-md-2">
          <label class="form-label">Prefijo</label>
          <div class="input-group input-group-sm">
            <select class="form-select" wire:model="idPrefix">
              <option value="REC">REC (plato)</option>
              <option value="SUB">SUB (sub-receta)</option>
            </select>
            <button class="btn btn-outline-primary" type="button" wire:click="regenerateId">
              <i class="fa-solid fa-rotate"></i>
            </button>
          </div>
        </div>
        @endif
        <div class="col-md-4">
          <label class="form-label">Nombre del plato</label>
          <input type="text" class="form-control form-control-sm @error('form.nombre_plato') is-invalid @enderror"
                 wire:model.defer="form.nombre_plato">
          @error('form.nombre_plato') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">PLU / Código POS</label>
          <input type="text" class="form-control form-control-sm @error('form.codigo_plato_pos') is-invalid @enderror"
                 wire:model.defer="form.codigo_plato_pos">
          @error('form.codigo_plato_pos') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Categoría</label>
          <input type="text" class="form-control form-control-sm @error('form.categoria_plato') is-invalid @enderror"
                 wire:model.defer="form.categoria_plato">
          @error('form.categoria_plato') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Porciones estándar</label>
          <input type="number" step="0.01" class="form-control form-control-sm @error('form.porciones_standard') is-invalid @enderror"
                 wire:model.defer="form.porciones_standard">
          @error('form.porciones_standard') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Tiempo preparación (min)</label>
          <input type="number" class="form-control form-control-sm @error('form.tiempo_preparacion_min') is-invalid @enderror"
                 wire:model.defer="form.tiempo_preparacion_min">
          @error('form.tiempo_preparacion_min') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Costo estándar por porción</label>
          <div class="input-group input-group-sm">
            <span class="input-group-text">MX$</span>
            <input type="number" step="0.01" class="form-control @error('form.costo_standard_porcion') is-invalid @enderror"
                   wire:model.defer="form.costo_standard_porcion">
          </div>
          @error('form.costo_standard_porcion') <div class="invalid-feedback d-block">{{ $message }}</div> @enderror
        </div>
        <div class="col-md-3">
          <label class="form-label">Precio sugerido</label>
          <div class="input-group input-group-sm">
            <span class="input-group-text">MX$</span>
            <input type="number" step="0.01" class="form-control @error('form.precio_venta_sugerido') is-invalid @enderror"
                   wire:model.defer="form.precio_venta_sugerido">
          </div>
          @error('form.precio_venta_sugerido') <div class="invalid-feedback d-block">{{ $message }}</div> @enderror
        </div>
      </div>
    </div>
  </div>

  <div class="card shadow-sm">
    <div class="card-header d-flex justify-content-between align-items-center">
      <h2 class="h6 mb-0"><i class="fa-solid fa-list-check me-2"></i> Ingredientes / Sub-recetas</h2>
      <button class="btn btn-outline-primary btn-sm" wire:click="addIngredientRow" type="button">
        <i class="fa-solid fa-plus me-1"></i> Agregar fila
      </button>
    </div>
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th style="width:18%">Item / Sub-receta</th>
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
              <input type="text"
                     class="form-control form-control-sm @error('ingredients.' . $index . '.item_id') is-invalid @enderror"
                     placeholder="ID de insumo o receta (ej. REC-00032, SUB-00005, REC-MOD-00010)"
                     wire:model.defer="ingredients.{{ $index }}.item_id">
              @error('ingredients.' . $index . '.item_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </td>
            <td>
              <input type="number" step="0.0001"
                     class="form-control form-control-sm text-end @error('ingredients.' . $index . '.cantidad') is-invalid @enderror"
                     wire:model.defer="ingredients.{{ $index }}.cantidad">
            </td>
            <td>
              <input type="text"
                     class="form-control form-control-sm @error('ingredients.' . $index . '.unidad_medida') is-invalid @enderror"
                     wire:model.defer="ingredients.{{ $index }}.unidad_medida">
            </td>
            <td>
              <input type="number" step="0.01"
                     class="form-control form-control-sm text-end @error('ingredients.' . $index . '.merma_porcentaje') is-invalid @enderror"
                     wire:model.defer="ingredients.{{ $index }}.merma_porcentaje">
            </td>
            <td>
              <input type="text"
                     class="form-control form-control-sm"
                     placeholder="Notas / instrucciones"
                     wire:model.defer="ingredients.{{ $index }}.instrucciones_especificas">
            </td>
            <td>
              <input type="number" class="form-control form-control-sm text-center"
                     wire:model.defer="ingredients.{{ $index }}.orden">
            </td>
            <td class="text-center">
              <button class="btn btn-sm btn-outline-danger"
                      wire:click="removeIngredientRow({{ $index }})"
                      type="button">
                <i class="fa-regular fa-trash-can"></i>
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
      Captura los IDs tal como aparecen en inventario o utiliza <code>REC-MOD-xxxxx</code> para sub-recetas placeholder que provienen de modificadores.
    </div>
  </div>
</div>
