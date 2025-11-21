{{--
    Search Input Component

    Input de búsqueda reutilizable con ícono y debounce.
    Compatible con Livewire wire:model.

    Uso:
    <x-search-input wire:model.live.debounce.300ms="search" placeholder="Buscar..." />
    <x-search-input wire:model.live="searchTerm" />
--}}

@props([
    'placeholder' => 'Buscar...',
    'id' => 'search-input-' . uniqid(),
])

<div class="input-group">
    <span class="input-group-text bg-white border-end-0">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-search text-muted" viewBox="0 0 16 16">
            <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001q.044.06.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1 1 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0"/>
        </svg>
    </span>
    <input
        type="text"
        id="{{ $id }}"
        {{ $attributes->merge(['class' => 'form-control border-start-0 ps-0']) }}
        placeholder="{{ $placeholder }}"
    >
</div>
