<div class="page py-3">
  <div class="card-vo mb-3">
    <h5 class="card-title mb-3"><i class="fa-solid fa-layer-group"></i> Últimos lotes registrados</h5>
    <div class="table-responsive">
      <table class="table table-sm align-middle mb-0">
        <thead class="table-light">
        <tr>
          <th>ID</th>
          <th>Item</th>
          <th>Lote proveedor</th>
          <th>Caducidad</th>
          <th>Estado</th>
          <th class="text-end">Stock actual</th>
        </tr>
        </thead>
        <tbody>
        @forelse($lots as $l)
          @php
            $caduca = $l->fecha_caducidad ? \Illuminate\Support\Carbon::parse($l->fecha_caducidad) : null;
            $expired = $caduca && $caduca->isPast();
          @endphp
          <tr class="{{ $expired ? 'table-danger' : '' }}">
            <td>{{ $l->id }}</td>
            <td>
              <div class="fw-semibold">{{ $l->item_nombre ?: $l->item_id }}</div>
              <small class="text-muted">{{ $l->item_id }}</small>
            </td>
            <td>{{ $l->lote }}</td>
            <td>{{ $caduca ? $caduca->format('Y-m-d') : '—' }}</td>
            <td>
              <span class="badge {{ $l->estado === 'ACTIVO' ? 'text-bg-success' : 'text-bg-warning' }}">{{ $l->estado }}</span>
            </td>
            <td class="text-end">{{ number_format((float) $l->stock, 3) }}</td>
          </tr>
        @empty
          <tr><td colspan="6" class="text-center text-muted py-4">Sin información disponible.</td></tr>
        @endforelse
        </tbody>
      </table>
    </div>
    <p class="text-muted small mt-3 mb-0">Se muestran hasta 100 lotes ordenados por caducidad.</p>
</div>
</div>
