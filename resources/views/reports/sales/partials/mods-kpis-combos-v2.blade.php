@php
    // Calcular totales mejorados para v2.0
    $totalBase = $rows->sum('ingreso_base');
    $totalMods = $rows->sum('costo_modificadores');
    $totalIngreso = $rows->sum('ingreso_total');
    $totalTickets = $rows->sum('tickets');
    $totalUnidades = $rows->sum('unidades_item');
    $totalItems = $rows->unique('menu_item')->count();
    $totalCombos = $rows->unique('combo')->count();
@endphp

<div class="row g-3 mb-4">
    <!-- KPI Principal con separación Base/Mods/Total -->
    <div class="col-12 col-lg-3">
        <div class="stat-card border-start border-4 border-primary">
            <div class="stat-label d-flex justify-content-between align-items-center">
                <span>Ventas Totales</span>
                <small class="text-muted">
                    <span class="badge bg-light text-dark">Base</span>
                    <span class="badge bg-warning text-dark">Mods</span>
                </small>
            </div>
            <div class="stat-value h4">
                ${{ number_format($totalIngreso, 2) }}
            </div>
            <div class="stat-detail small">
                <span class="text-success">${{ number_format($totalBase, 2) }}</span>
                <span class="mx-1">+</span>
                <span class="text-warning">${{ number_format($totalMods, 2) }}</span>
            </div>
        </div>
    </div>

    <!-- Tickets Distinct -->
    <div class="col-12 col-md-6 col-lg-3">
        <div class="stat-card border-start border-4 border-info">
            <div class="stat-label">Tickets (Reales)</div>
            <div class="stat-value">{{ number_format($totalTickets) }}</div>
            <div class="stat-detail small text-muted">
                Distintos tickets con modificadores
            </div>
        </div>
    </div>

    <!-- Unidades Vendidas -->
    <div class="col-12 col-md-6 col-lg-3">
        <div class="stat-card border-start border-4 border-success">
            <div class="stat-label">Unidades Vendidas</div>
            <div class="stat-value">{{ number_format($totalUnidades) }}</div>
            <div class="stat-detail small text-muted">
                {{ number_format($totalItems) }} ítems distintos
            </div>
        </div>
    </div>

    <!-- Combinaciones Únicas con Contexto -->
    <div class="col-12 col-md-6 col-lg-3">
        <div class="stat-card border-start border-4 border-secondary">
            <div class="stat-label">Combinaciones Únicas</div>
            <div class="stat-value">{{ number_format($totalCombos) }}</div>
            <div class="stat-detail small text-muted">
                Firmas de modificadores distintas
            </div>
        </div>
    </div>
</div>

<!-- Resumen de Modificadores (Adicional) -->
<div class="alert alert-info alert-sm mb-4">
    <div class="d-flex align-items-center">
        <i class="fa-solid fa-info-circle me-2"></i>
        <div>
            <strong>Resumen de Modificadores:</strong>
            {{ $totalMods > 0 ? '$' . number_format($totalMods, 2) . ' extra en modificadores' : 'Sin costo adicional en modificadores' }}
            ({{ round($totalIngreso > 0 ? ($totalMods / $totalIngreso) * 100 : 0, 1) }}% del total)
        </div>
    </div>
</div>

@if($includeEmpty)
<div class="alert alert-warning alert-sm mb-4">
    <div class="d-flex align-items-center">
        <i class="fa-solid fa-exclamation-triangle me-2"></i>
        <div>
            <strong>Vista de Catálogo:</strong> Incluyendo ítems sin ventas/mods para auditoría completa.
            <a href="{{ request()->fullUrlWithQuery(['include_empty' => null]) }}" class="alert-link">Ver solo ventas</a>
        </div>
    </div>
</div>
@endif