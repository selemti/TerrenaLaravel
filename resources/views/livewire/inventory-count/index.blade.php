<div>
    <div class="container-fluid py-4">
        {{-- Header --}}
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h2 class="mb-1">
                    <i class="fa-solid fa-clipboard-check text-primary me-2"></i>
                    Conteos de Inventario
                </h2>
                <p class="text-muted mb-0">Gestión de conteos físicos y ajustes de inventario</p>
            </div>
            <div>
                <a href="{{ route('inv.counts.create') }}" class="btn btn-primary">
                    <i class="fa-solid fa-plus me-1"></i>
                    Nuevo Conteo
                </a>
            </div>
        </div>

        {{-- Filtros --}}
        <div class="card shadow-sm mb-4">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label small text-muted">Buscar</label>
                        <input type="text"
                               class="form-control"
                               wire:model.live="search"
                               placeholder="Folio, notas...">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label small text-muted">Estado</label>
                        <select class="form-select" wire:model.live="estadoFilter">
                            <option value="all">Todos</option>
                            <option value="BORRADOR">Borrador</option>
                            <option value="EN_PROCESO">En Proceso</option>
                            <option value="AJUSTADO">Ajustado</option>
                            <option value="CANCELADO">Cancelado</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label small text-muted">Sucursal</label>
                        <select class="form-select" wire:model.live="sucursalFilter">
                            <option value="all">Todas</option>
                            @foreach($sucursales as $suc)
                                <option value="{{ $suc }}">{{ $suc }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label small text-muted">Almacén</label>
                        <select class="form-select" wire:model.live="almacenFilter">
                            <option value="all">Todos</option>
                            @foreach($almacenes as $alm)
                                <option value="{{ $alm }}">{{ $alm }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>
                <div class="mt-3">
                    <button type="button" class="btn btn-sm btn-outline-secondary" wire:click="limpiarFiltros">
                        <i class="fa-solid fa-filter-circle-xmark me-1"></i>
                        Limpiar filtros
                    </button>
                </div>
            </div>
        </div>

        {{-- Tabla de Conteos --}}
        <div class="card shadow-sm">
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Folio</th>
                                <th>Sucursal</th>
                                <th>Almacén</th>
                                <th>Programado</th>
                                <th>Iniciado</th>
                                <th>Estado</th>
                                <th>Items</th>
                                <th>Variación</th>
                                <th>Creado Por</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($conteos as $conteo)
                                <tr>
                                    <td>
                                        <strong class="text-primary">{{ $conteo->folio }}</strong>
                                    </td>
                                    <td>{{ $conteo->sucursal_id ?? '-' }}</td>
                                    <td>{{ $conteo->almacen_id ?? '-' }}</td>
                                    <td>
                                        @if($conteo->programado_para)
                                            <small>{{ $conteo->programado_para->format('d/m/Y H:i') }}</small>
                                        @else
                                            -
                                        @endif
                                    </td>
                                    <td>
                                        @if($conteo->iniciado_en)
                                            <small>{{ $conteo->iniciado_en->format('d/m/Y H:i') }}</small>
                                        @else
                                            -
                                        @endif
                                    </td>
                                    <td>{!! $conteo->estado_badge !!}</td>
                                    <td>
                                        <span class="badge bg-light text-dark">
                                            {{ number_format($conteo->total_items, 0) }}
                                        </span>
                                    </td>
                                    <td>
                                        @if(abs($conteo->total_variacion) < 0.001)
                                            <span class="badge bg-success">Sin variación</span>
                                        @elseif($conteo->total_variacion > 0)
                                            <span class="badge bg-info">+{{ number_format($conteo->total_variacion, 2) }}</span>
                                        @else
                                            <span class="badge bg-warning text-dark">{{ number_format($conteo->total_variacion, 2) }}</span>
                                        @endif
                                    </td>
                                    <td>
                                        @if($conteo->createdBy)
                                            <small>{{ $conteo->createdBy->name ?? $conteo->createdBy->username }}</small>
                                        @else
                                            -
                                        @endif
                                    </td>
                                    <td>
                                        @if($conteo->estado === 'EN_PROCESO')
                                            <a href="{{ route('inv.counts.capture', ['id' => $conteo->id]) }}"
                                               class="btn btn-sm btn-primary">
                                                <i class="fa-solid fa-pen-to-square"></i>
                                                Capturar
                                            </a>
                                        @elseif($conteo->estado === 'AJUSTADO')
                                            <a href="{{ route('inv.counts.detail', ['id' => $conteo->id]) }}"
                                               class="btn btn-sm btn-outline-primary">
                                                <i class="fa-solid fa-eye"></i>
                                                Ver
                                            </a>
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="10" class="text-center text-muted py-4">
                                        <i class="fa-solid fa-clipboard-question fa-2x mb-3 d-block"></i>
                                        No se encontraron conteos
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                {{-- Paginación --}}
                <div class="mt-3">
                    {{ $conteos->links() }}
                </div>
            </div>
        </div>
    </div>
</div>
