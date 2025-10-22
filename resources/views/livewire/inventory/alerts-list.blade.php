<div class="py-3">
  <div class="d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-2 mb-3">
    <div>
      <h2 class="h4 mb-0">Alertas de costo</h2>
      <div class="text-muted small">Monitoreo de variaciones en recetas y materias primas.</div>
    </div>
    <div class="text-muted small">
      <i class="fa-regular fa-bell me-1"></i>{{ $alerts->total() }} registros
    </div>
  </div>

  <div class="card shadow-sm mb-3">
    <div class="card-body">
      <div class="row g-3 align-items-end">
        <div class="col-md-3">
          <label class="form-label">Estado</label>
          <select class="form-select" wire:model="handled">
            <option value="pending">Pendientes</option>
            <option value="handled">Atendidas</option>
            <option value="all">Todas</option>
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label">Receta</label>
          <input type="text" class="form-control" placeholder="ID receta" wire:model.lazy="recipeId">
        </div>
        <div class="col-md-3">
          <label class="form-label">Desde</label>
          <input type="date" class="form-control" wire:model="dateFrom">
        </div>
        <div class="col-md-3">
          <label class="form-label">Hasta</label>
          <input type="date" class="form-control" wire:model="dateTo">
        </div>
      </div>
    </div>
  </div>

  <div class="card shadow-sm">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0">
        <thead class="table-light">
          <tr>
            <th>ID</th>
            <th>Receta</th>
            <th>Snapshot</th>
            <th class="text-end">Costo anterior</th>
            <th class="text-end">Costo nuevo</th>
            <th class="text-end">Δ %</th>
            <th>Estado</th>
            @if($canManage)
              <th class="text-end">Acciones</th>
            @endif
          </tr>
        </thead>
        <tbody>
        @forelse($alerts as $alert)
          <tr>
            <td class="text-muted">#{{ $alert->id }}</td>
            <td>
              <div class="fw-semibold">{{ $alert->recipe_name ?? 'Receta #' . $alert->recipe_id }}</div>
              <div class="small text-muted">{{ $alert->recipe_code ?? '' }}</div>
            </td>
            <td>
              <div>{{ \Carbon\Carbon::parse($alert->snapshot_at)->format('Y-m-d H:i') }}</div>
              <div class="small text-muted">Generada: {{ \Carbon\Carbon::parse($alert->created_at)->diffForHumans() }}</div>
            </td>
            <td class="text-end">$ {{ number_format((float) $alert->old_portion_cost, 4) }}</td>
            <td class="text-end">$ {{ number_format((float) $alert->new_portion_cost, 4) }}</td>
            <td class="text-end">
              @php
                $delta = (float) ($alert->delta_pct ?? 0);
              @endphp
              <span class="badge {{ $delta >= 0 ? 'text-bg-danger' : 'text-bg-success' }}">
                {{ number_format($delta, 2) }}%
              </span>
            </td>
            <td>
              @if($alert->handled)
                <span class="badge text-bg-success">Atendida</span>
              @else
                <span class="badge text-bg-warning text-dark">Pendiente</span>
              @endif
            </td>
            @if($canManage)
              <td class="text-end">
                @if(!$alert->handled)
                  <button class="btn btn-sm btn-outline-success" wire:click="acknowledge({{ $alert->id }})">
                    <i class="fa-solid fa-check"></i> Marcar atendida
                  </button>
                @else
                  <span class="text-muted small">—</span>
                @endif
              </td>
            @endif
          </tr>
          @empty
            <tr>
              <td colspan="{{ $canManage ? 8 : 7 }}" class="text-center text-muted py-4">
                Sin alertas registradas en el rango seleccionado.
              </td>
            </tr>
        @endforelse
        </tbody>
      </table>
    </div>
    <div class="card-footer">
      {{ $alerts->links() }}
    </div>
  </div>
</div>
