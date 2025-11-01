<div>
    <div class="container-fluid py-4">
        <div class="row mb-3 g-3 align-items-center">
            <div class="col">
                <h2 class="h4 mb-0">
                    <i class="fa-solid fa-circle-info me-2 text-primary"></i>
                    Orden de producción #{{ $order->folio ?? $order->id }}
                </h2>
                <p class="text-muted small mb-0">
                    Estado actual: <x-transfer-status-badge :status="$order->estado" /> · Creada {{ optional($order->created_at)->format('d/m/Y H:i') ?? 'N/D' }}
                </p>
            </div>
            <div class="col-auto">
                <a href="{{ route('production.index') }}" class="btn btn-outline-secondary">
                    <i class="fa-solid fa-arrow-left me-2"></i>
                    Volver al listado
                </a>
                <a href="{{ route('production.execute', $order->id) }}" class="btn btn-primary ms-2">
                    <i class="fa-solid fa-gears me-2"></i>
                    Ejecutar orden
                </a>
            </div>
        </div>

        <div class="row g-3">
            <div class="col-lg-4">
                <div class="card shadow-sm border-0 h-100">
                    <div class="card-body">
                        <h5 class="fw-semibold mb-3">Datos generales</h5>
                        <dl class="row mb-0 small">
                            <dt class="col-5">Receta</dt>
                            <dd class="col-7">{{ $order->recipe?->nombre ?? $order->item?->nombre ?? 'N/A' }}</dd>
                            <dt class="col-5">Versión</dt>
                            <dd class="col-7">{{ $order->recipeVersion?->version ?? 'No asignada' }}</dd>
                            <dt class="col-5">Cantidad planeada</dt>
                            <dd class="col-7">{{ number_format($order->qty_programada, 2) }} {{ $order->uom_base ?? 'PZ' }}</dd>
                            <dt class="col-5">Cantidad producida</dt>
                            <dd class="col-7">{{ number_format($order->qty_producida, 2) }}</dd>
                            <dt class="col-5">Sucursal</dt>
                            <dd class="col-7">{{ $order->sucursal?->nombre ?? 'N/A' }}</dd>
                            <dt class="col-5">Almacén</dt>
                            <dd class="col-7">{{ $order->almacen?->nombre ?? 'N/A' }}</dd>
                            <dt class="col-5">Programado</dt>
                            <dd class="col-7">{{ optional($order->programado_para)->format('d/m/Y H:i') ?? 'Sin fecha' }}</dd>
                            <dt class="col-5">Notas</dt>
                            <dd class="col-7">{{ $order->notas ?? 'Sin notas' }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
            <div class="col-lg-8">
                <div class="card shadow-sm border-0 mb-3">
                    <div class="card-body">
                        <h5 class="fw-semibold mb-3">Consumo de insumos</h5>
                        <div class="table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Ítem</th>
                                        <th style="width: 20%">Cantidad</th>
                                        <th style="width: 15%">Unidad</th>
                                        <th style="width: 25%">Lote</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse($consumos as $line)
                                        <tr>
                                            <td>{{ $line['item'] }}</td>
                                            <td>{{ number_format($line['cantidad'], 2) }}</td>
                                            <td>{{ $line['uom'] }}</td>
                                            <td>{{ $line['lote'] ?? '—' }}</td>
                                        </tr>
                                    @empty
                                        <tr>
                                            <td colspan="4" class="text-center text-muted">No hay consumos registrados.</td>
                                        </tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="card shadow-sm border-0 mb-3">
                    <div class="card-body">
                        <h5 class="fw-semibold mb-3">Producto terminado</h5>
                        <div class="table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Producto</th>
                                        <th style="width: 20%">Cantidad</th>
                                        <th style="width: 15%">Unidad</th>
                                        <th style="width: 25%">Lote</th>
                                        <th style="width: 20%">Caducidad</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse($salidas as $line)
                                        <tr>
                                            <td>{{ $line['item'] }}</td>
                                            <td>{{ number_format($line['cantidad'], 2) }}</td>
                                            <td>{{ $line['uom'] }}</td>
                                            <td>{{ $line['lote'] ?? '—' }}</td>
                                            <td>{{ $line['caducidad'] ? \Carbon\Carbon::parse($line['caducidad'])->format('d/m/Y') : '—' }}</td>
                                        </tr>
                                    @empty
                                        <tr>
                                            <td colspan="5" class="text-center text-muted">Sin registros de producción.</td>
                                        </tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="card shadow-sm border-0">
                    <div class="card-body">
                        <h5 class="fw-semibold mb-3">Mermas</h5>
                        <div class="table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Ítem</th>
                                        <th style="width: 20%">Cantidad</th>
                                        <th style="width: 15%">Unidad</th>
                                        <th>Motivo</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse($mermas as $line)
                                        <tr>
                                            <td>{{ $line['item'] }}</td>
                                            <td>{{ number_format($line['cantidad'], 2) }}</td>
                                            <td>{{ $line['uom'] }}</td>
                                            <td>{{ $line['motivo'] ?? '—' }}</td>
                                        </tr>
                                    @empty
                                        <tr>
                                            <td colspan="4" class="text-center text-muted">No se registraron mermas.</td>
                                        </tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
