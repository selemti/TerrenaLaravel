<div class="py-3">
    {{-- Header --}}
    <div class="card shadow-sm mb-3">
        <div class="card-header bg-info bg-opacity-10 border-bottom border-info">
            <div class="d-flex align-items-center justify-content-between">
                <div class="d-flex align-items-center">
                    <i class="fa-solid fa-clipboard-check text-info me-2 fs-4"></i>
                    <div>
                        <h5 class="mb-0 fw-bold">Aprobación de Fondos</h5>
                        <small class="text-muted">Revisión y cierre de fondos en revisión</small>
                    </div>
                </div>
                <div>
                    <span class="badge bg-info fs-6">{{ count($fondos) }} fondo(s) pendiente(s)</span>
                </div>
            </div>
        </div>
        <div class="card-body">
            <div class="alert alert-info d-flex align-items-start mb-0">
                <i class="fa-solid fa-circle-info mt-1 me-2"></i>
                <div class="small">
                    <strong>Instrucciones:</strong>
                    <ul class="mb-0 mt-2">
                        <li>Revisa cada fondo en detalle haciendo clic en "Ver detalle"</li>
                        <li>Verifica que todos los movimientos sin comprobante estén justificados</li>
                        <li>Aprueba movimientos individuales si es necesario</li>
                        <li>Una vez revisado, puedes aprobar y cerrar definitivamente o rechazar para correcciones</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    {{-- Lista de fondos EN_REVISION --}}
    <div class="card shadow-sm">
        <div class="card-header bg-white border-bottom">
            <h6 class="mb-0 fw-bold">
                <i class="fa-solid fa-list me-2"></i>
                Fondos en Revisión
            </h6>
        </div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th style="width: 5%;">#</th>
                        <th style="width: 15%;">Sucursal</th>
                        <th style="width: 10%;">Fecha</th>
                        <th style="width: 12%;">Responsable</th>
                        <th style="width: 10%;" class="text-end">Monto Inicial</th>
                        <th style="width: 8%;" class="text-center">Movimientos</th>
                        <th style="width: 10%;" class="text-center">Estado</th>
                        <th style="width: 10%;" class="text-end">Diferencia Arqueo</th>
                        <th style="width: 20%;" class="text-center">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($fondos as $fondo)
                        <tr>
                            <td class="font-monospace small text-muted">#{{ $fondo['id'] }}</td>
                            <td>{{ $fondo['sucursal_nombre'] }}</td>
                            <td>{{ $fondo['fecha'] }}</td>
                            <td class="small">{{ $fondo['responsable'] }}</td>
                            <td class="text-end fw-semibold">${{ number_format($fondo['monto_inicial'], 2) }} {{ $fondo['moneda'] }}</td>
                            <td class="text-center">
                                <span class="badge text-bg-light">{{ $fondo['total_movimientos'] }}</span>
                            </td>
                            <td class="text-center">
                                @if($fondo['sin_comprobante'] > 0 || $fondo['por_aprobar'] > 0)
                                    <div>
                                        @if($fondo['sin_comprobante'] > 0)
                                            <span class="badge text-bg-danger mb-1" title="Sin comprobante">
                                                <i class="fa-solid fa-file-circle-xmark me-1"></i>{{ $fondo['sin_comprobante'] }}
                                            </span>
                                        @endif
                                        @if($fondo['por_aprobar'] > 0)
                                            <span class="badge text-bg-warning" title="Por aprobar">
                                                <i class="fa-solid fa-clock me-1"></i>{{ $fondo['por_aprobar'] }}
                                            </span>
                                        @endif
                                    </div>
                                @else
                                    <span class="badge text-bg-success">
                                        <i class="fa-solid fa-circle-check me-1"></i>Completo
                                    </span>
                                @endif
                            </td>
                            <td class="text-end">
                                @if(abs($fondo['diferencia_arqueo']) < 0.01)
                                    <span class="text-success fw-bold">
                                        <i class="fa-solid fa-circle-check me-1"></i>CUADRA
                                    </span>
                                @elseif($fondo['diferencia_arqueo'] > 0)
                                    <span class="text-success">
                                        +${{ number_format($fondo['diferencia_arqueo'], 2) }}
                                    </span>
                                @else
                                    <span class="text-danger">
                                        -${{ number_format(abs($fondo['diferencia_arqueo']), 2) }}
                                    </span>
                                @endif
                            </td>
                            <td class="text-center">
                                <button wire:click="selectFondo({{ $fondo['id'] }})"
                                        class="btn btn-sm btn-primary">
                                    <i class="fa-solid fa-eye me-1"></i>
                                    Ver detalle
                                </button>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="9" class="text-center text-muted py-4">
                                <i class="fa-solid fa-check-circle fs-3 d-block mb-2 text-success"></i>
                                No hay fondos pendientes de aprobación
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    {{-- Modal: Detalle del fondo --}}
    @if($showDetailModal && $fondoDetail)
        <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog modal-xl modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header bg-info bg-opacity-10">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-file-invoice me-2"></i>
                            Detalle del Fondo #{{ $fondoDetail['id'] }}
                        </h5>
                        <button type="button" class="btn-close" wire:click="closeDetailModal"></button>
                    </div>
                    <div class="modal-body">
                        {{-- Información general --}}
                        <div class="row g-3 mb-4">
                            <div class="col-md-3">
                                <label class="small text-muted">Sucursal</label>
                                <div class="fw-semibold">{{ $fondoDetail['sucursal_nombre'] }}</div>
                            </div>
                            <div class="col-md-3">
                                <label class="small text-muted">Fecha</label>
                                <div class="fw-semibold">{{ $fondoDetail['fecha'] }}</div>
                            </div>
                            <div class="col-md-3">
                                <label class="small text-muted">Responsable</label>
                                <div class="fw-semibold">{{ $fondoDetail['responsable'] }}</div>
                            </div>
                            <div class="col-md-3">
                                <label class="small text-muted">Monto Inicial</label>
                                <div class="fw-semibold">${{ number_format($fondoDetail['monto_inicial'], 2) }} {{ $fondoDetail['moneda'] }}</div>
                            </div>
                        </div>

                        {{-- Resumen financiero --}}
                        <div class="card bg-light mb-4">
                            <div class="card-body">
                                <h6 class="fw-bold mb-3">Resumen Financiero</h6>
                                <div class="row text-center">
                                    <div class="col-3">
                                        <div class="text-muted small">Monto Inicial</div>
                                        <div class="fw-bold fs-5">${{ number_format($fondoDetail['monto_inicial'], 2) }}</div>
                                    </div>
                                    <div class="col-3">
                                        <div class="text-muted small">Total Egresos</div>
                                        <div class="fw-bold fs-5 text-danger">-${{ number_format($fondoDetail['total_egresos'], 2) }}</div>
                                    </div>
                                    <div class="col-3">
                                        <div class="text-muted small">Total Reintegros</div>
                                        <div class="fw-bold fs-5 text-success">+${{ number_format($fondoDetail['total_reintegros'], 2) }}</div>
                                    </div>
                                    <div class="col-3">
                                        <div class="text-muted small">Saldo Teórico</div>
                                        <div class="fw-bold fs-5 text-primary">${{ number_format($fondoDetail['saldo_disponible'], 2) }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {{-- Resultado del arqueo --}}
                        @if($fondoDetail['arqueo'])
                            <div class="card border-{{ abs($fondoDetail['arqueo']['diferencia']) < 0.01 ? 'success' : 'warning' }} mb-4">
                                <div class="card-header bg-{{ abs($fondoDetail['arqueo']['diferencia']) < 0.01 ? 'success' : 'warning' }} bg-opacity-10">
                                    <h6 class="mb-0 fw-bold">
                                        <i class="fa-solid fa-calculator me-2"></i>
                                        Resultado del Arqueo
                                    </h6>
                                </div>
                                <div class="card-body">
                                    <div class="row text-center">
                                        <div class="col-4">
                                            <div class="text-muted small">Saldo Esperado</div>
                                            <div class="fw-bold fs-5">${{ number_format($fondoDetail['arqueo']['monto_esperado'], 2) }}</div>
                                        </div>
                                        <div class="col-4">
                                            <div class="text-muted small">Efectivo Contado</div>
                                            <div class="fw-bold fs-5">${{ number_format($fondoDetail['arqueo']['monto_contado'], 2) }}</div>
                                        </div>
                                        <div class="col-4">
                                            <div class="text-muted small">Diferencia</div>
                                            @if(abs($fondoDetail['arqueo']['diferencia']) < 0.01)
                                                <div class="fw-bold fs-5 text-success">
                                                    <i class="fa-solid fa-circle-check me-1"></i>CUADRA
                                                </div>
                                            @elseif($fondoDetail['arqueo']['diferencia'] > 0)
                                                <div class="fw-bold fs-5 text-success">
                                                    +${{ number_format($fondoDetail['arqueo']['diferencia'], 2) }}
                                                    <div class="small">A favor</div>
                                                </div>
                                            @else
                                                <div class="fw-bold fs-5 text-danger">
                                                    -${{ number_format(abs($fondoDetail['arqueo']['diferencia']), 2) }}
                                                    <div class="small">Faltante</div>
                                                </div>
                                            @endif
                                        </div>
                                    </div>
                                    @if($fondoDetail['arqueo']['observaciones'])
                                        <hr>
                                        <div>
                                            <strong class="small">Observaciones del arqueo:</strong>
                                            <p class="mb-0 small">{{ $fondoDetail['arqueo']['observaciones'] }}</p>
                                        </div>
                                    @endif
                                </div>
                            </div>
                        @endif

                        {{-- Movimientos --}}
                        <h6 class="fw-bold mb-3">
                            <i class="fa-solid fa-list me-2"></i>
                            Movimientos ({{ count($fondoDetail['movimientos']) }})
                        </h6>
                        <div class="table-responsive">
                            <table class="table table-sm table-hover">
                                <thead class="table-light">
                                    <tr>
                                        <th>#</th>
                                        <th>Fecha/Hora</th>
                                        <th>Tipo</th>
                                        <th>Concepto</th>
                                        <th class="text-end">Monto</th>
                                        <th>Método</th>
                                        <th class="text-center">Comprobante</th>
                                        <th class="text-center">Estatus</th>
                                        <th class="text-center">Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($fondoDetail['movimientos'] as $mov)
                                        <tr class="{{ !$mov['tiene_comprobante'] && $mov['estatus'] === 'POR_APROBAR' ? 'table-warning' : '' }}">
                                            <td class="small">#{{ $mov['id'] }}</td>
                                            <td class="small">{{ $mov['fecha_hora'] }}</td>
                                            <td>
                                                @if($mov['tipo'] === 'EGRESO')
                                                    <span class="badge text-bg-danger">Egreso</span>
                                                @elseif($mov['tipo'] === 'REINTEGRO')
                                                    <span class="badge text-bg-success">Reintegro</span>
                                                @else
                                                    <span class="badge text-bg-info">Depósito</span>
                                                @endif
                                            </td>
                                            <td class="small">{{ $mov['concepto'] }}</td>
                                            <td class="text-end fw-semibold">${{ number_format($mov['monto'], 2) }}</td>
                                            <td>
                                                <span class="badge text-bg-light small">
                                                    {{ $mov['metodo'] === 'EFECTIVO' ? 'Efectivo' : 'Transfer.' }}
                                                </span>
                                            </td>
                                            <td class="text-center">
                                                @if($mov['tiene_comprobante'])
                                                    <a href="{{ asset('storage/' . $mov['adjunto_path']) }}"
                                                       target="_blank"
                                                       class="text-success"
                                                       title="Ver comprobante">
                                                        <i class="fa-solid fa-circle-check"></i>
                                                    </a>
                                                @else
                                                    <i class="fa-solid fa-circle-xmark text-danger" title="Sin comprobante"></i>
                                                @endif
                                            </td>
                                            <td class="text-center">
                                                @if($mov['estatus'] === 'APROBADO')
                                                    <span class="badge text-bg-success">Aprobado</span>
                                                @elseif($mov['estatus'] === 'POR_APROBAR')
                                                    <span class="badge text-bg-warning">Por aprobar</span>
                                                @else
                                                    <span class="badge text-bg-danger">Rechazado</span>
                                                @endif
                                            </td>
                                            <td class="text-center">
                                                @if(!$mov['tiene_comprobante'] && $mov['estatus'] === 'POR_APROBAR' && $canApprove)
                                                    <button wire:click="approveMovement({{ $mov['id'] }})"
                                                            class="btn btn-xs btn-success"
                                                            title="Aprobar movimiento">
                                                        <i class="fa-solid fa-check"></i>
                                                    </button>
                                                @else
                                                    —
                                                @endif
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="modal-footer bg-light">
                        <button class="btn btn-outline-secondary" wire:click="closeDetailModal">
                            Cerrar
                        </button>
                        @if($canApprove)
                            <button class="btn btn-danger" wire:click="openRejectModal">
                                <i class="fa-solid fa-times-circle me-1"></i>
                                Rechazar y reabrir
                            </button>
                        @endif
                        @if($canClose)
                            <button class="btn btn-success" wire:click="openApproveModal">
                                <i class="fa-solid fa-lock me-1"></i>
                                Aprobar y cerrar definitivamente
                            </button>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    @endif

    {{-- Modal: Rechazar fondo --}}
    @if($showRejectModal)
        <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true" style="background: rgba(0,0,0,0.7); z-index: 1060;">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header bg-danger bg-opacity-10">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-times-circle text-danger me-2"></i>
                            Rechazar Fondo
                        </h5>
                        <button type="button" class="btn-close" wire:click="closeRejectModal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="alert alert-warning">
                            <strong>Atención:</strong> El fondo regresará a estado ABIERTO para que el cajero pueda hacer correcciones y volver a arquear.
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Motivo del rechazo <span class="text-danger">*</span></label>
                            <textarea class="form-control @error('rejectReason') is-invalid @enderror"
                                      wire:model.defer="rejectReason"
                                      rows="4"
                                      placeholder="Explica por qué se rechaza este fondo (mínimo 10 caracteres)"></textarea>
                            @error('rejectReason') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-outline-secondary" wire:click="closeRejectModal">Cancelar</button>
                        <button class="btn btn-danger" wire:click="rejectFund" {{ $loading ? 'disabled' : '' }}>
                            @if($loading)
                                <span class="spinner-border spinner-border-sm me-1"></span>
                                Rechazando...
                            @else
                                <i class="fa-solid fa-times-circle me-1"></i>
                                Confirmar rechazo
                            @endif
                        </button>
                    </div>
                </div>
            </div>
        </div>
    @endif

    {{-- Modal: Aprobar fondo --}}
    @if($showApproveModal)
        <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true" style="background: rgba(0,0,0,0.7); z-index: 1060;">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header bg-success bg-opacity-10">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-lock text-success me-2"></i>
                            Cerrar Fondo Definitivamente
                        </h5>
                        <button type="button" class="btn-close" wire:click="closeApproveModal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="alert alert-success">
                            <strong>Confirmación:</strong> El fondo pasará a estado CERRADO y no se podrá modificar posteriormente.
                        </div>
                        <p class="mb-0">
                            ¿Confirmas que has revisado todos los movimientos y deseas cerrar definitivamente el fondo #{{ $selectedFondo->id }}?
                        </p>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-outline-secondary" wire:click="closeApproveModal">Cancelar</button>
                        <button class="btn btn-success" wire:click="approveFund" {{ $loading ? 'disabled' : '' }}>
                            @if($loading)
                                <span class="spinner-border spinner-border-sm me-1"></span>
                                Cerrando...
                            @else
                                <i class="fa-solid fa-check-circle me-1"></i>
                                Confirmar cierre
                            @endif
                        </button>
                    </div>
                </div>
            </div>
        </div>
    @endif
</div>
