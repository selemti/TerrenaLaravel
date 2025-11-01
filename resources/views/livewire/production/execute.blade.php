<div>
    <div class="container-fluid py-4">
        <div class="row mb-3 g-3 align-items-center">
            <div class="col">
                <h2 class="h4 mb-0">
                    <i class="fa-solid fa-gears me-2 text-primary"></i>
                    Ejecutar orden #{{ $order->folio ?? $order->id }}
                </h2>
                <p class="text-muted small mb-0">
                    Receta: {{ $order->recipe?->nombre ?? $order->item?->nombre ?? 'N/A' }} · Programado {{ optional($order->programado_para)->format('d/m/Y H:i') ?? 'Sin fecha' }}
                </p>
            </div>
            <div class="col-auto">
                <a href="{{ route('production.detail', $order->id) }}" class="btn btn-outline-secondary">
                    <i class="fa-solid fa-eye me-2"></i>
                    Ver detalle
                </a>
            </div>
        </div>

        <x-progress-stepper :steps="[
            ['label' => 'Consumir insumos', 'number' => 1],
            ['label' => 'Registrar producción', 'number' => 2],
            ['label' => 'Postear inventario', 'number' => 3],
        ]" :current="$currentStep" />

        <div class="card shadow-sm border-0">
            <div class="card-body">
                @if($currentStep === 1)
                    <h5 class="fw-semibold mb-3">Consumo de insumos</h5>
                    <p class="text-muted small">Registra las cantidades reales consumidas. Ajusta unidades o lotes si fue necesario.</p>
                    <div class="table-responsive">
                        <table class="table align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Ítem</th>
                                    <th style="width: 20%">Cantidad</th>
                                    <th style="width: 15%">Unidad</th>
                                    <th style="width: 20%">Lote / Batch</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($consumos as $index => $line)
                                    <tr>
                                        <td>
                                            <div class="fw-semibold">{{ $line['item'] }}</div>
                                            <small class="text-muted">ID: {{ $line['item_id'] }}</small>
                                        </td>
                                        <td>
                                            <input type="number" step="0.01" min="0" class="form-control @error('consumos.' . $index . '.cantidad') is-invalid @enderror" wire:model.live="consumos.{{ $index }}.cantidad">
                                            @error('consumos.' . $index . '.cantidad')
                                                <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </td>
                                        <td>
                                            <input type="text" class="form-control @error('consumos.' . $index . '.uom') is-invalid @enderror" wire:model.live="consumos.{{ $index }}.uom">
                                            @error('consumos.' . $index . '.uom')
                                                <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </td>
                                        <td>
                                            <input type="text" class="form-control" wire:model.live="consumos.{{ $index }}.inventory_batch_id" placeholder="Lote consumido">
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                    <div class="text-end">
                        <button class="btn btn-primary" wire:click="saveConsumption" wire:loading.attr="disabled" wire:target="saveConsumption">
                            @if($processing)
                                <span class="spinner-border spinner-border-sm me-2"></span>
                            @endif
                            Guardar consumo y continuar
                        </button>
                    </div>
                @elseif($currentStep === 2)
                    <h5 class="fw-semibold mb-3">Producción y mermas</h5>
                    <p class="text-muted small">Registra el producto terminado y cualquier merma generada durante el proceso.</p>
                    <div class="table-responsive mb-4">
                        <table class="table align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Producto</th>
                                    <th style="width: 18%">Cantidad</th>
                                    <th style="width: 15%">Unidad</th>
                                    <th style="width: 20%">Lote generado</th>
                                    <th style="width: 20%">Caducidad</th>
                                    <th class="text-end">&nbsp;</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($producciones as $index => $line)
                                    <tr>
                                        <td>
                                            <div class="fw-semibold">{{ $line['item'] ?: $line['item_id'] }}</div>
                                            <small class="text-muted">ID: {{ $line['item_id'] }}</small>
                                        </td>
                                        <td>
                                            <input type="number" step="0.01" min="0" class="form-control @error('producciones.' . $index . '.cantidad') is-invalid @enderror" wire:model.live="producciones.{{ $index }}.cantidad">
                                            @error('producciones.' . $index . '.cantidad')
                                                <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </td>
                                        <td>
                                            <input type="text" class="form-control @error('producciones.' . $index . '.uom') is-invalid @enderror" wire:model.live="producciones.{{ $index }}.uom">
                                            @error('producciones.' . $index . '.uom')
                                                <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </td>
                                        <td>
                                            <input type="text" class="form-control" wire:model.live="producciones.{{ $index }}.lote" placeholder="Lote de producción">
                                        </td>
                                        <td>
                                            <input type="date" class="form-control" wire:model.live="producciones.{{ $index }}.caducidad">
                                        </td>
                                        <td class="text-end">
                                            <button type="button" class="btn btn-link text-danger" wire:click="removeProductionLine({{ $index }})" title="Eliminar">
                                                <i class="fa-solid fa-trash"></i>
                                            </button>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                    <button type="button" class="btn btn-outline-primary mb-4" wire:click="addProductionLine">
                        <i class="fa-solid fa-plus me-2"></i>
                        Agregar línea de producto
                    </button>

                    <h6 class="fw-semibold">Mermas declaradas</h6>
                    <div class="table-responsive mb-3">
                        <table class="table align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Ítem</th>
                                    <th style="width: 18%">Cantidad</th>
                                    <th style="width: 15%">Unidad</th>
                                    <th>Motivo</th>
                                    <th class="text-end">&nbsp;</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($mermas as $index => $waste)
                                    <tr>
                                        <td>
                                            <input type="text" class="form-control @error('mermas.' . $index . '.item_id') is-invalid @enderror" wire:model.live="mermas.{{ $index }}.item_id" placeholder="ID de ítem">
                                            @error('mermas.' . $index . '.item_id')
                                                <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </td>
                                        <td>
                                            <input type="number" step="0.01" min="0" class="form-control @error('mermas.' . $index . '.cantidad') is-invalid @enderror" wire:model.live="mermas.{{ $index }}.cantidad">
                                            @error('mermas.' . $index . '.cantidad')
                                                <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </td>
                                        <td>
                                            <input type="text" class="form-control" wire:model.live="mermas.{{ $index }}.uom" placeholder="Unidad">
                                        </td>
                                        <td>
                                            <input type="text" class="form-control" wire:model.live="mermas.{{ $index }}.motivo" placeholder="Motivo">
                                        </td>
                                        <td class="text-end">
                                            <button type="button" class="btn btn-link text-danger" wire:click="removeWasteLine({{ $index }})">
                                                <i class="fa-solid fa-trash"></i>
                                            </button>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="5" class="text-center text-muted">Sin mermas registradas.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                    <button type="button" class="btn btn-outline-secondary" wire:click="addWasteLine">
                        <i class="fa-solid fa-plus me-2"></i>
                        Agregar merma
                    </button>

                    <div class="text-end mt-4">
                        <button class="btn btn-primary" wire:click="saveProduction" wire:loading.attr="disabled" wire:target="saveProduction">
                            @if($processing)
                                <span class="spinner-border spinner-border-sm me-2"></span>
                            @endif
                            Guardar producción
                        </button>
                    </div>
                @else
                    <div class="text-center py-5">
                        <i class="fa-solid fa-warehouse text-success" style="font-size: 3rem;"></i>
                        <h5 class="mt-3">¿Listo para postear al inventario?</h5>
                        <p class="text-muted">Esta acción generará los movimientos de salida y entrada correspondientes y cerrará la orden.</p>
                        <button class="btn btn-success" wire:click="postOrder" wire:loading.attr="disabled" wire:target="postOrder">
                            @if($processing)
                                <span class="spinner-border spinner-border-sm me-2"></span>
                            @endif
                            Postear orden
                        </button>
                    </div>
                @endif

                <div class="d-flex justify-content-between mt-4">
                    <button type="button" class="btn btn-outline-secondary" @if($currentStep === 1) disabled @endif wire:click="goToStep({{ $currentStep - 1 }})">
                        <i class="fa-solid fa-arrow-left me-1"></i>
                        Paso anterior
                    </button>
                    @if($currentStep < 3)
                        <button type="button" class="btn btn-outline-primary" wire:click="goToStep({{ $currentStep + 1 }})">
                            Siguiente paso
                            <i class="fa-solid fa-arrow-right ms-1"></i>
                        </button>
                    @endif
                </div>

                @if($apiError)
                    <div class="alert alert-danger mt-3 mb-0">
                        {{ $apiError }}
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>
