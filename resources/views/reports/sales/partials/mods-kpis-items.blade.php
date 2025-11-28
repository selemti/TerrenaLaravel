{{-- KPIs para vista summary_items --}}
@php $dayCount = count($summary['days'] ?? []); @endphp

<div class="row g-3 mb-4">
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Ítems únicos</p>
                <h3 class="fw-bold mb-0">{{ $summary['total_items'] ?? 0 }}</h3>
                <span class="text-muted small">Productos vendidos</span>
                <div class="text-muted small mt-2">{{ $dayCount === 1 ? '1 día analizado' : $dayCount . ' días en rango' }}</div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Categorías</p>
                <h3 class="fw-bold mb-0">{{ $summary['total_categories'] ?? 0 }}</h3>
                <span class="text-muted small">Familias de productos</span>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Unidades totales</p>
                <h3 class="fw-bold mb-0">{{ number_format($summary['total_units'] ?? 0) }}</h3>
                <span class="text-muted small">Productos vendidos</span>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Ingreso neto</p>
                <h3 class="fw-bold mb-0">${{ number_format($summary['total_net'] ?? 0, 2) }}</h3>
                <span class="text-muted small">Después de descuentos</span>
            </div>
        </div>
    </div>
</div>

<div class="row g-3 mb-4">
    <div class="col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Ingreso bruto</p>
                <h4 class="fw-bold mb-0">${{ number_format($summary['total_gross'] ?? 0, 2) }}</h4>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Descuentos</p>
                <h4 class="fw-bold mb-0 text-danger">${{ number_format($summary['total_discount'] ?? 0, 2) }}</h4>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Grupos de menú</p>
                <h4 class="fw-bold mb-0">{{ $summary['total_groups'] ?? 0 }}</h4>
            </div>
        </div>
    </div>
</div>
