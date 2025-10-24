<div>
    <div class="container-fluid py-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h2 class="mb-1">
                    <i class="fa-solid fa-plus-circle text-success me-2"></i>
                    Nuevo Conteo de Inventario
                </h2>
                <p class="text-muted mb-0">Seleccione los items a contar</p>
            </div>
            <a href="{{ route('inv.counts.index') }}" class="btn btn-outline-secondary">
                <i class="fa-solid fa-arrow-left me-1"></i>
                Volver
            </a>
        </div>

        <form wire:submit.prevent="crearConteo">
            {{-- Datos Generales --}}
            <div class="card shadow-sm mb-4">
                <div class="card-header bg-primary text-white">
                    <h5 class="mb-0">Datos del Conteo</h5>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label">Sucursal</label>
                            <select class="form-select" wire:model="form.sucursal_id">
                                <option value="">-- Seleccionar --</option>
                                @foreach($sucursales as $suc)
                                    <option value="{{ $suc->id }}">{{ $suc->nombre }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Almacén</label>
                            <select class="form-select" wire:model.live="form.almacen_id">
                                <option value="">-- Seleccionar --</option>
                                @foreach($almacenes as $alm)
                                    <option value="{{ $alm->id }}">{{ $alm->nombre }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Programado Para</label>
                            <input type="datetime-local"
                                   class="form-control"
                                   wire:model="form.programado_para">
                        </div>
                        <div class="col-12">
                            <label class="form-label">Notas</label>
                            <textarea class="form-control"
                                      rows="2"
                                      wire:model="form.notas"
                                      placeholder="Notas adicionales (opcional)"></textarea>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Selección de Items --}}
            <div class="card shadow-sm mb-4">
                <div class="card-header bg-info text-white">
                    <div class="d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">Items a Contar ({{ count($selectedItems) }} seleccionados)</h5>
                        <div>
                            <button type="button" class="btn btn-sm btn-light" wire:click="seleccionarTodos">
                                <i class="fa-solid fa-check-double"></i> Todos
                            </button>
                            <button type="button" class="btn btn-sm btn-light" wire:click="limpiarSeleccion">
                                <i class="fa-solid fa-times"></i> Limpiar
                            </button>
                        </div>
                    </div>
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <input type="text"
                               class="form-control"
                               wire:model.live="itemSearch"
                               placeholder="Buscar items por código o nombre...">
                    </div>

                    <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                        <table class="table table-sm table-hover">
                            <thead class="table-light sticky-top">
                                <tr>
                                    <th width="50"></th>
                                    <th>Código</th>
                                    <th>Nombre</th>
                                    <th>UOM</th>
                                    <th>Stock Teórico</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($items as $item)
                                    <tr wire:click="toggleItem({{ $item->id }})"
                                        style="cursor: pointer;"
                                        class="{{ isset($selectedItems[$item->id]) ? 'table-primary' : '' }}">
                                        <td>
                                            <input type="checkbox"
                                                   class="form-check-input"
                                                   {{ isset($selectedItems[$item->id]) ? 'checked' : '' }}>
                                        </td>
                                        <td>{{ $item->codigo }}</td>
                                        <td>{{ $item->nombre }}</td>
                                        <td>{{ $item->uom_base }}</td>
                                        <td>
                                            @if(isset($selectedItems[$item->id]))
                                                <strong class="text-primary">
                                                    {{ number_format($selectedItems[$item->id]['qty_teorica'], 2) }}
                                                </strong>
                                            @else
                                                -
                                            @endif
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            {{-- Botones de Acción --}}
            <div class="d-flex justify-content-end gap-2">
                <a href="{{ route('inv.counts.index') }}" class="btn btn-secondary">
                    <i class="fa-solid fa-times me-1"></i>
                    Cancelar
                </a>
                <button type="submit" class="btn btn-success" {{ count($selectedItems) === 0 ? 'disabled' : '' }}>
                    <i class="fa-solid fa-check me-1"></i>
                    Crear Conteo
                </button>
            </div>
        </form>
    </div>
</div>
