<div class="container py-3 space-y-4">
    <div class="d-flex justify-content-between align-items-center">
        <div>
            <h1 class="h4 mb-0">Recepción #{{ $recepcionId }}</h1>
            <div class="text-muted small">
                <span class="badge rounded-pill 
                    @if($estado === 'VALIDADA') bg-info text-dark
                    @elseif($estado === 'POSTEADA') bg-success
                    @elseif($estado === 'BORRADOR') bg-secondary
                    @else bg-light text-dark @endif">
                    {{ $estado }}
                </span>
                @if($requiere_aprobacion)
                    <span class="badge bg-warning text-dark ms-2">Requiere aprobación</span>
                @endif
            </div>
        </div>
        <a href="{{ route('inv.receptions') }}" class="btn btn-outline-secondary btn-sm">
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

    <div class="d-flex flex-wrap gap-2 mb-3">
        @if($canValidate)
            <button
                type="button"
                class="btn btn-primary btn-sm"
                wire:click="actionValidate"
            >
                <i class="fa-solid fa-clipboard-check me-1"></i>Validar
            </button>
        @endif

        @if($canOverride && $requiere_aprobacion)
            <button
                type="button"
                class="btn btn-warning btn-sm"
                wire:click="actionApprove"
            >
                <i class="fa-solid fa-shield-check me-1"></i>Aprobar tolerancia
            </button>
        @endif

        @if($canPost)
            <button
                type="button"
                class="btn btn-success btn-sm"
                wire:click="actionPost"
            >
                <i class="fa-solid fa-box-archive me-1"></i>Postear a inventario
            </button>
        @endif
    </div>

    <section class="card shadow-sm border-0">
        <div class="table-responsive">
            <table class="table align-middle mb-0">
                <thead class="table-light">
                    <tr class="text-muted small">
                        <th>Item</th>
                        <th>Qty ordenada</th>
                        <th>Qty recibida</th>
                        <th>% diferencia</th>
                        <th>Docs</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($lineas as $linea)
                        <tr @class(['table-warning' => $linea['fuera_tolerancia'] ?? false])>
                            <td>
                                <div class="fw-semibold">{{ $linea['item_nombre'] ?? 'N/D' }}</div>
                                <div class="text-muted small">ID {{ $linea['item_id'] ?? '-' }}</div>
                            </td>
                            <td>{{ $linea['qty_ordenada'] ?? '0.000000' }}</td>
                            <td>{{ $linea['qty_recibida'] ?? '0.000000' }}</td>
                            <td>
                                {{ number_format($linea['diferencia_pct'] ?? 0, 2) }}%
                                @if($linea['fuera_tolerancia'] ?? false)
                                    <span class="badge bg-warning text-dark ms-1">fuera</span>
                                @endif
                            </td>
                            <td>
                                @if(!empty($linea['doc_url']))
                                    <a class="small" href="{{ $linea['doc_url'] }}" target="_blank" rel="noreferrer">
                                        <i class="fa-solid fa-paperclip me-1"></i>Evidencia
                                    </a>
                                @else
                                    <span class="text-muted small">—</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="text-center text-muted py-4">
                                Sin líneas registradas para esta recepción.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </section>
</div>
