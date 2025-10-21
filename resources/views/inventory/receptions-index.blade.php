<div class="dashboard-grid py-3">
  @if($flashMessage)
    <div class="alert alert-success alert-dismissible fade show" role="alert">
      <i class="fa-solid fa-circle-check me-2"></i>{{ $flashMessage }}
      <button type="button" class="btn-close" aria-label="Cerrar" wire:click="$set('flashMessage', null)"></button>
    </div>
  @endif

  <div class="d-flex justify-content-between align-items-center mb-3">
    <div>
      <p class="text-muted mb-0">Listado de recepciones recientes (50 registros)</p>
    </div>
    <button type="button" class="btn btn-primary" wire:click="openCreateModal">
      <i class="fa-solid fa-plus me-1"></i>Nueva recepción
    </button>
  </div>

  <div class="card shadow-sm border-0">
    <div class="table-responsive">
      <table class="table table-striped table-sm align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th>ID</th>
            <th>Proveedor</th>
            <th>Sucursal</th>
            <th>Almacén</th>
            <th>Fecha</th>
          </tr>
        </thead>
        <tbody>
          @forelse($rows as $row)
            <tr>
              <td class="fw-semibold">{{ $row->id }}</td>
              <td>{{ $row->proveedor_nombre ?: $row->proveedor_id }}</td>
              <td>{{ $row->sucursal_nombre ?? '—' }}</td>
              <td>{{ $row->almacen_nombre ?? '—' }}</td>
              <td>{{ \Carbon\Carbon::parse($row->ts)->format('d/m/Y H:i') }}</td>
            </tr>
          @empty
            <tr>
              <td colspan="5" class="text-center text-muted py-4">Sin recepciones registradas.</td>
            </tr>
          @endforelse
        </tbody>
      </table>
    </div>
  </div>

  <div class="modal fade @if($showCreateModal) show @endif" tabindex="-1"
       style="{{ $showCreateModal ? 'display:block;' : '' }}" @if($showCreateModal) aria-modal="true" role="dialog" @endif
       @unless($showCreateModal) aria-hidden="true" @endunless
       id="reception-create-modal">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title"><i class="fa-solid fa-dolly me-2"></i>Nueva recepción</h5>
          <button type="button" class="btn-close" aria-label="Cerrar" wire:click="closeCreateModal"></button>
        </div>
        <div class="modal-body">
          @livewire('inventory.reception-create', ['asModal' => true], key('reception-create-modal'))
        </div>
      </div>
    </div>
  </div>

  @if($showCreateModal)
    <div class="modal-backdrop fade show"></div>
  @endif
</div>
