<div class="container-fluid py-3">
    <div class="d-flex align-items-start justify-content-between gap-3 flex-wrap mb-3">
        <div>
            <div class="text-muted small">Inventario / Kardex</div>
            <h1 class="h4 mb-1">{{ $kardex['item']['nombre'] ?? 'Item '.$itemId }}</h1>
            <div class="text-muted">
                {{ $kardex['item']['code'] ?? $itemId }}
                <span class="mx-2">|</span>
                UOM base: <strong>{{ $kardex['item']['uom_base'] ?? '-' }}</strong>
            </div>
        </div>

        <div class="text-end">
            <div class="text-muted small">Stock actual total</div>
            <div class="display-6 fs-3 fw-semibold">{{ number_format($stockActual, 3) }}</div>
            <div class="text-muted small">{{ $kardex['item']['uom_base'] ?? '' }}</div>
        </div>
    </div>

    <div class="card border-0 shadow-sm mb-3">
        <div class="card-body">
            <div class="row g-3 align-items-end">
                <div class="col-12 col-md-3">
                    <label for="filterFechaDesde" class="form-label">Desde</label>
                    <input
                        id="filterFechaDesde"
                        type="date"
                        class="form-control"
                        wire:model.live="filterFechaDesde"
                    >
                </div>

                <div class="col-12 col-md-3">
                    <label for="filterFechaHasta" class="form-label">Hasta</label>
                    <input
                        id="filterFechaHasta"
                        type="date"
                        class="form-control"
                        wire:model.live="filterFechaHasta"
                    >
                </div>

                <div class="col-12 col-md-4">
                    <label for="filterAlmacen" class="form-label">Almacen</label>
                    <select id="filterAlmacen" class="form-select" wire:model.live="filterAlmacen">
                        <option value="">Todos los almacenes</option>
                        @foreach($almacenes as $almacen)
                            <option value="{{ $almacen->id }}">
                                {{ $almacen->clave ? $almacen->clave.' - ' : '' }}{{ $almacen->nombre }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="col-12 col-md-2">
                    <button type="button" class="btn btn-outline-secondary w-100" wire:click="limpiarFiltros">
                        Limpiar
                    </button>
                </div>
            </div>
        </div>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="table-responsive">
            <table class="table table-sm table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th class="ps-3">Fecha/hora</th>
                        <th>Tipo</th>
                        <th class="text-end">Cantidad (+/-)</th>
                        <th class="text-end">Saldo acumulado</th>
                        <th>Referencia</th>
                        <th>Almacen</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($movements as $mov)
                        @php
                            $isPositive = ($mov['signo'] ?? 0) > 0;
                            $signedQty = ($isPositive ? 1 : -1) * (float) ($mov['qty_base'] ?? 0);
                        @endphp
                        <tr>
                            <td class="ps-3 text-nowrap">
                                {{ \Carbon\Carbon::parse($mov['ts'])->format('Y-m-d H:i') }}
                            </td>
                            <td>
                                <div class="fw-semibold">{{ $mov['tipo'] }}</div>
                                <div class="small text-muted">{{ $mov['tipo_label'] ?? '' }}</div>
                            </td>
                            <td class="text-end fw-semibold {{ $isPositive ? 'text-success' : 'text-danger' }}">
                                {{ $signedQty >= 0 ? '+' : '-' }}{{ number_format(abs($signedQty), 3) }}
                            </td>
                            <td class="text-end fw-semibold">
                                {{ number_format((float) ($mov['saldo'] ?? 0), 3) }}
                            </td>
                            <td>
                                @if(! empty($mov['ref_tipo']) || ! empty($mov['ref_id']))
                                    {{ $mov['ref_tipo'] ?? '-' }}{{ ! empty($mov['ref_id']) ? ' #'.$mov['ref_id'] : '' }}
                                @else
                                    <span class="text-muted">-</span>
                                @endif
                            </td>
                            <td>
                                @if(! empty($mov['almacen']))
                                    <div>{{ $mov['almacen']['nombre'] ?? '-' }}</div>
                                    <div class="small text-muted">{{ $mov['almacen']['clave'] ?? $mov['almacen']['id'] ?? '' }}</div>
                                @else
                                    <span class="text-muted">-</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center text-muted py-4">
                                Sin movimientos para el rango seleccionado.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="card-footer bg-white d-flex align-items-center justify-content-between gap-2 flex-wrap">
            <div class="text-muted small">
                Pagina {{ $kardex['pagination']['page'] }} de {{ $kardex['pagination']['last_page'] }}
                <span class="mx-1">|</span>
                {{ $kardex['pagination']['total'] }} movimientos
                <span class="mx-1">|</span>
                50 filas por pagina
            </div>
            <div class="btn-group">
                <button
                    type="button"
                    class="btn btn-outline-secondary btn-sm"
                    wire:click="prevPage"
                    @disabled($kardex['pagination']['page'] <= 1)
                >
                    Anterior
                </button>
                <button
                    type="button"
                    class="btn btn-outline-secondary btn-sm"
                    wire:click="nextPage({{ $kardex['pagination']['last_page'] }})"
                    @disabled($kardex['pagination']['page'] >= $kardex['pagination']['last_page'])
                >
                    Siguiente
                </button>
            </div>
        </div>
    </div>
</div>
