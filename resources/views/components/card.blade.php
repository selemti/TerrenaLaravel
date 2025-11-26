@props([
    'variant' => 'default', // default, elevated, bordered
    'padding' => 'normal',  // none, sm, normal, lg
    'borderColor' => null,  // primary, secondary, success, warning, info, danger
])

@php
$classes = 'card-ds';

// Variantes
$classes .= match ($variant) {
    'elevated' => ' card-ds--elevated',
    'bordered' => ' card-ds--bordered',
    default => ''
};

// Padding
$classes .= match ($padding) {
    'none' => ' p-0',
    'sm' => ' p-3',
    'lg' => ' p-5',
    default => ' p-4'
};

// Border color
if ($borderColor) {
    $classes .= ' card-ds--border-' . $borderColor;
}
@endphp

<div {{ $attributes->merge(['class' => $classes]) }}>
    @isset($header)
        <div class="card-ds__header">
            {{ $header }}
        </div>
    @endisset

    <div class="card-ds__body">
        {{ $slot }}
    </div>

    @isset($footer)
        <div class="card-ds__footer">
            {{ $footer }}
        </div>
    @endisset
</div>
