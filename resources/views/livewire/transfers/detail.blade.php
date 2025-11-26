<div class="container py-3 space-y-4">
    <div class="d-flex justify-content-between align-items-center">
        <div>
            <h1 class="h4 mb-0">Transferencia #{{ $transferId }}</h1>
            <div class="text-muted small">
                <span class="badge rounded-pill
                    @if($estado === 'APROBADA') bg-info text-dark
                    @elseif($estado === 'POSTEADA') bg-success
                    @elseif($estado === 'SOLICITADA') bg-secondary
                    @elseif($estado === 'EN_TRANSITO') bg-warning text-dark
                    @elseif($estado === 'RECIBIDA') bg-primary
                    @else bg-light text-dark @endif">
                    {{ $estado }}
                </span>
            </div>
        </div>
        <a href="{{ route('transfers.index') }}" class="btn btn-outline-secondary btn-sm">
            <i class="fa-solid fa-arrow-left me-1"></i>Volver
        </a>
    </div>

    @if($flashMessage)
        <div class="alert alert-success py-2">
            <i class="fa-solid fa-circle-check me-2"></i>{{ $flashMessage }}
        </div>
    @endif

    @if($errorMessage)
        <div class="alert alert-danger py-2">
            <i class="fa-solid fa-triangle-exclamation me-2"></i>{{ $errorMessage }}
        </div>
    @endif

    {{-- Información de cabecera --}}
    @if(!empty($cabecera))
        <section class="card shadow-sm border-0 mb-3">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <strong class="text-muted small">Almacén Origen:</strong>
                        <div>{{ $cabecera['almacen_origen'] ?? '-' }}</div>
                    </div>
                    <div class="col-md-6">
                        <strong class="text-muted small">Almacén Destino:</strong>
                        <div>{{ $cabecera['almacen_destino'] ?? '-' }}</div>
                    </div>
                    <div class="col-md-6">
                        <strong class="text-muted small">Creado por:</strong>
                        <div>{{ $cabecera['creado_por'] ?? '-' }}</div>
                    </div>
                    <div class="col-md-6">
                        <strong class="text-muted small">Fecha creación:</strong>
                        <div>{{ $cabecera['created_at'] ?? '-' }}</div>
                    </div>
                    @if(!empty($cabecera['guia']))
                        <div class="col-md-12">
                            <strong class="text-muted small">Guía de envío:</strong>
                            <div>{{ $cabecera['guia'] }}</div>
                        </div>
                    @endif
                </div>
            </div>
        </section>
    @endif

    {{-- Botones de acción según estado --}}
    <div class="d-flex flex-wrap gap-2 mb-3">
        @if($canApprove && $estado === 'SOLICITADA')
            <button type="button" class="btn btn-primary btn-sm" wire:click="actionApprove">
                <i class="fa-solid fa-check me-1"></i>Aprobar
            </button>
        @endif

        @if($estado === 'APROBADA')
            <a href="{{ route('transfers.dispatch', ['id' => $transferId]) }}" class="btn btn-warning btn-sm">
                <i class="fa-solid fa-truck me-1"></i>Despachar
            </a>
        @endif

        @if($estado === 'EN_TRANSITO')
            <a href="{{ route('transfers.receive', ['id' => $transferId]) }}" class="btn btn-info btn-sm">
                <i class="fa-solid fa-box-open me-1"></i>Recibir
            </a>
        @endif

        @if($canPost && $estado === 'RECIBIDA')
            <button type="button" class="btn btn-success btn-sm" wire:click="actionPost">
                <i class="fa-solid fa-box-archive me-1"></i>Postear a inventario
            </button>
        @endif
    </div>

    {{-- Tabla de líneas --}}
    <section class="card shadow-sm border-0">
        <div class="table-responsive">
            <table class="table align-middle mb-0">
                <thead class="table-light">
                    <tr class="text-muted small">
                        <th>Item</th>
                        <th>Qty solicitada</th>
                        <th>Qty despachada</th>
                        <th>Qty recibida</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($lineas as $linea)
                        <tr>
                            <td>
                                <div class="fw-semibold">{{ $linea['item_nombre'] ?? 'N/D' }}</div>
                                <div class="text-muted small">ID {{ $linea['item_id'] ?? '-' }}</div>
                            </td>
                            <td>{{ $linea['cantidad'] ?? '0.0000' }}</td>
                            <td>{{ $linea['cantidad_despachada'] ?? '0.0000' }}</td>
                            <td>{{ $linea['cantidad_recibida'] ?? '0.0000' }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="text-center text-muted py-4">
                                Sin líneas registradas para esta transferencia.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </section>
</div>
