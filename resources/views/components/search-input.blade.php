@props([
    'placeholder' => 'Buscar...',
    'model' => 'search',
    'value' => null,
    'size' => null,
])

@php
    $inputClasses = trim('form-control ' . ($size === 'sm' ? 'form-control-sm' : ''));
@endphp

<div class="input-group {{ $size === 'sm' ? 'input-group-sm' : '' }}">
    <span class="input-group-text bg-white">
        <i class="bi bi-search"></i>
    </span>
    <input
        type="search"
        {{ $attributes->merge(['class' => $inputClasses]) }}
        placeholder="{{ $placeholder }}"
        wire:model.live.debounce.300ms="{{ $model }}"
    >
    @if(!is_null($value) && strlen((string) $value) > 0)
        <button
            class="btn btn-outline-secondary"
            type="button"
            wire:click="$set('{{ $model }}', '')"
        >
            <i class="bi bi-x-lg"></i>
        </button>
    @endif
</div>
