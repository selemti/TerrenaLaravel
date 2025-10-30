<div>
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-1">Órdenes de Compra</h2>
            <p class="text-muted mb-0">Gestión de órdenes de compra</p>
        </div>
    </div>

    {{-- Estadísticas --}}
    <div class="row g-3 mb-4">
        <div class="col-md-2">
            <div class="card shadow-sm text-center">
                <div class="card-body py-3">
                    <h4 class="mb-0">{{ $stats['total'] }}</h4>
                    <small class="text-muted">Total</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center">
                <div class="card-body py-3">
                    <h4 class="mb-0">{{ $stats['borrador'] }}</h4>
                    <small class="text-muted">Borrador</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-success">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-success">{{ $stats['aprobada'] }}</h4>
                    <small class="text-muted">Aprobada</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-info">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-info">{{ $stats['enviada'] }}</h4>
                    <small class="text-muted">Enviada</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-primary">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-primary">{{ $stats['recibida'] }}</h4>
                    <small class="text-muted">Recibida</small>
                </div>
            </div>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-4">
                    <input type="text" class="form-control" wire:model.live.debounce.300ms="search" placeholder="Buscar por folio...">
                </div>
                <div class="col-md-3">
                    <select class="form-select" wire:model.live="estadoFilter">
                        <option value="all">Todos los estados</option>
                        <option value="BORRADOR">Borrador</option>
                        <option value="APROBADA">Aprobada</option>
                        <option value="ENVIADA">Enviada</option>
                        <option value="RECIBIDA">Recibida</option>
                        <option value="CERRADA">Cerrada</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <select class="form-select" wire:model.live="vendorFilter">
                        <option value="all">Todos los proveedores</option>
                        @foreach($vendors as $vendor)
                            <option value="{{ $vendor->id }}">{{ $vendor->nombre }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-2">
                    <button class="btn btn-outline-secondary w-100" wire:click="limpiarFiltros">
                        <i class="fa-solid fa-filter-circle-xmark me-2"></i>Limpiar
                    </button>
                </div>
            </div>
        </div>
    </div>

    {{-- Tabla --}}
    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Folio</th>
                            <th>Proveedor</th>
                            <th>Fecha</th>
                            <th class="text-end">Total</th>
                            <th>Fecha Promesa</th>
                            <th class="text-center">Estado</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($orders as $order)
                            <tr>
                                <td><strong>{{ $order->folio }}</strong></td>
                                <td>{{ $order->vendor->nombre }}</td>
                                <td><small>{{ $order->created_at->format('d/m/Y') }}</small></td>
                                <td class="text-end"><strong>${{ number_format($order->total, 2) }}</strong></td>
                                <td>
                                    @if($order->fecha_promesa)
                                        {{ $order->fecha_promesa->format('d/m/Y') }}
                                        @if($order->is_vencida)
                                            <span class="badge bg-danger ms-1">Vencida</span>
                                        @endif
                                    @else
                                        -
                                    @endif
                                </td>
                                <td class="text-center">{!! $order->estado_badge !!}</td>
                                <td class="text-end">
                                    <a href="{{ route('purchasing.orders.detail', $order->id) }}" class="btn btn-sm btn-outline-primary">
                                        <i class="fa-solid fa-eye"></i>
                                    </a>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="7" class="text-center py-4 text-muted">No se encontraron órdenes</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
        @if($orders->hasPages())
            <div class="card-footer">{{ $orders->links() }}</div>
        @endif
    </div>
</div>
