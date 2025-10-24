<div>
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-1">Orden de Compra {{ $order->folio }}</h2>
            <p class="text-muted mb-0">Detalle de orden de compra</p>
        </div>
        <div class="d-flex gap-2">
            {!! $order->estado_badge !!}
            <a href="{{ route('purchasing.orders.index') }}" class="btn btn-outline-secondary">
                <i class="fa-solid fa-arrow-left me-2"></i>Volver
            </a>
        </div>
    </div>

    <div class="row">
        <div class="col-md-8">
            {{-- Información General --}}
            <div class="card shadow-sm mb-4">
                <div class="card-header bg-light">
                    <h5 class="mb-0"><i class="fa-solid fa-info-circle me-2"></i>Información General</h5>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="small text-muted">Proveedor</label>
                            <p class="mb-0"><strong>{{ $order->vendor->nombre }}</strong></p>
                        </div>
                        <div class="col-md-6">
                            <label class="small text-muted">Fecha Promesa</label>
                            <p class="mb-0">{{ $order->fecha_promesa?->format('d/m/Y') ?? '-' }}</p>
                        </div>
                        <div class="col-md-6">
                            <label class="small text-muted">Creado por</label>
                            <p class="mb-0">{{ $order->creadoPor->name }}</p>
                        </div>
                        <div class="col-md-6">
                            <label class="small text-muted">Aprobado por</label>
                            <p class="mb-0">{{ $order->aprobadoPor->name ?? '-' }}</p>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Líneas de Orden --}}
            <div class="card shadow-sm">
                <div class="card-header bg-light">
                    <h5 class="mb-0"><i class="fa-solid fa-list me-2"></i>Items</h5>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Item</th>
                                    <th class="text-end">Cantidad</th>
                                    <th class="text-end">Precio Unit.</th>
                                    <th class="text-end">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($order->lines as $line)
                                    <tr>
                                        <td>
                                            <strong>{{ $line->item->codigo }}</strong><br>
                                            <small class="text-muted">{{ $line->item->nombre }}</small>
                                        </td>
                                        <td class="text-end">{{ number_format($line->qty, 2) }} {{ $line->uom }}</td>
                                        <td class="text-end">${{ number_format($line->precio_unitario, 2) }}</td>
                                        <td class="text-end"><strong>${{ number_format($line->total, 2) }}</strong></td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            {{-- Resumen Financiero --}}
            <div class="card shadow-sm">
                <div class="card-header bg-light">
                    <h5 class="mb-0"><i class="fa-solid fa-calculator me-2"></i>Resumen</h5>
                </div>
                <div class="card-body">
                    <table class="table table-sm mb-0">
                        <tr>
                            <td>Subtotal:</td>
                            <td class="text-end"><strong>${{ number_format($order->subtotal, 2) }}</strong></td>
                        </tr>
                        <tr>
                            <td>Descuento:</td>
                            <td class="text-end text-success">-${{ number_format($order->descuento, 2) }}</td>
                        </tr>
                        <tr>
                            <td>Impuestos:</td>
                            <td class="text-end">${{ number_format($order->impuestos, 2) }}</td>
                        </tr>
                        <tr class="table-light">
                            <th>Total:</th>
                            <th class="text-end"><h4 class="mb-0">${{ number_format($order->total, 2) }}</h4></th>
                        </tr>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
