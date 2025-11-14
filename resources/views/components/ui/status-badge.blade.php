@props([
    'status' => '',
    'type' => 'default', // 'default', 'success', 'warning', 'danger', 'info', 'primary', 'secondary', 'light', 'dark'
    'size' => 'md', // 'sm', 'md', 'lg'
    'withIcon' => false,
    'icon' => null, // Optional custom icon class
    'label' => null, // Optional custom label
])

@php
    $typeClasses = [
        'default' => 'bg-gray-100 text-gray-800',
        'success' => 'bg-green-100 text-green-800',
        'warning' => 'bg-yellow-100 text-yellow-800',
        'danger' => 'bg-red-100 text-red-800',
        'info' => 'bg-blue-100 text-blue-800',
        'primary' => 'bg-blue-100 text-blue-800',
        'secondary' => 'bg-gray-200 text-gray-800',
        'light' => 'bg-gray-100 text-gray-800',
        'dark' => 'bg-gray-800 text-white',
    ][$type] ?? $typeClasses['default'];
    
    $sizeClasses = [
        'sm' => 'text-xs px-2 py-1',
        'md' => 'text-sm px-3 py-1.5',
        'lg' => 'text-base px-4 py-2'
    ][$size];
    
    $badgeClasses = $typeClasses . ' ' . $sizeClasses . ' rounded-full font-medium inline-flex items-center';
    
    // Default icons based on type
    $defaultIcons = [
        'success' => 'fa fa-check-circle',
        'warning' => 'fa fa-exclamation-triangle',
        'danger' => 'fa fa-times-circle',
        'info' => 'fa fa-info-circle',
        'primary' => 'fa fa-circle',
        'secondary' => 'fa fa-circle',
        'light' => 'fa fa-circle',
        'dark' => 'fa fa-circle',
    ];
    
    $iconClass = $icon ?? ($withIcon ? ($defaultIcons[$type] ?? null) : null);
    
    // Default labels based on status
    $defaultLabels = [
        'DRAFT' => 'Borrador',
        'SOLICITADA' => 'Solicitada',
        'APROBADA' => 'Aprobada',
        'EN_TRANSITO' => 'En Tránsito',
        'RECIBIDA' => 'Recibida',
        'POSTEADA' => 'Posteada',
        'CANCELADA' => 'Cancelada',
        'ACTIVE' => 'Activo',
        'INACTIVE' => 'Inactivo',
        'PENDING' => 'Pendiente',
        'COMPLETED' => 'Completado',
        'PROCESSING' => 'Procesando',
        'FAILED' => 'Fallido',
        'APPROVED' => 'Aprobado',
        'REJECTED' => 'Rechazado',
        'PUBLISHED' => 'Publicado',
        'DRAFT' => 'Borrador',
    ];
    
    $labelText = $label ?? $defaultLabels[$status] ?? $status;
@endphp

<span class="{{ $badgeClasses }}">
    @if($iconClass)
        <i class="{{ $iconClass }} me-1.5"></i>
    @endif
    {{ $labelText }}
</span>