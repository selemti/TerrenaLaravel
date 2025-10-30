<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header bg-primary text-white">
                    <div class="d-flex justify-content-between align-items-center">
                        <h4 class="card-title mb-0">
                            <i class="fa-solid fa-map-marked-alt me-2"></i>
                            Mapeo POS - Recetas
                        </h4>
                        <button 
                            wire:click="create" 
                            class="btn btn-light btn-sm"
                        >
                            <i class="fa-solid fa-plus me-1"></i>
                            Nuevo Mapeo
                        </button>
                    </div>
                </div>
                
                <div class="card-body">
                    <!-- Filtros -->
                    <div class="row mb-3">
                        <div class="col-md-4">
                            <input 
                                type="text" 
                                class="form-control" 
                                placeholder="Buscar por PLU o receta..." 
                                wire:model.live="search"
                            >
                        </div>
                        <div class="col-md-3">
                            <select class="form-select" wire:model.live="tipo">
                                <option value="">Todos los tipos</option>
                                <option value="MENU">MENU</option>
                                <option value="MODIFIER">MODIFIER</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <select class="form-select" wire:model.live="perPage">
                                <option value="10">10 por página</option>
                                <option value="25">25 por página</option>
                                <option value="50">50 por página</option>
                            </select>
                        </div>
                    </div>

                    <!-- Tabla de mapeos -->
                    <div class="table-responsive">
                        <table class="table table-striped table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th>ID</th>
                                    <th>Tipo</th>
                                    <th>PLU</th>
                                    <th>Receta</th>
                                    <th>Vigencia</th>
                                    <th>Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($mappings as $mapping)
                                    <tr>
                                        <td>{{ $mapping->id }}</td>
                                        <td>
                                            <span class="badge bg-{{ $mapping->tipo === 'MENU' ? 'primary' : 'secondary' }}">
                                                {{ $mapping->tipo }}
                                            </span>
                                        </td>
                                        <td>{{ $mapping->plu }}</td>
                                        <td>
                                            {{ $mapping->recipe?->nombre_plato ?: 'N/A' }}
                                        </td>
                                        <td>
                                            @if($mapping->valid_from)
                                                {{ $mapping->valid_from->format('d/m/Y') }}
                                                @if($mapping->valid_to)
                                                    - {{ $mapping->valid_to->format('d/m/Y') }}
                                                @endif
                                            @else
                                                @if($mapping->vigente_desde)
                                                    Desde {{ $mapping->vigente_desde->format('d/m/Y') }}
                                                @else
                                                    Sin vigencia
                                                @endif
                                            @endif
                                        </td>
                                        <td>
                                            <div class="btn-group btn-group-sm" role="group">
                                                <button 
                                                    wire:click="edit({{ $mapping->id }})" 
                                                    class="btn btn-outline-primary"
                                                    title="Editar"
                                                >
                                                    <i class="fa-solid fa-edit"></i>
                                                </button>
                                                <button 
                                                    wire:click="delete({{ $mapping->id }})" 
                                                    class="btn btn-outline-danger"
                                                    title="Eliminar"
                                                    onclick="return confirm('¿Está seguro de eliminar este mapeo?')"
                                                >
                                                    <i class="fa-solid fa-trash"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6" class="text-center text-muted py-4">
                                            <i class="fa-regular fa-folder-open fa-2x mb-2"></i>
                                            <p class="mb-0">No se encontraron mapeos POS</p>
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    <!-- Paginación -->
                    <div class="d-flex justify-content-between align-items-center">
                        <div class="text-muted">
                            Mostrando {{ $mappings->firstItem() }} a {{ $mappings->lastItem() }} 
                            de {{ $mappings->total() }} resultados
                        </div>
                        <div>
                            {{ $mappings->links() }}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal para el formulario -->
    @if($showForm)
    <div 
        wire:ignore.self 
        class="modal fade show" 
        style="display: block; padding-right: 0;" 
        tabindex="-1"
        x-data="{ open: @entangle('showForm') }"
        x-show="open"
        x-on:keydown.escape.window="if($wire.showForm) $wire.closeForm()"
    >
        <div class="modal-backdrop fade show" style="display: block;"></div>
        <div class="modal-dialog modal-lg" x-on:click.outside="$wire.closeForm()">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        {{ $editingId ? 'Editar Mapeo POS' : 'Nuevo Mapeo POS' }}
                    </h5>
                    <button 
                        type="button" 
                        class="btn-close" 
                        wire:click="closeForm"
                    ></button>
                </div>
                <div class="modal-body">
                    @livewire('pos.pos-mapping-form', ['mappingId' => $editingId], key('form-' . ($editingId ?: 'new')))
                </div>
            </div>
        </div>
    </div>
    @endif
</div>