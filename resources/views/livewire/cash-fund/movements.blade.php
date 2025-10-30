<div class="py-3">
    {{-- Header del fondo --}}
    <div class="card shadow-sm mb-3">
        <div class="card-body">
            <div class="row align-items-center">
                <div class="col-lg-8">
                    <div class="d-flex align-items-center gap-3">
                        <div class="bg-success bg-opacity-10 p-3 rounded">
                            <i class="fa-solid fa-wallet text-success fs-3"></i>
                        </div>
                        <div>
                            <h5 class="mb-1 fw-bold">Fondo #{{ $fondo['id'] }} - {{ $fondo['sucursal_nombre'] }}</h5>
                            <div class="d-flex gap-3 small text-muted">
                                <span><i class="fa-regular fa-calendar me-1"></i>{{ \Carbon\Carbon::parse($fondo['fecha'])->format('d/m/Y') }}</span>
                                <span><i class="fa-solid fa-coins me-1"></i>Inicial: ${{ number_format($fondo['monto_inicial'], 2) }} {{ $fondo['moneda'] }}</span>
                                <span>
                                    @if($fondo['estado'] === 'ABIERTO')
                                        <span class="badge text-bg-success"><i class="fa-solid fa-unlock me-1"></i>ABIERTO</span>
                                    @elseif($fondo['estado'] === 'EN_REVISION')
                                        <span class="badge text-bg-warning"><i class="fa-solid fa-eye me-1"></i>EN REVISIÓN</span>
                                    @else
                                        <span class="badge text-bg-secondary"><i class="fa-solid fa-lock me-1"></i>CERRADO</span>
                                    @endif
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4 text-lg-end mt-3 mt-lg-0">
                    <button class="btn btn-primary" wire:click="openMovForm" {{ $fondo['estado'] !== 'ABIERTO' ? 'disabled' : '' }}>
                        <i class="fa-solid fa-plus me-1"></i>
                        Nuevo movimiento
                    </button>
                </div>
            </div>

            {{-- Barra de progreso --}}
            <div class="mt-3">
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <span class="small fw-semibold">Uso del fondo</span>
                    <span class="small text-muted">{{ number_format($porcentajeEgresado, 1) }}% egresado</span>
                </div>
                <div class="progress" style="height: 24px;">
                    <div class="progress-bar {{ $porcentajeEgresado > 90 ? 'bg-danger' : ($porcentajeEgresado > 70 ? 'bg-warning' : 'bg-success') }}"
                         role="progressbar"
                         style="width: {{ $porcentajeEgresado }}%"
                         aria-valuenow="{{ $porcentajeEgresado }}"
                         aria-valuemin="0"
                         aria-valuemax="100">
                        ${{ number_format($totalEgresos, 2) }}
                    </div>
                </div>
                <div class="d-flex justify-content-between mt-2 small">
                    <span class="text-danger"><i class="fa-solid fa-arrow-down me-1"></i>Egresos: ${{ number_format($totalEgresos, 2) }}</span>
                    @if($totalReintegros > 0)
                        <span class="text-success"><i class="fa-solid fa-arrow-up me-1"></i>Reintegros: ${{ number_format($totalReintegros, 2) }}</span>
                    @endif
                    <span class="fw-bold"><i class="fa-solid fa-wallet me-1"></i>Disponible: ${{ number_format($saldoDisponible, 2) }}</span>
                </div>
            </div>

            {{-- Semáforo de comprobación --}}
            @php
                $totalMovs = count($movimientos);
                $movsConComprobante = collect($movimientos)->where('tiene_comprobante', true)->count();
                $movsSinComprobante = $totalMovs - $movsConComprobante;
                $porcentajeComprobacion = $totalMovs > 0 ? ($movsConComprobante / $totalMovs) * 100 : 100;
            @endphp
            @if($movsSinComprobante > 0)
                <div class="alert alert-warning d-flex align-items-center mt-3 mb-0">
                    <i class="fa-solid fa-triangle-exclamation me-2"></i>
                    <span>{{ $movsSinComprobante }} movimiento(s) sin comprobante adjunto</span>
                </div>
            @endif
        </div>
    </div>

    {{-- Tabla de movimientos --}}
    <div class="card shadow-sm">
        <div class="card-header bg-white border-bottom">
            <h6 class="mb-0 fw-bold">
                <i class="fa-solid fa-list me-2"></i>
                Movimientos registrados ({{ count($movimientos) }})
            </h6>
        </div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th style="width: 4%;">#</th>
                        <th style="width: 10%;">Fecha/Hora</th>
                        <th style="width: 9%;">Tipo</th>
                        <th style="width: 20%;">Concepto</th>
                        <th style="width: 10%;">Proveedor</th>
                        <th style="width: 8%;" class="text-end">Monto</th>
                        <th style="width: 7%;">Método</th>
                        <th style="width: 7%;" class="text-center">Comprobante</th>
                        <th style="width: 9%;">Usuario</th>
                        <th style="width: 16%;" class="text-end">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($movimientos as $mov)
                        <tr>
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
                                <div class="text-truncate" style="max-width: 300px;" title="{{ $mov['concepto'] }}">
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
                                    <i class="fa-solid fa-circle-check text-success" title="Con comprobante"></i>
                                @else
                                    @if($mov['estatus'] === 'POR_APROBAR')
                                        <i class="fa-solid fa-clock text-warning" title="Pendiente de aprobación"></i>
                                    @else
                                        <i class="fa-solid fa-circle-xmark text-danger" title="Sin comprobante"></i>
                                    @endif
                                @endif
                            </td>
                            <td class="small">{{ $mov['creado_por'] ?? 'Sistema' }}</td>
                            <td class="text-end">
                                <div class="btn-group btn-group-sm" role="group">
                                    {{-- Editar --}}
                                    @if($fondo['estado'] === 'ABIERTO')
                                        <button wire:click="editMovement({{ $mov['id'] }})"
                                                class="btn btn-outline-primary"
                                                title="Editar movimiento">
                                            <i class="fa-solid fa-edit"></i>
                                        </button>
                                    @endif

                                    {{-- Adjuntar comprobante --}}
                                    @if(!$mov['tiene_comprobante'] && $fondo['estado'] === 'ABIERTO')
                                        <button wire:click="openAttachmentModal({{ $mov['id'] }})"
                                                class="btn btn-outline-warning"
                                                title="Adjuntar comprobante">
                                            <i class="fa-solid fa-paperclip"></i>
                                        </button>
                                    @endif

                                    {{-- Ver comprobante --}}
                                    @if($mov['tiene_comprobante'])
                                        <a href="{{ asset('storage/' . $mov['adjunto_path']) }}"
                                           target="_blank"
                                           class="btn btn-outline-success"
                                           title="Ver comprobante">
                                            <i class="fa-solid fa-eye"></i>
                                        </a>
                                    @endif

                                    {{-- Historial --}}
                                    <button wire:click="showAuditHistory({{ $mov['id'] }})"
                                            class="btn btn-outline-secondary"
                                            title="Ver historial de cambios">
                                        <i class="fa-solid fa-history"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="10" class="text-center text-muted py-4">
                                No hay movimientos registrados. Usa el botón "Nuevo movimiento".
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div class="card-footer bg-light d-flex justify-content-end">
            <button class="btn btn-success" wire:click="irArqueo" {{ $fondo['estado'] !== 'ABIERTO' ? 'disabled' : '' }}>
                <i class="fa-solid fa-calculator me-1"></i>
                Ir a arqueo y cierre
            </button>
        </div>
    </div>

    {{-- Modal: Nuevo movimiento --}}
    @if($showMovForm)
        <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            @if($editingMovementId)
                                <i class="fa-solid fa-edit me-2"></i>
                                Editar movimiento #{{ $editingMovementId }}
                            @else
                                <i class="fa-solid fa-plus-circle me-2"></i>
                                Registrar movimiento
                            @endif
                        </h5>
                        <button type="button" class="btn-close" wire:click="closeMovForm"></button>
                    </div>
                    <div class="modal-body">
                        <form wire:submit.prevent="saveMov">
                            <div class="row g-3">
                                {{-- Tipo --}}
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Tipo <span class="text-danger">*</span></label>
                                    <select class="form-select @error('movForm.tipo') is-invalid @enderror"
                                            wire:model.defer="movForm.tipo">
                                        <option value="EGRESO">Egreso</option>
                                        <option value="REINTEGRO">Reintegro</option>
                                        <option value="DEPOSITO">Depósito</option>
                                    </select>
                                    @error('movForm.tipo') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                </div>

                                {{-- Método --}}
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Método <span class="text-danger">*</span></label>
                                    <select class="form-select @error('movForm.metodo') is-invalid @enderror"
                                            wire:model.defer="movForm.metodo">
                                        <option value="EFECTIVO">Efectivo</option>
                                        <option value="TRANSFER">Transferencia</option>
                                    </select>
                                    @error('movForm.metodo') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                </div>

                                {{-- Monto --}}
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Monto <span class="text-danger">*</span></label>
                                    <div class="input-group">
                                        <span class="input-group-text">$</span>
                                        <input type="number" step="0.01"
                                               class="form-control @error('movForm.monto') is-invalid @enderror"
                                               wire:model.defer="movForm.monto"
                                               placeholder="0.00">
                                        @error('movForm.monto') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                    </div>
                                </div>

                                {{-- Concepto --}}
                                <div class="col-12">
                                    <label class="form-label fw-semibold">Concepto <span class="text-danger">*</span></label>
                                    <textarea class="form-control @error('movForm.concepto') is-invalid @enderror"
                                              wire:model.defer="movForm.concepto"
                                              rows="2"
                                              placeholder="Describe el motivo del movimiento"></textarea>
                                    @error('movForm.concepto') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                </div>

                                {{-- Proveedor --}}
                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">Proveedor (opcional)</label>
                                    <select class="form-select @error('movForm.proveedor_id') is-invalid @enderror"
                                            wire:model.defer="movForm.proveedor_id">
                                        <option value="">-- Ninguno --</option>
                                        @foreach($proveedores as $prov)
                                            <option value="{{ $prov['id'] }}">{{ $prov['nombre'] }}</option>
                                        @endforeach
                                    </select>
                                    @error('movForm.proveedor_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                </div>

                                {{-- Adjunto --}}
                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">Comprobante (opcional)</label>
                                    <input type="file"
                                           class="form-control @error('adjunto') is-invalid @enderror"
                                           wire:model="adjunto"
                                           accept="image/*,application/pdf">
                                    @error('adjunto') <div class="invalid-feedback">{{ $message }}</div> @enderror
                                    <small class="text-muted">JPG, PNG o PDF (máx. 5MB)</small>
                                </div>

                                {{-- Switch: requiere comprobante --}}
                                <div class="col-12">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox"
                                               id="requiereComprobanteSwitch"
                                               wire:model.defer="movForm.requiere_comprobante">
                                        <label class="form-check-label" for="requiereComprobanteSwitch">
                                            <i class="fa-solid fa-exclamation-triangle text-warning me-1"></i>
                                            Requiere aprobación (sin comprobante)
                                        </label>
                                    </div>
                                    <small class="text-muted">
                                        Marca esta opción si el egreso no tiene comprobante y necesita autorización de gerencia
                                    </small>
                                </div>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-outline-secondary" wire:click="closeMovForm">Cancelar</button>
                        <button class="btn btn-success" wire:click="saveMov" {{ $loading ? 'disabled' : '' }}>
                            @if($loading)
                                <span class="spinner-border spinner-border-sm me-1"></span>
                                Guardando...
                            @else
                                <i class="fa-solid fa-floppy-disk me-1"></i>
                                Guardar movimiento
                            @endif
                        </button>
                    </div>
                </div>
            </div>
        </div>
        <div class="modal-backdrop fade show"></div>
    @endif

    {{-- Modal: Adjuntar comprobante --}}
    @if($showAttachmentModal)
        <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-paperclip me-2"></i>
                            Adjuntar comprobante
                        </h5>
                        <button type="button" class="btn-close" wire:click="closeAttachmentModal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Seleccionar archivo</label>
                            <input type="file"
                                   class="form-control @error('adjunto') is-invalid @enderror"
                                   wire:model="adjunto"
                                   accept="image/*,application/pdf">
                            @error('adjunto') <div class="invalid-feedback">{{ $message }}</div> @enderror
                            <small class="text-muted">JPG, PNG o PDF (máx. 5MB)</small>
                        </div>

                        @if($adjunto)
                            <div class="alert alert-info">
                                <i class="fa-solid fa-file me-2"></i>
                                Archivo seleccionado: {{ $adjunto->getClientOriginalName() }}
                            </div>
                        @endif
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-outline-secondary" wire:click="closeAttachmentModal">Cancelar</button>
                        <button class="btn btn-primary" wire:click="attachFile" {{ $loading ? 'disabled' : '' }}>
                            @if($loading)
                                <span class="spinner-border spinner-border-sm me-1"></span>
                                Subiendo...
                            @else
                                <i class="fa-solid fa-upload me-1"></i>
                                Subir archivo
                            @endif
                        </button>
                    </div>
                </div>
            </div>
        </div>
        <div class="modal-backdrop fade show"></div>
    @endif

    {{-- Modal: Historial de auditoría --}}
    @if($showAuditModal)
        <div class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fa-solid fa-history me-2"></i>
                            Historial de cambios - Movimiento #{{ $auditMovementId }}
                        </h5>
                        <button type="button" class="btn-close" wire:click="closeAuditModal"></button>
                    </div>
                    <div class="modal-body">
                        @if(count($auditHistory) > 0)
                            <div class="table-responsive">
                                <table class="table table-sm table-hover">
                                    <thead class="table-light">
                                        <tr>
                                            <th>Fecha/Hora</th>
                                            <th>Acción</th>
                                            <th>Campo</th>
                                            <th>Valor Anterior</th>
                                            <th>Valor Nuevo</th>
                                            <th>Usuario</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @foreach($auditHistory as $log)
                                            <tr>
                                                <td class="small">{{ $log['created_at'] }}</td>
                                                <td>
                                                    @if($log['action'] === 'CREATED')
                                                        <span class="badge text-bg-success">Creado</span>
                                                    @elseif($log['action'] === 'UPDATED')
                                                        <span class="badge text-bg-warning">Modificado</span>
                                                    @elseif($log['action'] === 'DELETED')
                                                        <span class="badge text-bg-danger">Eliminado</span>
                                                    @elseif($log['action'] === 'ATTACHMENT_ADDED')
                                                        <span class="badge text-bg-info">Adjunto agregado</span>
                                                    @elseif($log['action'] === 'ATTACHMENT_REPLACED')
                                                        <span class="badge text-bg-info">Adjunto reemplazado</span>
                                                    @else
                                                        <span class="badge text-bg-secondary">{{ $log['action'] }}</span>
                                                    @endif
                                                </td>
                                                <td class="small">{{ $log['field_changed'] ?? '—' }}</td>
                                                <td class="small text-muted">{{ $log['old_value'] ?? '—' }}</td>
                                                <td class="small fw-semibold">{{ $log['new_value'] ?? '—' }}</td>
                                                <td class="small">{{ $log['changed_by'] }}</td>
                                            </tr>
                                        @endforeach
                                    </tbody>
                                </table>
                            </div>
                        @else
                            <div class="alert alert-info">
                                <i class="fa-solid fa-info-circle me-2"></i>
                                No hay cambios registrados para este movimiento.
                            </div>
                        @endif

                        <div class="mt-3">
                            <small class="text-muted">
                                <i class="fa-solid fa-shield-alt me-1"></i>
                                Este historial muestra todos los cambios realizados al movimiento para fines de auditoría.
                            </small>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" wire:click="closeAuditModal">Cerrar</button>
                    </div>
                </div>
            </div>
        </div>
        <div class="modal-backdrop fade show"></div>
    @endif
</div>
