<div>
    {{-- Header --}}
    <div class="d-flex align-items-center mb-4">
        <a href="{{ route('production.show', $orden->id) }}" class="btn btn-outline-secondary me-3">
            <i class="bi bi-arrow-left"></i> Volver
        </a>
        <h3 class="mb-0">Capturar Producción &mdash; {{ $orden->folio }}</h3>
        <span class="badge bg-{{ $orden->estado === 'pendiente' ? 'warning' : 'info' }} ms-3">{{ ucfirst($orden->estado) }}</span>
    </div>

    {{-- Flash messages --}}
    @if (session()->has('message'))
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="bi bi-check-circle-fill me-1"></i> {{ session('message') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    @endif
    @if (session()->has('error'))
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="bi bi-exclamation-triangle-fill me-1"></i> {{ session('error') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    @endif

    {{-- Order summary --}}
    <div class="card shadow-sm mb-4">
        <div class="card-header bg-light">
            <h5 class="mb-0"><i class="bi bi-info-circle me-1"></i> Resumen de Orden</h5>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-3">
                    <strong>Receta:</strong><br>{{ $orden->receta_nombre }}
                </div>
                <div class="col-md-3">
                    <strong>Producto:</strong><br>{{ $orden->item_nombre }} <small class="text-muted">({{ $orden->item_codigo }})</small>
                </div>
                <div class="col-md-3">
                    <strong>Qty Programada:</strong><br>{{ number_format($orden->qty_programada, 3) }}
                </div>
                <div class="col-md-3">
                    <strong>UOM:</strong><br>{{ $orden->uom_base }}
                </div>
            </div>
        </div>
    </div>

    {{-- BOM insumos table --}}
    <div class="card shadow-sm mb-4">
        <div class="card-header bg-light">
            <h5 class="mb-0"><i class="bi bi-list-check me-1"></i> Insumos (BOM)</h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Item</th>
                            <th class="text-end">Cantidad Requerida</th>
                            <th>UOM</th>
                            <th class="text-end">Merma %</th>
                            <th class="text-end">Stock Disponible</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($insumos as $insumo)
                            @php
                                $requerida = $insumo->cantidad * $orden->qty_programada;
                                $stock = $stockPorItem[$insumo->item_id] ?? 0;
                            @endphp
                            <tr class="{{ $stock < $requerida ? 'table-danger' : '' }}">
                                <td>
                                    {{ $insumo->item_nombre }}
                                    <small class="text-muted d-block">{{ $insumo->item_codigo }}</small>
                                </td>
                                <td class="text-end">{{ number_format($requerida, 3) }}</td>
                                <td>{{ $insumo->uom_clave }}</td>
                                <td class="text-end">{{ number_format($insumo->merma_porcentaje, 2) }}%</td>
                                <td class="text-end">
                                    {{ number_format($stock, 3) }}
                                    @if ($stock < $requerida)
                                        <i class="bi bi-exclamation-triangle-fill text-danger ms-1" title="Stock insuficiente"></i>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="text-center text-muted py-3">No hay insumos registrados.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    {{-- Capture form --}}
    <div class="card shadow-sm mb-4">
        <div class="card-header bg-light">
            <h5 class="mb-0"><i class="bi bi-pencil-square me-1"></i> Datos de Producción</h5>
        </div>
        <div class="card-body">
            <form wire:submit="completar">
                <div class="row g-3">
                    {{-- Cantidad Producida --}}
                    <div class="col-md-6">
                        <label for="qtyProducida" class="form-label">Cantidad Producida</label>
                        <input type="number" step="0.001" id="qtyProducida"
                               wire:model="qtyProducida"
                               class="form-control @error('qtyProducida') is-invalid @enderror">
                        @error('qtyProducida')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    {{-- Merma --}}
                    <div class="col-md-6">
                        <label for="qtyMerma" class="form-label">Merma</label>
                        <input type="number" step="0.001" id="qtyMerma"
                               wire:model="qtyMerma"
                               class="form-control @error('qtyMerma') is-invalid @enderror">
                        @error('qtyMerma')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    {{-- Lote Producido --}}
                    <div class="col-md-6">
                        <label for="loteProducido" class="form-label">Lote Producido</label>
                        <input type="text" id="loteProducido"
                               wire:model="loteProducido"
                               class="form-control @error('loteProducido') is-invalid @enderror">
                        @error('loteProducido')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    {{-- Fecha Caducidad --}}
                    <div class="col-md-6">
                        <label for="fechaCaducidad" class="form-label">Fecha de Caducidad</label>
                        <input type="date" id="fechaCaducidad"
                               wire:model="fechaCaducidad"
                               class="form-control @error('fechaCaducidad') is-invalid @enderror">
                        @error('fechaCaducidad')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    {{-- Notas --}}
                    <div class="col-12">
                        <label for="notas" class="form-label">Notas</label>
                        <textarea id="notas" rows="3"
                                  wire:model="notas"
                                  class="form-control @error('notas') is-invalid @enderror"></textarea>
                        @error('notas')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>
                </div>

                {{-- Submit --}}
                <div class="mt-4 d-flex justify-content-end">
                    <button type="submit" class="btn btn-success btn-lg"
                            wire:confirm="Esta accion completara la orden de produccion y descontara insumos del inventario. Desea continuar?"
                            wire:loading.attr="disabled">
                        <span wire:loading.remove wire:target="completar">
                            <i class="bi bi-check-circle me-1"></i> Completar Producción
                        </span>
                        <span wire:loading wire:target="completar">
                            <span class="spinner-border spinner-border-sm me-1" role="status"></span> Procesando...
                        </span>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
