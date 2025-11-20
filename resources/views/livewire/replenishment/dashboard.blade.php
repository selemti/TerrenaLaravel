<div>
    {{-- Header --}}
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-1">Sugerencias de Replenishment</h2>
            <p class="text-muted mb-0">Motor automático de sugerencias de reposición (MIN_MAX, SMA, POS)</p>
        </div>
        <div class="d-flex gap-2">
            <button class="btn btn-outline-secondary" wire:click="loadSuggestions" @disabled($loading)>
                <i class="fa-solid fa-rotate me-1"></i>Refrescar
            </button>
            <button class="btn btn-primary" wire:click="runCalculation" @disabled($loading)>
                @if($loading)
                    <i class="fa-solid fa-spinner fa-spin me-1"></i>Calculando...
                @else
                    <i class="fa-solid fa-gears me-1"></i>Calcular sugerencias
                @endif
            </button>
        </div>
    </div>

    {{-- Flash Messages --}}
    @if($flashMessage)
        <div class="alert alert-success alert-dismissible fade show py-2" role="alert">
            <i class="fa-solid fa-check-circle me-1"></i>{{ $flashMessage }}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    @endif
    @if($errorMessage)
        <div class="alert alert-danger alert-dismissible fade show py-2" role="alert">
            <i class="fa-solid fa-exclamation-triangle me-1"></i>{{ $errorMessage }}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    @endif

    {{-- Estadísticas --}}
    <div class="row g-3 mb-4">
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-secondary">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-secondary">{{ number_format($stats['total'] ?? 0) }}</h4>
                    <small class="text-muted">Total</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-warning">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-warning">{{ number_format($stats['pendiente'] ?? 0) }}</h4>
                    <small class="text-muted">Pendiente</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-success">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-success">{{ number_format($stats['aprobada'] ?? 0) }}</h4>
                    <small class="text-muted">Aprobada</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-primary">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-primary">{{ number_format($stats['convertida'] ?? 0) }}</h4>
                    <small class="text-muted">Convertida</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center border-danger">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-danger">{{ number_format($stats['rechazada'] ?? 0) }}</h4>
                    <small class="text-muted">Rechazada</small>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card shadow-sm text-center" style="border-left: 4px solid #dc3545;">
                <div class="card-body py-3">
                    <h4 class="mb-0 text-danger">{{ number_format($stats['urgentes'] ?? 0) }}</h4>
                    <small class="text-muted">Urgentes</small>
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
                           placeholder="Item ID, motivo...">
                </div>
                <div class="col-md-2">
                    <label class="form-label small">Estado</label>
                    <select class="form-select" wire:model.live="estadoFilter">
                        <option value="all">Todos</option>
                        <option value="PENDIENTE">Pendiente</option>
                        <option value="APROBADA">Aprobada</option>
                        <option value="RECHAZADA">Rechazada</option>
                        <option value="CONVERTIDA">Convertida</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label small">Prioridad</label>
                    <select class="form-select" wire:model.live="prioridadFilter">
                        <option value="all">Todas</option>
                        <option value="URGENTE">Urgente</option>
                        <option value="ALTA">Alta</option>
                        <option value="NORMAL">Normal</option>
                        <option value="BAJA">Baja</option>
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
                <div class="col-md-1">
                    <label class="form-label small">Origen</label>
                    <select class="form-select" wire:model.live="origenFilter">
                        <option value="all">Todos</option>
                        <option value="MIN_MAX">MIN_MAX</option>
                        <option value="SMA">SMA</option>
                        <option value="POS_CONSUMPTION">POS</option>
                    </select>
                </div>
                <div class="col-md-2 d-flex align-items-end">
                    <button class="btn btn-outline-secondary w-100" wire:click="limpiarFiltros">
                        <i class="fa-solid fa-filter-circle-xmark me-1"></i>Limpiar
                    </button>
                </div>
            </div>
            <div class="row g-3 mt-2">
                <div class="col-md-3">
                    <label class="form-label small">Desde</label>
                    <input type="date" class="form-control" wire:model.live="fechaDesde">
                </div>
                <div class="col-md-3">
                    <label class="form-label small">Hasta</label>
                    <input type="date" class="form-control" wire:model.live="fechaHasta">
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
                            <th>Item</th>
                            <th>Prioridad</th>
                            <th class="text-end">Stock Actual</th>
                            <th class="text-end">Stock Min</th>
                            <th class="text-end">Qty Sugerida</th>
                            <th>Origen</th>
                            <th>Motivo</th>
                            <th>Estado</th>
                            <th class="text-center">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($suggestions as $row)
                            <tr>
                                <td>
                                    <div class="fw-semibold">{{ $row['item']['nombre'] ?? $row['item_id'] ?? 'N/D' }}</div>
                                    <div class="text-muted small">{{ $row['item_id'] ?? '' }} • {{ $row['uom'] ?? '' }}</div>
                                </td>
                                <td>
                                    @php
                                        $prioridad = $row['prioridad'] ?? 'NORMAL';
                                        $prioridadClass = match($prioridad) {
                                            'URGENTE' => 'bg-danger text-white',
                                            'ALTA' => 'bg-warning text-dark',
                                            'NORMAL' => 'bg-info text-white',
                                            'BAJA' => 'bg-secondary text-white',
                                            default => 'bg-secondary text-white'
                                        };
                                    @endphp
                                    <span class="badge {{ $prioridadClass }}">{{ $prioridad }}</span>
                                </td>
                                <td class="text-end">{{ number_format((float)($row['stock_actual'] ?? 0), 2) }}</td>
                                <td class="text-end">{{ number_format((float)($row['stock_min'] ?? 0), 2) }}</td>
                                <td class="text-end fw-semibold text-primary">
                                    {{ number_format((float)($row['qty_sugerida'] ?? 0), 2) }}
                                </td>
                                <td>
                                    <span class="badge bg-light text-dark border">{{ $row['origen'] ?? '—' }}</span>
                                </td>
                                <td class="text-muted small" style="max-width: 250px;">
                                    {{ $row['motivo'] ?? '—' }}
                                </td>
                                <td>
                                    @php
                                        $estado = $row['estado'] ?? 'PENDIENTE';
                                        $estadoClass = match($estado) {
                                            'PENDIENTE' => 'bg-warning text-dark',
                                            'APROBADA' => 'bg-success text-white',
                                            'RECHAZADA' => 'bg-danger text-white',
                                            'CONVERTIDA' => 'bg-primary text-white',
                                            default => 'bg-secondary text-white'
                                        };
                                    @endphp
                                    <span class="badge {{ $estadoClass }}">{{ $estado }}</span>
                                </td>
                                <td class="text-center">
                                    <div class="btn-group btn-group-sm" role="group">
                                        @if($row['estado'] === 'PENDIENTE')
                                            <button class="btn btn-success"
                                                    wire:click="abrirModalAprobar({{ $row['id'] }})"
                                                    title="Aprobar">
                                                <i class="fa-solid fa-check"></i>
                                            </button>
                                            <button class="btn btn-danger"
                                                    wire:click="abrirModalRechazar({{ $row['id'] }})"
                                                    title="Rechazar">
                                                <i class="fa-solid fa-times"></i>
                                            </button>
                                        @elseif($row['estado'] === 'APROBADA')
                                            <button class="btn btn-primary"
                                                    wire:click="abrirModalConvertir({{ $row['id'] }})"
                                                    title="Convertir">
                                                <i class="fa-solid fa-arrow-right-arrow-left"></i>
                                            </button>
                                        @else
                                            <span class="text-muted small">—</span>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="9" class="text-center text-muted py-5">
                                    @if($loading)
                                        <i class="fa-solid fa-spinner fa-spin me-2"></i>Cargando sugerencias...
                                    @else
                                        <i class="fa-solid fa-inbox me-2"></i>No hay sugerencias con los filtros aplicados.
                                    @endif
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    {{-- Paginación
    <div class="mt-3">
        {{ $suggestions->links() }}
    </div>
    --}}

    {{-- Modal Aprobar --}}
    @if($showModalAprobar)
        <div class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header bg-success text-white">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-check-circle me-2"></i>Aprobar Sugerencia
                        </h5>
                        <button type="button" class="btn-close btn-close-white" wire:click="$set('showModalAprobar', false)"></button>
                    </div>
                    <div class="modal-body">
                        @if($errorMessage)
                            <div class="alert alert-danger py-2">{{ $errorMessage }}</div>
                        @endif
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Item</label>
                            <div class="text-muted">{{ $selectedSuggestion['item']['nombre'] ?? $selectedSuggestion['item_id'] ?? 'N/D' }}</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Cantidad Sugerida</label>
                            <div class="text-muted">{{ number_format((float)($selectedSuggestion['qty_sugerida'] ?? 0), 2) }} {{ $selectedSuggestion['uom'] ?? '' }}</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Cantidad a Aprobar</label>
                            <input type="number" class="form-control" wire:model="qtyAprobada"
                                   step="0.01" min="0" placeholder="Dejar vacío para usar cantidad sugerida">
                            <small class="text-muted">Puedes modificar la cantidad si es necesario</small>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" wire:click="$set('showModalAprobar', false)">
                            Cancelar
                        </button>
                        <button type="button" class="btn btn-success" wire:click="aprobarSugerencia">
                            <i class="fa-solid fa-check me-1"></i>Aprobar
                        </button>
                    </div>
                </div>
            </div>
        </div>
    @endif

    {{-- Modal Rechazar --}}
    @if($showModalRechazar)
        <div class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header bg-danger text-white">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-times-circle me-2"></i>Rechazar Sugerencia
                        </h5>
                        <button type="button" class="btn-close btn-close-white" wire:click="$set('showModalRechazar', false)"></button>
                    </div>
                    <div class="modal-body">
                        @if($errorMessage)
                            <div class="alert alert-danger py-2">{{ $errorMessage }}</div>
                        @endif
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Item</label>
                            <div class="text-muted">{{ $selectedSuggestion['item']['nombre'] ?? $selectedSuggestion['item_id'] ?? 'N/D' }}</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Motivo de Rechazo <span class="text-danger">*</span></label>
                            <textarea class="form-control" wire:model="motivoRechazo" rows="3"
                                      placeholder="Explica por qué rechazas esta sugerencia..." required></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" wire:click="$set('showModalRechazar', false)">
                            Cancelar
                        </button>
                        <button type="button" class="btn btn-danger" wire:click="rechazarSugerencia">
                            <i class="fa-solid fa-times me-1"></i>Rechazar
                        </button>
                    </div>
                </div>
            </div>
        </div>
    @endif

    {{-- Modal Convertir --}}
    @if($showModalConvertir)
        <div class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header bg-primary text-white">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-arrow-right-arrow-left me-2"></i>Convertir Sugerencia
                        </h5>
                        <button type="button" class="btn-close btn-close-white" wire:click="$set('showModalConvertir', false)"></button>
                    </div>
                    <div class="modal-body">
                        @if($errorMessage)
                            <div class="alert alert-danger py-2">{{ $errorMessage }}</div>
                        @endif
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Item</label>
                            <div class="text-muted">{{ $selectedSuggestion['item']['nombre'] ?? $selectedSuggestion['item_id'] ?? 'N/D' }}</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Cantidad Aprobada</label>
                            <div class="text-primary fs-5">{{ number_format((float)($selectedSuggestion['qty_aprobada'] ?? 0), 2) }} {{ $selectedSuggestion['uom'] ?? '' }}</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Convertir a <span class="text-danger">*</span></label>
                            <select class="form-select" wire:model="tipoConversion">
                                <option value="purchase_request">Solicitud de Compra (Purchase Request)</option>
                                <option value="production_order">Orden de Producción (Production Order)</option>
                            </select>
                            <small class="text-muted">
                                Selecciona si esta sugerencia debe generar una compra o producción interna
                            </small>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" wire:click="$set('showModalConvertir', false)">
                            Cancelar
                        </button>
                        <button type="button" class="btn btn-primary" wire:click="convertirSugerencia">
                            <i class="fa-solid fa-arrow-right me-1"></i>Convertir
                        </button>
                    </div>
                </div>
            </div>
        </div>
    @endif
</div>
