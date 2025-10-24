<div>
    {{-- Header --}}
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-1">Solicitudes de Compra</h2>
            <p class="text-muted mb-0">Gestión de solicitudes y requisiciones</p>
        </div>
        <a href="{{ route('purchasing.requests.create') }}" class="btn btn-primary">
            <i class="fa-solid fa-plus me-2"></i>Nueva Solicitud
        </a>
    </div>

    {{-- Estadísticas --}}
    <div class="row g-3 mb-4">
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-secondary">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-secondary">{{ number_format($stats['total']) }}</h4>
                    <small class="text-muted">Total</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-secondary">
                <div class="card-body py-3">
                    <h4 class="mb-0">{{ number_format($stats['borrador']) }}</h4>
                    <small class="text-muted">Borrador</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-info">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-info">{{ number_format($stats['cotizada']) }}</h4>
                    <small class="text-muted">Cotizada</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-success">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-success">{{ number_format($stats['aprobada']) }}</h4>
                    <small class="text-muted">Aprobada</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-primary">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-primary">{{ number_format($stats['ordenada']) }}</h4>
                    <small class="text-muted">Ordenada</small>
                </div>
            </div>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-3">
                    <label class="form-label small">Buscar</label>
                    <input type="text" class="form-control" wire:model.live.debounce.300ms="search"
                           placeholder="Folio o notas...">
                </div>
                <div class="col-md-2">
                    <label class="form-label small">Estado</label>
                    <select class="form-select" wire:model.live="estadoFilter">
                        <option value="all">Todos</option>
                        <option value="BORRADOR">Borrador</option>
                        <option value="COTIZADA">Cotizada</option>
                        <option value="APROBADA">Aprobada</option>
                        <option value="ORDENADA">Ordenada</option>
                        <option value="CANCELADA">Cancelada</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label small">Sucursal</label>
                    <select class="form-select" wire:model.live="sucursalFilter">
                        <option value="all">Todas</option>
                        @foreach($sucursales as $sucursal)
                            <option value="{{ $sucursal->id }}">{{ $sucursal->nombre }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label small">Desde</label>
                    <input type="date" class="form-control" wire:model.live="fechaDesde">
                </div>
                <div class="col-md-2">
                    <label class="form-label small">Hasta</label>
                    <input type="date" class="form-control" wire:model.live="fechaHasta">
                </div>
                <div class="col-md-1 d-flex align-items-end">
                    <button class="btn btn-outline-secondary w-100" wire:click="limpiarFiltros" title="Limpiar filtros">
                        <i class="fa-solid fa-filter-circle-xmark"></i>
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
                            <th>Fecha</th>
                            <th>Solicitante</th>
                            <th>Sucursal</th>
                            <th class="text-end">Items</th>
                            <th class="text-end">Importe Est.</th>
                            <th class="text-center">Cotizaciones</th>
                            <th class="text-center">Estado</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($requests as $request)
                            <tr>
                                <td>
                                    <strong>{{ $request->folio ?? 'S/N' }}</strong>
                                </td>
                                <td>
                                    <small>{{ $request->requested_at->format('d/m/Y') }}</small><br>
                                    <small class="text-muted">{{ $request->requested_at->format('H:i') }}</small>
                                </td>
                                <td>
                                    <small>{{ $request->requestedBy->name ?? $request->createdBy->name }}</small>
                                </td>
                                <td>
                                    <small>{{ $request->sucursal->nombre ?? '-' }}</small>
                                </td>
                                <td class="text-end">
                                    <span class="badge bg-light text-dark">{{ $request->total_lineas }}</span>
                                </td>
                                <td class="text-end">
                                    <strong>${{ number_format($request->importe_estimado, 2) }}</strong>
                                </td>
                                <td class="text-center">
                                    @if($request->total_quotes > 0)
                                        <span class="badge bg-info">{{ $request->total_quotes }}</span>
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                <td class="text-center">
                                    {!! $request->estado_badge !!}
                                </td>
                                <td class="text-end">
                                    <div class="btn-group btn-group-sm" role="group">
                                        <a href="{{ route('purchasing.requests.detail', $request->id) }}"
                                           class="btn btn-outline-primary" title="Ver detalle">
                                            <i class="fa-solid fa-eye"></i>
                                        </a>
                                        @if($request->is_editable)
                                            <a href="{{ route('purchasing.requests.create', ['edit' => $request->id]) }}"
                                               class="btn btn-outline-secondary" title="Editar">
                                                <i class="fa-solid fa-edit"></i>
                                            </a>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="9" class="text-center py-4 text-muted">
                                    <i class="fa-solid fa-inbox fa-2x mb-2 d-block"></i>
                                    No se encontraron solicitudes
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
        @if($requests->hasPages())
            <div class="card-footer">
                {{ $requests->links() }}
            </div>
        @endif
    </div>
</div>
