<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header bg-success text-white">
                    <h4 class="card-title mb-0">
                        <i class="fa-solid fa-clipboard-list me-2"></i>
                        Conteos Físicos de Inventario
                    </h4>
                </div>
                
                <div class="card-body">
                    <!-- Filtros -->
                    <div class="row mb-3">
                        <div class="col-md-3">
                            <input 
                                type="text" 
                                class="form-control" 
                                placeholder="Buscar conteos..." 
                                wire:model.live="search"
                            >
                        </div>
                        <div class="col-md-2">
                            <select class="form-select" wire:model.live="sucursal">
                                <option value="">Todas las sucursales</option>
                                @foreach($sucursales as $sucursal)
                                    <option value="{{ $sucursal }}">{{ $sucursal }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-2">
                            <select class="form-select" wire:model.live="estado">
                                <option value="">Todos los estados</option>
                                @foreach($estados as $estado)
                                    <option value="{{ $estado }}">{{ $estado }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-2">
                            <input 
                                type="date" 
                                class="form-control" 
                                placeholder="Desde" 
                                wire:model.live="fecha_desde"
                            >
                        </div>
                        <div class="col-md-2">
                            <input 
                                type="date" 
                                class="form-control" 
                                placeholder="Hasta" 
                                wire:model.live="fecha_hasta"
                            >
                        </div>
                        <div class="col-md-1">
                            <select class="form-select" wire:model.live="perPage">
                                <option value="10">10</option>
                                <option value="25">25</option>
                                <option value="50">50</option>
                            </select>
                        </div>
                    </div>

                    <!-- Tabla de conteos -->
                    <div class="table-responsive">
                        <table class="table table-striped table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th>ID</th>
                                    <th>Sucursal</th>
                                    <th>Estado</th>
                                    <th>Programado para</th>
                                    <th>Iniciado en</th>
                                    <th>Cerrado en</th>
                                    <th>Líneas</th>
                                    <th>Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($counts as $count)
                                    <tr>
                                        <td>{{ $count->id }}</td>
                                        <td>{{ $count->sucursal_id }}</td>
                                        <td>
                                            <span class="badge bg-{{ 
                                                $count->estado === 'CERRADO' ? 'success' : 
                                                ($count->estado === 'ABIERTO' ? 'warning' : 
                                                ($count->estado === 'PROGRAMADO' ? 'info' : 'secondary'))
                                            }}">
                                                {{ $count->estado }}
                                            </span>
                                        </td>
                                        <td>{{ $count->programado_para ? $count->programado_para->format('d/m/Y H:i') : 'N/A' }}</td>
                                        <td>{{ $count->iniciado_en ? $count->iniciado_en->format('d/m/Y H:i') : 'N/A' }}</td>
                                        <td>{{ $count->cerrado_en ? $count->cerrado_en->format('d/m/Y H:i') : 'N/A' }}</td>
                                        <td>{{ $count->lines->count() }}</td>
                                        <td>
                                            <div class="btn-group btn-group-sm" role="group">
                                                @if(in_array($count->estado, ['PROGRAMADO', 'ABIERTO']))
                                                    <button 
                                                        wire:click="closeCount({{ $count->id }})" 
                                                        class="btn btn-outline-success"
                                                        title="Cerrar conteo"
                                                        onclick="return confirm('¿Está seguro de cerrar este conteo?')"
                                                    >
                                                        <i class="fa-solid fa-lock"></i>
                                                    </button>
                                                @elseif($count->estado === 'CERRADO')
                                                    <button 
                                                        wire:click="openCount({{ $count->id }})" 
                                                        class="btn btn-outline-warning"
                                                        title="Reabrir conteo"
                                                        onclick="return confirm('¿Está seguro de reabrir este conteo?')"
                                                    >
                                                        <i class="fa-solid fa-unlock"></i>
                                                    </button>
                                                @endif
                                                <a 
                                                    href="{{ route('inventory.counts.detail', $count->id) }}" 
                                                    class="btn btn-outline-primary"
                                                    title="Ver detalles"
                                                >
                                                    <i class="fa-solid fa-eye"></i>
                                                </a>
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="8" class="text-center text-muted py-4">
                                            <i class="fa-regular fa-folder-open fa-2x mb-2"></i>
                                            <p class="mb-0">No se encontraron conteos de inventario</p>
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    <!-- Paginación -->
                    <div class="d-flex justify-content-between align-items-center">
                        <div class="text-muted">
                            Mostrando {{ $counts->firstItem() }} a {{ $counts->lastItem() }} 
                            de {{ $counts->total() }} resultados
                        </div>
                        <div>
                            {{ $counts->links() }}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>