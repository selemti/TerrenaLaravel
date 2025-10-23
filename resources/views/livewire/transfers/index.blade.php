<div class="py-3">
    {{-- Header --}}
    <div class="d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-2 mb-3">
        <div class="d-flex gap-2 w-100 w-lg-50">
            <div class="flex-grow-1">
                <input type="text" class="form-control" placeholder="Buscar por número, almacenes..."
                       wire:model.live.debounce.400ms="search">
            </div>
            <a href="{{ route('transfers.create') }}" class="btn btn-primary">
                <i class="fa-solid fa-plus me-1"></i>Nueva transferencia
            </a>
        </div>
        <div class="text-muted small">
            <i class="fa-regular fa-circle-info me-1"></i>
            <span>{{ count($transfers) }} transferencia(s)</span>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card shadow-sm mb-3">
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-3">
                    <label class="form-label">Estado</label>
                    <select class="form-select" wire:model.live="estadoFilter">
                        <option value="all">Todos</option>
                        <option value="borrador">Borrador</option>
                        <option value="despachada">Despachada</option>
                        <option value="recibida">Recibida</option>
                        <option value="parcial">Parcial</option>
                    </select>
                </div>
            </div>
        </div>
    </div>

    {{-- Tabla --}}
    <div class="card shadow-sm">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Número</th>
                        <th>Origen</th>
                        <th>Destino</th>
                        <th>Fecha</th>
                        <th>Estado</th>
                        <th>Ítems</th>
                        <th>Creado por</th>
                        <th class="text-end">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($transfers as $trans)
                        <tr>
                            <td class="font-monospace fw-semibold">{{ $trans['numero'] }}</td>
                            <td>{{ $trans['almacen_origen'] }}</td>
                            <td>{{ $trans['almacen_destino'] }}</td>
                            <td>{{ \Carbon\Carbon::parse($trans['fecha_solicitada'])->format('d/m/Y') }}</td>
                            <td>
                                @if($trans['estado'] === 'BORRADOR')
                                    <span class="badge text-bg-secondary">Borrador</span>
                                @elseif($trans['estado'] === 'DESPACHADA')
                                    <span class="badge text-bg-info">Despachada</span>
                                @elseif($trans['estado'] === 'RECIBIDA')
                                    <span class="badge text-bg-success">Recibida</span>
                                @else
                                    <span class="badge text-bg-warning">Parcial</span>
                                @endif
                            </td>
                            <td>{{ $trans['lineas_count'] }}</td>
                            <td class="small">{{ $trans['creado_por'] }}</td>
                            <td class="text-end">
                                <button class="btn btn-sm btn-outline-primary" disabled>
                                    <i class="fa-solid fa-eye"></i> Ver
                                </button>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="text-center text-muted py-4">
                                No hay transferencias. Usa "Nueva transferencia".
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
