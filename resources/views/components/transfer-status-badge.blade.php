@props(['status' => ''])
@php
    $map = [
        'BORRADOR' => ['class' => 'badge bg-secondary-subtle text-secondary-emphasis', 'label' => 'Borrador'],
        'PLANIFICADA' => ['class' => 'badge bg-warning text-dark', 'label' => 'Planificada'],
        'APROBADA' => ['class' => 'badge bg-primary', 'label' => 'Aprobada'],
        'EN_PROCESO' => ['class' => 'badge bg-info text-dark', 'label' => 'En proceso'],
        'COMPLETADA' => ['class' => 'badge bg-success', 'label' => 'Completada'],
        'COMPLETADO' => ['class' => 'badge bg-success', 'label' => 'Completada'],
        'POSTEADA' => ['class' => 'badge bg-success-subtle text-success-emphasis', 'label' => 'Posteada'],
        'CANCELADA' => ['class' => 'badge bg-danger', 'label' => 'Cancelada'],
    ];
    $entry = $map[$status] ?? ['class' => 'badge bg-secondary', 'label' => ucfirst(strtolower(str_replace('_', ' ', $status)))];
@endphp
<span {{ $attributes->merge(['class' => $entry['class']]) }}>{{ $entry['label'] }}</span>
