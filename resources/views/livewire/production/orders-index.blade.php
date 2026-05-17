<div>
    {{-- Encabezado --}}
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h5 class="mb-0 fw-bold"><i class="bi bi-gear-wide-connected me-2 text-primary"></i>Órdenes de Producción</h5>
        </div>
        <a href="{{ route('production.create') }}" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-circle me-1"></i>Nueva Orden
        </a>
    </div>

    {{-- Resumen de estados --}}
    <div class="row g-2 mb-3">
        @foreach(['BORRADOR' => 'secondary', 'EN_PROCESO' => 'warning', 'COMPLETADO' => 'info', 'POSTEADO' => 'success'] as $estado => $color)
        <div class="col-6 col-md-3">
            <div class="card border-0 shadow-sm text-center py-2">
                <div class="fs-4 fw-bold text-{{ $color }}">{{ $resumen[$estado] ?? 0 }}</div>
                <small class="text-muted">{{ $estado }}</small>
            </div>
        </div>
        @endforeach
    </div>

    {{-- Filtros --}}
    <div class="card mb-3 border-0 shadow-sm">
        <div class="card-body py-2">
            <div class="row g-2 align-items-end">
                <div class="col-md-3">
                    <input type="text" wire:model.live.debounce.400ms="search" placeholder="Buscar folio, receta, ítem…"
                           class="form-control form-control-sm">
                </div>
                <div class="col-md-2">
                    <select wire:model.live="filterEstado" class="form-select form-select-sm">
                        <option value="">Todos los estados</option>
                        @foreach($estados as $e)
                            <option value="{{ $e }}">{{ $e }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-2">
                    <input type="date" wire:model.live="filterFechaDesde" class="form-control form-control-sm">
                </div>
                <div class="col-md-2">
                    <input type="date" wire:model.live="filterFechaHasta" class="form-control form-control-sm">
                </div>
                <div class="col-md-3">
                    <button wire:click="limpiarFiltros" class="btn btn-outline-secondary btn-sm w-100">
                        <i class="bi bi-x-circle me-1"></i>Limpiar
                    </button>
                </div>
            </div>
        </div>
    </div>

    {{-- Tabla --}}
    <div class="card border-0 shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-sm table-hover mb-0 align-middle">
                    <thead class="table-light">
                        <tr>
                            <th class="ps-3">Folio</th>
                            <th>Receta / Ítem</th>
                            <th class="text-end">Programado</th>
                            <th class="text-end">Producido</th>
                            <th>UOM</th>
                            <th>Estado</th>
                            <th>Fecha</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($ordenes as $o)
                        <tr>
                            <td class="ps-3 fw-semibold">{{ $o->folio ?? '#'.$o->id }}</td>
                            <td>
                                <div class="small fw-semibold">{{ $o->receta_nombre ?? '—' }}</div>
                                <div class="text-muted" style="font-size:0.75rem">{{ $o->item_nombre ?? '—' }}</div>
                            </td>
                            <td class="text-end">{{ number_format($o->qty_programada, 3) }}</td>
                            <td class="text-end {{ $o->qty_producida > 0 ? 'text-success' : 'text-muted' }}">
                                {{ number_format($o->qty_producida, 3) }}
                            </td>
                            <td class="small">{{ $o->uom_base }}</td>
                            <td>
                                <span class="badge {{ match($o->estado) {
                                    'BORRADOR'   => 'bg-secondary',
                                    'EN_PROCESO' => 'bg-warning text-dark',
                                    'COMPLETADO' => 'bg-info text-dark',
                                    'POSTEADO'   => 'bg-success',
                                    'CANCELADO'  => 'bg-danger',
                                    default      => 'bg-light text-dark'
                                } }}">{{ $o->estado }}</span>
                            </td>
                            <td class="small text-muted">{{ \Carbon\Carbon::parse($o->created_at)->format('d/m/y') }}</td>
                            <td class="text-end pe-3">
                                <a href="{{ route('production.show', $o->id) }}" class="btn btn-outline-primary btn-sm py-0 px-2">
                                    <i class="bi bi-eye"></i>
                                </a>
                                @if($o->estado === 'EN_PROCESO')
                                <a href="{{ route('production.capture', $o->id) }}" class="btn btn-outline-warning btn-sm py-0 px-2 ms-1">
                                    <i class="bi bi-pencil-square"></i>
                                </a>
                                @endif
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="8" class="text-center text-muted py-4">
                                <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                                Sin órdenes de producción
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
            @if($ordenes->hasPages())
            <div class="px-3 py-2 border-top">
                {{ $ordenes->links() }}
            </div>
            @endif
        </div>
    </div>
</div>
