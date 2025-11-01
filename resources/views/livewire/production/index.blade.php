<div>
    <div class="container-fluid py-4">
        <div class="row align-items-center mb-4 g-3">
            <div class="col-md-6">
                <h2 class="h4 mb-0">
                    <i class="fa-solid fa-industry me-2 text-primary"></i>
                    Órdenes de producción
                </h2>
            </div>
            <div class="col-md-6 text-md-end">
                <a href="{{ route('production.create') }}" class="btn btn-primary">
                    <i class="fa-solid fa-plus me-2"></i>
                    Nueva orden
                </a>
            </div>
        </div>

        <div class="card shadow-sm border-0 mb-4">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">Estado</label>
                        <select class="form-select" wire:model.live="estado">
                            <option value="">Todos</option>
                            @foreach($estadosDisponibles as $estadoOption)
                                <option value="{{ $estadoOption['value'] }}">{{ $estadoOption['label'] }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Sucursal</label>
                        <select class="form-select" wire:model.live="sucursalId">
                            <option value="">Todas</option>
                            @foreach($sucursales as $sucursal)
                                <option value="{{ $sucursal['id'] }}">{{ $sucursal['label'] }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Almacén</label>
                        <select class="form-select" wire:model.live="almacenId">
                            <option value="">Todos</option>
                            @foreach($almacenes as $almacen)
                                <option value="{{ $almacen['id'] }}">{{ $almacen['label'] }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Desde</label>
                        <input type="date" class="form-control" wire:model.live="fechaDesde">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Hasta</label>
                        <input type="date" class="form-control" wire:model.live="fechaHasta">
                    </div>
                    <div class="col-md-1 d-flex align-items-end">
                        <button class="btn btn-outline-secondary w-100" wire:click="clearFilters">
                            <i class="fa-solid fa-eraser me-1"></i>
                            Limpiar
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <div class="card shadow-sm border-0 d-none d-md-block">
            <div class="card-body p-0">
                <div wire:loading wire:target="estado,sucursalId,almacenId,fechaDesde,fechaHasta,postOrder" class="p-4">
                    <div class="table-responsive">
                        <table class="table mb-0">
                            <tbody>
                                @for($i = 0; $i < 4; $i++)
                                    <tr>
                                        <td><div class="skeleton skeleton-text w-75"></div></td>
                                        <td><div class="skeleton skeleton-text"></div></td>
                                        <td><div class="skeleton skeleton-text w-50"></div></td>
                                        <td><div class="skeleton skeleton-text w-25"></div></td>
                                        <td><div class="skeleton skeleton-text w-50"></div></td>
                                        <td><div class="skeleton skeleton-text w-25"></div></td>
                                        <td class="text-end"><div class="skeleton skeleton-button ms-auto"></div></td>
                                    </tr>
                                @endfor
                            </tbody>
                        </table>
                    </div>
                </div>
                <div wire:loading.class="opacity-50" wire:target="estado,sucursalId,almacenId,fechaDesde,fechaHasta,postOrder">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th class="text-nowrap">Folio</th>
                                    <th>Receta</th>
                                    <th class="text-nowrap">Programado</th>
                                    <th>Cantidad</th>
                                    <th>Sucursal</th>
                                    <th>Estado</th>
                                    <th class="text-end">Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($orders as $order)
                                    <tr>
                                        <td class="text-nowrap">
                                            <span class="fw-semibold">{{ $order->folio ?? ('OP-' . $order->id) }}</span><br>
                                            <small class="text-muted">Creado {{ optional($order->created_at)->format('d/m/Y H:i') }}</small>
                                        </td>
                                        <td>
                                            <div class="fw-semibold">{{ $order->recipe?->nombre ?? $order->item?->nombre ?? 'N/A' }}</div>
                                            <small class="text-muted">Versión: {{ $order->recipeVersion?->version ?? 'No asignada' }}</small>
                                        </td>
                                        <td class="text-nowrap">
                                            {{ optional($order->programado_para)->format('d/m/Y H:i') ?? 'Sin fecha' }}
                                        </td>
                                        <td class="text-nowrap">
                                            {{ number_format($order->qty_programada, 2) }} {{ $order->uom_base ?? 'PZ' }}
                                            @if($order->qty_producida > 0)
                                                <br>
                                                <small class="text-muted">Producido: {{ number_format($order->qty_producida, 2) }}</small>
                                            @endif
                                        </td>
                                        <td>
                                            {{ $order->sucursal?->nombre ?? 'N/A' }}<br>
                                            <small class="text-muted">{{ $order->almacen?->nombre ?? 'Sin almacén' }}</small>
                                        </td>
                                        <td>
                                            <x-transfer-status-badge :status="$order->estado" />
                                        </td>
                                        <td class="text-end">
                                            <div class="btn-group btn-group-sm">
                                                <a href="{{ route('production.detail', $order->id) }}" class="btn btn-outline-primary" title="Ver detalle">
                                                    <i class="fa-solid fa-eye"></i>
                                                </a>

                                                @if(in_array($order->estado, [\App\Models\ProductionOrder::ESTADO_PLANIFICADA, \App\Models\ProductionOrder::ESTADO_EN_PROCESO]))
                                                    <a href="{{ route('production.execute', $order->id) }}" class="btn btn-outline-success" title="Ejecutar orden">
                                                        <i class="fa-solid fa-play"></i>
                                                    </a>
                                                @endif

                                                @if(in_array($order->estado, [\App\Models\ProductionOrder::ESTADO_COMPLETADA, \App\Models\ProductionOrder::ESTADO_COMPLETADO]))
                                                    <button class="btn btn-outline-success"
                                                            wire:click="postOrder({{ $order->id }})"
                                                            wire:loading.attr="disabled"
                                                            wire:target="postOrder"
                                                            title="Postear a inventario">
                                                        @if($postingOrderId === $order->id)
                                                            <span class="spinner-border spinner-border-sm"></span>
                                                        @else
                                                            <i class="fa-solid fa-boxes-packing"></i>
                                                        @endif
                                                    </button>
                                                @endif
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="7">
                                            <x-empty-state
                                                icon="industry"
                                                title="Sin órdenes de producción"
                                                description="Crea una nueva orden para comenzar a producir"
                                            />
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="p-3 border-top">
                    {{ $orders->links() }}
                </div>
            </div>
        </div>

        <div class="d-md-none">
            @forelse($orders as $order)
                <div class="card shadow-sm border-0 mb-3">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <div>
                                <h5 class="card-title mb-1">{{ $order->recipe?->nombre ?? $order->item?->nombre ?? 'N/A' }}</h5>
                                <small class="text-muted">Folio {{ $order->folio ?? ('OP-' . $order->id) }}</small>
                            </div>
                            <x-transfer-status-badge :status="$order->estado" />
                        </div>
                        <p class="small text-muted mb-3">
                            Programado: {{ optional($order->programado_para)->format('d/m/Y H:i') ?? 'Sin fecha' }}<br>
                            Cantidad: {{ number_format($order->qty_programada, 2) }} {{ $order->uom_base ?? 'PZ' }}<br>
                            Sucursal: {{ $order->sucursal?->nombre ?? 'N/A' }}
                        </p>
                        <div class="d-flex gap-2">
                            <a href="{{ route('production.detail', $order->id) }}" class="btn btn-outline-primary btn-sm flex-fill">
                                <i class="fa-solid fa-eye me-1"></i> Detalle
                            </a>
                            @if(in_array($order->estado, [\App\Models\ProductionOrder::ESTADO_PLANIFICADA, \App\Models\ProductionOrder::ESTADO_EN_PROCESO]))
                                <a href="{{ route('production.execute', $order->id) }}" class="btn btn-outline-success btn-sm flex-fill">
                                    <i class="fa-solid fa-play me-1"></i> Ejecutar
                                </a>
                            @endif
                        </div>
                        @if(in_array($order->estado, [\App\Models\ProductionOrder::ESTADO_COMPLETADA, \App\Models\ProductionOrder::ESTADO_COMPLETADO]))
                            <button class="btn btn-success w-100 mt-2"
                                    wire:click="postOrder({{ $order->id }})"
                                    wire:loading.attr="disabled"
                                    wire:target="postOrder">
                                @if($postingOrderId === $order->id)
                                    <span class="spinner-border spinner-border-sm me-2"></span>
                                @endif
                                Postear a inventario
                            </button>
                        @endif
                    </div>
                </div>
            @empty
                <x-empty-state
                    icon="industry"
                    title="Sin órdenes registradas"
                    description="Comienza creando una orden de producción"
                />
                <a href="{{ route('production.create') }}" class="btn btn-primary w-100 mt-3">
                    <i class="fa-solid fa-plus me-2"></i>
                    Nueva orden
                </a>
            @endforelse

            {{ $orders->links() }}
        </div>
    </div>
</div>
