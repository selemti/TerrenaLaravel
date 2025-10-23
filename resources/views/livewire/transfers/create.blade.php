<div class="py-3">
    <div class="row justify-content-center">
        <div class="col-xl-10">
            {{-- Header --}}
            <div class="card shadow-sm mb-3">
                <div class="card-header bg-white border-bottom">
                    <div class="d-flex align-items-center">
                        <i class="fa-solid fa-truck-ramp-box text-primary me-2 fs-4"></i>
                        <div>
                            <h5 class="mb-0 fw-bold">Nueva Transferencia</h5>
                            <small class="text-muted">Movimiento de inventario entre almacenes</small>
                        </div>
                    </div>
                </div>
                <div class="card-body">
                    <form wire:submit.prevent="save">
                        <div class="row g-3">
                            {{-- Almacén origen --}}
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">
                                    Almacén de origen <span class="text-danger">*</span>
                                </label>
                                <select class="form-select @error('form.almacen_origen_id') is-invalid @enderror"
                                        wire:model.defer="form.almacen_origen_id">
                                    <option value="">-- Selecciona almacén --</option>
                                    @foreach($almacenes as $alm)
                                        <option value="{{ $alm['id'] }}">{{ $alm['nombre'] }}</option>
                                    @endforeach
                                </select>
                                @error('form.almacen_origen_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                                <small class="text-muted">Desde dónde se envía el inventario</small>
                            </div>

                            {{-- Almacén destino --}}
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">
                                    Almacén de destino <span class="text-danger">*</span>
                                </label>
                                <select class="form-select @error('form.almacen_destino_id') is-invalid @enderror"
                                        wire:model.defer="form.almacen_destino_id">
                                    <option value="">-- Selecciona almacén --</option>
                                    @foreach($almacenes as $alm)
                                        <option value="{{ $alm['id'] }}">{{ $alm['nombre'] }}</option>
                                    @endforeach
                                </select>
                                @error('form.almacen_destino_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                                <small class="text-muted">Hacia dónde se recibe el inventario</small>
                            </div>

                            {{-- Fecha solicitada --}}
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">
                                    Fecha solicitada <span class="text-danger">*</span>
                                </label>
                                <input type="date"
                                       class="form-control @error('form.fecha_solicitada') is-invalid @enderror"
                                       wire:model.defer="form.fecha_solicitada"
                                       min="{{ now()->format('Y-m-d') }}">
                                @error('form.fecha_solicitada')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            {{-- Observaciones --}}
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Observaciones</label>
                                <textarea class="form-control @error('form.observaciones') is-invalid @enderror"
                                          wire:model.defer="form.observaciones"
                                          rows="2"
                                          placeholder="Notas adicionales sobre la transferencia"></textarea>
                                @error('form.observaciones')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                    </form>
                </div>
            </div>

            {{-- Líneas de items --}}
            <div class="card shadow-sm">
                <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-boxes-stacked me-2"></i>
                        Ítems a transferir ({{ count($lineas) }})
                    </h6>
                    <button type="button" class="btn btn-sm btn-outline-primary" wire:click="addLinea">
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
                            @forelse($lineas as $index => $linea)
                                <tr>
                                    <td>
                                        <select class="form-select form-select-sm @error('lineas.'.$index.'.item_id') is-invalid @enderror"
                                                wire:model.defer="lineas.{{ $index }}.item_id">
                                            <option value="">-- Selecciona ítem --</option>
                                            @foreach($items as $item)
                                                <option value="{{ $item['id'] }}">{{ $item['nombre'] }}</option>
                                            @endforeach
                                        </select>
                                        @error('lineas.'.$index.'.item_id')
                                            <div class="invalid-feedback d-block">{{ $message }}</div>
                                        @enderror
                                    </td>
                                    <td>
                                        <input type="number"
                                               step="0.01"
                                               class="form-control form-control-sm text-end @error('lineas.'.$index.'.cantidad') is-invalid @enderror"
                                               wire:model.defer="lineas.{{ $index }}.cantidad"
                                               placeholder="0.00">
                                        @error('lineas.'.$index.'.cantidad')
                                            <div class="invalid-feedback d-block">{{ $message }}</div>
                                        @enderror
                                    </td>
                                    <td>
                                        <select class="form-select form-select-sm @error('lineas.'.$index.'.uom_id') is-invalid @enderror"
                                                wire:model.defer="lineas.{{ $index }}.uom_id">
                                            <option value="">-- UOM --</option>
                                            @if(!empty($linea['item_id']))
                                                @php
                                                    $selectedItem = collect($items)->firstWhere('id', $linea['item_id']);
                                                @endphp
                                                @if($selectedItem)
                                                    <option value="{{ $selectedItem['uom_id'] }}" selected>
                                                        {{ $selectedItem['uom_codigo'] }}
                                                    </option>
                                                @endif
                                            @endif
                                        </select>
                                        @error('lineas.'.$index.'.uom_id')
                                            <div class="invalid-feedback d-block">{{ $message }}</div>
                                        @enderror
                                    </td>
                                    <td class="text-end">
                                        <button type="button"
                                                class="btn btn-sm btn-outline-danger"
                                                wire:click="removeLinea({{ $index }})"
                                                {{ count($lineas) === 1 ? 'disabled' : '' }}>
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
                    <a href="{{ url('/inventario') }}" class="btn btn-outline-secondary">
                        <i class="fa-solid fa-arrow-left me-1"></i>
                        Cancelar
                    </a>
                    <button type="button" class="btn btn-success" wire:click="save" {{ $loading ? 'disabled' : '' }}>
                        @if($loading)
                            <span class="spinner-border spinner-border-sm me-1"></span>
                            Guardando...
                        @else
                            <i class="fa-solid fa-floppy-disk me-1"></i>
                            Crear transferencia
                        @endif
                    </button>
                </div>
            </div>

            {{-- Info de ayuda --}}
            <div class="alert alert-info mt-3 d-flex align-items-start">
                <i class="fa-solid fa-circle-info mt-1 me-2"></i>
                <div class="small">
                    <strong>Flujo de transferencia:</strong>
                    Una vez creada, la transferencia quedará en estado <span class="badge text-bg-secondary">BORRADOR</span>.
                    Debe ser <strong>despachada</strong> desde el almacén de origen y posteriormente <strong>recibida</strong>
                    (completa o parcialmente) en el almacén destino.
                </div>
            </div>
        </div>
    </div>
</div>
