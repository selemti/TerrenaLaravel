{{--
    Status Badge Component

    Badge reutilizable para mostrar estados.
    Soporta diferentes variantes de Bootstrap.

    Uso:
    <x-status-badge status="active" />
    <x-status-badge status="inactive" />
    <x-status-badge status="pending" />
    <x-status-badge status="approved" />
    <x-status-badge status="rejected" />
    <x-status-badge status="custom" label="Mi Estado" color="primary" />
--}}

@props([
    'status' => 'active',
    'label' => null,
    'color' => null,
    'icon' => true,
])

@php
    // Mapeo de estados a colores y labels
    $statusConfig = [
        'active' => [
            'color' => 'success',
            'label' => 'Activo',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-check-circle-fill" viewBox="0 0 16 16"><path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0m-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"/></svg>'
        ],
        'inactive' => [
            'color' => 'secondary',
            'label' => 'Inactivo',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-x-circle-fill" viewBox="0 0 16 16"><path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0M5.354 4.646a.5.5 0 1 0-.708.708L7.293 8l-2.647 2.646a.5.5 0 0 0 .708.708L8 8.707l2.646 2.647a.5.5 0 0 0 .708-.708L8.707 8l2.647-2.646a.5.5 0 0 0-.708-.708L8 7.293z"/></svg>'
        ],
        'pending' => [
            'color' => 'warning',
            'label' => 'Pendiente',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-clock-fill" viewBox="0 0 16 16"><path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0M8 3.5a.5.5 0 0 0-1 0V9a.5.5 0 0 0 .252.434l3.5 2a.5.5 0 0 0 .496-.868L8 8.71z"/></svg>'
        ],
        'approved' => [
            'color' => 'success',
            'label' => 'Aprobado',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-check-circle-fill" viewBox="0 0 16 16"><path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0m-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"/></svg>'
        ],
        'rejected' => [
            'color' => 'danger',
            'label' => 'Rechazado',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-x-circle-fill" viewBox="0 0 16 16"><path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0M5.354 4.646a.5.5 0 1 0-.708.708L7.293 8l-2.647 2.646a.5.5 0 0 0 .708.708L8 8.707l2.646 2.647a.5.5 0 0 0 .708-.708L8.707 8l2.647-2.646a.5.5 0 0 0-.708-.708L8 7.293z"/></svg>'
        ],
        'in_progress' => [
            'color' => 'info',
            'label' => 'En Progreso',
            'icon' => '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-arrow-repeat" viewBox="0 0 16 16"><path d="M11.534 7h3.932a.25.25 0 0 1 .192.41l-1.966 2.36a.25.25 0 0 1-.384 0l-1.966-2.36a.25.25 0 0 1 .192-.41m-11 2h3.932a.25.25 0 0 0 .192-.41L2.692 6.23a.25.25 0 0 0-.384 0L.342 8.59A.25.25 0 0 0 .534 9"/><path fill-rule="evenodd" d="M8 3c-1.552 0-2.94.707-3.857 1.818a.5.5 0 1 1-.771-.636A6.002 6.002 0 0 1 13.917 7H12.9A5 5 0 0 0 8 3M3.1 9a5.002 5.002 0 0 0 8.757 2.182.5.5 0 1 1 .771.636A6.002 6.002 0 0 1 2.083 9z"/></svg>'
        ],
    ];

    $config = $statusConfig[$status] ?? [
        'color' => $color ?? 'secondary',
        'label' => $label ?? ucfirst($status),
        'icon' => null
    ];

    $badgeColor = $color ?? $config['color'];
    $badgeLabel = $label ?? $config['label'];
    $badgeIcon = $icon && isset($config['icon']) ? $config['icon'] : null;
@endphp

<span {{ $attributes->merge(['class' => "badge bg-{$badgeColor} d-inline-flex align-items-center gap-1"]) }}>
    @if($badgeIcon)
        {!! $badgeIcon !!}
    @endif
    {{ $badgeLabel }}
</span>
