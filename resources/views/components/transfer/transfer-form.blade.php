@props([
    'formState' => [],
    'warehouses' => [],
    'items' => [],
    'lines' => [],
    'errors' => [],
    'loading' => false,
    'onSave' => null,
    'onAddLine' => null,
    'onRemoveLine' => null,
])

<div {{ $attributes->merge(['class' => '']) }}>
    {{-- Transfer Header Form --}}
    <div class="card shadow-sm mb-3">
        <div class="card-header bg-white border-bottom">
            <div class="d-flex align-items-center">
                <i class="fa-solid fa-truck-ramp-box text-primary me-2 fs-4"></i>
                <div>
                    <h5 class="mb-0 fw-bold">Detalles de Transferencia</h5>
                    <small class="text-muted">Información general de la transferencia</small>
                </div>
            </div>
        </div>
        <div class="card-body">
            <div class="row g-3">
                {{-- Almacén origen --}}
                <div class="col-md-6">
                    <label class="form-label fw-semibold">
                        Almacén de origen <span class="text-danger">*</span>
                    </label>
                    <select 
                        class="form-select @error('form.almacen_origen_id', $errors) is-invalid @enderror"
                        name="form[almacen_origen_id]"
                        wire:model.defer="form.almacen_origen_id"
                    >
                        <option value="">-- Selecciona almacén --</option>
                        @foreach($warehouses as $warehouse)
                            <option value="{{ $warehouse['id'] }}">{{ $warehouse['nombre'] }}</option>
                        @endforeach
                    </select>
                    @error('form.almacen_origen_id', $errors)
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                    <small class="text-muted">Desde dónde se envía el inventario</small>
                </div>

                {{-- Almacén destino --}}
                <div class="col-md-6">
                    <label class="form-label fw-semibold">
                        Almacén de destino <span class="text-danger">*</span>
                    </label>
                    <select 
                        class="form-select @error('form.almacen_destino_id', $errors) is-invalid @enderror"
                        name="form[almacen_destino_id]"
                        wire:model.defer="form.almacen_destino_id"
                    >
                        <option value="">-- Selecciona almacén --</option>
                        @foreach($warehouses as $warehouse)
                            <option value="{{ $warehouse['id'] }}">{{ $warehouse['nombre'] }}</option>
                        @endforeach
                    </select>
                    @error('form.almacen_destino_id', $errors)
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                    <small class="text-muted">Hacia dónde se recibe el inventario</small>
                </div>

                {{-- Fecha solicitada --}}
                <div class="col-md-6">
                    <label class="form-label fw-semibold">
                        Fecha solicitada <span class="text-danger">*</span>
                    </label>
                    <input 
                        type="date"
                        class="form-control @error('form.fecha_solicitada', $errors) is-invalid @enderror"
                        name="form[fecha_solicitada]"
                        wire:model.defer="form.fecha_solicitada"
                        min="{{ now()->format('Y-m-d') }}"
                    >
                    @error('form.fecha_solicitada', $errors)
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                {{-- Observaciones --}}
                <div class="col-md-6">
                    <label class="form-label fw-semibold">Observaciones</label>
                    <textarea 
                        class="form-control @error('form.observaciones', $errors) is-invalid @enderror"
                        name="form[observaciones]"
                        wire:model.defer="form.observaciones"
                        rows="2"
                        placeholder="Notas adicionales sobre la transferencia"
                    ></textarea>
                    @error('form.observaciones', $errors)
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>
            </div>
        </div>
    </div>

    {{-- Items Lines --}}
    <div class="card shadow-sm">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center">
            <h6 class="mb-0 fw-bold">
                <i class="fa-solid fa-boxes-stacked me-2"></i>
                Ítems a transferir ({{ count($lines) }})
            </h6>
            <button 
                type="button" 
                class="btn btn-sm btn-outline-primary" 
                wire:click="{{ $onAddLine }}"
            >
                <i class="fa-solid fa-plus me-1"></i>
                Agregar ítem
            </button>
        </div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th style="width: 40%;">Ítem</th>
                        <th style="width: 20%;">Cantidad</th>
                        <th style="width: 20%;">UOM</th>
                        <th style="width: 20%;" class="text-end">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($lines as $index => $line)
                        <tr>
                            <td>
                                <select 
                                    class="form-select form-select-sm @error('lineas.'.$index.'.item_id', $errors) is-invalid @enderror"
                                    name="lineas[{{ $index }}][item_id]"
                                    wire:model.defer="lineas.{{ $index }}.item_id"
                                >
                                    <option value="">-- Selecciona ítem --</option>
                                    @foreach($items as $item)
                                        <option value="{{ $item['id'] }}">{{ $item['nombre'] }}</option>
                                    @endforeach
                                </select>
                                @error('lineas.'.$index.'.item_id', $errors)
                                    <div class="invalid-feedback d-block">{{ $message }}</div>
                                @enderror
                            </td>
                            <td>
                                <input 
                                    type="number"
                                    step="0.01"
                                    class="form-control form-control-sm text-end @error('lineas.'.$index.'.cantidad', $errors) is-invalid @enderror"
                                    name="lineas[{{ $index }}][cantidad]"
                                    wire:model.defer="lineas.{{ $index }}.cantidad"
                                    placeholder="0.00"
                                >
                                @error('lineas.'.$index.'.cantidad', $errors)
                                    <div class="invalid-feedback d-block">{{ $message }}</div>
                                @enderror
                            </td>
                            <td>
                                <select 
                                    class="form-select form-select-sm @error('lineas.'.$index.'.uom_id', $errors) is-invalid @enderror"
                                    name="lineas[{{ $index }}][uom_id]"
                                    wire:model.defer="lineas.{{ $index }}.uom_id"
                                >
                                    <option value="">-- UOM --</option>
                                    @if(!empty($line['item_id']))
                                        @php
                                            $selectedItem = collect($items)->firstWhere('id', $line['item_id']);
                                        @endphp
                                        @if($selectedItem)
                                            <option value="{{ $selectedItem['uom_id'] }}" selected>
                                                {{ $selectedItem['uom_codigo'] }}
                                            </option>
                                        @endif
                                    @endif
                                </select>
                                @error('lineas.'.$index.'.uom_id', $errors)
                                    <div class="invalid-feedback d-block">{{ $message }}</div>
                                @enderror
                            </td>
                            <td class="text-end">
                                <button 
                                    type="button"
                                    class="btn btn-sm btn-outline-danger"
                                    wire:click="{{ $onRemoveLine }}({{ $index }})"
                                    {{ count($lines) === 1 ? 'disabled' : '' }}
                                >
                                    <i class="fa-solid fa-trash"></i>
                                </button>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="text-center text-muted py-3">
                                No hay ítems. Usa el botón "Agregar ítem".
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div class="card-footer bg-light d-flex justify-content-between">
            {{ $footer }}
        </div>
    </div>
</div>