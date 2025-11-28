{{-- KPIs para vista summary_item_mods y legacy --}}
@php $dayCount = count($summary['days'] ?? []); @endphp

<div class="row g-3 mb-4">
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Ítems únicos</p>
                <h3 class="fw-bold mb-0">{{ $summary['total_items'] }}</h3>
                <span class="text-muted small">Productos con modificadores</span>
                <div class="text-muted small mt-2">{{ $dayCount === 1 ? '1 día analizado' : $dayCount . ' días en rango' }}</div>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Modificadores únicos</p>
                <h3 class="fw-bold mb-0">{{ $summary['total_modifiers'] }}</h3>
                <span class="text-muted small">Extras aplicados</span>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Monto adicional</p>
                <h3 class="fw-bold mb-0">${{ number_format($summary['total_amount'], 2) }}</h3>
                <span class="text-muted small">Ingreso extra obtenido</span>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Promedio por selección</p>
                <h3 class="fw-bold mb-0">${{ number_format($summary['avg_amount_per_selection'], 2) }}</h3>
                <span class="text-muted small">{{ number_format($summary['total_selections']) }} selecciones</span>
            </div>
        </div>
    </div>
</div>

@if(isset($summary['top_modifiers']) && count($summary['top_modifiers']) > 0)
<div class="row g-3 mb-4">
    <div class="col-lg-6">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-header bg-white">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-star text-warning me-2"></i>
                    Top modificadores por monto
                </h5>
            </div>
            <div class="card-body">
                <ol class="list-group list-group-numbered list-group-flush">
                    @foreach($summary['top_modifiers'] as $modifier)
                        <li class="list-group-item d-flex justify-content-between align-items-start">
                            <div class="me-auto">
                                <div class="fw-semibold">{{ $modifier['modifier'] }}</div>
                                <span class="text-muted small">{{ number_format($modifier['times_selected']) }} selecciones</span>
                            </div>
                            <span class="badge bg-primary-subtle text-primary">
                                ${{ number_format($modifier['amount'], 2) }}
                            </span>
                        </li>
                    @endforeach
                </ol>
            </div>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <p class="text-muted mb-1 small">Combinaciones</p>
                <h4 class="fw-bold mb-0">{{ number_format($summary['total_combinations'] ?? 0) }}</h4>
                <span class="text-muted small">Ítem + Modificador únicos</span>
            </div>
        </div>
    </div>
</div>
@endif
