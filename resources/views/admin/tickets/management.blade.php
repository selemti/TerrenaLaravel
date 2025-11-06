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

    {{-- Cierre Masivo --}}
    <div class="card border-0 shadow-sm mb-4 full-width-card border-primary">
        <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
            <h5 class="mb-0">
                <i class="fa-solid fa-bolt me-2"></i>
                Cierre Masivo de Tickets
            </h5>
            <span class="badge bg-warning text-dark">Acción Masiva</span>
        </div>
        <div class="card-body">
            <div class="alert alert-info mb-4">
                <i class="fa-solid fa-info-circle me-2"></i>
                <strong>¿Qué hace esta herramienta?</strong><br>
                Cierra automáticamente tickets con monto > 0 y deuda = 0 (típicamente descuentos no cerrados).
                Se recomienda cerrar primero tickets >30 días. Se crea un backup automático antes de ejecutar.
            </div>

            <div class="row g-3 align-items-end">
                <div class="col-md-3">
                    <label class="form-label">Días Mínimos de Antigüedad</label>
                    <input type="number" class="form-control" id="minDays" value="30" min="7" max="365">
                    <small class="text-muted">Mínimo 7 días (recomendado: 30)</small>
                </div>
                <div class="col-md-4">
                    <button type="button" class="btn btn-outline-primary" onclick="previewMassiveClose()">
                        <i class="fa-solid fa-eye me-1"></i> Vista Previa
                    </button>
                    <button type="button" class="btn btn-danger" onclick="showExecuteConfirmation()" id="btnExecuteMassive" disabled>
                        <i class="fa-solid fa-bolt me-1"></i> Ejecutar Cierre Masivo
                    </button>
                </div>
                <div class="col-md-5">
                    <div id="previewResults"></div>
                </div>
            </div>

            <div id="previewDetails" class="mt-4" style="display: none;">
                <h6 class="text-primary">Muestra de Tickets a Cerrar</h6>
                <div class="table-responsive">
                    <table class="table table-sm table-bordered" id="previewTable">
                        <thead class="table-light">
                            <tr>
                                <th>ID</th>
                                <th>Fecha Creación</th>
                                <th>Días</th>
                                <th>Terminal</th>
                                <th class="text-end">Monto</th>
                            </tr>
                        </thead>
                        <tbody id="previewTableBody"></tbody>
                    </table>
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
                                        @endphp
                                        <span class="badge {{ $badgeClass }} badge-tipo">{{ $badgeText }}</span>
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
                                        <div class="btn-group btn-group-sm" role="group">
                                            {{-- Anular (excepto tickets ya pagados y cerrados) --}}
                                            @if($ticket->tipo_problema !== 'pagado_sin_cierre' && $ticket->tipo_problema !== 'cerrado_con_descuento_100')
                                                <button type="button" class="btn btn-outline-danger"
                                                        onclick="voidTicket({{ $ticket->id }})"
                                                        title="Anular ticket">
                                                    <i class="fa-solid fa-ban"></i>
                                                </button>
                                            @endif

                                            {{-- Cerrar (solo para pagados sin cierre) --}}
                                            @if($ticket->tipo_problema === 'pagado_sin_cierre')
                                                <button type="button" class="btn btn-outline-success"
                                                        onclick="closeTicket({{ $ticket->id }})"
                                                        title="Cerrar ticket">
                                                    <i class="fa-solid fa-check"></i>
                                                </button>
                                            @endif

                                            {{-- Marcar como pagado (solo para cerrados sin pago con transacciones) --}}
                                            @if($ticket->tipo_problema === 'cerrado_sin_pago' && $ticket->num_transacciones > 0)
                                                <button type="button" class="btn btn-outline-primary"
                                                        onclick="markAsPaid({{ $ticket->id }})"
                                                        title="Marcar como pagado">
                                                    <i class="fa-solid fa-dollar-sign"></i>
                                                </button>
                                            @endif

                                            {{-- Reabrir (solo para cerrados sin pago sin transacciones) --}}
                                            @if($ticket->tipo_problema === 'cerrado_sin_pago' && $ticket->num_transacciones == 0)
                                                <button type="button" class="btn btn-outline-warning"
                                                        onclick="reopenTicket({{ $ticket->id }})"
                                                        title="Reabrir ticket">
                                                    <i class="fa-solid fa-rotate-left"></i>
                                                </button>
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
                                <option value="Error en captura">Error en captura</option>
                                <option value="Cliente no se presentó">Cliente no se presentó</option>
                                <option value="Producto no disponible">Producto no disponible</option>
                                <option value="Fallo en preparación">Fallo en preparación</option>
                                <option value="Devolución de cliente">Devolución de cliente</option>
                                <option value="Fallo en sistema">Fallo en sistema</option>
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
    
    // Función para cerrar directamente tickets con descuento 100% - sin confirmación ni razón
    async function closeTicketDirect(ticketId) {
        if (confirm(`¿Está seguro que desea CERRAR el ticket #${ticketId} con descuento 100%?\n\nEste ticket ya tiene monto total de $0.`)) {
            // Primero obtener el nombre del descuento
            try {
                const response = await fetch(`{{ url('/api/caja/ticket') }}/${ticketId}`, {
                    headers: {
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}'
                    }
                });

                if (response.ok) {
                    const ticketData = await response.json();
                    const ticket = ticketData.ticket || {};
                    let discountReason = 'Cierre por descuento 100%';
                    
                    // Obtener el nombre del descuento aplicado
                    if (ticket.discounts && ticket.discounts.length > 0) {
                        const firstDiscount = ticket.discounts[0];
                        discountReason = `${firstDiscount.name || firstDiscount.descripcion || 'Descuento'} - Cierre automático`;
                    } else if (ticket.total_discount > 0) {
                        discountReason = `Descuento Aplicado - Cierre automático`;
                    }
                    
                    // Ejecutar el cierre con la razón del descuento
                    executeActionWithReason('{{ route("admin.tickets.close") }}', { 
                        ticket_id: ticketId 
                    }, ticketId, discountReason);
                } else {
                    // Si no se puede obtener el descuento, usar el cierre normal
                    executeAction('{{ route("admin.tickets.close") }}', { ticket_id: ticketId }, ticketId);
                }
            } catch (error) {
                console.error('Error obteniendo información del descuento:', error);
                // Si falla, usar el cierre normal
                executeAction('{{ route("admin.tickets.close") }}', { ticket_id: ticketId }, ticketId);
            }
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

    // Función para preparar la acción de marcar como pagado
    function prepareMarkAsPaid(ticketId) {
        currentTicketId = ticketId;
        currentAction = 'mark-paid';
        
        document.getElementById('actionDescription').textContent = `¿Está seguro que desea marcar como PAGADO el ticket #${ticketId}?\n\nEsto verificará que las transacciones cubran el monto total.`;
        document.getElementById('ticketActionModalLabel').textContent = 'Marcar como Pagado';
        document.getElementById('confirmActionBtn').textContent = 'Marcar Pagado';
        
        // Resetear el formulario
        document.getElementById('ticketActionReason').value = '';
        document.getElementById('otherReasonInput').classList.add('d-none');
        document.getElementById('otherReasonInput').value = '';
        
        const modal = new bootstrap.Modal(document.getElementById('ticketActionModal'));
        modal.show();
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

        // Ejecutar la acción correspondiente
        switch(currentAction) {
            case 'void':
                executeAction('{{ route("admin.tickets.void") }}', { ticket_id: currentTicketId, reason: finalReason }, currentTicketId);
                break;
            case 'close':
                executeAction('{{ route("admin.tickets.close") }}', { ticket_id: currentTicketId }, currentTicketId);
                break;
            case 'mark-paid':
                executeAction('{{ route("admin.tickets.mark-paid") }}', { ticket_id: currentTicketId }, currentTicketId);
                break;
            case 'reopen':
                executeAction('{{ route("admin.tickets.reopen") }}', { ticket_id: currentTicketId, reason: finalReason }, currentTicketId);
                break;
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

    // Función para marcar como pagado
    function markAsPaid(ticketId) {
        prepareMarkAsPaid(ticketId);
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
    
    // Función para mostrar mensajes usando el modal de información existente
    function showMessage(title, message, type) {
        // Actualizar el contenido del modal actual
        document.getElementById('actionDescription').innerHTML = `
            <div class="alert alert-${type} mb-3">
                <i class="fa-solid fa-${type === 'success' ? 'check-circle' : 'exclamation-triangle'} me-2"></i>
                <strong>${title}:</strong> ${message}
            </div>
        `;
        document.getElementById('ticketActionModalLabel').textContent = title;
        document.getElementById('confirmActionBtn').style.display = 'none';
        
        // Mostrar el modal
        const modal = new bootstrap.Modal(document.getElementById('ticketActionModal'));
        modal.show();
        
        // Cerrar el modal después de 3 segundos si es éxito
        if (type === 'success') {
            setTimeout(() => {
                modal.hide();
            }, 3000);
        }
        
        // Evento para restablecer el botón cuando se oculta el modal
        document.getElementById('ticketActionModal').addEventListener('hidden.bs.modal', function () {
            document.getElementById('confirmActionBtn').style.display = 'block';
        }, { once: true }); // Usar 'once' para que se ejecute solo una vez
    }

    // ========== CIERRE MASIVO ==========

    // Función para obtener vista previa del cierre masivo
    async function previewMassiveClose() {
        const minDays = parseInt(document.getElementById('minDays').value);

        if (minDays < 7) {
            alert('El número mínimo de días debe ser al menos 7');
            return;
        }

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
                const stats = result.stats;

                // Mostrar resumen en la columna de resultados
                const previewHtml = `
                    <div class="alert alert-${stats.cantidad > 0 ? 'warning' : 'success'} mb-0">
                        <strong>Vista Previa:</strong><br>
                        <i class="fa-solid fa-ticket me-1"></i> ${stats.cantidad || 0} tickets<br>
                        <i class="fa-solid fa-dollar-sign me-1"></i> ${formatMoney(stats.monto_total)}<br>
                        <small>Rango: ${stats.fecha_mas_antigua || 'N/A'} a ${stats.fecha_mas_reciente || 'N/A'}</small>
                    </div>
                `;
                document.getElementById('previewResults').innerHTML = previewHtml;

                // Habilitar botón de ejecución si hay tickets
                document.getElementById('btnExecuteMassive').disabled = stats.cantidad === 0;

                // Mostrar muestra de tickets
                if (result.sample && result.sample.length > 0) {
                    let tableHtml = '';
                    result.sample.forEach(ticket => {
                        tableHtml += `
                            <tr>
                                <td class="font-monospace">#${ticket.id}</td>
                                <td>${ticket.create_date ? new Date(ticket.create_date).toLocaleDateString() : 'N/A'}</td>
                                <td>${ticket.dias || 0} días</td>
                                <td class="font-monospace">${ticket.terminal_id || 'N/A'}</td>
                                <td class="text-end">${formatMoney(ticket.total_price)}</td>
                            </tr>
                        `;
                    });
                    document.getElementById('previewTableBody').innerHTML = tableHtml;
                    document.getElementById('previewDetails').style.display = 'block';
                } else {
                    document.getElementById('previewDetails').style.display = 'none';
                }
            } else {
                alert('Error al obtener vista previa: ' + (result.message || 'Error desconocido'));
            }
        } catch (error) {
            console.error('Error:', error);
            alert('Error al obtener vista previa: ' + error.message);
        }
    }

    // Función para mostrar modal de confirmación de ejecución
    function showExecuteConfirmation() {
        const minDays = parseInt(document.getElementById('minDays').value);

        const confirmation = prompt(
            `⚠️ ADVERTENCIA: Esta acción cerrará MASIVAMENTE todos los tickets con más de ${minDays} días.\n\n` +
            `Se creará un backup automático antes de ejecutar.\n\n` +
            `Para confirmar, escriba exactamente: CERRAR MASIVO`
        );

        if (confirmation === 'CERRAR MASIVO') {
            executeMassiveClose(minDays);
        } else if (confirmation !== null) {
            alert('Confirmación incorrecta. Debe escribir exactamente "CERRAR MASIVO"');
        }
    }

    // Función para ejecutar el cierre masivo
    async function executeMassiveClose(minDays) {
        try {
            // Deshabilitar botón mientras se ejecuta
            const btn = document.getElementById('btnExecuteMassive');
            btn.disabled = true;
            btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin me-1"></i> Ejecutando...';

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

            if (result.ok) {
                alert(`✅ ÉXITO\n\n${result.message}\n\nTickets cerrados: ${result.affected || 0}`);
                // Recargar la página para mostrar los cambios
                location.reload();
            } else {
                alert('❌ ERROR\n\n' + result.message);
                btn.disabled = false;
                btn.innerHTML = '<i class="fa-solid fa-bolt me-1"></i> Ejecutar Cierre Masivo';
            }
        } catch (error) {
            console.error('Error:', error);
            alert('❌ ERROR\n\nError al ejecutar el cierre masivo: ' + error.message);

            const btn = document.getElementById('btnExecuteMassive');
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-bolt me-1"></i> Ejecutar Cierre Masivo';
        }
    }
</script>
@endpush
@endsection
