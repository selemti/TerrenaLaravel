<div class="py-3">
    <div class="row justify-content-center">
        <div class="col-lg-10">
            {{-- Header --}}
            <div class="card shadow-sm mb-3">
                <div class="card-header bg-warning bg-opacity-10 border-bottom border-warning">
                    <div class="d-flex align-items-center">
                        <i class="fa-solid fa-calculator text-warning me-2 fs-4"></i>
                        <div>
                            <h5 class="mb-0 fw-bold">Arqueo y Cierre de Fondo</h5>
                            <small class="text-muted">Fondo #{{ $fondo['id'] }} - {{ $fondo['sucursal_nombre'] }}</small>
                        </div>
                    </div>
                </div>
                <div class="card-body">
                    <div class="alert alert-info d-flex align-items-start mb-0">
                        <i class="fa-solid fa-circle-info mt-1 me-2"></i>
                        <div class="small">
                            <strong>Importante:</strong> Realiza el conteo físico del efectivo en caja y registra el monto exacto.
                            El sistema calculará automáticamente la diferencia con el saldo teórico.
                            Si hay diferencia, el fondo pasará a revisión de gerencia.
                        </div>
                    </div>
                </div>
            </div>

            {{-- Alertas visuales --}}
            @if($totalSinComprobante > 0 || $totalPorAprobar > 0)
                <div class="alert alert-warning d-flex align-items-start mb-3">
                    <i class="fa-solid fa-triangle-exclamation me-2 mt-1"></i>
                    <div>
                        <strong>Atención antes de cerrar:</strong>
                        <ul class="mb-0 mt-2">
                            @if($totalSinComprobante > 0)
                                <li>{{ $totalSinComprobante }} movimiento(s) sin comprobante adjunto</li>
                            @endif
                            @if($totalPorAprobar > 0)
                                <li>{{ $totalPorAprobar }} movimiento(s) pendiente(s) de aprobación gerencial</li>
                            @endif
                        </ul>
                        <small class="text-muted d-block mt-2">
                            Estos movimientos requerirán revisión antes del cierre definitivo del fondo.
                        </small>
                    </div>
                </div>
            @elseif($porcentajeComprobacion === 100)
                <div class="alert alert-success d-flex align-items-center mb-3">
                    <i class="fa-solid fa-circle-check me-2"></i>
                    <span>Todos los movimientos tienen comprobante. El fondo está listo para arqueo.</span>
                </div>
            @endif

            {{-- Resumen del fondo --}}
            <div class="row g-3 mb-3">
                <div class="col-md-3">
                    <div class="card border-primary">
                        <div class="card-body text-center">
                            <div class="text-primary mb-2">
                                <i class="fa-solid fa-wallet fs-3"></i>
                            </div>
                            <h6 class="text-muted small mb-1">Monto Inicial</h6>
                            <h4 class="fw-bold mb-0">${{ number_format($fondo['monto_inicial'], 2) }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-danger">
                        <div class="card-body text-center">
                            <div class="text-danger mb-2">
                                <i class="fa-solid fa-arrow-down fs-3"></i>
                            </div>
                            <h6 class="text-muted small mb-1">Total Egresos</h6>
                            <h4 class="fw-bold mb-0 text-danger">${{ number_format($totalEgresos, 2) }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-success">
                        <div class="card-body text-center">
                            <div class="text-success mb-2">
                                <i class="fa-solid fa-arrow-up fs-3"></i>
                            </div>
                            <h6 class="text-muted small mb-1">Reintegros</h6>
                            <h4 class="fw-bold mb-0 text-success">${{ number_format($totalReintegros, 2) }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-warning">
                        <div class="card-body text-center">
                            <div class="text-warning mb-2">
                                <i class="fa-solid fa-calculator fs-3"></i>
                            </div>
                            <h6 class="text-muted small mb-1">Saldo Teórico</h6>
                            <h4 class="fw-bold mb-0">${{ number_format($saldoTeorico, 2) }}</h4>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Formulario de arqueo --}}
            <div class="card shadow-sm">
                <div class="card-header bg-white border-bottom">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-hand-holding-dollar me-2"></i>
                        Conteo de efectivo
                    </h6>
                </div>
                <div class="card-body">
                    <form wire:submit.prevent="openConfirm">
                        <div class="row g-3">
                            {{-- Efectivo contado --}}
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">
                                    Efectivo contado físicamente <span class="text-danger">*</span>
                                </label>
                                <div class="input-group input-group-lg">
                                    <span class="input-group-text">
                                        <i class="fa-solid fa-dollar-sign"></i>
                                    </span>
                                    <input type="number"
                                           step="0.01"
                                           class="form-control @error('arqueoForm.efectivo_contado') is-invalid @enderror"
                                           wire:model.lazy="arqueoForm.efectivo_contado"
                                           placeholder="0.00"
                                           autofocus>
                                    @error('arqueoForm.efectivo_contado')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                    @enderror
                                </div>
                                <small class="text-muted">
                                    Monto total de efectivo disponible en la caja
                                </small>
                            </div>

                            {{-- Observaciones --}}
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Observaciones (opcional)</label>
                                <textarea class="form-control @error('arqueoForm.observaciones') is-invalid @enderror"
                                          wire:model.defer="arqueoForm.observaciones"
                                          rows="3"
                                          placeholder="Notas adicionales sobre el arqueo"></textarea>
                                @error('arqueoForm.observaciones')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                @enderror
                            </div>

                            {{-- Indicador de diferencia --}}
                            @if($this->arqueoForm['efectivo_contado'] !== '')
                                <div class="col-12">
                                    <div class="card {{ abs($diferencia) < 0.01 ? 'border-success' : 'border-warning' }} mb-0">
                                        <div class="card-body">
                                            <div class="row align-items-center">
                                                <div class="col-md-4 text-center border-end">
                                                    <h6 class="text-muted small mb-1">Saldo teórico</h6>
                                                    <h4 class="mb-0">${{ number_format($saldoTeorico, 2) }}</h4>
                                                </div>
                                                <div class="col-md-4 text-center border-end">
                                                    <h6 class="text-muted small mb-1">Efectivo contado</h6>
                                                    <h4 class="mb-0 fw-bold">${{ number_format($efectivoContado, 2) }}</h4>
                                                </div>
                                                <div class="col-md-4 text-center">
                                                    <h6 class="text-muted small mb-1">Diferencia</h6>
                                                    @if(abs($diferencia) < 0.01)
                                                        <h4 class="mb-0 text-success">
                                                            <i class="fa-solid fa-circle-check me-1"></i>
                                                            CUADRA
                                                        </h4>
                                                    @elseif($diferencia > 0)
                                                        <h4 class="mb-0 text-success">
                                                            +${{ number_format($diferencia, 2) }}
                                                            <small class="d-block small">A favor</small>
                                                        </h4>
                                                    @else
                                                        <h4 class="mb-0 text-danger">
                                                            -${{ number_format(abs($diferencia), 2) }}
                                                            <small class="d-block small">Faltante</small>
                                                        </h4>
                                                    @endif
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            @endif
                        </div>
                    </form>
                </div>

                <div class="card-footer bg-light d-flex justify-content-between">
                    <a href="{{ route('cashfund.movements', ['id' => $fondoId]) }}" class="btn btn-outline-secondary">
                        <i class="fa-solid fa-arrow-left me-1"></i>
                        Volver a movimientos
                    </a>
                    <button class="btn btn-success" wire:click="openConfirm" {{ $loading ? 'disabled' : '' }}>
                        <i class="fa-solid fa-lock me-1"></i>
                        Registrar arqueo
                    </button>
                </div>
            </div>

            {{-- Resúmenes financieros --}}
            <div class="card shadow-sm mt-3">
                <div class="card-header bg-white border-bottom">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-chart-pie me-2"></i>
                        Resúmenes Financieros
                    </h6>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        {{-- Por tipo de movimiento --}}
                        <div class="col-md-6">
                            <h6 class="text-muted small mb-3">Por tipo de movimiento</h6>
                            <div class="d-flex justify-content-between mb-2">
                                <span><i class="fa-solid fa-arrow-down text-danger me-1"></i> Egresos</span>
                                <strong class="text-danger">${{ number_format($resumenPorTipo['EGRESO'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between mb-2">
                                <span><i class="fa-solid fa-arrow-up text-success me-1"></i> Reintegros</span>
                                <strong class="text-success">${{ number_format($resumenPorTipo['REINTEGRO'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between">
                                <span><i class="fa-solid fa-plus text-info me-1"></i> Depósitos</span>
                                <strong class="text-info">${{ number_format($resumenPorTipo['DEPOSITO'], 2) }}</strong>
                            </div>
                        </div>

                        {{-- Por método de pago --}}
                        <div class="col-md-6">
                            <h6 class="text-muted small mb-3">Por método de pago</h6>
                            <div class="d-flex justify-content-between mb-2">
                                <span><i class="fa-solid fa-money-bill me-1"></i> Efectivo</span>
                                <strong>${{ number_format($resumenPorMetodo['EFECTIVO'], 2) }}</strong>
                            </div>
                            <div class="d-flex justify-content-between mb-3">
                                <span><i class="fa-solid fa-building-columns me-1"></i> Transferencia</span>
                                <strong>${{ number_format($resumenPorMetodo['TRANSFER'], 2) }}</strong>
                            </div>
                        </div>

                        {{-- Estatus de comprobación --}}
                        <div class="col-12">
                            <hr>
                            <h6 class="text-muted small mb-3">Estatus de comprobación</h6>
                            <div class="row text-center">
                                <div class="col-4">
                                    <div class="border rounded p-3">
                                        <h4 class="text-success mb-1">{{ $totalConComprobante }}</h4>
                                        <small class="text-muted">Con comprobante</small>
                                    </div>
                                </div>
                                <div class="col-4">
                                    <div class="border rounded p-3">
                                        <h4 class="text-danger mb-1">{{ $totalSinComprobante }}</h4>
                                        <small class="text-muted">Sin comprobante</small>
                                    </div>
                                </div>
                                <div class="col-4">
                                    <div class="border rounded p-3">
                                        <h4 class="text-warning mb-1">{{ $totalPorAprobar }}</h4>
                                        <small class="text-muted">Por aprobar</small>
                                    </div>
                                </div>
                            </div>
                            <div class="mt-3">
                                <div class="d-flex justify-content-between mb-2">
                                    <small class="text-muted">Porcentaje de comprobación</small>
                                    <small class="fw-semibold">{{ number_format($porcentajeComprobacion, 1) }}%</small>
                                </div>
                                <div class="progress" style="height: 20px;">
                                    <div class="progress-bar {{ $porcentajeComprobacion === 100 ? 'bg-success' : ($porcentajeComprobacion >= 80 ? 'bg-warning' : 'bg-danger') }}"
                                         role="progressbar"
                                         style="width: {{ $porcentajeComprobacion }}%">
                                        {{ number_format($porcentajeComprobacion, 0) }}%
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Detalle completo de movimientos --}}
            <div class="card shadow-sm mt-3">
                <div class="card-header bg-white border-bottom">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-list-check me-2"></i>
                        Detalle de Movimientos ({{ count($movimientos) }})
                    </h6>
                </div>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th style="width: 4%;">#</th>
                                <th style="width: 10%;">Fecha/Hora</th>
                                <th style="width: 9%;">Tipo</th>
                                <th style="width: 22%;">Concepto</th>
                                <th style="width: 12%;">Proveedor</th>
                                <th style="width: 9%;" class="text-end">Monto</th>
                                <th style="width: 8%;">Método</th>
                                <th style="width: 8%;" class="text-center">Comprobante</th>
                                <th style="width: 10%;">Usuario</th>
                                <th style="width: 8%;" class="text-center">Estatus</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($movimientos as $mov)
                                <tr class="{{ !$mov['tiene_comprobante'] ? 'table-warning' : '' }}">
                                    <td class="font-monospace small text-muted">#{{ $mov['id'] }}</td>
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
                                    <td>
                                        <div style="max-width: 300px;" title="{{ $mov['concepto'] }}">
                                            {{ $mov['concepto'] }}
                                        </div>
                                    </td>
                                    <td class="small text-muted">{{ $mov['proveedor_nombre'] ?? '—' }}</td>
                                    <td class="text-end fw-semibold">
                                        ${{ number_format($mov['monto'], 2) }}
                                    </td>
                                    <td>
                                        <span class="badge text-bg-light">
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
                                    <td class="small">{{ $mov['creado_por'] ?? 'Sistema' }}</td>
                                    <td class="text-center">
                                        @if($mov['estatus'] === 'APROBADO')
                                            <span class="badge text-bg-success">Aprobado</span>
                                        @elseif($mov['estatus'] === 'POR_APROBAR')
                                            <span class="badge text-bg-warning">Por aprobar</span>
                                        @else
                                            <span class="badge text-bg-danger">Rechazado</span>
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="10" class="text-center text-muted py-4">
                                        No hay movimientos registrados en este fondo.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                        <tfoot class="table-light">
                            <tr>
                                <td colspan="5" class="text-end fw-bold">TOTAL:</td>
                                <td class="text-end fw-bold">${{ number_format($movimientos->sum('monto'), 2) }}</td>
                                <td colspan="4"></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        </div>
    </div>

    {{-- Modal de confirmación --}}
    @if($showConfirmModal)
        <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-triangle-exclamation text-warning me-2"></i>
                            Confirmar arqueo
                        </h5>
                        <button type="button" class="btn-close" wire:click="closeConfirm"></button>
                    </div>
                    <div class="modal-body">
                        <p class="mb-2">
                            ¿Confirmas que el efectivo contado físicamente es <strong>${{ number_format($efectivoContado, 2) }}</strong>?
                        </p>
                        @if(abs($diferencia) > 0.01)
                            <div class="alert alert-warning mb-0">
                                <strong>Atención:</strong> Existe una diferencia de
                                <strong>${{ number_format(abs($diferencia), 2) }}</strong>
                                {{ $diferencia > 0 ? '(a favor)' : '(faltante)' }}.
                                El fondo pasará a revisión de gerencia.
                            </div>
                        @else
                            <div class="alert alert-success mb-0">
                                <i class="fa-solid fa-circle-check me-1"></i>
                                El fondo cuadra perfectamente. Se cerrará automáticamente.
                            </div>
                        @endif
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-outline-secondary" wire:click="closeConfirm">Cancelar</button>
                        <button class="btn btn-success" wire:click="guardarArqueo" {{ $loading ? 'disabled' : '' }}>
                            @if($loading)
                                <span class="spinner-border spinner-border-sm me-1"></span>
                                Guardando...
                            @else
                                <i class="fa-solid fa-check me-1"></i>
                                Confirmar y cerrar
                            @endif
                        </button>
                    </div>
                </div>
            </div>
        </div>
        <div class="modal-backdrop fade show"></div>
    @endif
</div>
