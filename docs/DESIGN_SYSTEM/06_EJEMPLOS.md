# Ejemplos de Uso

## Cards con header y tabla
```blade
<x-card padding="none" variant="elevated" borderColor="primary">
    <x-slot name="header">
        <div class="d-flex justify-content-between align-items-center">
            <h6 class="mb-0">Movimientos recientes</h6>
            <x-button variant="outline" size="sm" icon="fa-download">Exportar</x-button>
        </div>
    </x-slot>
    <div class="table-responsive p-3">
        <table class="table table-hover mb-0">
            <thead class="table-light">
            <tr><th>SKU</th><th>Tipo</th><th class="text-end">Cantidad</th></tr>
            </thead>
            <tbody>
            <tr>
                <td>SKU-001</td>
                <td><x-badge type="info" pill>Entrada</x-badge></td>
                <td class="text-end">25</td>
            </tr>
            </tbody>
        </table>
    </div>
</x-card>
```

## KPIs combinados
```blade
<div class="row g-3">
    <div class="col-md-4">
        <x-kpi-card icon="fa-box" label="Stock disponible" value="8,230" variant="primary" helper="Almacenes activos" />
    </div>
    <div class="col-md-4">
        <x-kpi-card icon="fa-triangle-exclamation" label="Alertas" value="12" variant="warning" helper="Revisar hoy" />
    </div>
    <div class="col-md-4">
        <x-kpi-card icon="fa-circle-check" label="Órdenes completas" value="96%" variant="success" helper="Últimos 7 días" />
    </div>
</div>
```

## Alertas con acción
```blade
<x-alert type="warning" dismissible>
    Hay transferencias en tránsito sin recibir.
    <a href="{{ route('transfers.index') }}" class="text-warning fw-semibold ms-1">Revisar</a>
</x-alert>
```

## Stat con tendencia
```blade
<x-stat label="Ticket promedio" value="$245.10" subtext="Últimos 30 días" trend="+3.1%" trendDirection="up" />
```
