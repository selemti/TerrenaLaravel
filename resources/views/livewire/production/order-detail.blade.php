<div>
    {{-- Header --}}
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h3 class="mb-1">
                Orden <strong>{{ $orden->folio }}</strong>
                @php
                    $badgeMap = [
                        'BORRADOR'   => 'secondary',
                        'EN_PROCESO' => 'warning',
                        'COMPLETADA' => 'info',
                        'POSTEADA'   => 'success',
                        'CANCELADA'  => 'danger',
                    ];
                    $badge = $badgeMap[$orden->estado] ?? 'secondary';
                @endphp
                <span class="badge bg-{{ $badge }}">{{ $orden->estado }}</span>
            </h3>
        </div>
        <a href="{{ route('production.index') }}" class="btn btn-outline-secondary">
            <i class="bi bi-arrow-left"></i> Volver
        </a>
    </div>

    {{-- Flash messages --}}
    @if (session()->has('success'))
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            {{ session('success') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    @endif
    @if (session()->has('error'))
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            {{ session('error') }}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    @endif

    {{-- Info card --}}
    <div class="card shadow-sm mb-4">
        <div class="card-header"><i class="bi bi-info-circle"></i> Detalle de la Orden</div>
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-4">
                    <small class="text-muted d-block">Receta</small>
                    <strong>{{ $orden->receta_nombre }}</strong>
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">Producto</small>
                    <strong>{{ $orden->item_nombre }}</strong>
                    <span class="text-muted">({{ $orden->item_codigo }})</span>
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">UOM Base</small>
                    <strong>{{ $orden->uom_base }}</strong>
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">Qty Programada</small>
                    <strong>{{ $orden->qty_programada }}</strong>
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">Qty Producida</small>
                    <strong>{{ $orden->qty_producida ?? '—' }}</strong>
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">Qty Merma</small>
                    <strong>{{ $orden->qty_merma ?? '—' }}</strong>
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">Programado para</small>
                    {{ $orden->programado_para ? \Carbon\Carbon::parse($orden->programado_para)->format('d/m/Y') : '—' }}
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">Iniciado en</small>
                    {{ $orden->iniciado_en ? \Carbon\Carbon::parse($orden->iniciado_en)->format('d/m/Y H:i') : '—' }}
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">Cerrado en</small>
                    {{ $orden->cerrado_en ? \Carbon\Carbon::parse($orden->cerrado_en)->format('d/m/Y H:i') : '—' }}
                </div>
                <div class="col-md-4">
                    <small class="text-muted d-block">Creado</small>
                    {{ \Carbon\Carbon::parse($orden->created_at)->format('d/m/Y H:i') }}
                </div>
                @if ($orden->notas)
                    <div class="col-12">
                        <small class="text-muted d-block">Notas</small>
                        {{ $orden->notas }}
                    </div>
                @endif
            </div>
        </div>
    </div>

    {{-- Action buttons --}}
    @if ($orden->estado === 'BORRADOR')
        <div class="d-flex gap-2 mb-4">
            <button wire:click="iniciar" class="btn btn-warning">
                <i class="bi bi-play-fill"></i> Iniciar Producción
            </button>
            <button wire:click="cancelar" wire:confirm="¿Estás seguro?" class="btn btn-outline-danger">
                <i class="bi bi-x-circle"></i> Cancelar
            </button>
        </div>
    @elseif ($orden->estado === 'EN_PROCESO')
        <div class="mb-4">
            <a href="{{ route('production.capture', $orden->id) }}" class="btn btn-warning">
                <i class="bi bi-pencil-square"></i> Capturar Producción
            </a>
        </div>
    @endif

    {{-- Insumos --}}
    @if ($inputs->count())
        <div class="card shadow-sm mb-4">
            <div class="card-header"><i class="bi bi-box-arrow-in-down"></i> Insumos</div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Producto</th>
                            <th>Código</th>
                            <th class="text-end">Cantidad</th>
                            <th>UOM</th>
                            <th>Lote Origen</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($inputs as $input)
                            <tr>
                                <td>{{ $input->item_nombre }}</td>
                                <td>{{ $input->item_codigo }}</td>
                                <td class="text-end">{{ $input->qty }}</td>
                                <td>{{ $input->uom }}</td>
                                <td>{{ $input->lote_origen ?? '—' }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    @endif

    {{-- Salidas --}}
    @if ($outputs->count())
        <div class="card shadow-sm mb-4">
            <div class="card-header"><i class="bi bi-box-arrow-up"></i> Salidas</div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Producto</th>
                            <th>Lote Producido</th>
                            <th>Fecha Caducidad</th>
                            <th class="text-end">Cantidad</th>
                            <th>UOM</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($outputs as $output)
                            <tr>
                                <td>{{ $output->item_nombre }}</td>
                                <td>{{ $output->lote_producido ?? '—' }}</td>
                                <td>{{ $output->fecha_caducidad ? \Carbon\Carbon::parse($output->fecha_caducidad)->format('d/m/Y') : '—' }}</td>
                                <td class="text-end">{{ $output->qty }}</td>
                                <td>{{ $output->uom }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    @endif

    {{-- Movimientos --}}
    @if ($movimientos->count())
        <div class="card shadow-sm mb-4">
            <div class="card-header"><i class="bi bi-arrow-left-right"></i> Movimientos Inventario</div>
            <div class="card-body p-0">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Producto</th>
                            <th>Tipo</th>
                            <th class="text-end">Cantidad</th>
                            <th>Fecha</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($movimientos as $mov)
                            <tr>
                                <td>{{ $mov->item_nombre }}</td>
                                <td>{{ $mov->tipo }}</td>
                                <td class="text-end">{{ $mov->cantidad }}</td>
                                <td>{{ \Carbon\Carbon::parse($mov->ts)->format('d/m/Y H:i') }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    @endif
</div>
