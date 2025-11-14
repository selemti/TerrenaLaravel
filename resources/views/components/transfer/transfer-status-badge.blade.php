@props([
    'status' => '',
    'size' => 'md', // 'sm', 'md', 'lg'
    'withIcon' => true,
])

@php
    $statusConfig = [
        'BORRADOR' => [
            'class' => 'bg-gray-100 text-gray-800',
            'icon' => 'fa fa-file',
            'label' => 'Borrador'
        ],
        'SOLICITADA' => [
            'class' => 'bg-blue-100 text-blue-800',
            'icon' => 'fa fa-clock',
            'label' => 'Solicitada'
        ],
        'APROBADA' => [
            'class' => 'bg-indigo-100 text-indigo-800',
            'icon' => 'fa fa-check-circle',
            'label' => 'Aprobada'
        ],
        'EN_TRANSITO' => [
            'class' => 'bg-amber-100 text-amber-800',
            'icon' => 'fa fa-truck',
            'label' => 'En Tránsito'
        ],
        'RECIBIDA' => [
            'class' => 'bg-emerald-100 text-emerald-800',
            'icon' => 'fa fa-check-to-slot',
            'label' => 'Recibida'
        ],
        'POSTEADA' => [
            'class' => 'bg-purple-100 text-purple-800',
            'icon' => 'fa fa-database',
            'label' => 'Posteada'
        ],
        'CANCELADA' => [
            'class' => 'bg-red-100 text-red-800',
            'icon' => 'fa fa-ban',
            'label' => 'Cancelada'
        ]
    ];
    
    $config = $statusConfig[$status] ?? $statusConfig['BORRADOR'];
    
    $sizeClasses = [
        'sm' => 'text-xs px-2 py-1',
        'md' => 'text-sm px-3 py-1.5',
        'lg' => 'text-base px-4 py-2'
    ][$size];
    
    $badgeClasses = $config['class'] . ' ' . $sizeClasses . ' rounded-full font-medium';
@endphp

<span class="{{ $badgeClasses }} inline-flex items-center">
    @if($withIcon)
        <i class="{{ $config['icon'] }} me-1.5"></i>
    @endif
    {{ $config['label'] }}
</span>