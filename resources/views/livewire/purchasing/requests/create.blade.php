<div>
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-1">Nueva Solicitud de Compra</h2>
            <p class="text-muted mb-0">Crear requisición de materiales e insumos</p>
        </div>
        <a href="{{ route('purchasing.requests.index') }}" class="btn btn-outline-secondary">
            <i class="fa-solid fa-arrow-left me-2"></i>Volver
        </a>
    </div>

    <form wire:submit.prevent="crearSolicitud">
        {{-- Datos Generales --}}
        <div class="card shadow-sm mb-4">
            <div class="card-header bg-light">
                <h5 class="mb-0"><i class="fa-solid fa-file-lines me-2"></i>Datos Generales</h5>
            </div>
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label">Sucursal <small class="text-muted">(opcional)</small></label>
                        <select class="form-select" wire:model="sucursal_id">
                            <option value="">Sin asignar</option>
                            @foreach($sucursales as $sucursal)
                                <option value="{{ $sucursal->id }}">{{ $sucursal->nombre }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Fecha Requerida <span class="text-danger">*</span></label>
                        <input type="date" class="form-control @error('requested_at') is-invalid @enderror"
                               wire:model="requested_at" required>
                        @error('requested_at') <div class="invalid-feedback">{{ $message }}</div> @enderror
                    </div>
                    <div class="col-md-12">
                        <label class="form-label">Notas</label>
                        <textarea class="form-control" wire:model="notas" rows="2"
                                  placeholder="Observaciones, especificaciones..."></textarea>
                    </div>
                </div>
            </div>
        </div>

        {{-- Items Solicitados --}}
        <div class="card shadow-sm mb-4">
            <div class="card-header bg-light d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><i class="fa-solid fa-box me-2"></i>Items Solicitados</h5>
                <button type="button" class="btn btn-sm btn-primary" wire:click="$set('showItemModal', true)">
                    <i class="fa-solid fa-plus me-1"></i>Agregar Item
                </button>
            </div>
            <div class="card-body p-0">
                @if(count($lineas) > 0)
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 25%;">Item</th>
                                    <th style="width: 15%;">Cantidad</th>
                                    <th style="width: 10%;">UOM</th>
                                    <th style="width: 15%;">Fecha Req.</th>
                                    <th style="width: 20%;">Proveedor Pref.</th>
                                    <th style="width: 10%;">Precio Est.</th>
                                    <th style="width: 5%;"></th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($lineas as $index => $linea)
                                    <tr wire:key="linea-{{ $index }}">
                                        <td>
                                            <strong>{{ $linea['item_codigo'] }}</strong><br>
                                            <small class="text-muted">{{ $linea['item_nombre'] }}</small>
                                        </td>
                                        <td>
                                            <input type="number" class="form-control form-control-sm"
                                                   wire:model="lineas.{{ $index }}.qty" step="0.001" min="0.001" required>
                                        </td>
                                        <td>
                                            <input type="text" class="form-control form-control-sm"
                                                   wire:model="lineas.{{ $index }}.uom" required>
                                        </td>
                                        <td>
                                            <input type="date" class="form-control form-control-sm"
                                                   wire:model="lineas.{{ $index }}.fecha_requerida">
                                        </td>
                                        <td>
                                            <select class="form-select form-select-sm" wire:model="lineas.{{ $index }}.preferred_vendor_id">
                                                <option value="">Sin preferencia</option>
                                                @foreach($proveedores as $prov)
                                                    <option value="{{ $prov->id }}">{{ $prov->nombre }}</option>
                                                @endforeach
                                            </select>
                                        </td>
                                        <td class="text-end">
                                            <small>${{ number_format($linea['last_price'] ?? 0, 2) }}</small>
                                        </td>
                                        <td class="text-end">
                                            <button type="button" class="btn btn-sm btn-outline-danger"
                                                    wire:click="removerLinea({{ $index }})" title="Eliminar">
                                                <i class="fa-solid fa-trash"></i>
                                            </button>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                @else
                    <div class="text-center py-5 text-muted">
                        <i class="fa-solid fa-box-open fa-3x mb-3 d-block opacity-25"></i>
                        <p>No hay items agregados</p>
                        <button type="button" class="btn btn-primary" wire:click="$set('showItemModal', true)">
                            <i class="fa-solid fa-plus me-2"></i>Agregar Primer Item
                        </button>
                    </div>
                @endif
            </div>
            @if(count($lineas) > 0)
                <div class="card-footer bg-light">
                    <div class="row">
                        <div class="col-md-6">
                            <strong>Total items:</strong> {{ count($lineas) }}
                        </div>
                        <div class="col-md-6 text-end">
                            <strong>Importe estimado:</strong>
                            ${{ number_format(collect($lineas)->sum(fn($l) => $l['qty'] * ($l['last_price'] ?? 0)), 2) }}
                        </div>
                    </div>
                </div>
            @endif
        </div>

        {{-- Botones de Acción --}}
        <div class="d-flex justify-content-end gap-2">
            <a href="{{ route('purchasing.requests.index') }}" class="btn btn-outline-secondary">
                Cancelar
            </a>
            <button type="submit" class="btn btn-primary" @if(count($lineas) === 0) disabled @endif>
                <i class="fa-solid fa-save me-2"></i>Crear Solicitud
            </button>
        </div>
    </form>

    {{-- Modal de Búsqueda de Items --}}
    @if($showItemModal)
        <div class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Buscar Item</h5>
                        <button type="button" class="btn-close" wire:click="$set('showItemModal', false)"></button>
                    </div>
                    <div class="modal-body">
                        <input type="text" class="form-control mb-3" wire:model.live.debounce.300ms="searchItem"
                               placeholder="Buscar por código o nombre..." autofocus>

                        @if($searchItem && $items->count() > 0)
                            <div class="list-group">
                                @foreach($items as $item)
                                    <button type="button" class="list-group-item list-group-item-action"
                                            wire:click="agregarItem({{ $item->id }})">
                                        <div class="d-flex w-100 justify-content-between">
                                            <strong>{{ $item->codigo }}</strong>
                                            <small class="text-muted">${{ number_format($item->costo_promedio ?? 0, 2) }}</small>
                                        </div>
                                        <small class="text-muted">{{ $item->nombre }}</small>
                                    </button>
                                @endforeach
                            </div>
                            @if($items->hasPages())
                                <div class="mt-3">
                                    {{ $items->links() }}
                                </div>
                            @endif
                        @elseif($searchItem)
                            <div class="text-center text-muted py-4">
                                <i class="fa-solid fa-search fa-2x mb-2 d-block"></i>
                                No se encontraron items
                            </div>
                        @else
                            <div class="text-center text-muted py-4">
                                <i class="fa-solid fa-keyboard fa-2x mb-2 d-block"></i>
                                Escribe para buscar items
                            </div>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    @endif
</div>
