@props([
    'icon' => 'inbox',
    'title' => 'No hay registros',
    'description' => 'No se encontraron resultados',
    'actionLabel' => null,
    'actionClick' => null,
])

<div class="text-center py-5">
    <i class="bi bi-{{ $icon }} text-muted" style="font-size: 3.5rem;"></i>
    <h5 class="mt-3 text-muted">{{ $title }}</h5>
    <p class="text-muted">{{ $description }}</p>

    @if($actionLabel && $actionClick)
        <button
            type="button"
            class="btn btn-primary mt-2"
            wire:click="{{ $actionClick }}"
        >
            <i class="bi bi-plus-circle me-2"></i>
            {{ $actionLabel }}
        </button>
    @endif
</div>
