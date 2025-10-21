<div>
  <div class="container py-3">
    <div class="d-flex align-items-center justify-content-between mb-3">
      <h1 class="h4 mb-0">
        <i class="fa-solid fa-bowl-food me-2"></i> Recetas
      </h1>
      <div class="d-flex gap-2 flex-wrap">
        <div class="d-flex gap-2">
          <input type="text"
                 class="form-control form-control-sm"
                 placeholder="Buscar receta (PLU, nombre...)"
                 wire:model.live.debounce.400ms="search">
          <select class="form-select form-select-sm"
                  wire:model.live="category"
                  style="min-width: 160px;">
            <option value="">Todas las categorías</option>
            @foreach($categories as $cat)
              <option value="{{ $cat['value'] }}">{{ $cat['label'] }}</option>
            @endforeach
          </select>
        </div>
        <a class="btn btn-success btn-sm" href="{{ route('rec.editor') }}">
          <i class="fa-solid fa-plus me-1"></i> Nueva
        </a>
      </div>
    </div>

    @if(session('ok'))
      <div class="alert alert-success py-1 small">{{ session('ok') }}</div>
    @endif

    <div class="card shadow-sm">
      <div class="table-responsive">
        <table class="table table-sm align-middle mb-0">
          <thead class="table-light">
            <tr>
              <th style="width:180px">Receta</th>
              <th>PLU</th>
              <th style="width:140px">Versión</th>
              <th style="width:150px" class="text-end">Costo estándar</th>
              <th style="width:150px" class="text-end">Precio sugerido</th>
              <th style="width:160px" class="text-end">Acciones</th>
            </tr>
          </thead>
          <tbody>
            @forelse($recipes as $r)
              @php
                $published = $r->publishedVersion;
                $latest = $r->latestVersion;
              @endphp
              <tr>
                <td>
                  <div class="fw-semibold">{{ $r->nombre_plato }}</div>
                  <div class="text-muted small">{{ $r->id }}{{ $r->categoria_plato ? ' · '.$r->categoria_plato : '' }}</div>
                </td>
                <td class="font-monospace">{{ $r->codigo_plato_pos ?? '—' }}</td>
                <td>
                  @if($published)
                    <span class="badge bg-success-subtle text-success">Publicado v{{ $published->version }}</span>
                  @elseif($latest)
                    <span class="badge bg-secondary-subtle text-secondary">Borrador v{{ $latest->version }}</span>
                  @else
                    <span class="badge bg-warning-subtle text-warning">Sin versión</span>
                  @endif
                </td>
                <td class="text-end">MX$ {{ number_format((float)($r->costo_standard_porcion ?? 0), 2) }}</td>
                <td class="text-end">MX$ {{ number_format((float)($r->precio_venta_sugerido ?? 0), 2) }}</td>
                <td class="text-end">
                  <div class="btn-group btn-group-sm">
                    <a class="btn btn-outline-secondary" href="{{ route('rec.editor', ['id' => $r->id]) }}">
                      <i class="fa-regular fa-pen-to-square"></i> Editar
                    </a>
                    <button class="btn btn-outline-danger"
                            wire:click="confirmDelete('{{ $r->id }}')">
                      <i class="fa-regular fa-trash-can"></i>
                    </button>
                  </div>
                </td>
              </tr>
            @empty
              <tr>
                <td colspan="6" class="text-muted py-4 text-center">Sin resultados.</td>
              </tr>
            @endforelse
          </tbody>
        </table>
      </div>
      <div class="card-footer py-2">
        {{ $recipes->links() }}
      </div>
    </div>
  </div>

  <div class="modal fade @if($confirmingDelete) show d-block @endif"
       tabindex="-1" role="dialog" @if($confirmingDelete) style="background: rgba(0,0,0,.3)" @endif>
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Confirmar</h5>
          <button type="button" class="btn-close" aria-label="Cerrar" wire:click="cancelDelete"></button>
        </div>
        <div class="modal-body">
          ¿Eliminar la receta seleccionada?
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" wire:click="cancelDelete">Cancelar</button>
          <button class="btn btn-danger" wire:click="delete">Eliminar</button>
        </div>
      </div>
    </div>
  </div>
</div>
