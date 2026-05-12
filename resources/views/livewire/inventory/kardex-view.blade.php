<div>
    {{-- Header del ítem --}}
    <div class="card mb-3 border-0 shadow-sm">
        <div class="card-body py-3">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h5 class="mb-0 fw-bold">
                        <i class="bi bi-journal-text me-2 text-primary"></i>Kardex — {{ $item?->nombre ?? 'Ítem #'.$itemId }}
                    </h5>
                    <small class="text-muted">{{ $item?->codigo }} · UOM base: <strong>{{ $item?->uom_base ?? '—' }}</strong></small>
                </div>
                <div class="text-end">
                    <div class="fs-4 fw-bold {{ $stockActual >= 0 ? 'text-success' : 'text-danger' }}">
                        {{ number_format($stockActual, 3) }}
                    </div>
                    <small class="text-muted">Stock actual ({{ $item?->uom_base }})</small>
                </div>
            </div>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card mb-3 border-0 shadow-sm">
        <div class="card-body py-2">
            <div class="row g-2 align-items-end">
                <div class="col-md-3">
                    <label class="form-label small mb-1">Tipo de movimiento</label>
                    <select wire:model.live="filterTipo" class="form-select form-select-sm">
                        <option value="">Todos</option>
                        @foreach($tipos as $t)
                            <option value="{{ $t }}">{{ $t }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label small mb-1">Desde</label>
                    <input type="date" wire:model.live="filterFechaDesde" class="form-control form-control-sm">
                </div>
                <div class="col-md-3">
                    <label class="form-label small mb-1">Hasta</label>
                    <input type="date" wire:model.live="filterFechaHasta" class="form-control form-control-sm">
                </div>
                <div class="col-md-3">
                    <button wire:click="$set('filterTipo','');$set('filterFechaDesde','');$set('filterFechaHasta','')"
                            class="btn btn-outline-secondary btn-sm w-100">
                        <i class="bi bi-x-circle me-1"></i>Limpiar
                    </button>
                </div>
            </div>
        </div>
    </div>

    {{-- Tabla de movimientos --}}
    <div class="card border-0 shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-sm table-hover mb-0 align-middle">
                    <thead class="table-light">
                        <tr>
                            <th class="ps-3">Fecha</th>
                            <th>Tipo</th>
                            <th>Referencia</th>
                            <th class="text-end">Cantidad</th>
                            <th>UOM</th>
                            <th class="text-end">Qty Original</th>
                            <th>UOM Orig.</th>
                            <th class="text-end">Saldo Acum.</th>
                            <th>Lote</th>
                        </tr>
                    </thead>
                    <tbody>
                        @php
                            $saldo = $saldoAnterior;
                            $tiposPositivos = ['COMPRA','TRANSFER_IN','PROD_IN'];
                            $tiposNegativos = ['TRANSFER_OUT','PROD_OUT','MERMA'];
                        @endphp

                        @forelse($movimientos as $mov)
                            @php
                                $saldo += $mov->cantidad;
                                $esPositivo = in_array($mov->tipo, $tiposPositivos) || $mov->cantidad > 0;
                                $esNegativo = in_array($mov->tipo, $tiposNegativos) || ($mov->tipo === 'COUNT_ADJ' && $mov->cantidad < 0);
                                $colorTipo = match(true) {
                                    in_array($mov->tipo, $tiposPositivos) => 'text-success',
                                    in_array($mov->tipo, $tiposNegativos) => 'text-danger',
                                    $mov->tipo === 'AJUSTE_POS' => 'text-warning',
                                    $mov->tipo === 'COUNT_ADJ' => $mov->cantidad >= 0 ? 'text-success' : 'text-danger',
                                    default => ''
                                };
                            @endphp
                            <tr>
                                <td class="ps-3 text-muted small">
                                    {{ \Carbon\Carbon::parse($mov->fecha)->format('d/m/y H:i') }}
                                </td>
                                <td>
                                    <span class="badge {{ match(true) {
                                        in_array($mov->tipo, $tiposPositivos) => 'bg-success',
                                        in_array($mov->tipo, $tiposNegativos) => 'bg-danger',
                                        $mov->tipo === 'AJUSTE_POS' => 'bg-warning text-dark',
                                        $mov->tipo === 'COUNT_ADJ' => 'bg-info text-dark',
                                        default => 'bg-secondary'
                                    } }} small">{{ $mov->tipo }}</span>
                                </td>
                                <td class="small text-muted">
                                    @if($mov->ref_tipo && $mov->ref_id)
                                        {{ $mov->ref_tipo }} #{{ $mov->ref_id }}
                                    @else
                                        —
                                    @endif
                                </td>
                                <td class="text-end fw-semibold {{ $colorTipo }}">
                                    {{ $mov->cantidad > 0 ? '+' : '' }}{{ number_format($mov->cantidad, 3) }}
                                </td>
                                <td class="small">{{ $item?->uom_base }}</td>
                                <td class="text-end small text-muted">
                                    {{ $mov->qty_original ? number_format($mov->qty_original, 3) : '—' }}
                                </td>
                                <td class="small text-muted">{{ $mov->uom_original ?? '—' }}</td>
                                <td class="text-end fw-bold {{ $saldo >= 0 ? 'text-dark' : 'text-danger' }}">
                                    {{ number_format($saldo, 3) }}
                                </td>
                                <td class="small text-muted">{{ $mov->lote_codigo ?? '—' }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="9" class="text-center text-muted py-4">
                                    <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                                    Sin movimientos con los filtros actuales
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @if($movimientos->hasPages())
                <div class="px-3 py-2 border-top">
                    {{ $movimientos->links() }}
                </div>
            @endif
        </div>
    </div>
</div>
