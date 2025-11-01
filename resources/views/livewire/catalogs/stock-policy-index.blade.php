<div>
    <div class="card shadow-sm border-0">
        <div class="card-body">
            <div class="d-flex flex-wrap align-items-end gap-2">
                <div class="flex-grow-1">
                    <label class="form-label small text-muted mb-1">Buscar</label>
                    <x-search-input
                        placeholder="Buscar políticas..."
                        model="search"
                        :value="$search"
                        size="sm"
                    />
                </div>
                <div>
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
                            Nueva política
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
                                <th>Artículo</th>
                                <th>Sucursal</th>
                                <th class="text-end">Mín</th>
                                <th class="text-end">Máx</th>
                                <th class="text-end">Reorden</th>
                                <th class="text-center">Estado</th>
                                <th class="text-end">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                        @forelse($rows as $row)
                            <tr>
                                <td>{{ $row->item_name }}</td>
                                <td>{{ $row->sucursal_name }}</td>
                                <td class="text-end">{{ number_format($row->min_qty, 2) }}</td>
                                <td class="text-end">{{ number_format($row->max_qty, 2) }}</td>
                                <td class="text-end">{{ number_format($row->reorder_qty, 2) }}</td>
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
                                <td colspan="7">
                                    <x-empty-state
                                        icon="diagram-3"
                                        title="Sin políticas"
                                        description="Configura el stock mínimo y máximo para tus artículos"
                                        action-label="Nueva política"
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
                                <h6 class="card-title mb-0">{{ $row->item_name }}</h6>
                                <x-status-badge :active="$row->activo" />
                            </div>
                            <div class="small text-muted mb-3">
                                <div><strong>Sucursal:</strong> {{ $row->sucursal_name }}</div>
                                <div><strong>Mín:</strong> {{ number_format($row->min_qty, 2) }}</div>
                                <div><strong>Máx:</strong> {{ number_format($row->max_qty, 2) }}</div>
                                <div><strong>Reorden:</strong> {{ number_format($row->reorder_qty, 2) }}</div>
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
                        icon="diagram-3"
                        title="Sin políticas"
                        description="Configura el stock mínimo y máximo para tus artículos"
                        action-label="Nueva política"
                        action-click="create"
                    />
                @endforelse
            </div>
        </div>

        <div class="card-footer bg-white py-2">
            {{ $rows->links() }}
        </div>
    </div>

    <div class="modal fade" id="modalStock" tabindex="-1" aria-labelledby="modalStockLabel" aria-hidden="true" wire:ignore.self>
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg">
                <form wire:submit.prevent="save">
                    <div class="modal-header bg-primary bg-opacity-10">
                        <h5 class="modal-title" id="modalStockLabel">
                            <i class="bi bi-sliders me-2"></i>
                            {{ $editId ? 'Editar política' : 'Nueva política' }}
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar" wire:click="closeModal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">Artículo <span class="text-danger">*</span></label>
                            <select
                                class="form-select @error('item_id') is-invalid @enderror"
                                wire:model.live="item_id"
                            >
                                <option value="">-- Selecciona --</option>
                                @foreach ($items as $item)
                                    <option value="{{ $item->id }}">{{ $item->name }}</option>
                                @endforeach
                            </select>
                            @error('item_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Sucursal <span class="text-danger">*</span></label>
                            <select
                                class="form-select @error('sucursal_id') is-invalid @enderror"
                                wire:model.live="sucursal_id"
                            >
                                <option value="">-- Selecciona --</option>
                                @foreach ($sucursales as $s)
                                    <option value="{{ $s->id }}">{{ $s->name }}</option>
                                @endforeach
                            </select>
                            @error('sucursal_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        <div class="row g-3">
                            <div class="col-4">
                                <label class="form-label">Mínimo <span class="text-danger">*</span></label>
                                <input
                                    type="number"
                                    step="0.0001"
                                    min="0"
                                    class="form-control @error('min_qty') is-invalid @enderror"
                                    wire:model.live="min_qty"
                                >
                                @error('min_qty')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-4">
                                <label class="form-label">Máximo <span class="text-danger">*</span></label>
                                <input
                                    type="number"
                                    step="0.0001"
                                    min="0"
                                    class="form-control @error('max_qty') is-invalid @enderror"
                                    wire:model.live="max_qty"
                                >
                                @error('max_qty')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="col-4">
                                <label class="form-label">Reorden <span class="text-danger">*</span></label>
                                <input
                                    type="number"
                                    step="0.0001"
                                    min="0"
                                    class="form-control @error('reorder_qty') is-invalid @enderror"
                                    wire:model.live="reorder_qty"
                                >
                                @error('reorder_qty')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>
                        </div>
                        <div class="form-check form-switch mt-3">
                            <input
                                class="form-check-input"
                                type="checkbox"
                                id="stockActivo"
                                wire:model.live="activo"
                            >
                            <label class="form-check-label" for="stockActivo">
                                Política activa
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

        const modalEl = document.getElementById('modalStock');
        const modal = new bootstrap.Modal(modalEl);

        Livewire.on('toggle-stock-modal', (payload = { open: false }) => {
            const open = typeof payload === 'object' && payload !== null && 'open' in payload
                ? payload.open
                : !!payload;

            open ? modal.show() : modal.hide();
        });

        modalEl.addEventListener('hidden.bs.modal', () => {
            Livewire.dispatch('stock-modal-closed');
        });
    });
</script>
@endpush
