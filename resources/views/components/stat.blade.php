@props([
    'label',
    'value' => '—',
    'subtext' => null,
    'icon' => null,
    'trend' => null,
    'trendDirection' => 'up', // up, down, flat
])

@php
$classes = 'stat-ds';
$trendIcon = match ($trendDirection) {
    'down' => 'fa-arrow-down',
    'flat' => 'fa-minus',
    default => 'fa-arrow-up',
};
@endphp

<div {{ $attributes->merge(['class' => $classes]) }}>
    <div class="d-flex align-items-center gap-2 mb-1">
        @if($icon)
            <span class="stat-ds__icon"><i class="fa-solid {{ $icon }}"></i></span>
        @endif
        <span class="stat-ds__label">{{ $label }}</span>
    </div>

    <div class="stat-ds__value">{{ $value }}</div>

    @if($subtext)
        <div class="stat-ds__subtext text-muted">{{ $subtext }}</div>
    @endif

    @if($trend)
        <div class="stat-ds__trend stat-ds__trend--{{ $trendDirection }}">
            <i class="fa-solid {{ $trendIcon }}"></i>
            <span>{{ $trend }}</span>
        </div>
    @endif
</div>
