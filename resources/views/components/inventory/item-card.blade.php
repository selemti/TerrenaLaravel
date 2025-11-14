@props([
    'item' => null,
    'showStock' => true,
    'showActions' => true,
    'stock' => null,
    'actions' => null,
])

<div class="card h-100 shadow-sm">
    <div class="card-body">
        <div class="d-flex justify-content-between align-items-start mb-2">
            <h6 class="card-title mb-0 fw-bold text-truncate" title="{{ $item['nombre'] ?? 'Nombre no disponible' }}">
                {{ $item['nombre'] ?? 'Nombre no disponible' }}
            </h6>
            <span class="badge bg-secondary ms-2 flex-shrink-0">
                {{ $item['sku'] ?? $item['clave'] ?? 'N/A' }}
            </span>
        </div>
        
        <p class="card-text text-muted small mb-2">
            {{ $item['categoria'] ?? 'Sin categoría' }}
        </p>
        
        @if($showStock && $stock !== null)
            <div class="d-flex justify-content-between align-items-center mt-3 pt-3 border-top">
                <div>
                    <span class="text-muted small">Existencia:</span>
                    <span class="fw-semibold ms-1">
                        {{ number_format($stock['cantidad_actual'] ?? 0, 2) }} 
                        {{ $stock['unidad_medida'] ?? $item['unidad_medida'] ?? '' }}
                    </span>
                </div>
                <span class="badge 
                    {{ ($stock['cantidad_actual'] ?? 0) <= ($item['stock_minimo'] ?? 0) ? 'bg-danger' : 'bg-success' }}
                ">
                    {{ ($stock['cantidad_actual'] ?? 0) <= ($item['stock_minimo'] ?? 0) ? 'Bajo' : 'Normal' }}
                </span>
            </div>
        @endif
    </div>
    
    @if($showActions)
        <div class="card-footer bg-transparent border-top">
            @if($actions)
                {{ $actions }}
            @else
                <div class="d-flex gap-2">
                    <button class="btn btn-sm btn-outline-primary flex-fill">
                        <i class="fa-solid fa-eye me-1"></i>Ver
                    </button>
                    <button class="btn btn-sm btn-outline-secondary flex-fill">
                        <i class="fa-solid fa-pen me-1"></i>Editar
                    </button>
                </div>
            @endif
        </div>
    @endif
</div>