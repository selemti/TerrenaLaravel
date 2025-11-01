@props([
    'active' => true,
    'labels' => ['Activo', 'Inactivo'],
])

@if($active)
    <span {{ $attributes->merge(['class' => 'badge bg-success']) }}>
        <i class="bi bi-check-circle me-1"></i>
        {{ $labels[0] }}
    </span>
@else
    <span {{ $attributes->merge(['class' => 'badge bg-secondary']) }}>
        <i class="bi bi-x-circle me-1"></i>
        {{ $labels[1] }}
    </span>
@endif
