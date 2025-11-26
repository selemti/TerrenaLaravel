@props([
    'icon' => 'fa-chart-line',
    'label',
    'value' => '—',
    'helper' => null,
    'variant' => 'primary', // primary, success, warning, info, danger, neutral
    'badge' => null,
])

@php
$classes = 'kpi-card kpi-card--' . $variant;
@endphp

<div {{ $attributes->merge(['class' => $classes]) }}>
    <div class="d-flex justify-content-between align-items-start mb-2">
        <div class="kpi-card__icon">
            <i class="fa-solid {{ $icon }}"></i>
        </div>
        @if($badge)
            <span class="kpi-card__badge">{{ $badge }}</span>
        @endif
    </div>

    <div class="kpi-card__label">{{ $label }}</div>
    <div class="kpi-card__value">{{ $value }}</div>

    @if($helper)
        <div class="kpi-card__helper text-muted">{{ $helper }}</div>
    @endif
</div>
