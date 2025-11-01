<div>
    <div class="card shadow-sm border-0">
        <div class="card-body">
            <div class="row g-2 align-items-end">
                <div class="col-md-8">
                    <label class="form-label small text-muted mb-1">Buscar</label>
                    <x-search-input
                        placeholder="Buscar sucursales..."
                        model="search"
                        :value="$search"
                        size="sm"
                    />
                </div>
                <div class="col-md-4 text-md-end">
                    <label class="form-label small text-muted mb-1 d-block">&nbsp;</label>
                    <button
                        type="button"
                        class="btn btn-sm btn-primary"
                        wire:click="create"
                        wire:loading.attr="disabled"
                        wire:target="create"
                    >
                        <span wire:loading wire:target="create">
                            <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                            Abriendo...
                        </span>
                        <span wire:loading.remove wire:target="create">
                            <i class="bi bi-plus-circle me-1"></i>
                            Nueva sucursal
                        </span>
                    </button>
                </div>
            </div>
        </div>

        <div class="px-3 py-4" wire:loading.delay wire:target="search,page,create,edit,delete">
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th><div class="skeleton skeleton-text"></div></th>
                            <th><div class="skeleton skeleton-text"></div></th>
                            <th><div class="skeleton skeleton-text"></div></th>
                            <th><div class="skeleton skeleton-text"></div></th>
                            <th><div class="skeleton skeleton-text"></div></th>
                        </tr>
                    </thead>
                    <tbody>
                        @for ($i = 0; $i < 5; $i++)
                            <tr>
                                <td><div class="skeleton skeleton-text"></div></td>
                                <td><div class="skeleton skeleton-text"></div></td>
                                <td><div class="skeleton skeleton-text"></div></td>
                                <td><div class="skeleton skeleton-text"></div></td>
                                <td class="text-end"><div class="skeleton skeleton-button ms-auto"></div></td>
                            </tr>
                        @endfor
                    </tbody>
                </table>
            </div>
        </div>

        <div wire:loading.remove wire:target="search,page,create,edit,delete">
            <div class="d-none d-md-block">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Clave</th>
                                <th>Nombre</th>
                                <th>Ubicación</th>
                                <th class="text-center">Estado</th>
                                <th class="text-end">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                        @forelse($rows as $row)
                            <tr>
                                <td class="fw-semibold">{{ $row->clave }}</td>
                                <td>{{ $row->nombre }}</td>
                                <td>{{ $row->ubicacion ?: '—' }}</td>
                                <td class="text-center">
                                    <x-status-badge :active="$row->activo" />
                                </td>
                                <td class="text-end">
                                    <x-action-buttons
                                        :edit-action="'edit(' . $row->id . ')'"
                                        :delete-action="'delete(' . $row->id . ')'"
                                    />
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5">
                                    <x-empty-state
                                        icon="building"
                                        title="Sin sucursales"
                                        description="Captura tu primera sucursal para comenzar"
                                        action-label="Nueva sucursal"
                                        action-click="create"
                                    />
                                </td>
                            </tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="d-md-none px-3 pb-3">
                @forelse ($rows as $row)
                    <div class="card border-0 shadow-sm mb-3">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <h6 class="card-title mb-0">{{ $row->nombre }}</h6>
                                <x-status-badge :active="$row->activo" />
                            </div>
                            <div class="small text-muted mb-3">
                                <div><strong>Clave:</strong> {{ $row->clave }}</div>
                                @if($row->ubicacion)
                                    <div><strong>Ubicación:</strong> {{ $row->ubicacion }}</div>
                                @endif
                            </div>
                            <x-action-buttons
                                class="w-100"
                                size="md"
                                :edit-action="'edit(' . $row->id . ')'"
                                :delete-action="'delete(' . $row->id . ')'"
                            />
                        </div>
                    </div>
                @empty
                    <x-empty-state
                        icon="building"
                        title="Sin sucursales"
                        description="Captura tu primera sucursal para comenzar"
                        action-label="Nueva sucursal"
                        action-click="create"
                    />
                @endforelse
            </div>
        </div>

        <div class="card-footer bg-white py-2">
            {{ $rows->links() }}
        </div>
    </div>

    <div class="modal fade" id="modalSucursal" tabindex="-1" aria-labelledby="modalSucursalLabel" aria-hidden="true" wire:ignore.self>
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg">
                <form wire:submit.prevent="save">
                    <div class="modal-header bg-primary bg-opacity-10">
                        <h5 class="modal-title" id="modalSucursalLabel">
                            <i class="bi bi-shop-window me-2"></i>
                            {{ $editId ? 'Editar sucursal' : 'Nueva sucursal' }}
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">Clave <span class="text-danger">*</span>
                                <small class="text-muted">({{ strlen($clave) }}/16)</small>
                            </label>
                            <input
                                type="text"
                                class="form-control @error('clave') is-invalid @enderror"
                                wire:model.live="clave"
                                maxlength="16"
                                placeholder="SUC-01"
                            >
                            @error('clave')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Nombre <span class="text-danger">*</span>
                                <small class="text-muted">({{ strlen($nombre) }}/120)</small>
                            </label>
                            <input
                                type="text"
                                class="form-control @error('nombre') is-invalid @enderror"
                                wire:model.live="nombre"
                                maxlength="120"
                                placeholder="Nombre de la sucursal"
                            >
                            @error('nombre')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Ubicación</label>
                            <textarea
                                class="form-control @error('ubicacion') is-invalid @enderror"
                                wire:model.live="ubicacion"
                                rows="3"
                                maxlength="160"
                                placeholder="Dirección o referencia"
                            ></textarea>
                            @error('ubicacion')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="form-check form-switch">
                            <input
                                class="form-check-input"
                                type="checkbox"
                                id="sucursalActiva"
                                wire:model.live="activo"
                            >
                            <label class="form-check-label" for="sucursalActiva">
                                Sucursal activa
                                @if($activo)
                                    <span class="badge bg-success ms-2">Activa</span>
                                @else
                                    <span class="badge bg-secondary ms-2">Inactiva</span>
                                @endif
                            </label>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button
                            type="button"
                            class="btn btn-outline-secondary"
                            data-bs-dismiss="modal"
                            wire:click="closeModal"
                            wire:loading.attr="disabled"
                            wire:target="save"
                        >
                            Cancelar
                        </button>
                        <button
                            type="submit"
                            class="btn btn-primary"
                            wire:loading.attr="disabled"
                            wire:target="save"
                        >
                            <span wire:loading wire:target="save">
                                <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                                Guardando...
                            </span>
                            <span wire:loading.remove wire:target="save">
                                <i class="bi bi-check-circle me-2"></i>
                                Guardar
                            </span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', () => {
        if (!window.bootstrap) return;

        const modalEl = document.getElementById('modalSucursal');
        const modal = new bootstrap.Modal(modalEl);

        Livewire.on('toggle-sucursal-modal', (payload = { open: false }) => {
            const open = typeof payload === 'object' && payload !== null && 'open' in payload
                ? payload.open
                : !!payload;

            open ? modal.show() : modal.hide();
        });

        modalEl.addEventListener('hidden.bs.modal', () => {
            Livewire.dispatch('sucursal-modal-closed');
        });
    });
</script>
@endpush
