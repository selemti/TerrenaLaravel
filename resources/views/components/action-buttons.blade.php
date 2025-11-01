@props([
    'editAction',
    'deleteAction',
    'size' => 'sm',
])

<div {{ $attributes->class(['btn-group', 'btn-group-' . $size]) }}>
    <button
        type="button"
        class="btn btn-outline-primary"
        wire:click="{{ $editAction }}"
    >
        <i class="bi bi-pencil-square"></i>
        <span class="d-none d-lg-inline ms-1">Editar</span>
    </button>
    <button
        type="button"
        class="btn btn-outline-danger"
        wire:click="{{ $deleteAction }}"
        onclick="return confirm('¿Desea eliminar este registro?')"
    >
        <i class="bi bi-trash"></i>
        <span class="d-none d-lg-inline ms-1">Eliminar</span>
    </button>
</div>
