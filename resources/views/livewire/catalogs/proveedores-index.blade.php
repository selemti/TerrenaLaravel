<div>
    @if ($tableNotice !== '')
        <div class="alert alert-warning alert-dismissible fade show position-fixed top-0 end-0 m-3" role="alert" style="z-index:1085;">
            <i class="bi bi-exclamation-triangle me-2"></i>{{ $tableNotice }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Cerrar"></button>
        </div>
    @endif

    <div class="card shadow-sm border-0">
        <div class="card-body">
            <div class="row g-2 align-items-end">
                <div class="col-md-8">
                    <label class="form-label small text-muted mb-1">Buscar</label>
                    <x-search-input
                        placeholder="Buscar proveedores..."
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
                        @disabled(! $tableReady)
                    >
                        <span wire:loading wire:target="create">
                            <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                            Abriendo...
                        </span>
                        <span wire:loading.remove wire:target="create">
                            <i class="bi bi-plus-circle me-1"></i>
                            Nuevo proveedor
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
                                <th>RFC</th>
                                <th>Nombre</th>
                                <th>Teléfono</th>
                                <th>Correo</th>
                                <th class="text-center">Estado</th>
                                <th class="text-end">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                        @forelse($rows as $row)
                            <tr>
                                <td class="fw-semibold">{{ $row->rfc }}</td>
                                <td>{{ $row->nombre }}</td>
                                <td>{{ $row->telefono ?: '—' }}</td>
                                <td>{{ $row->email ?: '—' }}</td>
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
                                <td colspan="6">
                                    <x-empty-state
                                        icon="people"
                                        title="Sin proveedores"
                                        description="Comienza agregando tu primer proveedor"
                                        action-label="Nuevo proveedor"
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
                                <div><strong>RFC:</strong> {{ $row->rfc }}</div>
                                @if($row->telefono)
                                    <div><strong>Tel:</strong> {{ $row->telefono }}</div>
                                @endif
                                @if($row->email)
                                    <div><strong>Email:</strong> {{ $row->email }}</div>
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
                        icon="people"
                        title="Sin proveedores"
                        description="Comienza agregando tu primer proveedor"
                        action-label="Nuevo proveedor"
                        action-click="create"
                    />
                @endforelse
            </div>
        </div>

        <div class="card-footer bg-white py-2">
            {{ $rows->links() }}
        </div>
    </div>

    <div class="modal fade" id="modalProveedor" tabindex="-1" aria-labelledby="modalProveedorLabel" aria-hidden="true" wire:ignore.self>
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg">
                <form wire:submit.prevent="save">
                    <div class="modal-header bg-primary bg-opacity-10">
                        <h5 class="modal-title" id="modalProveedorLabel">
                            <i class="bi bi-truck-front me-2"></i>
                            {{ $editId ? 'Editar proveedor' : 'Nuevo proveedor' }}
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">RFC <span class="text-danger">*</span></label>
                            <input
                                type="text"
                                class="form-control @error('rfc') is-invalid @elseif(!$errors->has('rfc') && strlen($rfc) >= 12) is-valid @enderror"
                                wire:model.live="rfc"
                                placeholder="ABC123456XYZ"
                                maxlength="20"
                            >
                            @error('rfc')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                            @if(!$errors->has('rfc') && strlen($rfc) >= 12)
                                <div class="valid-feedback d-block">
                                    <i class="bi bi-check-circle me-1"></i>
                                    RFC válido
                                </div>
                            @endif
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
                                placeholder="Nombre del proveedor"
                            >
                            @error('nombre')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Teléfono</label>
                            <input
                                type="tel"
                                class="form-control @error('telefono') is-invalid @enderror"
                                wire:model.live="telefono"
                                maxlength="10"
                                placeholder="5551234567"
                            >
                            @error('telefono')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                            <small class="form-text text-muted">10 dígitos sin espacios ni guiones</small>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Correo electrónico</label>
                            <input
                                type="email"
                                class="form-control @error('email') is-invalid @enderror"
                                wire:model.live="email"
                                maxlength="120"
                                placeholder="proveedor@example.com"
                            >
                            @error('email')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="form-check form-switch">
                            <input
                                class="form-check-input"
                                type="checkbox"
                                id="proveedorActivo"
                                wire:model.live="activo"
                            >
                            <label class="form-check-label" for="proveedorActivo">
                                Proveedor activo
                                @if($activo)
                                    <span class="badge bg-success ms-2">Activo</span>
                                @else
                                    <span class="badge bg-secondary ms-2">Inactivo</span>
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

        const modalEl = document.getElementById('modalProveedor');
        const modal = new bootstrap.Modal(modalEl);

        Livewire.on('toggle-proveedor-modal', (payload = { open: false }) => {
            const open = typeof payload === 'object' && payload !== null && 'open' in payload
                ? payload.open
                : !!payload;

            open ? modal.show() : modal.hide();
        });

        modalEl.addEventListener('hidden.bs.modal', () => {
            Livewire.dispatch('proveedor-modal-closed');
        });
    });
</script>
@endpush
