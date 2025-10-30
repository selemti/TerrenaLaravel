<div class="card shadow-sm border-warning">
    <div class="card-body">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h5 class="card-title mb-0">
                <i class="fa-solid fa-exclamation-triangle text-warning me-2"></i>
                Items sin Mapeo POS
            </h5>
            <button 
                wire:click="loadCounts" 
                class="btn btn-sm btn-outline-secondary"
                title="Recargar"
            >
                <i class="fa-solid fa-sync"></i>
            </button>
        </div>

        <div class="row g-3">
            <div class="col-md-6">
                <div class="text-center p-3 bg-light rounded">
                    <div class="fs-2 fw-bold text-danger">{{ $unmappedMenuCount }}</div>
                    <div class="text-muted small">Items MENU sin mapear</div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="text-center p-3 bg-light rounded">
                    <div class="fs-2 fw-bold text-warning">{{ $unmappedModifierCount }}</div>
                    <div class="text-muted small">MODIFIER sin mapear</div>
                </div>
            </div>
        </div>

        <div class="mt-3">
            <small class="text-muted">
                <i class="fa-regular fa-calendar me-1"></i>
                Fecha: {{ \Carbon\Carbon::parse($fecha)->format('d/m/Y') }} | 
                Sucursal: {{ $sucursal_id }}
            </small>
        </div>

        @if($unmappedMenuCount > 0 || $unmappedModifierCount > 0)
        <div class="mt-3">
            <a 
                href="{{ route('pos.mapping') }}" 
                class="btn btn-warning btn-sm w-100"
            >
                <i class="fa-solid fa-tools me-1"></i>
                Ir a Mapeo POS
            </a>
        </div>
        @endif
    </div>
</div>
