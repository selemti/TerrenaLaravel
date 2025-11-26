@props([
    'type' => 'info', // info, success, warning, danger, neutral
    'icon' => null,
    'dismissible' => false,
])

@php
$classes = 'alert-ds alert-ds--' . $type;
if ($dismissible) {
    $classes .= ' alert-ds--dismissible';
}

$iconClass = $icon ?? match ($type) {
    'success' => 'fa-circle-check',
    'warning' => 'fa-triangle-exclamation',
    'danger' => 'fa-circle-xmark',
    'neutral' => 'fa-circle-info',
    default => 'fa-circle-info',
};
@endphp

<div {{ $attributes->merge(['class' => $classes, 'role' => 'alert']) }}>
    <div class="alert-ds__icon">
        <i class="fa-solid {{ $iconClass }}"></i>
    </div>
    <div class="alert-ds__content">
        {{ $slot }}
    </div>
    @if($dismissible)
        <button type="button" class="alert-ds__close" data-bs-dismiss="alert" aria-label="Cerrar">
            <i class="fa-solid fa-xmark"></i>
        </button>
    @endif
</div>
