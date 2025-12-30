<div class="row g-3 mb-3">
    <div class="col-12 col-md-3">
        <div class="stat-card">
            <div class="stat-label">Combinaciones únicas</div>
            <div class="stat-value">{{ number_format((int) ($summary['total_combos'] ?? 0)) }}</div>
        </div>
    </div>
    <div class="col-12 col-md-3">
        <div class="stat-card">
            <div class="stat-label">Ítems únicos</div>
            <div class="stat-value">{{ number_format((int) ($summary['total_items'] ?? 0)) }}</div>
        </div>
    </div>
    <div class="col-12 col-md-3">
        <div class="stat-card">
            <div class="stat-label">Unidades vendidas</div>
            <div class="stat-value">{{ number_format((int) ($summary['total_units'] ?? 0)) }}</div>
        </div>
    </div>
    <div class="col-12 col-md-3">
        <div class="stat-card">
            <div class="stat-label">Monto extra modifiers</div>
            <div class="stat-value">${{ number_format((float) ($summary['total_amount'] ?? 0), 2) }}</div>
        </div>
    </div>
</div>
