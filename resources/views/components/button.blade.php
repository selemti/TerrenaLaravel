@props([
    'variant' => 'primary', // primary, secondary, outline, ghost, danger
    'size' => 'md', // sm, md, lg
    'icon' => null,
    'iconPosition' => 'left', // left, right
    'block' => false,
    'as' => 'button', // button, a
])

@php
$classes = 'btn-ds btn-ds--' . $variant;

$classes .= match ($size) {
    'sm' => ' btn-ds--sm',
    'lg' => ' btn-ds--lg',
    default => ' btn-ds--md'
};

if ($block) {
    $classes .= ' w-100';
}
@endphp

@if($as === 'a')
    <a {{ $attributes->merge(['class' => $classes]) }}>
        @if($icon && $iconPosition === 'left')
            <i class="fa-solid {{ $icon }} me-2"></i>
        @endif
        {{ $slot }}
        @if($icon && $iconPosition === 'right')
            <i class="fa-solid {{ $icon }} ms-2"></i>
        @endif
    </a>
@else
    <button {{ $attributes->merge(['class' => $classes, 'type' => 'button']) }}>
        @if($icon && $iconPosition === 'left')
            <i class="fa-solid {{ $icon }} me-2"></i>
        @endif
        {{ $slot }}
        @if($icon && $iconPosition === 'right')
            <i class="fa-solid {{ $icon }} ms-2"></i>
        @endif
    </button>
@endif
