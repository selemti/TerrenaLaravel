<div>
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-1">Solicitud {{ $request->folio }}</h2>
            <p class="text-muted mb-0">Detalle de solicitud de compra</p>
        </div>
        <div class="d-flex gap-2">
            {!! $request->estado_badge !!}
            <a href="{{ route('purchasing.requests.index') }}" class="btn btn-outline-secondary">
                <i class="fa-solid fa-arrow-left me-2"></i>Volver
            </a>
        </div>
    </div>

    {{-- Información General --}}
    <div class="card shadow-sm mb-4">
        <div class="card-header bg-light">
            <h5 class="mb-0"><i class="fa-solid fa-info-circle me-2"></i>Información General</h5>
        </div>
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-3">
                    <label class="small text-muted">Folio</label>
                    <p class="mb-0"><strong>{{ $request->folio }}</strong></p>
                </div>
                <div class="col-md-3">
                    <label class="small text-muted">Fecha Solicitada</label>
                    <p class="mb-0">{{ $request->requested_at->format('d/m/Y H:i') }}</p>
                </div>
                <div class="col-md-3">
                    <label class="small text-muted">Creado por</label>
                    <p class="mb-0">{{ $request->createdBy->name }}</p>
                </div>
                <div class="col-md-3">
                    <label class="small text-muted">Sucursal</label>
                    <p class="mb-0">{{ $request->sucursal->nombre ?? '-' }}</p>
                </div>
                @if($request->notas)
                <div class="col-12">
                    <label class="small text-muted">Notas</label>
                    <p class="mb-0">{{ $request->notas }}</p>
                </div>
                @endif
            </div>
        </div>
    </div>

    {{-- Líneas de Solicitud --}}
    <div class="card shadow-sm mb-4">
        <div class="card-header bg-light d-flex justify-content-between align-items-center">
            <h5 class="mb-0"><i class="fa-solid fa-list me-2"></i>Items Solicitados</h5>
            <span class="badge bg-primary">{{ $request->lines->count() }} items</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Código</th>
                            <th>Item</th>
                            <th class="text-end">Cantidad</th>
                            <th>UOM</th>
                            <th>Fecha Req.</th>
                            <th>Proveedor Pref.</th>
                            <th class="text-end">Precio Est.</th>
                            <th class="text-end">Subtotal</th>
                            <th class="text-center">Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($request->lines as $line)
                            <tr>
                                <td><code>{{ $line->item->codigo }}</code></td>
                                <td>{{ $line->item->nombre }}</td>
                                <td class="text-end">{{ number_format($line->qty, 2) }}</td>
                                <td>{{ $line->uom }}</td>
                                <td>{{ $line->fecha_requerida?->format('d/m/Y') ?? '-' }}</td>
                                <td><small>{{ $line->preferredVendor->nombre ?? '-' }}</small></td>
                                <td class="text-end">${{ number_format($line->last_price ?? 0, 2) }}</td>
                                <td class="text-end"><strong>${{ number_format($line->monto_estimado, 2) }}</strong></td>
                                <td class="text-center">{!! $line->estado_badge !!}</td>
                            </tr>
                        @endforeach
                    </tbody>
                    <tfoot class="table-light">
                        <tr>
                            <th colspan="7" class="text-end">Total Estimado:</th>
                            <th class="text-end">${{ number_format($request->importe_estimado, 2) }}</th>
                            <th></th>
                        </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    </div>

    {{-- Cotizaciones Recibidas --}}
    @if($request->quotes->count() > 0)
    <div class="card shadow-sm">
        <div class="card-header bg-light">
            <h5 class="mb-0"><i class="fa-solid fa-file-invoice-dollar me-2"></i>Cotizaciones Recibidas</h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Proveedor</th>
                            <th>Folio Proveedor</th>
                            <th>Recibida</th>
                            <th class="text-end">Total</th>
                            <th class="text-center">Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($request->quotes as $quote)
                            <tr>
                                <td>{{ $quote->vendor->nombre }}</td>
                                <td>{{ $quote->folio_proveedor ?? '-' }}</td>
                                <td>{{ $quote->recibida_en?->format('d/m/Y') ?? '-' }}</td>
                                <td class="text-end"><strong>${{ number_format($quote->total, 2) }}</strong></td>
                                <td class="text-center">{!! $quote->estado_badge !!}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    @endif
</div>
