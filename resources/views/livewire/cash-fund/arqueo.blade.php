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

            {{-- Resumen de movimientos --}}
            <div class="card shadow-sm mt-3">
                <div class="card-header bg-white">
                    <h6 class="mb-0 fw-bold">
                        <i class="fa-solid fa-list-check me-2"></i>
                        Resumen de movimientos ({{ count($movimientos) }})
                    </h6>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-sm table-hover mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>#</th>
                                    <th>Tipo</th>
                                    <th class="text-end">Monto</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($movimientos as $mov)
                                    <tr>
                                        <td>{{ $mov['id'] }}</td>
                                        <td>
                                            @if($mov['tipo'] === 'EGRESO')
                                                <span class="badge text-bg-danger">Egreso</span>
                                            @else
                                                <span class="badge text-bg-success">{{ $mov['tipo'] }}</span>
                                            @endif
                                        </td>
                                        <td class="text-end">${{ number_format($mov['monto'], 2) }}</td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
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
