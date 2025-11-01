<div>
    <div class="container-fluid py-4">
        <div class="row mb-3 g-3 align-items-center">
            <div class="col">
                <h2 class="h4 mb-0">
                    <i class="fa-solid fa-industry me-2 text-primary"></i>
                    Nueva orden de producción
                </h2>
            </div>
            <div class="col-auto">
                <a href="{{ route('production.index') }}" class="btn btn-outline-secondary">
                    <i class="fa-solid fa-arrow-left me-2"></i>
                    Regresar al listado
                </a>
            </div>
        </div>

        <x-progress-stepper :steps="[
            ['label' => 'Información general', 'number' => 1],
            ['label' => 'Ingredientes / insumos', 'number' => 2],
            ['label' => 'Revisión', 'number' => 3],
        ]" :current="$step" />

        <div class="card shadow-sm border-0">
            <div class="card-body">
                <form wire:submit.prevent="save">
                    @if($step === 1)
                        <div class="row g-3">
                            <div class="col-lg-6">
                                <label class="form-label">Receta <span class="text-danger">*</span></label>
                                <select class="form-select @error('form.receta_id') is-invalid @enderror" wire:model.live="form.receta_id">
                                    <option value="">Selecciona una receta…</option>
                                    @foreach($recetas as $receta)
                                        <option value="{{ $receta['id'] }}">{{ $receta['label'] }}</option>
                                    @endforeach
                                </select>
                                @error('form.receta_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-lg-6">
                                <label class="form-label">Versión de receta</label>
                                <select class="form-select @error('form.receta_version_id') is-invalid @enderror" wire:model.live="form.receta_version_id">
                                    <option value="">Selecciona una versión…</option>
                                    @foreach($versiones as $version)
                                        <option value="{{ $version['id'] }}">{{ $version['label'] }}</option>
                                    @endforeach
                                </select>
                                @error('form.receta_version_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Cantidad a producir <span class="text-danger">*</span></label>
                                <input type="number" step="0.01" min="0.01" class="form-control @error('form.cantidad_planeada') is-invalid @enderror" wire:model.live="form.cantidad_planeada">
                                @error('form.cantidad_planeada')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Sucursal <span class="text-danger">*</span></label>
                                <select class="form-select @error('form.sucursal_id') is-invalid @enderror" wire:model.live="form.sucursal_id">
                                    <option value="">Selecciona…</option>
                                    @foreach($sucursales as $sucursal)
                                        <option value="{{ $sucursal['id'] }}">{{ $sucursal['label'] }}</option>
                                    @endforeach
                                </select>
                                @error('form.sucursal_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Almacén destino <span class="text-danger">*</span></label>
                                <select class="form-select @error('form.almacen_id') is-invalid @enderror" wire:model.live="form.almacen_id">
                                    <option value="">Selecciona…</option>
                                    @foreach($almacenes as $almacen)
                                        <option value="{{ $almacen['id'] }}">{{ $almacen['label'] }}</option>
                                    @endforeach
                                </select>
                                @error('form.almacen_id')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Programado para</label>
                                <input type="datetime-local" class="form-control @error('form.programado_para') is-invalid @enderror" wire:model.live="form.programado_para">
                                @error('form.programado_para')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Notas</label>
                                <textarea class="form-control" rows="3" wire:model.live="form.notas" placeholder="Instrucciones especiales, lote objetivo, etc."></textarea>
                            </div>
                        </div>
                    @elseif($step === 2)
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead class="table-light">
                                    <tr>
                                        <th style="width: 35%">Ítem / insumo</th>
                                        <th style="width: 20%">Cantidad</th>
                                        <th style="width: 20%">Unidad</th>
                                        <th style="width: 20%">Lote origen (opcional)</th>
                                        <th class="text-end">&nbsp;</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($lineItems as $index => $line)
                                        <tr>
                                            <td>
                                                <select class="form-select @error('lineItems.' . $index . '.item_id') is-invalid @enderror" wire:model.live="lineItems.{{ $index }}.item_id">
                                                    <option value="">Selecciona ítem…</option>
                                                    @foreach($items as $item)
                                                        <option value="{{ $item['id'] }}">{{ $item['label'] }}</option>
                                                    @endforeach
                                                </select>
                                                @error('lineItems.' . $index . '.item_id')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                @enderror
                                            </td>
                                            <td>
                                                <input type="number" min="0.01" step="0.01" class="form-control @error('lineItems.' . $index . '.cantidad') is-invalid @enderror" wire:model.live="lineItems.{{ $index }}.cantidad">
                                                @error('lineItems.' . $index . '.cantidad')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                @enderror
                                            </td>
                                            <td>
                                                <select class="form-select @error('lineItems.' . $index . '.uom') is-invalid @enderror" wire:model.live="lineItems.{{ $index }}.uom">
                                                    @foreach($uoms as $uom)
                                                        <option value="{{ $uom['id'] }}">{{ $uom['label'] }}</option>
                                                    @endforeach
                                                </select>
                                                @error('lineItems.' . $index . '.uom')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                @enderror
                                            </td>
                                            <td>
                                                <input type="text" class="form-control" wire:model.live="lineItems.{{ $index }}.inventory_batch_id" placeholder="Lote / batch">
                                            </td>
                                            <td class="text-end">
                                                @if(count($lineItems) > 1)
                                                    <button type="button" class="btn btn-link text-danger" wire:click="removeLine({{ $index }})" title="Eliminar insumo">
                                                        <i class="fa-solid fa-trash"></i>
                                                    </button>
                                                @endif
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                        <button type="button" class="btn btn-outline-primary" wire:click="addLine">
                            <i class="fa-solid fa-plus me-2"></i>
                            Agregar insumo
                        </button>
                    @else
                        <div class="row g-3">
                            <div class="col-md-6">
                                <div class="border rounded p-3 h-100 bg-light-subtle">
                                    <h5 class="fw-semibold mb-3">Resumen general</h5>
                                    <ul class="list-unstyled mb-0 small">
                                        <li><strong>Receta:</strong> {{ optional(collect($recetas)->firstWhere('id', $form['receta_id']))['label'] ?? 'No definida' }}</li>
                                        <li><strong>Versión:</strong> {{ optional(collect($versiones)->firstWhere('id', $form['receta_version_id']))['label'] ?? 'No asignada' }}</li>
                                        <li><strong>Cantidad:</strong> {{ number_format((float) $form['cantidad_planeada'], 2) }}</li>
                                        <li><strong>Sucursal:</strong> {{ optional(collect($sucursales)->firstWhere('id', $form['sucursal_id']))['label'] ?? 'N/A' }}</li>
                                        <li><strong>Almacén:</strong> {{ optional(collect($almacenes)->firstWhere('id', $form['almacen_id']))['label'] ?? 'N/A' }}</li>
                                        <li><strong>Programado para:</strong> {{ $form['programado_para'] ? \Carbon\Carbon::parse($form['programado_para'])->format('d/m/Y H:i') : 'Sin fecha' }}</li>
                                    </ul>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="border rounded p-3 h-100">
                                    <h5 class="fw-semibold mb-3">Insumos planeados</h5>
                                    <ul class="list-unstyled small mb-0">
                                        @foreach($resumenLineas as $linea)
                                            <li class="d-flex justify-content-between">
                                                <span>{{ $linea['item'] }}</span>
                                                <span>{{ number_format($linea['cantidad'], 2) }} <span class="text-muted">{{ $linea['uom'] }}</span></span>
                                            </li>
                                        @endforeach
                                    </ul>
                                    <hr>
                                    <div class="d-flex justify-content-between fw-semibold">
                                        <span>Total insumos</span>
                                        <span>{{ number_format($totalCantidad, 2) }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endif

                    <div class="d-flex justify-content-between align-items-center mt-4">
                        <div>
                            @if($step > 1)
                                <button type="button" class="btn btn-outline-secondary" wire:click="goToStep({{ $step - 1 }})">
                                    <i class="fa-solid fa-arrow-left me-1"></i>
                                    Anterior
                                </button>
                            @endif
                        </div>
                        <div class="d-flex gap-2">
                            @if($step < 3)
                                <button type="button" class="btn btn-primary" wire:click="goToStep({{ $step + 1 }})">
                                    Siguiente
                                    <i class="fa-solid fa-arrow-right ms-1"></i>
                                </button>
                            @else
                                <button type="submit" class="btn btn-success" @if($saving) disabled @endif>
                                    @if($saving)
                                        <span class="spinner-border spinner-border-sm me-2"></span>
                                    @endif
                                    Crear orden de producción
                                </button>
                            @endif
                        </div>
                    </div>

                    @if($apiError)
                        <div class="alert alert-danger mt-3">
                            {{ $apiError }}
                        </div>
                    @endif
                </form>
            </div>
        </div>
    </div>
</div>
