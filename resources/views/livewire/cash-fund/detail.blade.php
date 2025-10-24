<div class="py-3">
    {{-- Header para impresión (solo visible al imprimir) --}}
    <div class="d-none d-print-block print-header">
        <h1>ESTADO DE CUENTA - FONDO DE CAJA CHICA</h1>
        <h2>Fondo #{{ $fondo['id'] }}@if($fondo['descripcion']) - {{ $fondo['descripcion'] }}@endif</h2>
        <p class="mb-0">{{ $fondo['sucursal_nombre'] }} • {{ $fondo['fecha'] }}</p>
    </div>

    {{-- Header para pantalla --}}
    <div class="card shadow-sm mb-3 d-print-none">
        <div class="card-header {{ $fondo['estado'] === 'CERRADO' ? 'bg-secondary' : 'bg-warning' }} bg-opacity-10 border-bottom">
            <div class="d-flex align-items-center justify-content-between">
                <div class="d-flex align-items-center">
                    <i class="fa-solid fa-{{ $fondo['estado'] === 'CERRADO' ? 'lock' : 'eye' }} me-2 fs-4"></i>
                    <div>
                        <h5 class="mb-0 fw-bold">Detalle Completo del Fondo #{{ $fondo['id'] }}</h5>
                        <small class="text-muted">{{ $fondo['sucursal_nombre'] }} - {{ $fondo['fecha'] }}</small>
                    </div>
                </div>
                <div>
                    @if($fondo['estado'] === 'CERRADO')
                        <span class="badge bg-secondary fs-6">
                            <i class="fa-solid fa-lock me-1"></i>CERRADO
                        </span>
                    @elseif($fondo['estado'] === 'EN_REVISION')
                        <span class="badge bg-warning fs-6">
                            <i class="fa-solid fa-eye me-1"></i>EN REVISIÓN
                        </span>
                    @else
                        <span class="badge bg-success fs-6">
                            <i class="fa-solid fa-unlock me-1"></i>ABIERTO
                        </span>
                    @endif
                </div>
            </div>
        </div>
        <div class="card-body">
            <div class="alert {{ $fondo['estado'] === 'CERRADO' ? 'alert-secondary' : 'alert-info' }} d-flex align-items-start mb-0">
                <i class="fa-solid fa-info-circle mt-1 me-2"></i>
                <div class="small">
                    @if($fondo['estado'] === 'CERRADO')
                        <strong>Fondo cerrado:</strong> Este fondo ha sido cerrado definitivamente y no puede ser modificado.
                        Esta es una vista de solo lectura para consulta histórica.
                    @else
                        <strong>Vista de detalle:</strong> Esta es una vista de solo lectura del fondo.
                        {{ $fondo['estado'] === 'EN_REVISION' ? 'El fondo está en revisión pendiente de aprobación.' : '' }}
                    @endif
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        {{-- Columna izquierda: Información y movimientos --}}
        <div class="col-lg-8">
            {{-- Información general --}}
            <div class="card shadow-sm mb-3">
                <div class="card-header bg-white border-bottom">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-info-circle me-2"></i>
                        Información General
                    </h6>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Sucursal</label>
                            <div class="fw-semibold">{{ $fondo['sucursal_nombre'] }}</div>
                        </div>
                        <div class="col-md-3">
                            <label class="small text-muted mb-1">Fecha del Fondo</label>
                            <div class="fw-semibold">{{ $fondo['fecha'] }}</div>
                        </div>
                        <div class="col-md-3">
                            <label class="small text-muted mb-1">Moneda</label>
                            <div class="fw-semibold">{{ $fondo['moneda'] }}</div>
                        </div>
                        @if($fondo['descripcion'])
                            <div class="col-12">
                                <label class="small text-muted mb-1">Descripción</label>
                                <div class="fw-semibold">{{ $fondo['descripcion'] }}</div>
                            </div>
                        @endif
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Responsable del Fondo</label>
                            <div class="fw-semibold">{{ $fondo['responsable'] }}</div>
                        </div>
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Creado por</label>
                            <div class="fw-semibold">{{ $fondo['creado_por'] }}</div>
                        </div>
                        <div class="col-md-6">
                            <label class="small text-muted mb-1">Fecha de Creación</label>
                            <div class="fw-semibold">{{ $fondo['fecha_creacion'] }}</div>
                        </div>
                        @if($fondo['fecha_cierre'])
                            <div class="col-md-6">
                                <label class="small text-muted mb-1">Fecha de Cierre</label>
                                <div class="fw-semibold text-danger">
                                    <i class="fa-solid fa-lock me-1"></i>
                                    {{ $fondo['fecha_cierre'] }}
                                </div>
                            </div>
                        @endif
                    </div>
                </div>
            </div>

            {{-- Resumen financiero --}}
            <div class="card shadow-sm mb-3">
                <div class="card-header bg-white border-bottom">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-chart-line me-2"></i>
                        Resumen Financiero
                    </h6>
                </div>
                <div class="card-body">
                    <div class="row text-center g-3">
                        <div class="col-3">
                            <div class="border rounded p-3">
                                <div class="text-muted small mb-1">Monto Inicial</div>
                                <h4 class="mb-0 text-primary">${{ number_format($fondo['monto_inicial'], 2) }}</h4>
                            </div>
                        </div>
                        <div class="col-3">
                            <div class="border rounded p-3">
                                <div class="text-muted small mb-1">Total Egresos</div>
                                <h4 class="mb-0 text-danger">-${{ number_format($totalEgresos, 2) }}</h4>
                            </div>
                        </div>
                        <div class="col-3">
                            <div class="border rounded p-3">
                                <div class="text-muted small mb-1">Total Reintegros</div>
                                <h4 class="mb-0 text-success">+${{ number_format($totalReintegros, 2) }}</h4>
                            </div>
                        </div>
                        <div class="col-3">
                            <div class="border rounded p-3 bg-light">
                                <div class="text-muted small mb-1">Saldo Final</div>
                                <h4 class="mb-0 fw-bold">${{ number_format($saldoFinal, 2) }}</h4>
                            </div>
                        </div>
                    </div>

                    <hr class="my-3">

                    <div class="row">
                        <div class="col-md-6">
                            <h6 class="small text-muted mb-2">Por Tipo de Movimiento</h6>
                            <div class="d-flex justify-content-between mb-1">
                                <span class="small"><i class="fa-solid fa-arrow-down text-danger me-1"></i> Egresos</span>
                                <strong class="small">${{ number_format($resumenPorTipo['EGRESO'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between mb-1">
                                <span class="small"><i class="fa-solid fa-arrow-up text-success me-1"></i> Reintegros</span>
                                <strong class="small">${{ number_format($resumenPorTipo['REINTEGRO'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between">
                                <span class="small"><i class="fa-solid fa-plus text-info me-1"></i> Depósitos</span>
                                <strong class="small">${{ number_format($resumenPorTipo['DEPOSITO'], 2) }}</strong>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <h6 class="small text-muted mb-2">Por Método de Pago</h6>
                            <div class="d-flex justify-content-between mb-1">
                                <span class="small"><i class="fa-solid fa-money-bill me-1"></i> Efectivo</span>
                                <strong class="small">${{ number_format($resumenPorMetodo['EFECTIVO'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between mb-1">
                                <span class="small"><i class="fa-solid fa-building-columns me-1"></i> Transferencia</span>
                                <strong class="small">${{ number_format($resumenPorMetodo['TRANSFER'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between mt-3">
                                <span class="small">Comprobantes</span>
                                <span>
                                    <span class="badge text-bg-success">{{ $totalConComprobante }} con</span>
                                    <span class="badge text-bg-danger">{{ $totalSinComprobante }} sin</span>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Tabla de movimientos --}}
            <div class="card shadow-sm mb-3">
                <div class="card-header bg-white border-bottom">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-list me-2"></i>
                        Movimientos ({{ count($movimientos) }})
                    </h6>
                </div>
                <div class="table-responsive">
                    <table class="table table-hover table-sm align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th style="width: 4%;">#</th>
                                <th style="width: 11%;">Fecha/Hora</th>
                                <th style="width: 10%;">Tipo</th>
                                <th style="width: 25%;">Concepto</th>
                                <th style="width: 10%;" class="text-end">Monto</th>
                                <th style="width: 10%;">Método</th>
                                <th style="width: 8%;" class="text-center">Comprobante</th>
                                <th style="width: 8%;" class="text-center">Estatus</th>
                                <th style="width: 14%;">Usuario</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($movimientos as $mov)
                                <tr>
                                    <td class="small text-muted">#{{ $mov['id'] }}</td>
                                    <td class="small">{{ $mov['fecha_hora'] }}</td>
                                    <td>
                                        @if($mov['tipo'] === 'EGRESO')
                                            <span class="badge text-bg-danger"><i class="fa-solid fa-arrow-down me-1"></i>Egreso</span>
                                        @elseif($mov['tipo'] === 'REINTEGRO')
                                            <span class="badge text-bg-success"><i class="fa-solid fa-arrow-up me-1"></i>Reintegro</span>
                                        @else
                                            <span class="badge text-bg-info"><i class="fa-solid fa-plus me-1"></i>Depósito</span>
                                        @endif
                                    </td>
                                    <td class="small">{{ $mov['concepto'] }}</td>
                                    <td class="text-end fw-semibold">${{ number_format($mov['monto'], 2) }}</td>
                                    <td>
                                        <span class="badge text-bg-light small">
                                            @if($mov['metodo'] === 'EFECTIVO')
                                                <i class="fa-solid fa-money-bill me-1"></i>Efectivo
                                            @else
                                                <i class="fa-solid fa-building-columns me-1"></i>Transfer.
                                            @endif
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        @if($mov['tiene_comprobante'])
                                            <a href="{{ asset('storage/' . $mov['adjunto_path']) }}"
                                               target="_blank"
                                               class="text-success"
                                               title="Ver comprobante">
                                                <i class="fa-solid fa-circle-check fs-5"></i>
                                            </a>
                                        @else
                                            <i class="fa-solid fa-circle-xmark text-danger fs-5" title="Sin comprobante"></i>
                                        @endif
                                    </td>
                                    <td class="text-center">
                                        @if($mov['estatus'] === 'APROBADO')
                                            <span class="badge text-bg-success small">Aprobado</span>
                                        @elseif($mov['estatus'] === 'POR_APROBAR')
                                            <span class="badge text-bg-warning small">Por aprobar</span>
                                        @else
                                            <span class="badge text-bg-danger small">Rechazado</span>
                                        @endif
                                    </td>
                                    <td class="small">{{ $mov['creado_por'] }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="9" class="text-center text-muted py-4">
                                        No hay movimientos registrados.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                        <tfoot class="table-light">
                            <tr>
                                <td colspan="4" class="text-end fw-bold">TOTAL:</td>
                                <td class="text-end fw-bold">${{ number_format($movimientos->sum('monto'), 2) }}</td>
                                <td colspan="4"></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        </div>

        {{-- Columna derecha: Arqueo y Timeline --}}
        <div class="col-lg-4">
            {{-- Resultado del arqueo --}}
            @if($arqueo)
                <div class="print-section">
                <div class="card shadow-sm mb-3 border-{{ abs($arqueo['diferencia']) < 0.01 ? 'success' : 'warning' }}">
                    <div class="card-header bg-{{ abs($arqueo['diferencia']) < 0.01 ? 'success' : 'warning' }} bg-opacity-10">
                        <h6 class="mb-0 fw-bold">
                            <i class="fa-solid fa-calculator me-2"></i>
                            Resultado del Arqueo
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="text-center mb-3">
                            @if(abs($arqueo['diferencia']) < 0.01)
                                <div class="display-6 text-success">
                                    <i class="fa-solid fa-circle-check"></i>
                                </div>
                                <h5 class="text-success mb-0">CUADRA PERFECTAMENTE</h5>
                            @elseif($arqueo['diferencia'] > 0)
                                <div class="display-6 text-success">+${{ number_format($arqueo['diferencia'], 2) }}</div>
                                <h6 class="text-muted">A favor</h6>
                            @else
                                <div class="display-6 text-danger">-${{ number_format(abs($arqueo['diferencia']), 2) }}</div>
                                <h6 class="text-muted">Faltante</h6>
                            @endif
                        </div>

                        <hr>

                        <div class="mb-2">
                            <div class="d-flex justify-content-between">
                                <span class="small text-muted">Saldo Esperado:</span>
                                <strong class="small">${{ number_format($arqueo['monto_esperado'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between">
                                <span class="small text-muted">Efectivo Contado:</span>
                                <strong class="small">${{ number_format($arqueo['monto_contado'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between">
                                <span class="small text-muted">Diferencia:</span>
                                <strong class="small">${{ number_format($arqueo['diferencia'], 2) }}</strong>
                            </div>
                        </div>

                        @if($arqueo['observaciones'])
                            <hr>
                            <div>
                                <strong class="small">Observaciones:</strong>
                                <p class="small mb-0">{{ $arqueo['observaciones'] }}</p>
                            </div>
                        @endif

                        <hr>

                        <div class="small text-muted">
                            <i class="fa-solid fa-user me-1"></i>{{ $arqueo['creado_por'] }}<br>
                            <i class="fa-solid fa-clock me-1"></i>{{ $arqueo['fecha'] }}
                        </div>
                    </div>
                </div>
                </div>
            @endif

            {{-- Timeline de eventos (solo visible en pantalla) --}}
            <div class="card shadow-sm d-print-none no-print">
                <div class="card-header bg-white border-bottom">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-timeline me-2"></i>
                        Línea de Tiempo
                    </h6>
                </div>
                <div class="card-body">
                    <div class="timeline">
                        @foreach($timeline as $event)
                            <div class="timeline-item mb-3">
                                <div class="d-flex">
                                    <div class="flex-shrink-0">
                                        <div class="timeline-icon bg-{{ $event['color'] }} bg-opacity-10 text-{{ $event['color'] }} rounded-circle p-2">
                                            <i class="fa-solid {{ $event['icono'] }}"></i>
                                        </div>
                                    </div>
                                    <div class="flex-grow-1 ms-3">
                                        <strong class="small">{{ $event['descripcion'] }}</strong>
                                        <div class="small text-muted">{{ $event['fecha'] }}</div>
                                        <div class="small">{{ $event['detalle'] }}</div>
                                        <div class="small text-muted"><i class="fa-solid fa-user me-1"></i>{{ $event['usuario'] }}</div>
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Botones de acción (solo visible en pantalla) --}}
    <div class="card shadow-sm d-print-none">
        <div class="card-footer bg-light d-flex justify-content-between">
            <a href="{{ route('cashfund.index') }}" class="btn btn-outline-secondary">
                <i class="fa-solid fa-arrow-left me-1"></i>
                Volver a lista de fondos
            </a>
            <div>
                <button class="btn btn-outline-primary" onclick="window.print()">
                    <i class="fa-solid fa-print me-1"></i>
                    Imprimir
                </button>
                {{-- Botón para exportar PDF (futuro) --}}
                {{-- <button class="btn btn-outline-danger">
                    <i class="fa-solid fa-file-pdf me-1"></i>
                    Exportar PDF
                </button> --}}
            </div>
        </div>
    </div>

    {{-- Footer para impresión (solo visible al imprimir) --}}
    <div class="d-none d-print-block print-footer">
        <p class="mb-1">Documento generado el {{ now()->format('d/m/Y H:i') }}</p>
        <p class="mb-0">Sistema de Gestión de Caja Chica • TerrenaLaravel</p>
    </div>
</div>

@push('styles')
<style>
.timeline-icon {
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
}

/* ========================================
   ESTILOS PARA IMPRESIÓN - ESTADO DE CUENTA
   ======================================== */
@media print {
    /* Ocultar elementos no necesarios */
    .btn,
    .card-footer,
    .top-bar,
    .sidebar,
    .status-bar,
    .timeline,
    .no-print {
        display: none !important;
    }

    /* Ajustar márgenes de página */
    @page {
        margin: 1cm;
        size: letter;
    }

    body {
        margin: 0;
        padding: 0;
        font-size: 10pt;
    }

    /* Contenido principal */
    .main-content {
        width: 100% !important;
        padding: 0 !important;
    }

    /* Header del estado de cuenta */
    .print-header {
        text-align: center;
        border-bottom: 3px solid #333;
        padding-bottom: 10px;
        margin-bottom: 20px;
    }

    .print-header h1 {
        font-size: 18pt;
        font-weight: bold;
        margin: 0;
        color: #000;
    }

    .print-header h2 {
        font-size: 14pt;
        margin: 5px 0;
        color: #555;
    }

    /* Información general en grid */
    .print-info-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 10px;
        margin-bottom: 20px;
        font-size: 9pt;
    }

    .print-info-item {
        border: 1px solid #ddd;
        padding: 5px 10px;
    }

    .print-info-item label {
        font-weight: bold;
        display: block;
        font-size: 8pt;
        color: #666;
    }

    .print-info-item .value {
        font-size: 10pt;
        color: #000;
    }

    /* Resumen financiero */
    .print-summary {
        background: #f8f9fa;
        border: 2px solid #333;
        padding: 10px;
        margin: 15px 0;
        page-break-inside: avoid;
    }

    .print-summary-row {
        display: flex;
        justify-content: space-between;
        padding: 5px 0;
        border-bottom: 1px solid #ddd;
    }

    .print-summary-row:last-child {
        border-bottom: none;
        font-weight: bold;
        font-size: 12pt;
        border-top: 2px solid #333;
        padding-top: 8px;
        margin-top: 5px;
    }

    /* Tabla de movimientos */
    .table {
        width: 100%;
        border-collapse: collapse;
        margin: 15px 0;
        font-size: 8pt;
    }

    .table thead {
        background: #333 !important;
        color: white !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }

    .table th {
        padding: 8px 5px;
        text-align: left;
        border: 1px solid #333;
        font-weight: bold;
    }

    .table td {
        padding: 6px 5px;
        border: 1px solid #ddd;
    }

    .table tbody tr:nth-child(even) {
        background: #f9f9f9 !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }

    .table tfoot {
        background: #e9ecef !important;
        font-weight: bold;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }

    /* Resultado del arqueo */
    .print-arqueo {
        border: 2px solid #333;
        padding: 15px;
        margin: 20px 0;
        page-break-inside: avoid;
    }

    .print-arqueo-title {
        font-size: 12pt;
        font-weight: bold;
        text-align: center;
        margin-bottom: 10px;
    }

    .print-arqueo-value {
        font-size: 18pt;
        font-weight: bold;
        text-align: center;
        margin: 10px 0;
    }

    /* Badges y badges de color */
    .badge {
        border: 1px solid #333;
        padding: 2px 6px;
        border-radius: 3px;
        font-size: 7pt;
        font-weight: bold;
    }

    .text-bg-danger {
        background: #f8d7da !important;
        color: #721c24 !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }

    .text-bg-success {
        background: #d4edda !important;
        color: #155724 !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }

    .text-bg-info {
        background: #d1ecf1 !important;
        color: #0c5460 !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }

    .text-bg-warning {
        background: #fff3cd !important;
        color: #856404 !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }

    /* Footer de impresión */
    .print-footer {
        margin-top: 30px;
        padding-top: 15px;
        border-top: 2px solid #333;
        font-size: 8pt;
        text-align: center;
        color: #666;
    }

    /* Evitar saltos de página inapropiados */
    .card, .print-section {
        page-break-inside: avoid;
    }

    h1, h2, h3, h4, h5, h6 {
        page-break-after: avoid;
    }

    /* Ocultar columna de acciones en la tabla */
    .table th:last-child,
    .table td:last-child {
        display: none;
    }
}
</style>
@endpush
