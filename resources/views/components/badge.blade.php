@props([
    'type' => 'neutral', // primary, secondary, success, warning, danger, info, neutral
    'icon' => null,
    'pill' => false,
])

@php
$classes = 'badge-ds badge-ds--' . $type;
if ($pill) {
    $classes .= ' badge-ds--pill';
}
@endphp

<span {{ $attributes->merge(['class' => $classes]) }}>
    @if($icon)
        <i class="fa-solid {{ $icon }} me-1"></i>
    @endif
    {{ $slot }}
</span>
