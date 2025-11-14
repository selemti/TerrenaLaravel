@extends('layouts.terrena', [
    'active' => 'admin',
    'title' => 'Gestión de Tickets Problemáticos',
    'pageTitle' => 'Gestión de Tickets',
])

@php
    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
    $formatDate = fn ($date) => $date ? \Carbon\Carbon::parse($date)->format('d/m/Y H:i') : '-';
@endphp

@section('content')
<style>
    .stat-card {
        transition: transform 0.2s;
    }
    .stat-card:hover {
        transform: translateY(-2px);
    }
    .ticket-row:hover {
        background-color: rgba(37,99,235,0.04);
    }
    .badge-tipo {
        font-size: 0.7rem;
        padding: 0.25rem 0.5rem;
    }
    /* Ajuste para compensar el padding del layout principal */
    .full-width-card {
        margin-left: -1rem;
        margin-right: -1rem;
        border-radius: 0;
    }
    /* Corrección para que los elementos se muestren en bloque y no en fila */
    .row {
        display: flex !important;
        flex-wrap: wrap;
        margin-right: -0.75rem;
        margin-left: -0.75rem;
    }
</style>

<div class="container-xxl px-4">
    {{-- Estadísticas Resumidas --}}
    <div class="row g-3 mb-4">
        <div class="col-md-3 col-6">
            <div class="card stat-card border-0 shadow-sm bg-danger text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-white-50 mb-1">Cerrados sin Pago</h6>
                            <h3 class="mb-0">{{ $stats['cerrado_sin_pago']->cantidad ?? 0 }}</h3>
                            <small>{{ $formatMoney($stats['cerrado_sin_pago']->monto_total ?? 0) }}</small>
                        </div>
                        <i class="fa-solid fa-circle-xmark fa-2x opacity-50"></i>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card stat-card border-0 shadow-sm bg-success text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-white-50 mb-1">Cerrados con Descuento 100%</h6>
                            <h3 class="mb-0">{{ $stats['cerrado_con_descuento_100']->cantidad ?? 0 }}</h3>
                            <small>{{ $formatMoney($stats['cerrado_con_descuento_100']->monto_total ?? 0) }}</small>
                        </div>
                        <i class="fa-solid fa-percent fa-2x opacity-50"></i>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card stat-card border-0 shadow-sm bg-warning text-dark">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-dark-50 mb-1">Abiertos con Deuda</h6>
                            <h3 class="mb-0">{{ $stats['abierto_con_deuda']->cantidad ?? 0 }}</h3>
                            <small>{{ $formatMoney($stats['abierto_con_deuda']->monto_total ?? 0) }}</small>
                        </div>
                        <i class="fa-solid fa-clock fa-2x opacity-50"></i>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card stat-card border-0 shadow-sm bg-secondary text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-white-50 mb-1">Abiertos Vacíos</h6>
                            <h3 class="mb-0">{{ $stats['abierto_vacio']->cantidad ?? 0 }}</h3>
                            <small>{{ $formatMoney($stats['abierto_vacio']->monto_total ?? 0) }}</small>
                        </div>
                        <i class="fa-solid fa-inbox fa-2x opacity-50"></i>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card stat-card border-0 shadow-sm bg-info text-white">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 class="text-white-50 mb-1">Pagados sin Cierre</h6>
                            <h3 class="mb-0">{{ $stats['pagado_sin_cierre']->cantidad ?? 0 }}</h3>
                            <small>{{ $formatMoney($stats['pagado_sin_cierre']->monto_total ?? 0) }}</small>
                        </div>
                        <i class="fa-solid fa-check-circle fa-2x opacity-50"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card border-0 shadow-sm mb-4 full-width-card">
        <div class="card-body">
            <form method="GET" action="{{ route('admin.tickets.management') }}" class="row g-3 align-items-end">
                <div class="col-md-4">
                    <label class="form-label small">Filtrar por Tipo</label>
                    <select name="type" class="form-select" onchange="this.form.submit()">
                        <option value="all" {{ $filterType === 'all' ? 'selected' : '' }}>Todos</option>
                        <option value="cerrado_sin_pago" {{ $filterType === 'cerrado_sin_pago' ? 'selected' : '' }}>Cerrados sin Pago</option>
                        <option value="cerrado_con_descuento_100" {{ $filterType === 'cerrado_con_descuento_100' ? 'selected' : '' }}>Cerrados con Descuento 100%</option>
                        <option value="abierto_con_deuda" {{ $filterType === 'abierto_con_deuda' ? 'selected' : '' }}>Abiertos con Deuda</option>
                        <option value="abierto_vacio" {{ $filterType === 'abierto_vacio' ? 'selected' : '' }}>Abiertos Vacíos</option>
                        <option value="pagado_sin_cierre" {{ $filterType === 'pagado_sin_cierre' ? 'selected' : '' }}>Pagados sin Cierre</option>
                    </select>
                </div>
                <div class="col-md-8 text-end">
                    <button type="button" class="btn btn-outline-primary" onclick="location.reload()">
                        <i class="fa-solid fa-refresh me-1"></i> Actualizar
                    </button>
                    <button type="button" class="btn btn-warning ms-2" onclick="openMassiveCloseWizard()">
                        <i class="fa-solid fa-bolt me-1"></i> Cierre Masivo
                    </button>
                </div>
            </form>
        </div>
    </div>

    {{-- Tabla de Tickets --}}
    <div class="card border-0 shadow-sm full-width-card">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center">
            <h5 class="mb-0">
                <i class="fa-solid fa-list-check me-2"></i>
                Tickets Problemáticos ({{ count($tickets) }})
            </h5>
            <small class="text-muted">Total: {{ $stats['total'] ?? 0 }} tickets problemáticos</small>
        </div>
        <div class="card-body p-0">
            @if(count($tickets) > 0)
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="table-light sticky-top">
                            <tr>
                                <th>ID</th>
                                <th>Tipo Problema</th>
                                <th>Fecha Creación</th>
                                <th>Días</th>
                                <th>Terminal</th>
                                <th>Sucursal</th>
                                <th class="text-end">Monto</th>
                                <th class="text-end">Deuda</th>
                                <th>Items</th>
                                <th class="text-center">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($tickets as $ticket)
                                <tr class="ticket-row" id="ticket-row-{{ $ticket->id }}">
                                    <td class="font-monospace fw-bold">
                                        <a href="javascript:void(0)" class="ticket-detail-link" 
                                           data-ticket-id="{{ $ticket->id }}" 
                                           onclick="showTicketDetail({{ $ticket->id }})"
                                           title="Ver detalle del ticket #{{ $ticket->id }}">
                                           #{{ $ticket->id }}
                                        </a>
                                    </td>
                                    <td>
                                        @php
                                            $badgeClass = match($ticket->tipo_problema) {
                                                'cerrado_sin_pago' => 'bg-danger',
                                                'cerrado_con_descuento_100' => 'bg-success',
                                                'abierto_con_deuda' => 'bg-warning text-dark',
                                                'abierto_vacio' => 'bg-secondary',
                                                'pagado_sin_cierre' => 'bg-info',
                                                default => 'bg-light'
                                            };
                                            $badgeText = match($ticket->tipo_problema) {
                                                'cerrado_sin_pago' => 'Cerrado sin pago',
                                                'cerrado_con_descuento_100' => 'Cerrado con descuento 100%',
                                                'abierto_con_deuda' => 'Abierto con deuda',
                                                'abierto_vacio' => 'Abierto vacío',
                                                'pagado_sin_cierre' => 'Pagado sin cierre',
                                                default => 'Desconocido'
                                            };
                                            // Verificar si es legacy (pre-sistema de sesiones)
                                            $ticketDate = \Carbon\Carbon::parse($ticket->create_date);
                                            $isTicketLegacy = $ticketDate->lt(\Carbon\Carbon::parse('2025-10-01')); // Antes de octubre 2025
                                        @endphp
                                        <span class="badge {{ $badgeClass }} badge-tipo">{{ $badgeText }}</span>
                                        @if($isTicketLegacy)
                                            <span class="badge bg-light text-dark badge-tipo ms-1" title="Ticket anterior al sistema de sesiones">Legacy</span>
                                        @endif
                                    </td>
                                    <td>{{ $formatDate($ticket->create_date) }}</td>
                                    <td>
                                        <span class="{{ $ticket->dias_desde_creacion > 14 ? 'text-danger fw-bold' : '' }}">
                                            {{ $ticket->dias_desde_creacion }} días
                                        </span>
                                    </td>
                                    <td class="font-monospace">{{ $ticket->terminal_id }}</td>
                                    <td>{{ $ticket->branch_key ?? '-' }}</td>
                                    <td class="text-end font-monospace">{{ $formatMoney($ticket->total_price) }}</td>
                                    <td class="text-end font-monospace">{{ $formatMoney($ticket->due_amount) }}</td>
                                    <td class="text-center">{{ $ticket->num_items }}</td>
                                    <td class="text-center">
                                        @php
                                            // Verificar si la sesión del ticket tiene postcorte aprobado
                                            $session = null;
                                            $sesionBloqueada = false;
                                            $isLegacy = false;
                                            try {
                                                $sessionCheck = DB::connection('pgsql')->selectOne("
                                                    SELECT s.id,
                                                           (SELECT COUNT(*) FROM selemti.postcorte p
                                                            WHERE p.sesion_id = s.id AND p.aprobado_en IS NOT NULL) as bloqueado
                                                    FROM selemti.sesion_cajon s
                                                    WHERE s.terminal_id = ?
                                                      AND s.apertura_ts <= ?
                                                      AND (s.cierre_ts IS NULL OR s.cierre_ts >= ?)
                                                    LIMIT 1
                                                ", [$ticket->terminal_id, $ticket->create_date, $ticket->create_date]);

                                                $session = $sessionCheck;
                                                $isLegacy = !$session; // Ticket sin sesión = legacy
                                                $sesionBloqueada = $session && $session->bloqueado > 0;
                                            } catch (\Exception $e) {
                                                $sesionBloqueada = false;
                                                $isLegacy = true; // En caso de error, asumir legacy
                                            }
                                        @endphp
                                        <div class="btn-group btn-group-sm" role="group">
                                            {{-- Anular (excepto tickets ya pagados y cerrados, o si sesión bloqueada) --}}
                                            @if($ticket->tipo_problema !== 'pagado_sin_cierre' && $ticket->tipo_problema !== 'cerrado_con_descuento_100')
                                                @if(!$sesionBloqueada)
                                                    <button type="button" class="btn btn-outline-danger"
                                                            onclick="voidTicket({{ $ticket->id }})"
                                                            title="Anular ticket">
                                                        <i class="fa-solid fa-ban"></i>
                                                    </button>
                                                @else
                                                    <button type="button" class="btn btn-outline-secondary" disabled
                                                            title="Sesión cerrada - No se puede modificar">
                                                        <i class="fa-solid fa-lock"></i>
                                                    </button>
                                                @endif
                                            @endif

                                            {{-- Cerrar (solo para pagados sin cierre) --}}
                                            @if($ticket->tipo_problema === 'pagado_sin_cierre')
                                                <button type="button" class="btn btn-outline-success"
                                                        onclick="closeTicket({{ $ticket->id }})"
                                                        title="Cerrar ticket">
                                                    <i class="fa-solid fa-check"></i>
                                                </button>
                                            @endif

                                            {{-- Mensaje informativo para tickets cerrados sin pago con transacciones --}}
                                            @if($ticket->tipo_problema === 'cerrado_sin_pago' && $ticket->num_transacciones > 0)
                                                <span class="d-inline-block" tabindex="0" data-bs-toggle="tooltip" data-bs-placement="top"
                                                      title="Debe procesarse el pago desde el POS">
                                                    <button type="button" class="btn btn-outline-secondary" disabled style="pointer-events: none;">
                                                        <i class="fa-solid fa-cash-register"></i>
                                                    </button>
                                                </span>
                                            @endif

                                            {{-- Reabrir (solo para cerrados sin pago sin transacciones, y si sesión no bloqueada) --}}
                                            @if($ticket->tipo_problema === 'cerrado_sin_pago' && $ticket->num_transacciones == 0)
                                                @if(!$sesionBloqueada)
                                                    <button type="button" class="btn btn-outline-warning"
                                                            onclick="reopenTicket({{ $ticket->id }})"
                                                            title="Reabrir ticket">
                                                        <i class="fa-solid fa-rotate-left"></i>
                                                    </button>
                                                @else
                                                    <button type="button" class="btn btn-outline-secondary" disabled
                                                            title="Sesión cerrada - No se puede modificar">
                                                        <i class="fa-solid fa-lock"></i>
                                                    </button>
                                                @endif
                                            @endif
                                            
                                            {{-- Cerrar directamente tickets con descuento 100% - no se necesita confirmación ni razón --}}
                                            @if($ticket->tipo_problema === 'cerrado_con_descuento_100')
                                                <button type="button" class="btn btn-outline-success"
                                                        onclick="closeTicketDirect({{ $ticket->id }})"
                                                        title="Cerrar ticket (descuento 100%)">
                                                    <i class="fa-solid fa-check"></i>
                                                </button>
                                            @endif
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @else
                <div class="p-5 text-center text-muted">
                    <i class="fa-solid fa-check-circle fa-3x mb-3 text-success opacity-50"></i>
                    <h5 class="text-muted">No hay tickets problemáticos en este momento</h5>
                    <p class="mb-0">Todos los tickets están correctamente gestionados</p>
                </div>
            @endif
        </div>
    </div>
</div>

<!-- Modal para detalle de ticket -->
<div class="modal fade" id="ticketDetailModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="ticketDetailModalLabel">Detalle del Ticket</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <div class="modal-body">
                <div id="ticketDetailContent">
                    <div class="text-center p-5">
                        <i class="fa-solid fa-spinner fa-spin fa-2x mb-3"></i>
                        <p>Cargando detalle del ticket...</p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
            </div>
        </div>
    </div>
</div>

    <!-- Modal para confirmación y razón de anulación -->
    <div class="modal fade" id="ticketActionModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="ticketActionModalLabel">Confirmar Acción</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                </div>
                <div class="modal-body">
                    <div id="ticketActionContent">
                        <p id="actionDescription">Descripción de la acción</p>
                        <div class="mb-3">
                            <label for="ticketActionReason" class="form-label">Razón:</label>
                            <select class="form-select" id="ticketActionReason">
                                <option value="">Seleccione una razón</option>
                                @foreach($voidReasons as $id => $reason)
                                    <option value="{{ $reason }}">{{ $reason }}</option>
                                @endforeach
                                <option value="Otro">Otro</option>
                            </select>
                            <input type="text" class="form-control mt-2 d-none" id="otherReasonInput" placeholder="Especifique la razón">
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                    <button type="button" class="btn btn-primary" id="confirmActionBtn">Confirmar</button>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modal para mostrar mensajes informativos -->
    <div class="modal fade" id="messageModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="messageModalLabel">Mensaje</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                </div>
                <div class="modal-body">
                    <div id="messageContent"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal de Confirmación de Ejecución -->
    <div class="modal fade" id="confirmExecutionModal" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-danger">
                <div class="modal-header bg-danger text-white py-2">
                    <h6 class="modal-title mb-0">
                        <i class="fa-solid fa-triangle-exclamation me-2"></i>
                        Confirmación Requerida
                    </h6>
                </div>
                <div class="modal-body py-3">
                    <div class="text-center mb-3">
                        <i class="fa-solid fa-circle-exclamation fa-3x text-warning mb-2"></i>
                        <h5 class="text-danger mb-0">⚠️ Acción Irreversible</h5>
                    </div>

                    <div class="alert alert-warning py-2 mb-3">
                        <small><strong>Esta acción:</strong></small>
                        <ul class="mb-0 mt-1 small">
                            <li>Cerrará <strong id="confirmTicketCount">0</strong> tickets (<strong id="confirmMinDays">0</strong>+ días)</li>
                            <li>Cambios permanentes en BD</li>
                            <li>Backup automático incluido</li>
                        </ul>
                    </div>

                    <div class="border border-primary rounded p-3">
                        <label class="form-label fw-bold mb-2 small">
                            Escriba: <span class="text-danger">CERRAR MASIVO</span>
                        </label>
                        <input type="text" class="form-control text-center"
                               id="confirmationInput"
                               placeholder="Escriba aquí..."
                               autocomplete="off">
                        <small class="form-text text-muted d-block mt-1">
                            <i class="fa-solid fa-keyboard me-1"></i>
                            Exactamente como se muestra arriba
                        </small>
                    </div>
                </div>
                <div class="modal-footer py-2">
                    <button type="button" class="btn btn-sm btn-secondary" onclick="cancelConfirmation()">
                        <i class="fa-solid fa-xmark me-1"></i> Cancelar
                    </button>
                    <button type="button" class="btn btn-sm btn-danger" id="btnConfirmExecution" onclick="confirmExecution()" disabled>
                        <i class="fa-solid fa-bolt me-1"></i> Ejecutar
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Wizard para Cierre Masivo -->
    <div class="modal fade" id="massiveCloseModal" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header bg-warning py-2">
                    <div>
                        <h6 class="modal-title mb-0">
                            <i class="fa-solid fa-bolt me-2"></i>
                            <span id="wizardTitle">Cierre Masivo</span>
                        </h6>
                        <small class="text-muted" id="wizardStep" style="font-size: 0.75rem;">Paso 1 de 3</small>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                </div>
                <div class="modal-body py-3" style="min-height: 350px; max-height: 70vh;">
                    <!-- PASO 1: Configuración -->
                    <div id="wizardStep1" style="display: none;">
                        <div class="alert alert-info py-2 mb-3">
                            <small class="d-block mb-1"><strong><i class="fa-solid fa-info-circle me-1"></i> ¿Qué hace?</strong></small>
                            <small>Cierra automáticamente dos tipos de tickets:</small>
                            <ul class="mb-1 mt-1 small ps-3">
                                <li>Pagados sin fecha de cierre (falla del POS)</li>
                                <li>Con descuento 100% (no marcados como pagados)</li>
                            </ul>
                            <div class="mt-2 p-2 bg-white rounded border">
                                <small><i class="fa-solid fa-shield-halved text-warning me-1"></i> <strong>Seguridad:</strong> Backup automático incluido</small>
                            </div>
                        </div>

                        <div class="card border-primary">
                            <div class="card-body py-3">
                                <label class="form-label fw-bold mb-2">
                                    <i class="fa-solid fa-calendar-days me-2"></i>
                                    Antigüedad Mínima (días)
                                </label>
                                <p class="text-muted small mb-2">
                                    Solo tickets con esta antigüedad o más. Recomendado: 30+ días.
                                </p>
                                <input type="number" class="form-control" id="minDaysWizard" value="30" min="7" max="365">
                                <small class="form-text" id="rangeHintWizard">Cargando...</small>
                            </div>
                        </div>
                    </div>

                    <!-- PASO 2: Vista Previa -->
                    <div id="wizardStep2" style="display: none;">
                        <div id="previewContent">
                            <div class="text-center p-5">
                                <i class="fa-solid fa-spinner fa-spin fa-2x mb-3 text-primary"></i>
                                <p>Cargando tickets...</p>
                            </div>
                        </div>
                    </div>

                    <!-- PASO 3: Resultado -->
                    <div id="wizardStep3" style="display: none;">
                        <div id="resultContent" class="text-center p-5">
                            <!-- Se llenará dinámicamente -->
                        </div>
                    </div>
                </div>
                <div class="modal-footer py-2">
                    <button type="button" class="btn btn-sm btn-secondary" id="btnCancel" data-bs-dismiss="modal">Cancelar</button>
                    <button type="button" class="btn btn-sm btn-outline-secondary" id="btnBack" onclick="goToPreviousStep()" style="display: none;">
                        <i class="fa-solid fa-arrow-left me-1"></i> Atrás
                    </button>
                    <button type="button" class="btn btn-sm btn-primary" id="btnNext" onclick="goToNextStep()">
                        Siguiente <i class="fa-solid fa-arrow-right ms-1"></i>
                    </button>
                    <button type="button" class="btn btn-sm btn-danger" id="btnExecute" onclick="executeFromWizard()" style="display: none;">
                        <i class="fa-solid fa-bolt me-1"></i> Ejecutar
                    </button>
                    <button type="button" class="btn btn-sm btn-success" id="btnClose" onclick="closeWizard()" style="display: none;">
                        <i class="fa-solid fa-check me-1"></i> Cerrar
                    </button>
                </div>
            </div>
        </div>
    </div>

@push('scripts')
<script>
    // Función para mostrar el detalle del ticket
    async function showTicketDetail(ticketId) {
        try {
            // Mostrar el modal con el loader
            const modal = new bootstrap.Modal(document.getElementById('ticketDetailModal'));
            document.getElementById('ticketDetailModalLabel').textContent = `Detalle del Ticket #${ticketId}`;
            modal.show();
            
            // Cargar el detalle del ticket desde la API
            const response = await fetch(`{{ url('/api/caja/ticket') }}/${ticketId}`, {
                headers: {
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                }
            });

            if (!response.ok) {
                throw new Error(`Error al cargar el ticket: ${response.status}`);
            }

            const ticketData = await response.json();
            displayTicketDetails(ticketData);
        } catch (error) {
            console.error('Error al cargar el detalle del ticket:', error);
            document.getElementById('ticketDetailContent').innerHTML = `
                <div class="alert alert-danger" role="alert">
                    <i class="fa-solid fa-exclamation-triangle me-2"></i>
                    Error al cargar el detalle del ticket: ${error.message}
                </div>
            `;
        }
    }

    // Función para mostrar los detalles del ticket en el modal
    function displayTicketDetails(data) {
        // Verificar si la respuesta tiene la estructura esperada
        if (!data.ok || !data.ticket) {
            document.getElementById('ticketDetailContent').innerHTML = `
                <div class="alert alert-warning" role="alert">
                    <i class="fa-solid fa-exclamation-triangle me-2"></i>
                    No se pudieron cargar los detalles del ticket o no existen datos.
                </div>
            `;
            return;
        }

        // Extraer el ticket de la respuesta
        const ticket = data.ticket;
        let itemsHtml = '';

        // Detalle de items
        if (ticket.items && ticket.items.length > 0) {
            ticket.items.forEach(item => {
                itemsHtml += `
                    <tr>
                        <td>${item.item_name || item.description || item.name || item.id}</td>
                        <td class="text-center">${item.item_quantity || item.qty || 1}</td>
                        <td class="text-end">${formatMoney(item.item_price)}</td>
                        <td class="text-end">${formatMoney(item.total_price)}</td>
                        <td class="text-end">${formatMoney(item.discount || 0)}</td>
                    </tr>
                `;
            });
        } else {
            itemsHtml = '<tr><td colspan="5" class="text-center">No hay artículos registrados</td></tr>';
        }

        // Construir el HTML del contenido
        const contentHtml = `
            <div class="ticket-detail-container">
                <div class="row mb-4">
                    <div class="col-md-6">
                        <h6>Información General</h6>
                        <table class="table table-sm table-borderless">
                            <tr>
                                <td><strong>ID:</strong></td>
                                <td>${ticket.id}</td>
                            </tr>
                            <tr>
                                <td><strong>Folio Diario:</strong></td>
                                <td>${ticket.daily_folio || 'N/A'}</td>
                            </tr>
                            <tr>
                                <td><strong>Fecha de Creación:</strong></td>
                                <td>${ticket.create_date ? new Date(ticket.create_date).toLocaleString() : 'N/A'}</td>
                            </tr>
                            <tr>
                                <td><strong>Terminal:</strong></td>
                                <td>${ticket.terminal || ticket.terminal_id || 'N/A'}</td>
                            </tr>
                            <tr>
                                <td><strong>Usuario:</strong></td>
                                <td>${ticket.usuario || 'N/A'}</td>
                            </tr>
                        </table>
                    </div>
                    <div class="col-md-6">
                        <h6>Estado y Montos</h6>
                        <table class="table table-sm table-borderless">
                            <tr>
                                <td><strong>Anulado:</strong></td>
                                <td>${ticket.voided ? 'Sí' : 'No'}</td>
                            </tr>
                            ${ticket.voided ? `<tr><td><strong>Razón Anulación:</strong></td><td>${ticket.void_reason || 'N/A'}</td></tr>` : ''}
                            <tr>
                                <td><strong>Subtotal:</strong></td>
                                <td class="text-end">${formatMoney(ticket.sub_total)}</td>
                            </tr>
                            <tr>
                                <td><strong>Descuento Total:</strong></td>
                                <td class="text-end">${formatMoney(ticket.total_discount)}</td>
                            </tr>
                            <tr>
                                <td><strong>Impuestos:</strong></td>
                                <td class="text-end">${formatMoney(ticket.total_tax)}</td>
                            </tr>
                            <tr>
                                <td><strong>Monto Total:</strong></td>
                                <td class="text-end fw-bold">${formatMoney(ticket.total_price)}</td>
                            </tr>
                        </table>
                    </div>
                </div>

                <h6>Artículos del Ticket</h6>
                <div class="table-responsive mb-4">
                    <table class="table table-sm table-bordered">
                        <thead class="table-light">
                            <tr>
                                <th>Descripción</th>
                                <th class="text-center">Cant</th>
                                <th class="text-end">Precio Unitario</th>
                                <th class="text-end">Total</th>
                                <th class="text-end">Descuento</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${itemsHtml}
                        </tbody>
                    </table>
                </div>
            </div>
        `;

        document.getElementById('ticketDetailContent').innerHTML = contentHtml;
    }

    // Función auxiliar para formatear dinero
    function formatMoney(amount) {
        // Validar null, undefined, o valores no numéricos
        if (amount === null || amount === undefined || amount === '') {
            amount = 0;
        }
        if (typeof amount === 'string') {
            amount = parseFloat(amount);
        }
        if (isNaN(amount)) {
            amount = 0;
        }
        return '$' + amount.toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,');
    }

    // Variables para almacenar el ticket y acción actuales
    let currentTicketId = null;
    let currentAction = null;
    
    // Función para preparar la acción de anular ticket
    function prepareVoidTicket(ticketId) {
        currentTicketId = ticketId;
        currentAction = 'void';
        
        document.getElementById('actionDescription').textContent = `¿Está seguro que desea ANULAR el ticket #${ticketId}?`;
        document.getElementById('ticketActionModalLabel').textContent = 'Anular Ticket';
        document.getElementById('confirmActionBtn').textContent = 'Anular Ticket';
        
        // Resetear el formulario
        document.getElementById('ticketActionReason').value = '';
        document.getElementById('otherReasonInput').classList.add('d-none');
        document.getElementById('otherReasonInput').value = '';
        
        const modal = new bootstrap.Modal(document.getElementById('ticketActionModal'));
        modal.show();
    }
    
    // Función para preparar la acción de cerrar ticket
    function prepareCloseTicket(ticketId) {
        currentTicketId = ticketId;
        currentAction = 'close';
        
        document.getElementById('actionDescription').textContent = `¿Está seguro que desea CERRAR el ticket #${ticketId}?`;
        document.getElementById('ticketActionModalLabel').textContent = 'Cerrar Ticket';
        document.getElementById('confirmActionBtn').textContent = 'Cerrar Ticket';
        
        // Resetear el formulario
        document.getElementById('ticketActionReason').value = '';
        document.getElementById('otherReasonInput').classList.add('d-none');
        document.getElementById('otherReasonInput').value = '';
        
        const modal = new bootstrap.Modal(document.getElementById('ticketActionModal'));
        modal.show();
    }
    
    // Función para cerrar directamente tickets con descuento 100% - con modal bonito
    function closeTicketDirect(ticketId) {
        currentTicketId = ticketId;
        currentAction = 'close-discount';

        document.getElementById('actionDescription').innerHTML = `
            <strong>¿Confirma cerrar el ticket #${ticketId}?</strong><br>
            <small class="text-muted">Este ticket tiene descuento del 100% (monto total: $0.00)</small>
        `;
        document.getElementById('ticketActionModalLabel').textContent = 'Cerrar Ticket con Descuento';
        document.getElementById('confirmActionBtn').textContent = 'Cerrar Ticket';

        // NO requerir razón para descuentos 100%
        document.getElementById('ticketActionReason').closest('.mb-3').style.display = 'none';

        const modal = new bootstrap.Modal(document.getElementById('ticketActionModal'));
        modal.show();
    }
    
    // Función para ejecutar cierre con información del descuento
    async function executeCloseWithDiscountInfo(ticketId) {
        try {
            // Obtener información del ticket para el descuento
            const response = await fetch(`{{ url('/api/caja/ticket') }}/${ticketId}`, {
                headers: {
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                }
            });

            let discountReason = 'Descuento 100%';
            if (response.ok) {
                const ticketData = await response.json();
                const ticket = ticketData.ticket || {};

                // Obtener el nombre del descuento aplicado
                if (ticket.discounts && ticket.discounts.length > 0) {
                    const firstDiscount = ticket.discounts[0];
                    discountReason = `${firstDiscount.name || firstDiscount.descripcion || 'Descuento'} - Cierre automático`;
                } else if (ticket.total_discount > 0) {
                    discountReason = `Descuento Aplicado - Cierre automático`;
                }
            }

            // Ejecutar el cierre con la razón del descuento
            executeAction('{{ route("admin.tickets.close") }}', {
                ticket_id: ticketId,
                reason: discountReason
            }, ticketId);
        } catch (error) {
            console.error('Error obteniendo información del descuento:', error);
            // Si falla, usar cierre sin razón específica
            executeAction('{{ route("admin.tickets.close") }}', { ticket_id: ticketId }, ticketId);
        }
    }

    // Función modificada para ejecutar acción con razón específica
    async function executeActionWithReason(url, data, ticketId, reason = null) {
        try {
            const fullData = { ...data };
            if (reason) {
                fullData.reason = reason;  // Ajustar según el formato esperado por el backend
            }

            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(fullData)
            });

            const result = await response.json();

            if (result.ok) {
                // Mostrar mensaje de éxito usando el modal de información
                showMessage('Éxito', result.message, 'success');
                
                // Remover la fila de la tabla
                const row = document.getElementById(`ticket-row-${ticketId}`);
                if (row) {
                    row.style.opacity = '0';
                    row.style.transition = 'opacity 0.5s';
                    setTimeout(() => row.remove(), 500);
                }
                // Recargar después de 1 segundo para actualizar estadísticas
                setTimeout(() => location.reload(), 1000);
            } else {
                // Mostrar error usando el modal de información
                showMessage('Error', result.message, 'danger');
            }
        } catch (error) {
            console.error('Error:', error);
            // Mostrar error usando el modal de información
            showMessage('Error', 'Error al ejecutar la acción: ' + error.message, 'danger');
        }
    }

    // Función para preparar la acción de reabrir ticket
    function prepareReopenTicket(ticketId) {
        currentTicketId = ticketId;
        currentAction = 'reopen';
        
        document.getElementById('actionDescription').textContent = `¿Está seguro que desea REABRIR el ticket #${ticketId}?`;
        document.getElementById('ticketActionModalLabel').textContent = 'Reabrir Ticket';
        document.getElementById('confirmActionBtn').textContent = 'Reabrir Ticket';
        
        // Resetear el formulario
        document.getElementById('ticketActionReason').value = '';
        document.getElementById('otherReasonInput').classList.add('d-none');
        document.getElementById('otherReasonInput').value = '';
        
        const modal = new bootstrap.Modal(document.getElementById('ticketActionModal'));
        modal.show();
    }

    // Función para confirmar la acción
    function confirmAction() {
        const reasonSelect = document.getElementById('ticketActionReason');
        const reason = reasonSelect.value;

        // Para tickets con descuento 100%, NO se requiere razón (se obtiene automáticamente de la BD)
        // Para cierre normal tampoco se requiere razón
        const requiresReason = currentAction !== 'close-discount' && currentAction !== 'close';

        if (requiresReason) {
            // Validar que se haya seleccionado una razón
            if (!reason) {
                alert('Por favor seleccione una razón para la acción.');
                return;
            }

            // Si se selecciona "Otro", mostrar campo de texto
            let finalReason = reason;
            if (reason === 'Otro') {
                const otherInput = document.getElementById('otherReasonInput');
                if (otherInput.classList.contains('d-none')) {
                    otherInput.classList.remove('d-none');
                    otherInput.focus();
                    return; // No continuar, se necesita especificar la razón
                }
                const otherReason = otherInput.value.trim();
                if (!otherReason) {
                    alert('Por favor especifique la razón en el campo de texto.');
                    return;
                }
                finalReason = otherReason;
            }

            // Ejecutar acciones que requieren razón
            switch(currentAction) {
                case 'void':
                    executeAction('{{ route("admin.tickets.void") }}', { ticket_id: currentTicketId, reason: finalReason }, currentTicketId);
                    break;
                case 'reopen':
                    executeAction('{{ route("admin.tickets.reopen") }}', { ticket_id: currentTicketId, reason: finalReason }, currentTicketId);
                    break;
            }
        } else {
            // Ejecutar acciones que NO requieren razón
            switch(currentAction) {
                case 'close':
                    executeAction('{{ route("admin.tickets.close") }}', { ticket_id: currentTicketId }, currentTicketId);
                    break;
                case 'close-discount':
                    // Obtiene automáticamente el nombre del descuento de la BD
                    executeCloseWithDiscountInfo(currentTicketId);
                    break;
            }
        }

        // Cerrar el modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('ticketActionModal'));
        if (modal) {
            modal.hide();
        }
    }

    // Manejar cambio en el select de razón
    document.addEventListener('DOMContentLoaded', function() {
        const reasonSelect = document.getElementById('ticketActionReason');
        const otherInput = document.getElementById('otherReasonInput');
        
        reasonSelect.addEventListener('change', function() {
            if (this.value === 'Otro') {
                otherInput.classList.remove('d-none');
                otherInput.focus();
            } else {
                otherInput.classList.add('d-none');
            }
        });

        // Asociar el botón de confirmación
        document.getElementById('confirmActionBtn').addEventListener('click', confirmAction);
    });

    // Función para anular ticket
    function voidTicket(ticketId) {
        prepareVoidTicket(ticketId);
    }

    // Función para cerrar ticket
    function closeTicket(ticketId) {
        prepareCloseTicket(ticketId);
    }

    // Función para reabrir ticket
    function reopenTicket(ticketId) {
        prepareReopenTicket(ticketId);
    }

    // Función genérica para ejecutar acciones
    async function executeAction(url, data, ticketId) {
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (result.ok) {
                // Mostrar mensaje de éxito usando el modal de información
                showMessage('Éxito', result.message, 'success');
                
                // Remover la fila de la tabla
                const row = document.getElementById(`ticket-row-${ticketId}`);
                if (row) {
                    row.style.opacity = '0';
                    row.style.transition = 'opacity 0.5s';
                    setTimeout(() => row.remove(), 500);
                }
                // Recargar después de 1 segundo para actualizar estadísticas
                setTimeout(() => location.reload(), 1000);
            } else {
                // Mostrar error usando el modal de información
                showMessage('Error', result.message, 'danger');
            }
        } catch (error) {
            console.error('Error:', error);
            // Mostrar error usando el modal de información
            showMessage('Error', 'Error al ejecutar la acción: ' + error.message, 'danger');
        }
    }
    
    // Función para mostrar mensajes usando el modal de información separado
    function showMessage(title, message, type) {
        // Actualizar el contenido del modal de mensajes
        document.getElementById('messageContent').innerHTML = `
            <div class="alert alert-${type}">
                <i class="fa-solid fa-${type === 'success' ? 'check-circle' : 'exclamation-triangle'} me-2"></i>
                <strong>${title}:</strong> ${message}
            </div>
        `;
        document.getElementById('messageModalLabel').textContent = title;
        
        // Mostrar el modal
        const modal = new bootstrap.Modal(document.getElementById('messageModal'));
        modal.show();
        
        // Cerrar el modal después de 3 segundos si es éxito
        if (type === 'success') {
            setTimeout(() => {
                modal.hide();
            }, 3000);
        }
    }

    // ========== CIERRE MASIVO - WIZARD ==========

    // Variables globales
    let ticketsToClose = [];
    let currentWizardStep = 1;
    let rangeData = null;

    // Cargar rango de días disponible al iniciar la página
    document.addEventListener('DOMContentLoaded', async function() {
        try {
            const response = await fetch('{{ route("admin.tickets.massive-close.range") }}', {
                headers: { 'Accept': 'application/json' }
            });
            const result = await response.json();

            if (result.ok && result.range) {
                rangeData = result.range;
            }
        } catch (error) {
            console.error('Error al cargar rango:', error);
        }

        // Los tooltips se inicializan globalmente en terrena.blade.php
    });

    // Abrir wizard
    async function openMassiveCloseWizard() {
        // Resetear wizard
        currentWizardStep = 1;
        ticketsToClose = [];

        // Mostrar modal
        const modal = new bootstrap.Modal(document.getElementById('massiveCloseModal'));
        modal.show();

        // Cargar rango si no está disponible
        if (!rangeData) {
            try {
                const response = await fetch('{{ route("admin.tickets.massive-close.range") }}', {
                    headers: { 'Accept': 'application/json' }
                });
                const result = await response.json();
                if (result.ok && result.range) {
                    rangeData = result.range;
                }
            } catch (error) {
                console.error('Error al cargar rango:', error);
            }
        }

        // Configurar Paso 1
        if (rangeData && rangeData.total_tickets > 0) {
            const minDaysInput = document.getElementById('minDaysWizard');
            const rangeHint = document.getElementById('rangeHintWizard');

            minDaysInput.min = rangeData.dias_minimo || 7;
            minDaysInput.max = rangeData.dias_maximo || 365;
            minDaysInput.value = Math.min(30, rangeData.dias_maximo);
            rangeHint.textContent = `Rango disponible: ${rangeData.dias_minimo}-${rangeData.dias_maximo} días (${rangeData.total_tickets} tickets)`;
            rangeHint.classList.remove('text-danger');
            rangeHint.classList.add('text-success');
        } else {
            const rangeHint = document.getElementById('rangeHintWizard');
            rangeHint.textContent = 'No hay tickets problemáticos disponibles';
            rangeHint.classList.add('text-danger');
            document.getElementById('btnNext').disabled = true;
        }

        showWizardStep(1);
    }

    // Mostrar paso específico del wizard
    function showWizardStep(step) {
        currentWizardStep = step;

        // Ocultar todos los pasos
        document.getElementById('wizardStep1').style.display = 'none';
        document.getElementById('wizardStep2').style.display = 'none';
        document.getElementById('wizardStep3').style.display = 'none';

        // Mostrar paso actual
        document.getElementById(`wizardStep${step}`).style.display = 'block';
        document.getElementById('wizardStep').textContent = `Paso ${step} de 3`;

        // Actualizar botones
        const btnCancel = document.getElementById('btnCancel');
        const btnBack = document.getElementById('btnBack');
        const btnNext = document.getElementById('btnNext');
        const btnExecute = document.getElementById('btnExecute');
        const btnClose = document.getElementById('btnClose');

        // Reset todos los botones
        btnCancel.style.display = 'inline-block';
        btnBack.style.display = 'none';
        btnNext.style.display = 'none';
        btnExecute.style.display = 'none';
        btnClose.style.display = 'none';

        if (step === 1) {
            document.getElementById('wizardTitle').textContent = 'Cierre Masivo - Configuración';
            btnNext.style.display = 'inline-block';
            btnNext.disabled = false;
        } else if (step === 2) {
            document.getElementById('wizardTitle').textContent = 'Cierre Masivo - Vista Previa';
            btnBack.style.display = 'inline-block';
            btnExecute.style.display = 'inline-block';
            btnExecute.disabled = ticketsToClose.length === 0;
        } else if (step === 3) {
            document.getElementById('wizardTitle').textContent = 'Cierre Masivo - Resultado';
            btnCancel.style.display = 'none';
            btnClose.style.display = 'inline-block';
        }
    }

    // Ir al siguiente paso
    async function goToNextStep() {
        if (currentWizardStep === 1) {
            // Validar input
            const minDays = parseInt(document.getElementById('minDaysWizard').value);
            const minInput = parseInt(document.getElementById('minDaysWizard').min);
            const maxInput = parseInt(document.getElementById('minDaysWizard').max);

            if (minDays < minInput || minDays > maxInput) {
                alert(`El número de días debe estar entre ${minInput} y ${maxInput}`);
                return;
            }

            // Ir a paso 2 y cargar tickets
            showWizardStep(2);
            await loadTicketsPreview(minDays);
        }
    }

    // Ir al paso anterior
    function goToPreviousStep() {
        if (currentWizardStep === 2) {
            showWizardStep(1);
        }
    }

    // Cargar vista previa de tickets
    async function loadTicketsPreview(minDays) {
        try {
            const response = await fetch(`{{ route('admin.tickets.massive-close.preview') }}?min_days=${minDays}`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                }
            });

            const result = await response.json();

            if (result.ok && result.stats) {
                ticketsToClose = result.tickets || [];
                displayPreviewInWizard(result.stats, ticketsToClose);
            } else {
                document.getElementById('previewContent').innerHTML = `
                    <div class="alert alert-danger">
                        <i class="fa-solid fa-exclamation-triangle me-2"></i>
                        Error: ${result.message || 'No se pudo obtener la vista previa'}
                    </div>
                `;
            }
        } catch (error) {
            console.error('Error:', error);
            document.getElementById('previewContent').innerHTML = `
                <div class="alert alert-danger">
                    <i class="fa-solid fa-exclamation-triangle me-2"></i>
                    Error al cargar tickets: ${error.message}
                </div>
            `;
        }
    }

    // Mostrar vista previa en el wizard
    function displayPreviewInWizard(stats, tickets) {
        const cantidad = stats.cantidad || 0;

        // Habilitar/deshabilitar botón de ejecución
        document.getElementById('btnExecute').disabled = cantidad === 0;

        if (cantidad === 0) {
            document.getElementById('previewContent').innerHTML = `
                <div class="alert alert-success text-center">
                    <i class="fa-solid fa-check-circle fa-3x mb-3 text-success"></i>
                    <h4>No hay tickets para cerrar</h4>
                    <p>No se encontraron tickets problemáticos con los criterios especificados.</p>
                </div>
            `;
            return;
        }

        // Generar tabla con TODOS los tickets
        let tableRows = '';
        tickets.forEach((ticket, index) => {
            const tipoBadge = ticket.tipo === 'Pagado sin cierre'
                ? '<span class="badge bg-info text-white" style="font-size: 0.7rem;">Pagado</span>'
                : '<span class="badge bg-success" style="font-size: 0.7rem;">Desc. 100%</span>';

            tableRows += `
                <tr>
                    <td class="text-muted">${index + 1}</td>
                    <td class="font-monospace"><strong>#${ticket.id}</strong></td>
                    <td>${tipoBadge}</td>
                    <td>${ticket.create_date ? new Date(ticket.create_date).toLocaleDateString('es-MX', {day: '2-digit', month: '2-digit'}) : 'N/A'}</td>
                    <td class="text-center"><small>${ticket.dias || 0}d</small></td>
                    <td class="font-monospace"><small>${ticket.terminal_id || 'N/A'}</small></td>
                    <td class="text-end">${formatMoney(ticket.total_price)}</td>
                </tr>
            `;
        });

        const contentHtml = `
            <div class="alert alert-warning py-2 mb-3">
                <div class="row text-center g-2">
                    <div class="col-4">
                        <i class="fa-solid fa-ticket text-warning"></i>
                        <div class="fw-bold">${cantidad}</div>
                        <small class="text-muted">Tickets</small>
                    </div>
                    <div class="col-4">
                        <i class="fa-solid fa-dollar-sign text-success"></i>
                        <div class="fw-bold">${formatMoney(stats.monto_total)}</div>
                        <small class="text-muted">Total</small>
                    </div>
                    <div class="col-4">
                        <i class="fa-solid fa-calendar-days text-primary"></i>
                        <div><small><strong>${stats.fecha_mas_antigua || 'N/A'}</strong> a <strong>${stats.fecha_mas_reciente || 'N/A'}</strong></small></div>
                        <small class="text-muted">Rango</small>
                    </div>
                </div>
            </div>

            <div class="mb-2">
                <small class="text-primary fw-bold">
                    <i class="fa-solid fa-list me-1"></i>
                    Tickets a cerrar (${cantidad})
                </small>
            </div>
            <div class="table-responsive" style="max-height: 350px; overflow-y: auto;">
                <table class="table table-sm table-hover table-bordered mb-0" style="font-size: 0.85rem;">
                    <thead class="table-light sticky-top">
                        <tr>
                            <th style="width: 40px;">#</th>
                            <th style="width: 80px;">ID</th>
                            <th style="width: 140px;">Tipo</th>
                            <th>Fecha</th>
                            <th class="text-center" style="width: 70px;">Días</th>
                            <th style="width: 70px;">Term.</th>
                            <th class="text-end" style="width: 80px;">Monto</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${tableRows}
                    </tbody>
                </table>
            </div>
        `;

        document.getElementById('previewContent').innerHTML = contentHtml;
    }

    // Mostrar modal de confirmación
    function executeFromWizard() {
        const minDays = parseInt(document.getElementById('minDaysWizard').value);
        const cantidad = ticketsToClose.length;

        // Actualizar datos en el modal de confirmación
        document.getElementById('confirmTicketCount').textContent = cantidad;
        document.getElementById('confirmMinDays').textContent = minDays;
        document.getElementById('confirmationInput').value = '';
        document.getElementById('btnConfirmExecution').disabled = true;

        // Ocultar el wizard temporalmente
        const wizardModal = bootstrap.Modal.getInstance(document.getElementById('massiveCloseModal'));
        wizardModal.hide();

        // Esperar a que se cierre el wizard antes de abrir el de confirmación
        document.getElementById('massiveCloseModal').addEventListener('hidden.bs.modal', function openConfirmModal() {
            // Mostrar modal de confirmación
            const confirmModal = new bootstrap.Modal(document.getElementById('confirmExecutionModal'));
            confirmModal.show();

            // Focus en el input
            setTimeout(() => {
                document.getElementById('confirmationInput').focus();
            }, 500);

            // Remover el listener para no acumularlo
            document.getElementById('massiveCloseModal').removeEventListener('hidden.bs.modal', openConfirmModal);
        }, { once: true });
    }

    // Validar input de confirmación en tiempo real
    document.addEventListener('DOMContentLoaded', function() {
        const confirmInput = document.getElementById('confirmationInput');
        const btnConfirm = document.getElementById('btnConfirmExecution');

        if (confirmInput) {
            confirmInput.addEventListener('input', function() {
                const value = this.value.trim();
                btnConfirm.disabled = value !== 'CERRAR MASIVO';

                // Feedback visual
                if (value.length > 0) {
                    if (value === 'CERRAR MASIVO') {
                        this.classList.remove('is-invalid');
                        this.classList.add('is-valid');
                    } else {
                        this.classList.remove('is-valid');
                        this.classList.add('is-invalid');
                    }
                } else {
                    this.classList.remove('is-valid', 'is-invalid');
                }
            });

            // Permitir ejecutar con Enter
            confirmInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter' && this.value.trim() === 'CERRAR MASIVO') {
                    confirmExecution();
                }
            });
        }
    });

    // Cancelar confirmación
    function cancelConfirmation() {
        const confirmModal = bootstrap.Modal.getInstance(document.getElementById('confirmExecutionModal'));
        confirmModal.hide();

        // Volver a mostrar el wizard en el paso 2
        document.getElementById('confirmExecutionModal').addEventListener('hidden.bs.modal', function reopenWizard() {
            const wizardModal = new bootstrap.Modal(document.getElementById('massiveCloseModal'));
            wizardModal.show();
            // Remover el listener
            document.getElementById('confirmExecutionModal').removeEventListener('hidden.bs.modal', reopenWizard);
        }, { once: true });
    }

    // Ejecutar tras confirmación
    async function confirmExecution() {
        const minDays = parseInt(document.getElementById('minDaysWizard').value);
        const cantidad = ticketsToClose.length;

        // Cerrar modal de confirmación
        const confirmModal = bootstrap.Modal.getInstance(document.getElementById('confirmExecutionModal'));
        confirmModal.hide();

        // Esperar a que se cierre antes de continuar
        document.getElementById('confirmExecutionModal').addEventListener('hidden.bs.modal', async function executeAfterClose() {
            // Mostrar el wizard de nuevo
            const wizardModal = new bootstrap.Modal(document.getElementById('massiveCloseModal'));
            wizardModal.show();

            // Remover el listener
            document.getElementById('confirmExecutionModal').removeEventListener('hidden.bs.modal', executeAfterClose);

            // Ejecutar el cierre masivo
            await performMassiveClose(minDays, cantidad);
        }, { once: true });
    }

    // Función separada para ejecutar el cierre masivo
    async function performMassiveClose(minDays, cantidad) {

        try {
            // Deshabilitar botón mientras se ejecuta
            const btn = document.getElementById('btnExecute');
            btn.disabled = true;
            btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin me-2"></i> Ejecutando...';

            const response = await fetch(`{{ route('admin.tickets.massive-close.execute') }}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({
                    min_days: minDays,
                    confirmation: 'CERRAR MASIVO'
                })
            });

            const result = await response.json();

            // Ir a paso 3 (resultado)
            showWizardStep(3);

            if (result.ok) {
                showSuccessResult(result.affected || cantidad, result.message);
            } else {
                showErrorResult(result.message || 'Error desconocido');
            }
        } catch (error) {
            console.error('Error:', error);
            showWizardStep(3);
            showErrorResult('Error al ejecutar el cierre masivo: ' + error.message);
        }
    }

    // Mostrar resultado exitoso
    function showSuccessResult(cantidad, message) {
        document.getElementById('resultContent').innerHTML = `
            <div class="text-center py-4">
                <i class="fa-solid fa-circle-check fa-4x mb-3 text-success"></i>
                <h5 class="text-success mb-3">¡Completado Exitosamente!</h5>
                <div class="alert alert-success py-2 mb-3">
                    <div class="fw-bold mb-1"><i class="fa-solid fa-check me-1"></i>${cantidad} tickets cerrados</div>
                    <small>${message}</small>
                </div>
                <small class="text-muted d-block">
                    <i class="fa-solid fa-shield-halved me-1"></i>
                    Backup automático creado
                </small>
            </div>
        `;
    }

    // Mostrar resultado con error
    function showErrorResult(errorMessage) {
        document.getElementById('resultContent').innerHTML = `
            <div class="text-center py-4">
                <i class="fa-solid fa-circle-xmark fa-4x mb-3 text-danger"></i>
                <h5 class="text-danger mb-3">Error en la Operación</h5>
                <div class="alert alert-danger py-2 mb-3">
                    <div class="fw-bold mb-1"><i class="fa-solid fa-exclamation-triangle me-1"></i>Ocurrió un problema</div>
                    <small>${errorMessage}</small>
                </div>
                <small class="text-muted">No se realizaron cambios</small>
            </div>
        `;
    }

    // Cerrar wizard y recargar
    function closeWizard() {
        const modal = bootstrap.Modal.getInstance(document.getElementById('massiveCloseModal'));
        modal.hide();
        location.reload();
    }
</script>
@endpush
@endsection
