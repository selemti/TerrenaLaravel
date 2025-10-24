<div>
    {{-- Header --}}
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-1">Pedidos Sugeridos</h2>
            <p class="text-muted mb-0">Sistema de reposición automática de inventario</p>
        </div>
        <div class="d-flex gap-2">
            <button wire:click="generarSugerencias"
                    wire:loading.attr="disabled"
                    class="btn btn-primary">
                <span wire:loading.remove wire:target="generarSugerencias">
                    <i class="fa-solid fa-magic me-2"></i>Generar Sugerencias
                </span>
                <span wire:loading wire:target="generarSugerencias">
                    <i class="fa-solid fa-spinner fa-spin me-2"></i>Generando...
                </span>
            </button>
        </div>
    </div>

    {{-- Estadísticas --}}
    <div class="row g-3 mb-4" wire:poll.30s>
        <div class="col-md-2">
            <div class="card shadow-sm text-center">
                <div class="card-body py-3">
                    <h4 class="mb-0">{{ $stats['total'] }}</h4>
                    <small class="text-muted">Total</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-warning">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-warning">{{ $stats['pendientes'] }}</h4>
                    <small class="text-muted">Pendientes</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-danger">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-danger">{{ $stats['urgentes'] }}</h4>
                    <small class="text-muted">Urgentes</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-info">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-info">{{ $stats['compras'] }}</h4>
                    <small class="text-muted">Compras</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-success">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-success">{{ $stats['producciones'] }}</h4>
                    <small class="text-muted">Producciones</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-primary">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-primary">{{ $stats['convertidas_hoy'] }}</h4>
                    <small class="text-muted">Convertidas Hoy</small>
                </div>
            </div>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-3">
                    <input type="text"
                           class="form-control"
                           wire:model.live.debounce.300ms="search"
                           placeholder="Buscar por folio o item...">
                </div>
                <div class="col-md-2">
                    <select class="form-select" wire:model.live="tipoFilter">
                        <option value="all">Todos los tipos</option>
                        <option value="COMPRA">Compras</option>
                        <option value="PRODUCCION">Producciones</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <select class="form-select" wire:model.live="prioridadFilter">
                        <option value="all">Todas las prioridades</option>
                        <option value="URGENTE">Urgente</option>
                        <option value="ALTA">Alta</option>
                        <option value="NORMAL">Normal</option>
                        <option value="BAJA">Baja</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <select class="form-select" wire:model.live="estadoFilter">
                        <option value="all">Todos los estados</option>
                        <option value="PENDIENTE">Pendiente</option>
                        <option value="REVISADA">Revisada</option>
                        <option value="APROBADA">Aprobada</option>
                        <option value="CONVERTIDA">Convertida</option>
                        <option value="RECHAZADA">Rechazada</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <select class="form-select" wire:model.live="sucursalFilter">
                        <option value="all">Todas las sucursales</option>
                        @foreach($sucursales as $sucursal)
                            <option value="{{ $sucursal->id }}">{{ $sucursal->nombre }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-1">
                    <button class="btn btn-outline-secondary w-100"
                            wire:click="limpiarFiltros"
                            title="Limpiar filtros">
                        <i class="fa-solid fa-filter-circle-xmark"></i>
                    </button>
                </div>
            </div>
            <div class="row mt-2">
                <div class="col-md-3">
                    <div class="form-check">
                        <input class="form-check-input"
                               type="checkbox"
                               wire:model.live="urgenciasOnly"
                               id="urgenciasOnly">
                        <label class="form-check-label" for="urgenciasOnly">
                            <i class="fa-solid fa-triangle-exclamation text-warning me-1"></i>
                            Solo urgencias
                        </label>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Acciones múltiples --}}
    @if(count($selectedIds) > 0)
    <div class="alert alert-info d-flex justify-content-between align-items-center mb-3">
        <span>
            <i class="fa-solid fa-check-circle me-2"></i>
            <strong>{{ count($selectedIds) }}</strong> sugerencias seleccionadas
        </span>
        <div class="btn-group">
            <button class="btn btn-sm btn-success"
                    wire:click="aprobarSeleccionadas"
                    wire:confirm="¿Aprobar {{ count($selectedIds) }} sugerencias?">
                <i class="fa-solid fa-check me-1"></i>Aprobar Todas
            </button>
            <button class="btn btn-sm btn-primary"
                    wire:click="convertirSeleccionadasACompra"
                    wire:confirm="¿Convertir {{ count($selectedIds) }} sugerencias a compras?">
                <i class="fa-solid fa-shopping-cart me-1"></i>Convertir a Compras
            </button>
        </div>
    </div>
    @endif

    {{-- Tabla de sugerencias --}}
    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th style="width: 40px;">
                                <input type="checkbox"
                                       class="form-check-input"
                                       wire:model.live="selectAll">
                            </th>
                            <th>Folio</th>
                            <th>Item</th>
                            <th>Sucursal</th>
                            <th class="text-center">Tipo</th>
                            <th class="text-center">Prioridad</th>
                            <th class="text-end">Stock</th>
                            <th class="text-end">Sugerida</th>
                            <th class="text-center">Días Rest.</th>
                            <th class="text-center">Estado</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($suggestions as $suggestion)
                            <tr class="{{ $suggestion->prioridad === 'URGENTE' ? 'table-danger' : '' }}">
                                <td>
                                    @if($suggestion->puede_aprobarse)
                                    <input type="checkbox"
                                           class="form-check-input"
                                           wire:model.live="selectedIds"
                                           value="{{ $suggestion->id }}">
                                    @endif
                                </td>
                                <td>
                                    <strong>{{ $suggestion->folio }}</strong>
                                    <br>
                                    <small class="text-muted">
                                        {{ $suggestion->sugerido_en->format('d/m/Y H:i') }}
                                    </small>
                                </td>
                                <td>
                                    <strong>{{ $suggestion->item->item_code ?? $suggestion->item_id }}</strong>
                                    <br>
                                    <small class="text-muted">{{ $suggestion->item->nombre ?? '-' }}</small>
                                </td>
                                <td>
                                    <small>{{ $suggestion->sucursal->nombre ?? '-' }}</small>
                                </td>
                                <td class="text-center">{!! $suggestion->tipo_badge !!}</td>
                                <td class="text-center">
                                    {!! $suggestion->urgencia_icono !!}
                                    {!! $suggestion->prioridad_badge !!}
                                </td>
                                <td class="text-end">
                                    <strong>{{ number_format($suggestion->stock_actual, 2) }}</strong>
                                    <br>
                                    <small class="text-muted">
                                        Min: {{ number_format($suggestion->stock_min, 2) }}
                                    </small>
                                </td>
                                <td class="text-end">
                                    <strong>{{ number_format($suggestion->qty_sugerida, 2) }}</strong>
                                    {{ $suggestion->uom }}
                                </td>
                                <td class="text-center">
                                    @if($suggestion->dias_stock_restante !== null)
                                        <span class="badge {{ $suggestion->dias_stock_restante <= 1 ? 'bg-danger' : ($suggestion->dias_stock_restante <= 3 ? 'bg-warning' : 'bg-secondary') }}">
                                            {{ $suggestion->dias_stock_restante }} día(s)
                                        </span>
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                <td class="text-center">{!! $suggestion->estado_badge !!}</td>
                                <td class="text-end">
                                    <div class="btn-group btn-group-sm">
                                        @if($suggestion->puede_aprobarse)
                                            <button class="btn btn-outline-success"
                                                    wire:click="aprobar({{ $suggestion->id }})"
                                                    title="Aprobar">
                                                <i class="fa-solid fa-check"></i>
                                            </button>
                                            <button class="btn btn-outline-danger"
                                                    wire:click="$dispatch('openRejectModal', { id: {{ $suggestion->id }} })"
                                                    title="Rechazar">
                                                <i class="fa-solid fa-times"></i>
                                            </button>
                                        @endif

                                        @if($suggestion->estado === 'APROBADA')
                                            @if($suggestion->tipo === 'COMPRA')
                                                <button class="btn btn-outline-primary"
                                                        wire:click="convertirACompra({{ $suggestion->id }})"
                                                        title="Convertir a Compra">
                                                    <i class="fa-solid fa-shopping-cart"></i>
                                                </button>
                                            @else
                                                <button class="btn btn-outline-success"
                                                        wire:click="convertirAProduccion({{ $suggestion->id }})"
                                                        title="Convertir a Producción">
                                                    <i class="fa-solid fa-industry"></i>
                                                </button>
                                            @endif
                                        @endif

                                        <button class="btn btn-outline-info"
                                                title="Ver detalle">
                                            <i class="fa-solid fa-eye"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="11" class="text-center py-4 text-muted">
                                    <i class="fa-solid fa-inbox fa-2x mb-2 d-block"></i>
                                    No se encontraron sugerencias con los filtros aplicados
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        {{-- Paginación --}}
        @if($suggestions->hasPages())
            <div class="card-footer">
                {{ $suggestions->links() }}
            </div>
        @endif
    </div>

    {{-- Loading overlay --}}
    <div wire:loading.flex
         wire:target="generarSugerencias,aprobarSeleccionadas,convertirSeleccionadasACompra"
         class="position-fixed top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center"
         style="background: rgba(0,0,0,0.5); z-index: 9999;">
        <div class="spinner-border text-light" style="width: 3rem; height: 3rem;" role="status">
            <span class="visually-hidden">Procesando...</span>
        </div>
    </div>
</div>

@push('scripts')
<script>
    // Notificaciones
    document.addEventListener('livewire:init', () => {
        Livewire.on('notify', (event) => {
            const data = event[0] || event;
            const type = data.type || 'info';
            const message = data.message || 'Operación completada';

            // Aquí puedes usar tu sistema de notificaciones preferido
            // Por ahora solo console.log, pero puedes integrar toastr, sweetalert, etc.
            console.log(`[${type.toUpperCase()}] ${message}`);

            // Ejemplo con alert básico (reemplazar con tu librería)
            if (type === 'error') {
                alert('❌ ' + message);
            } else if (type === 'success') {
                alert('✅ ' + message);
            }
        });
    });
</script>
@endpush
