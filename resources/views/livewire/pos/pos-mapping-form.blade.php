<div class="modal fade" 
     id="posMappingModal" 
     tabindex="-1" 
     aria-labelledby="posMappingModalLabel" 
     aria-hidden="true"
     wire:ignore.self>
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title" id="posMappingModalLabel">
                    {{ $mapping ? 'Editar Mapeo POS' : 'Nuevo Mapeo POS' }}
                </h5>
                <button 
                    type="button" 
                    class="btn-close btn-close-white" 
                    data-bs-dismiss="modal" 
                    aria-label="Close"
                    wire:click="resetForm"
                ></button>
            </div>
            <form wire:submit.prevent="save">
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Tipo *</label>
                                <select 
                                    class="form-select @error('tipo') is-invalid @enderror" 
                                    wire:model="tipo"
                                    required
                                >
                                    <option value="">Seleccione un tipo</option>
                                    <option value="MENU">MENU</option>
                                    <option value="MODIFIER">MODIFIER</option>
                                </select>
                                @error('tipo')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">PLU *</label>
                                <input 
                                    type="text" 
                                    class="form-control @error('plu') is-invalid @enderror" 
                                    wire:model="plu" 
                                    placeholder="Ingrese el PLU"
                                    required
                                >
                                @error('plu')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Receta</label>
                                <select 
                                    class="form-select @error('receta_id') is-invalid @enderror" 
                                    wire:model="receta_id"
                                >
                                    <option value="">Seleccione una receta (opcional)</option>
                                    @foreach($recetas as $receta)
                                        <option value="{{ $receta->id }}">{{ $receta->nombre_plato }}</option>
                                    @endforeach
                                </select>
                                @error('receta_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Versión de Receta</label>
                                <input 
                                    type="number" 
                                    class="form-control @error('recipe_version_id') is-invalid @enderror" 
                                    wire:model="recipe_version_id" 
                                    placeholder="ID de versión de receta"
                                >
                                @error('recipe_version_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Válido Desde</label>
                                <input 
                                    type="date" 
                                    class="form-control @error('valid_from') is-invalid @enderror" 
                                    wire:model="valid_from"
                                >
                                @error('valid_from')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Válido Hasta</label>
                                <input 
                                    type="date" 
                                    class="form-control @error('valid_to') is-invalid @enderror" 
                                    wire:model="valid_to"
                                >
                                @error('valid_to')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Vigente Desde</label>
                        <input 
                            type="date" 
                            class="form-control @error('vigente_desde') is-invalid @enderror" 
                            wire:model="vigente_desde"
                        >
                        @error('vigente_desde')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <!-- No hay campo 'sucursal_id' en la tabla pos_map en el esquema actual -->
                </div>
                <div class="modal-footer">
                    <button 
                        type="button" 
                        class="btn btn-secondary" 
                        data-bs-dismiss="modal"
                        wire:click="resetForm"
                    >
                        Cancelar
                    </button>
                    <button 
                        type="submit" 
                        class="btn btn-primary"
                    >
                        <i class="fa-solid fa-save me-1"></i>
                        {{ $mapping ? 'Actualizar' : 'Guardar' }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>