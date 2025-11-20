<div class="container py-3 space-y-3">
  <div class="d-flex justify-content-between align-items-center">
    <div>
      <h1 class="h4 mb-0">Recibir transferencia #{{ $transferId }}</h1>
      <div class="text-muted small">
        <span class="badge {{ $estado === 'EN_TRANSITO' ? 'text-bg-info' : 'text-bg-secondary' }}">{{ $estado ?: '—' }}</span>
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
      <div class="table-responsive mb-3">
        <table class="table align-middle mb-0">
          <thead class="table-light">
            <tr class="text-muted small">
              <th>Item</th>
              <th>Despachado</th>
              <th>Recibido</th>
              <th>UOM</th>
            </tr>
          </thead>
          <tbody>
            @forelse($lines as $i => $line)
              <tr>
                <td>
                  <div class="fw-semibold">{{ $line['item_nombre'] ?? $line['item_id'] }}</div>
                  <div class="text-muted small">ID {{ $line['item_id'] }}</div>
                </td>
                <td>{{ $line['cantidad_despachada'] ?? '—' }}</td>
                <td style="width: 180px;">
                  <input type="number" step="0.0001" class="form-control form-control-sm"
                         wire:model="lines.{{ $i }}.cantidad_recibida">
                </td>
                <td>{{ $line['unidad_medida'] ?? '—' }}</td>
              </tr>
            @empty
              <tr>
                <td colspan="4" class="text-center text-muted py-3">Sin líneas cargadas.</td>
              </tr>
            @endforelse
          </tbody>
        </table>
      </div>

      <div class="mb-3">
        <label class="form-label">Observaciones</label>
        <textarea class="form-control" rows="2" wire:model.defer="observaciones" placeholder="Notas opcionales"></textarea>
      </div>

      <button type="button" class="btn btn-success" wire:click="receive">
        <i class="fa-solid fa-boxes-packing me-1"></i>Confirmar recepción
      </button>
    </div>
  </div>

  @if(!empty($varianzas))
    <div class="card border-warning-subtle">
      <div class="card-header bg-warning-subtle fw-semibold">
        Varianzas detectadas
      </div>
      <div class="card-body">
        <ul class="mb-0">
          @foreach($varianzas as $var)
            <li class="text-warning">
              Línea #{{ $var['line_id'] }} · Item {{ $var['item_id'] ?? '' }} · Varianza {{ $var['varianza'] ?? 0 }}
              ({{ number_format($var['varianza_porcentaje'] ?? 0, 2) }}%)
            </li>
          @endforeach
        </ul>
      </div>
    </div>
  @endif
</div>
