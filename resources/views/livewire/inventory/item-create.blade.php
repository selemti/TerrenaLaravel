<div>
    @if(!$authorized)
        <div class="alert alert-warning">
            <i class="fa-solid fa-triangle-exclamation me-2"></i>
            No tienes permiso para dar de alta items.
        </div>
    @else
        <div class="card">
            <div class="card-header bg-light">
                <h5 class="mb-0">
                    <i class="fa-solid fa-box me-2"></i>
                    Alta de Item
                </h5>
            </div>
            <div class="card-body">
                <form wire:submit.prevent="save">
                    {{-- Identificación --}}
                    <div class="row mb-4">
                        <div class="col-12">
                            <h6 class="text-primary border-bottom pb-2 mb-3">
                                <i class="fa-solid fa-id-card me-2"></i>Identificación
                            </h6>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Nombre <span class="text-danger">*</span></label>
                            <input type="text" class="form-control @error('nombre') is-invalid @enderror"
                                   wire:model="nombre"
                                   placeholder="Ej: Aceite de Soya Nutrioli">
                            @error('nombre')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">
                                Código / SKU
                                <small class="text-muted">(Opcional - Se genera automáticamente)</small>
                            </label>
                            <input type="text" class="form-control @error('item_code') is-invalid @enderror"
                                   wire:model="item_code"
                                   placeholder="Ej: ACEITE-NUTRIOLI-01">
                            @error('item_code')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="col-12 mt-3">
                            <label class="form-label">Descripción</label>
                            <textarea class="form-control @error('descripcion') is-invalid @enderror"
                                      wire:model="descripcion"
                                      rows="2"
                                      placeholder="Descripción detallada del producto..."></textarea>
                            @error('descripcion')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                    </div>

                    {{-- Categorización --}}
                    <div class="row mb-4">
                        <div class="col-12">
                            <h6 class="text-primary border-bottom pb-2 mb-3">
                                <i class="fa-solid fa-tags me-2"></i>Categorización
                            </h6>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Tipo <span class="text-danger">*</span></label>
                            <select class="form-select @error('tipo') is-invalid @enderror" wire:model="tipo">
                                @foreach($tipos as $key => $label)
                                    <option value="{{ $key }}">{{ $label }}</option>
                                @endforeach
                            </select>
                            @error('tipo')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Categoría <small class="text-muted">(Opcional)</small></label>
                            <select class="form-select @error('category_id') is-invalid @enderror" wire:model="category_id">
                                <option value="">Sin categoría</option>
                                @foreach($categorias as $cat)
                                    <option value="{{ $cat['id'] }}">{{ $cat['nombre'] }}</option>
                                @endforeach
                            </select>
                            @error('category_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                    </div>

                    {{-- Sistema de Unidades de Medida (3 niveles) --}}
                    <div class="row mb-4">
                        <div class="col-12">
                            <h6 class="text-primary border-bottom pb-2 mb-3">
                                <i class="fa-solid fa-balance-scale me-2"></i>Unidades de Medida
                            </h6>
                        </div>

                        {{-- Unidad BASE (Inventario) --}}
                        <div class="col-md-4">
                            <div class="card bg-light h-100">
                                <div class="card-body">
                                    <h6 class="card-subtitle mb-2 text-muted">
                                        <i class="fa-solid fa-box-archive me-1"></i>
                                        Unidad BASE (Inventario)
                                    </h6>
                                    <label class="form-label">Unidad <span class="text-danger">*</span></label>
                                    <select class="form-select @error('unidad_medida_id') is-invalid @enderror"
                                            wire:model.live="unidad_medida_id">
                                        <option value="">Seleccionar...</option>
                                        @foreach($unidadesBase as $u)
                                            <option value="{{ $u['id'] }}">
                                                {{ $u['clave'] }} - {{ $u['nombre'] }}
                                            </option>
                                        @endforeach
                                    </select>
                                    @error('unidad_medida_id')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                    @enderror
                                    <small class="text-muted d-block mt-2">
                                        <i class="fa-solid fa-info-circle me-1"></i>
                                        Unidad canónica para inventario (KG, L, PZ)
                                    </small>
                                </div>
                            </div>
                        </div>

                        {{-- Unidad de COMPRA --}}
                        <div class="col-md-4">
                            <div class="card bg-light h-100">
                                <div class="card-body">
                                    <h6 class="card-subtitle mb-2 text-muted">
                                        <i class="fa-solid fa-shopping-cart me-1"></i>
                                        Unidad de COMPRA
                                    </h6>
                                    <label class="form-label">Unidad de compra</label>
                                    <select class="form-select @error('unidad_compra_id') is-invalid @enderror"
                                            wire:model="unidad_compra_id">
                                        <option value="">Igual a unidad base</option>
                                        @foreach($unidadesCompra as $u)
                                            <option value="{{ $u['id'] }}">
                                                {{ $u['clave'] }} - {{ $u['nombre'] }}
                                            </option>
                                        @endforeach
                                    </select>
                                    @error('unidad_compra_id')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                    @enderror

                                    <div class="row mt-3">
                                        <div class="col-6">
                                            <label class="form-label">Piezas</label>
                                            <input type="number"
                                                   class="form-control form-control-sm"
                                                   wire:model.live="cant_piezas"
                                                   placeholder="12">
                                        </div>
                                        <div class="col-6">
                                            <label class="form-label">Contenido c/u</label>
                                            <input type="number"
                                                   step="0.001"
                                                   class="form-control form-control-sm"
                                                   wire:model.live="contenido_pieza"
                                                   placeholder="1.5">
                                        </div>
                                    </div>

                                    @if($factor_compra && $factor_compra != 1.0)
                                        <div class="alert alert-success mt-2 py-1 px-2 small">
                                            <i class="fa-solid fa-calculator me-1"></i>
                                            <strong>Factor calculado:</strong> {{ number_format($factor_compra, 3) }}
                                        </div>
                                    @endif

                                    <small class="text-muted d-block mt-2">
                                        <i class="fa-solid fa-info-circle me-1"></i>
                                        Cómo vende el proveedor (CAJA, PAQUETE, etc)
                                    </small>
                                </div>
                            </div>
                        </div>

                        {{-- Unidad de SALIDA (Recetas) --}}
                        <div class="col-md-4">
                            <div class="card bg-light h-100">
                                <div class="card-body">
                                    <h6 class="card-subtitle mb-2 text-muted">
                                        <i class="fa-solid fa-utensils me-1"></i>
                                        Unidad de SALIDA (Recetas)
                                    </h6>
                                    <label class="form-label">Unidad de salida</label>
                                    <select class="form-select @error('unidad_salida_id') is-invalid @enderror"
                                            wire:model="unidad_salida_id">
                                        <option value="">No aplica</option>
                                        @foreach($unidadesSalida as $u)
                                            <option value="{{ $u['id'] }}">
                                                {{ $u['clave'] }} - {{ $u['nombre'] }}
                                                @if(isset($u['categoria']))
                                                    <small>({{ $u['categoria'] }})</small>
                                                @endif
                                            </option>
                                        @endforeach
                                    </select>
                                    @error('unidad_salida_id')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                    @enderror
                                    <small class="text-muted d-block mt-2">
                                        <i class="fa-solid fa-info-circle me-1"></i>
                                        Unidad para recetas de cocina (ML, TAZA, PORCION)
                                    </small>
                                </div>
                            </div>
                        </div>
                    </div>

                    {{-- Presentación --}}
                    @if($presentacion_texto || ($cant_piezas && $contenido_pieza))
                        <div class="row mb-4">
                            <div class="col-12">
                                <div class="alert alert-info">
                                    <strong><i class="fa-solid fa-box-open me-2"></i>Vista previa de presentación:</strong>
                                    <div class="mt-2">
                                        @if($presentacion_texto)
                                            {{ $presentacion_texto }}
                                        @elseif($cant_piezas && $contenido_pieza)
                                            {{ $cant_piezas }} pzas de {{ number_format($contenido_pieza, 2) }}
                                            @if($unidad_medida_id)
                                                @php
                                                    $unidadBase = collect($unidadesBase)->firstWhere('id', $unidad_medida_id);
                                                @endphp
                                                {{ $unidadBase['clave'] ?? '' }}
                                            @endif
                                        @endif
                                    </div>
                                </div>
                            </div>
                            <div class="col-12">
                                <label class="form-label">Texto de presentación personalizado</label>
                                <input type="text"
                                       class="form-control"
                                       wire:model="presentacion_texto"
                                       placeholder="Ej: 12 pzas de 1.5 L">
                                <small class="text-muted">Si lo dejas vacío, se generará automáticamente</small>
                            </div>
                        </div>
                    @endif

                    {{-- Propiedades físicas --}}
                    <div class="row mb-4">
                        <div class="col-12">
                            <h6 class="text-primary border-bottom pb-2 mb-3">
                                <i class="fa-solid fa-temperature-half me-2"></i>Propiedades Físicas
                            </h6>
                        </div>
                        <div class="col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input"
                                       type="checkbox"
                                       id="perishable"
                                       wire:model="perishable">
                                <label class="form-check-label" for="perishable">
                                    <i class="fa-solid fa-snowflake me-1"></i>Perecedero
                                </label>
                            </div>
                        </div>
                        @if($perishable)
                            <div class="col-md-3">
                                <label class="form-label">Temp. mínima (°C)</label>
                                <input type="number"
                                       class="form-control @error('temperatura_min') is-invalid @enderror"
                                       wire:model="temperatura_min"
                                       placeholder="4">
                                @error('temperatura_min')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-md-3">
                                <label class="form-label">Temp. máxima (°C)</label>
                                <input type="number"
                                       class="form-control @error('temperatura_max') is-invalid @enderror"
                                       wire:model="temperatura_max"
                                       placeholder="8">
                                @error('temperatura_max')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        @endif
                    </div>

                    {{-- Costo y Estado --}}
                    <div class="row mb-4">
                        <div class="col-12">
                            <h6 class="text-primary border-bottom pb-2 mb-3">
                                <i class="fa-solid fa-dollar-sign me-2"></i>Costo y Estado
                            </h6>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Costo promedio</label>
                            <div class="input-group">
                                <span class="input-group-text">$</span>
                                <input type="number"
                                       step="0.01"
                                       class="form-control @error('costo_promedio') is-invalid @enderror"
                                       wire:model="costo_promedio"
                                       placeholder="0.00">
                                @error('costo_promedio')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="form-check form-switch mt-4">
                                <input class="form-check-input"
                                       type="checkbox"
                                       id="activo"
                                       wire:model="activo">
                                <label class="form-check-label" for="activo">
                                    <i class="fa-solid fa-circle-check me-1"></i>Activo
                                </label>
                            </div>
                        </div>
                    </div>

                    {{-- Botones --}}
                    <div class="row">
                        <div class="col-12">
                            <hr>
                            @error('form')
                                <div class="alert alert-danger">
                                    <i class="fa-solid fa-triangle-exclamation me-2"></i>
                                    {{ $message }}
                                </div>
                            @enderror
                            <div class="d-flex justify-content-between">
                                <a href="{{ route('inventory.items') }}" class="btn btn-secondary">
                                    <i class="fa-solid fa-arrow-left me-2"></i>Cancelar
                                </a>
                                <button type="submit" class="btn btn-primary">
                                    <i class="fa-solid fa-save me-2"></i>Guardar Item
                                </button>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    @endif
</div>
