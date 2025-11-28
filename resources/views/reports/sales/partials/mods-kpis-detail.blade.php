{{-- KPIs para vista detail --}}
@php $dayCount = count($summary['days'] ?? []); @endphp

<div class="row g-3 mb-4">
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Total registros</p>
                <h3 class="fw-bold mb-0">{{ number_format($summary['total_records'] ?? 0) }}</h3>
                <span class="text-muted small">Líneas de detalle</span>
                <div class="text-muted small mt-2">{{ $dayCount === 1 ? '1 día analizado' : $dayCount . ' días en rango' }}</div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Tickets únicos</p>
                <h3 class="fw-bold mb-0">{{ number_format($summary['total_tickets'] ?? 0) }}</h3>
                <span class="text-muted small">Ventas procesadas</span>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Ítems únicos</p>
                <h3 class="fw-bold mb-0">{{ $summary['total_items'] ?? 0 }}</h3>
                <span class="text-muted small">Productos con mods</span>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Modificadores únicos</p>
                <h3 class="fw-bold mb-0">{{ $summary['total_modifiers'] ?? 0 }}</h3>
                <span class="text-muted small">Extras diferentes</span>
            </div>
        </div>
    </div>
</div>

<div class="row g-3 mb-4">
    <div class="col-md-6">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Total monto extra</p>
                <h4 class="fw-bold mb-0">${{ number_format($summary['total_amount'] ?? 0, 2) }}</h4>
                <span class="text-muted small">Ingreso por modificadores</span>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Selecciones totales</p>
                <h4 class="fw-bold mb-0">{{ number_format($summary['total_selections'] ?? 0) }}</h4>
                <span class="text-muted small">Modificadores aplicados</span>
            </div>
        </div>
    </div>
</div>
