<div class="container py-3 space-y-3">
  <div class="d-flex justify-content-between align-items-center">
    <div>
      <h1 class="h4 mb-0">Despachar transferencia #{{ $transferId }}</h1>
      <div class="text-muted small">
        <span class="badge {{ $estado === 'APROBADA' ? 'text-bg-info' : 'text-bg-secondary' }}">{{ $estado ?: '—' }}</span>
      </div>
    </div>
    <a href="{{ route('transfers.index') }}" class="btn btn-outline-secondary btn-sm">
      <i class="fa-solid fa-arrow-left me-1"></i>Volver
    </a>
  </div>

  @if($flashMessage)
    <div class="alert alert-success py-2">
      <i class="fa-solid fa-circle-check me-1"></i>{{ $flashMessage }}
    </div>
  @endif

  @if($errorMessage)
    <div class="alert alert-danger py-2">
      <i class="fa-solid fa-triangle-exclamation me-1"></i>{{ $errorMessage }}
    </div>
  @endif

  <div class="card shadow-sm border-0">
    <div class="card-body">
      <div class="mb-3">
        <label class="form-label">Número de guía / referencia</label>
        <input type="text" class="form-control" placeholder="Opcional" wire:model.defer="numeroGuia">
      </div>

      <div class="table-responsive mb-3">
        <table class="table align-middle mb-0">
          <thead class="table-light">
            <tr class="text-muted small">
              <th>Item</th>
              <th>Cantidad</th>
              <th>UOM</th>
            </tr>
          </thead>
          <tbody>
            @forelse($lines as $line)
              <tr>
                <td>
                  <div class="fw-semibold">{{ $line['item_nombre'] ?? $line['item_id'] }}</div>
                  <div class="text-muted small">ID {{ $line['item_id'] }}</div>
                </td>
                <td>{{ $line['cantidad_solicitada'] ?? '—' }}</td>
                <td>{{ $line['unidad_medida'] ?? '—' }}</td>
              </tr>
            @empty
              <tr>
                <td colspan="3" class="text-center text-muted py-3">Sin líneas cargadas.</td>
              </tr>
            @endforelse
          </tbody>
        </table>
      </div>

      <button type="button" class="btn btn-primary" wire:click="markInTransit">
        <i class="fa-solid fa-truck-arrow-right me-1"></i>Marcar en tránsito
      </button>
    </div>
  </div>
</div>
