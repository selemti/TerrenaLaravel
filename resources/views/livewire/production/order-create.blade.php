<div>
    {{-- Encabezado --}}
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h5 class="mb-0 fw-bold"><i class="bi bi-plus-circle me-2 text-primary"></i>Nueva Orden de Producción</h5>
        </div>
        <a href="{{ route('production.index') }}" class="btn btn-outline-secondary btn-sm">
            <i class="bi bi-arrow-left me-1"></i>Volver
        </a>
    </div>

    {{-- Formulario --}}
    <div class="card border-0 shadow-sm">
        <div class="card-body">
            <form wire:submit="save">
                <div class="row g-3">

                    {{-- Receta --}}
                    <div class="col-md-6">
                        <label for="recipeId" class="form-label small fw-semibold">Receta</label>
                        <select wire:model="recipeId" id="recipeId" class="form-select form-select-sm @error('recipeId') is-invalid @enderror">
                            <option value="">— Seleccionar receta —</option>
                            @foreach($recetas as $receta)
                                <option value="{{ $receta->id }}">{{ $receta->nombre }} ({{ $receta->uom_base }})</option>
                            @endforeach
                        </select>
                        @error('recipeId')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    {{-- Cantidad Programada --}}
                    <div class="col-md-6">
                        <label for="qtyProgramada" class="form-label small fw-semibold">Cantidad Programada</label>
                        <input type="number" wire:model="qtyProgramada" id="qtyProgramada" step="0.001" min="0.001"
                               class="form-control form-control-sm @error('qtyProgramada') is-invalid @enderror">
                        @error('qtyProgramada')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    {{-- Programado Para --}}
                    <div class="col-md-6">
                        <label for="programadoPara" class="form-label small fw-semibold">Programado Para</label>
                        <input type="date" wire:model="programadoPara" id="programadoPara"
                               class="form-control form-control-sm @error('programadoPara') is-invalid @enderror">
                        @error('programadoPara')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    {{-- Notas --}}
                    <div class="col-12">
                        <label for="notas" class="form-label small fw-semibold">Notas</label>
                        <textarea wire:model="notas" id="notas" rows="3"
                                  class="form-control form-control-sm @error('notas') is-invalid @enderror"
                                  placeholder="Observaciones opcionales..."></textarea>
                        @error('notas')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    {{-- Botón --}}
                    <div class="col-12 text-end">
                        <button type="submit" class="btn btn-primary btn-sm">
                            <span wire:loading.remove wire:target="save">
                                <i class="bi bi-check-circle me-1"></i>Crear Orden
                            </span>
                            <span wire:loading wire:target="save">
                                <span class="spinner-border spinner-border-sm me-1" role="status"></span>Guardando...
                            </span>
                        </button>
                    </div>

                </div>
            </form>
        </div>
    </div>
</div>
