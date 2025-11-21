{{--
    Loading Spinner Component

    Spinner reutilizable para mostrar estados de carga.
    Compatible con Livewire wire:loading.

    Uso:
    <x-loading-spinner />
    <x-loading-spinner size="sm" />
    <x-loading-spinner size="lg" color="primary" />
    <x-loading-spinner wire:loading wire:target="save" />
--}}

@props([
    'size' => 'md',      // sm, md, lg
    'color' => 'primary', // primary, secondary, success, danger, warning, info
    'text' => null        // Texto opcional debajo del spinner
])

@php
    $sizeClasses = [
        'sm' => 'spinner-border-sm',
        'md' => '',
        'lg' => 'spinner-border-lg',
    ];

    $sizeClass = $sizeClasses[$size] ?? '';
@endphp

<div {{ $attributes->merge(['class' => 'd-flex flex-column align-items-center justify-content-center gap-2']) }}>
    <div class="spinner-border text-{{ $color }} {{ $sizeClass }}" role="status">
        <span class="visually-hidden">Cargando...</span>
    </div>

    @if($text)
        <small class="text-muted">{{ $text }}</small>
    @endif
</div>
