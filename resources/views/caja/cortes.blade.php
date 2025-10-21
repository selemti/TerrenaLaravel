@extends('layouts.terrena')
    @includeIf('caja._wizard_modals')
@section('title', 'Administración de cajas')

@section('page-title')
    <div class="d-flex align-items-center justify-content-between mb-2">
        <div class="d-flex align-items-center gap-2">
            <h2 class="mb-0"><i class="fa-solid fa-cash-register me-2"></i> Administración de cajas</h2>
        </div>
    </div>
@endsection

@section('content')

    <div class="dashboard-grid">
		<div class="d-flex align-items-center justify-content-between mb-2">
					<div class="d-flex align-items-center gap-2">
						<h2 class="mb-0">Cajas</h2>
						<span class="badge bg-secondary" id="badgeFecha">{{ $date ?? now()->format('Y-m-d') }}</span>
					</div>
					<div class="d-flex align-items-center gap-2">
						<button id="btnRefrescar" class="btn btn-outline-secondary btn-sm">
							<i class="fa-solid fa-rotate"></i> Refrescar
						</button>
						<!-- Botón global para abrir Wizard (opcional; igual habrá botón por fila) -->
					</div>
				</div>

        {{-- Campo oculto para sincronizar fecha con JavaScript --}}
        <input type="hidden" id="filtroFecha" value="{{ $date ?? now()->format('Y-m-d') }}">

        {{-- KPIs --}}
        <div class="row g-3 mb-3">
            <div class="col-6 col-lg-2">
                <div class="kpi">
                    <div class="kpi-label">🟢 Activas</div>
                    <div class="kpi-value" id="kpiAbiertas">{{ $abiertas ?? 0 }}</div>
                </div>
            </div>
            <div class="col-6 col-lg-2">
                <div class="kpi">
                    <div class="kpi-label">⏸️ Pendientes</div>
                    <div class="kpi-value" id="kpiPendientes">{{ $pendientes ?? 0 }}</div>
                </div>
            </div>
            <div class="col-6 col-lg-2">
                <div class="kpi">
                    <div class="kpi-label">📋 Precortes</div>
                    <div class="kpi-value" id="kpiPrecortes">{{ $precortes ?? 0 }}</div>
                </div>
            </div>
            <div class="col-6 col-lg-2">
                <div class="kpi">
                    <div class="kpi-label">✅ Conciliadas</div>
                    <div class="kpi-value" id="kpiConcil">{{ $conciliadas ?? 0 }}</div>
                </div>
            </div>
            <div class="col-6 col-lg-2">
                <div class="kpi {{ count($anulaciones ?? []) > 0 ? 'kpi-warning' : '' }}">
                    <div class="kpi-label">⚠️ Excepciones</div>
                    <div class="kpi-value" id="kpiAnulaciones">{{ count($anulaciones ?? []) }}</div>
                </div>
            </div>
        </div>

        {{-- Tabs de filtro --}}
        <ul class="nav nav-pills mb-3" id="cajaTabs" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="tab-activas" data-bs-toggle="pill" data-bs-target="#" type="button" role="tab" data-filtro="activas">
                    🟢 Activas <span class="badge bg-success ms-1">{{ $abiertas ?? 0 }}</span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="tab-pendientes" data-bs-toggle="pill" data-bs-target="#" type="button" role="tab" data-filtro="pendientes">
                    ⏸️ Pendientes <span class="badge bg-warning text-dark ms-1">{{ $pendientes ?? 0 }}</span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="tab-conciliadas" data-bs-toggle="pill" data-bs-target="#" type="button" role="tab" data-filtro="conciliadas">
                    ✅ Conciliadas <span class="badge bg-secondary ms-1">{{ $conciliadas ?? 0 }}</span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="tab-todas" data-bs-toggle="pill" data-bs-target="#" type="button" role="tab" data-filtro="todas">
                    Todas
                </button>
            </li>
        </ul>

        {{-- Tabla --}}
        <div class="table-responsive shadow-sm rounded bg-white">
            <table class="table table-sm align-middle mb-0" id="tablaCajas">
                <thead class="table-light">
                    <tr>
                        <th>Sucursal</th>
                        <th>Terminal</th>
                        <th>Cajero</th>
                        <th>Hora Apertura</th>
                        <th>Estado</th>
                        <th class="text-end">Fondo Inicial</th>
                        <th style="width:150px">Acciones</th>
                    </tr>
                </thead>
                <tbody id="tbodyCajas">
                    @forelse($cajas ?? [] as $caja)
                        <tr data-estado="{{ $caja->estado }}">
                            <td>{{ $caja->location ?? '–' }}</td>
                            <td>{{ $caja->name ?? $caja->id ?? '–' }}</td>
                            <td>{{ $caja->assigned_name ?? '–' }}</td>
                            <td>
                                @if($caja->apertura_ts)
                                    {{ \Carbon\Carbon::parse($caja->apertura_ts)->format('h:i A') }}
                                @else
                                    –
                                @endif
                            </td>
                            <td>
                                @switch($caja->estado)
                                    @case('REGULARIZAR')
                                        <span class="badge bg-danger">⚠️ Regularizar</span>
                                        @break
                                    @case('ABIERTA')
                                        <span class="badge bg-success">🟢 Abierta</span>
                                        @break
                                    @case('PRECORTE_PENDIENTE')
                                        <span class="badge bg-warning text-dark">📋 Precorte Pendiente</span>
                                        @break
                                    @case('VALIDACION')
                                        <span class="badge bg-info">🔍 En Validación</span>
                                        @break
                                    @case('EN_REVISION')
                                        <span class="badge bg-primary">👀 En Revisión</span>
                                        @break
                                    @case('CONCILIADA')
                                        <span class="badge bg-secondary">✅ Conciliada</span>
                                        @break
                                    @default
                                        <span class="badge bg-light text-dark">Disponible</span>
                                @endswitch
                            </td>
                            <td class="text-end">${{ number_format($caja->opening_float ?? 0, 2) }}</td>
                            <td class="text-end">
                                <div class="d-flex flex-wrap gap-2">
                                    @if($caja->sesion_id && in_array($caja->estado, ['ABIERTA', 'PRECORTE_PENDIENTE', 'VALIDACION', 'REGULARIZAR']))
                                        <button type="button" class="btn btn-sm btn-primary"
                                                data-caja-action="wizard"
                                                data-store="1"
                                                data-terminal="{{ $caja->id }}"
                                                data-user="{{ $caja->assigned_user }}"
                                                data-bdate="{{ $date ?? now()->format('Y-m-d') }}"
                                                data-opening="{{ $caja->opening_float }}"
                                                data-sesion="{{ $caja->sesion_id }}"
                                                title="Abrir Wizard">
                                            <i class="fa-solid fa-wand-magic-sparkles"></i>
                                        </button>
                                    @elseif($caja->estado === 'CONCILIADA')
                                        <button type="button" class="btn btn-sm btn-outline-secondary" disabled title="Sesión conciliada">
                                            <i class="fa-solid fa-check"></i>
                                        </button>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7" class="text-center text-secondary py-4">No hay sesiones para {{ $date ?? 'esta fecha' }}.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{-- Widget de Excepciones (Anulaciones, Devoluciones, Descuentos, etc.) --}}
        <div class="card border-warning mt-3 mb-3">
            <div class="card-body p-3">
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <h6 class="mb-0 text-warning">
                        <i class="fa-solid fa-triangle-exclamation me-1"></i>
                        Excepciones de Venta del Día
                    </h6>
                    <button type="button" class="btn btn-sm btn-outline-warning" data-bs-toggle="modal" data-bs-target="#modalAnulaciones">
                        Ver todas ({{ count($anulaciones ?? []) }}) <i class="fa-solid fa-chevron-right ms-1"></i>
                    </button>
                </div>
                @if(count($anulaciones ?? []) > 0)
                    <div class="table-responsive">
                        <table class="table table-sm table-hover align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 80px">Ticket</th>
                                    <th style="width: 100px">Terminal</th>
                                    <th style="width: 130px">Tipo</th>
                                    <th style="width: 90px">Hora</th>
                                    <th>Usuario</th>
                                    <th>Razón</th>
                                    <th class="text-end" style="width: 110px">Monto</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach(array_slice($anulaciones, 0, 5) as $anulacion)
                                    <tr class="cursor-pointer" data-ticket-id="{{ $anulacion['ticket_internal_id'] }}" onclick="verDetalleTicket({{ $anulacion['ticket_internal_id'] }})">
                                        <td>
                                            <span class="badge bg-secondary clickable">
                                                #{{ $anulacion['ticket_id'] }}
                                            </span>
                                        </td>
                                        <td class="text-muted small">{{ $anulacion['terminal'] }}</td>
                                        <td>
                                            @switch($anulacion['tipo'])
                                                @case('Anulación')
                                                    <span class="badge bg-danger">
                                                        <i class="fa-solid fa-ban me-1"></i>{{ $anulacion['tipo'] }}
                                                    </span>
                                                    @break
                                                @case('Devolución')
                                                    <span class="badge bg-warning text-dark">
                                                        <i class="fa-solid fa-rotate-left me-1"></i>{{ $anulacion['tipo'] }}
                                                    </span>
                                                    @break
                                                @case('Descuento')
                                                    <span class="badge bg-info">
                                                        <i class="fa-solid fa-percent me-1"></i>{{ $anulacion['tipo'] }}
                                                    </span>
                                                    @break
                                                @case('Desperdicio')
                                                    <span class="badge bg-dark">
                                                        <i class="fa-solid fa-trash me-1"></i>{{ $anulacion['tipo'] }}
                                                    </span>
                                                    @break
                                                @case('Ajuste')
                                                    <span class="badge bg-primary">
                                                        <i class="fa-solid fa-arrows-up-down me-1"></i>{{ $anulacion['tipo'] }}
                                                    </span>
                                                    @break
                                                @default
                                                    <span class="badge bg-secondary">{{ $anulacion['tipo'] }}</span>
                                            @endswitch
                                        </td>
                                        <td class="text-muted small">{{ $anulacion['hora'] }}</td>
                                        <td class="text-muted small">{{ $anulacion['usuario'] }}</td>
                                        <td class="text-muted small">{{ $anulacion['razon'] }}</td>
                                        <td class="text-end fw-bold text-danger">${{ number_format($anulacion['monto'], 2) }}</td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                @else
                    <div class="alert alert-success mb-0" role="alert">
                        <i class="fa-solid fa-circle-check me-2"></i>
                        No se registraron excepciones para esta fecha. ¡Excelente!
                    </div>
                @endif
            </div>
        </div>

        {{-- Panel Detalle --}}
        <div class="mt-3" id="panelDetalle" hidden>
            <div class="card">
                <div class="card-body">
                    <div class="d-flex align-items-center justify-content-between">
                        <h5 class="mb-0">Detalle de Caja</h5>
                        <button class="btn btn-light btn-sm" id="btnOcultarDetalle">Ocultar</button>
                    </div>
                    <div id="detalleContenido" class="mt-3"><em>Selecciona una caja…</em></div>
                </div>
            </div>
        </div>
    </div>

    {{-- Modal Detalle de Ticket --}}
    <div class="modal fade" id="modalDetalleTicket" tabindex="-1" aria-labelledby="modalDetalleTicketLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header bg-primary bg-opacity-10">
                    <h5 class="modal-title" id="modalDetalleTicketLabel">
                        <i class="fa-solid fa-receipt me-2"></i>
                        Detalle del Ticket <span id="ticketNumero"></span>
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div id="ticketDetalleContenido">
                        <div class="text-center py-4">
                            <div class="spinner-border text-primary" role="status">
                                <span class="visually-hidden">Cargando...</span>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                </div>
            </div>
        </div>
    </div>

    {{-- Modal Excepciones --}}
    <div class="modal fade" id="modalAnulaciones" tabindex="-1" aria-labelledby="modalAnulacionesLabel" aria-hidden="true">
        <div class="modal-dialog modal-xl modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header bg-warning bg-opacity-10">
                    <h5 class="modal-title" id="modalAnulacionesLabel">
                        <i class="fa-solid fa-triangle-exclamation me-2"></i>
                        Historial de Excepciones de Venta
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    @if(count($anulaciones ?? []) > 0)
                        <div class="alert alert-warning d-flex align-items-center mb-3" role="alert">
                            <i class="fa-solid fa-triangle-exclamation me-2"></i>
                            <div>
                                Se encontraron <strong>{{ count($anulaciones) }}</strong> excepciones para el día <strong>{{ $date ?? now()->format('Y-m-d') }}</strong>
                                <br>
                                <small class="text-muted">
                                    Incluye: Anulaciones, Devoluciones, Descuentos, Desperdicios y Ajustes de precio
                                </small>
                            </div>
                        </div>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead class="table-light">
                                    <tr>
                                        <th style="width: 80px">Ticket</th>
                                        <th style="width: 100px">Terminal</th>
                                        <th style="width: 140px">Tipo</th>
                                        <th style="width: 90px">Hora</th>
                                        <th>Usuario</th>
                                        <th>Razón / Detalle</th>
                                        <th class="text-end" style="width: 110px">Monto</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($anulaciones as $anulacion)
                                        <tr class="cursor-pointer" onclick="verDetalleTicket({{ $anulacion['ticket_internal_id'] }})">
                                            <td>
                                                <span class="badge bg-secondary clickable">
                                                    #{{ $anulacion['ticket_id'] }}
                                                </span>
                                            </td>
                                            <td class="text-muted small">{{ $anulacion['terminal'] }}</td>
                                            <td>
                                                @switch($anulacion['tipo'])
                                                    @case('Anulación')
                                                        <span class="badge bg-danger">
                                                            <i class="fa-solid fa-ban me-1"></i>{{ $anulacion['tipo'] }}
                                                        </span>
                                                        @break
                                                    @case('Devolución')
                                                        <span class="badge bg-warning text-dark">
                                                            <i class="fa-solid fa-rotate-left me-1"></i>{{ $anulacion['tipo'] }}
                                                        </span>
                                                        @break
                                                    @case('Descuento')
                                                        <span class="badge bg-info">
                                                            <i class="fa-solid fa-percent me-1"></i>{{ $anulacion['tipo'] }}
                                                        </span>
                                                        @break
                                                    @case('Desperdicio')
                                                        <span class="badge bg-dark">
                                                            <i class="fa-solid fa-trash me-1"></i>{{ $anulacion['tipo'] }}
                                                        </span>
                                                        @break
                                                    @case('Ajuste')
                                                        <span class="badge bg-primary">
                                                            <i class="fa-solid fa-arrows-up-down me-1"></i>{{ $anulacion['tipo'] }}
                                                        </span>
                                                        @break
                                                    @default
                                                        <span class="badge bg-secondary">{{ $anulacion['tipo'] }}</span>
                                                @endswitch
                                            </td>
                                            <td>{{ $anulacion['hora'] }}</td>
                                            <td>
                                                <i class="fa-solid fa-user text-muted me-1"></i>
                                                {{ $anulacion['usuario'] }}
                                            </td>
                                            <td class="small text-muted">{{ $anulacion['razon'] }}</td>
                                            <td class="text-end">
                                                <span class="fw-bold text-danger">${{ number_format($anulacion['monto'], 2) }}</span>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                                <tfoot class="table-light">
                                    <tr>
                                        <td colspan="6" class="text-end fw-bold">Total Excepciones:</td>
                                        <td class="text-end fw-bold text-danger">
                                            ${{ number_format(array_sum(array_column($anulaciones, 'monto')), 2) }}
                                        </td>
                                    </tr>
                                </tfoot>
                            </table>
                        </div>
                    @else
                        <div class="alert alert-success" role="alert">
                            <i class="fa-solid fa-circle-check me-2"></i>
                            No se registraron excepciones para esta fecha. ¡Excelente trabajo del equipo!
                        </div>
                    @endif
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                </div>
            </div>
        </div>
    </div>

@endsection

@push('scripts')
    <style>
        .cursor-pointer { cursor: pointer; }
        .clickable { cursor: pointer; transition: transform 0.1s; }
        .clickable:hover { transform: scale(1.05); }
        .cursor-pointer:hover { background-color: #f8f9fa; }
    </style>

    <script>
        // Función global para ver detalle del ticket
        async function verDetalleTicket(ticketId) {
            const modalAnulacionesEl = document.getElementById('modalAnulaciones');
            const modalDetalleEl = document.getElementById('modalDetalleTicket');

            // Cerrar modal de excepciones si está abierto (para evitar problema de z-index y aria-hidden)
            const modalExcepciones = bootstrap.Modal.getInstance(modalAnulacionesEl);
            let volverAbrirExcepciones = false;

            if (modalExcepciones) {
                volverAbrirExcepciones = true;

                // Esperar a que se cierre completamente antes de abrir el siguiente
                const promesaCierre = new Promise(resolve => {
                    modalAnulacionesEl.addEventListener('hidden.bs.modal', resolve, { once: true });
                });

                modalExcepciones.hide();
                await promesaCierre;
            }

            const modal = new bootstrap.Modal(modalDetalleEl, {
                backdrop: true,
                keyboard: true,
                focus: true
            });

            const contenido = document.getElementById('ticketDetalleContenido');
            const numero = document.getElementById('ticketNumero');

            // Si venimos del modal de excepciones, volver a abrirlo cuando cerremos este
            if (volverAbrirExcepciones) {
                const handlerReabrir = function() {
                    // Pequeño delay para evitar conflictos de aria-hidden
                    setTimeout(() => {
                        const modalExc = new bootstrap.Modal(modalAnulacionesEl);
                        modalExc.show();
                    }, 150);
                };

                modalDetalleEl.addEventListener('hidden.bs.modal', handlerReabrir, { once: true });
            }

            // Mostrar modal con spinner
            modal.show();
            contenido.innerHTML = '<div class="text-center py-4"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Cargando...</span></div></div>';
            numero.textContent = `#${ticketId}`;

            try {
                console.log('Cargando detalle del ticket:', ticketId);
                const response = await fetch(`/TerrenaLaravel/api/caja/ticket/${ticketId}`);

                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }

                const data = await response.json();
                console.log('Datos del ticket recibidos:', data);

                if (!data.ok) {
                    throw new Error(data.error || 'Error al cargar ticket');
                }

                const ticket = data.ticket;
                numero.textContent = `#${ticket.daily_folio || ticket.id}`;

                // Renderizar detalle del ticket
                let html = `
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <p class="mb-1"><strong>Terminal:</strong> ${ticket.terminal || '–'}</p>
                            <p class="mb-1"><strong>Fecha:</strong> ${new Date(ticket.create_date).toLocaleString('es-MX')}</p>
                            <p class="mb-1"><strong>Mesero:</strong> ${ticket.usuario || '–'}</p>
                        </div>
                        <div class="col-md-6 text-end">
                            <p class="mb-1"><strong>Subtotal:</strong> $${parseFloat(ticket.sub_total || 0).toFixed(2)}</p>
                            ${ticket.total_discount > 0 ? `<p class="mb-1 text-danger"><strong>Descuento:</strong> -$${parseFloat(ticket.total_discount).toFixed(2)}</p>` : ''}
                            <p class="mb-1"><strong>IVA:</strong> $${parseFloat(ticket.total_tax || 0).toFixed(2)}</p>
                            <h5 class="mt-2"><strong>Total:</strong> $${parseFloat(ticket.total_price || 0).toFixed(2)}</h5>
                        </div>
                    </div>
                    <hr>
                    <h6 class="mb-3">Items del Ticket:</h6>
                    <div class="table-responsive">
                        <table class="table table-sm align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Cant.</th>
                                    <th>Producto</th>
                                    <th class="text-end">Precio Unit.</th>
                                    <th class="text-end">Descuento</th>
                                    <th class="text-end">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                `;

                if (ticket.items && ticket.items.length > 0) {
                    ticket.items.forEach(item => {
                        const hasDiscount = parseFloat(item.discount || 0) > 0;
                        const rowClass = hasDiscount ? 'table-warning' : '';
                        const quantity = parseFloat(item.item_quantity || 1);

                        html += `
                            <tr class="${rowClass}">
                                <td>${quantity > 0 ? quantity : 1}</td>
                                <td>
                                    ${item.item_name || 'Item desconocido'}
                                    ${hasDiscount ? '<span class="badge bg-info ms-2"><i class="fa-solid fa-percent"></i> Con descuento</span>' : ''}
                                </td>
                                <td class="text-end">$${parseFloat(item.item_price || 0).toFixed(2)}</td>
                                <td class="text-end ${hasDiscount ? 'text-danger fw-bold' : ''}">
                                    ${hasDiscount ? `-$${parseFloat(item.discount).toFixed(2)}` : '–'}
                                </td>
                                <td class="text-end fw-bold">$${parseFloat(item.total_price || 0).toFixed(2)}</td>
                            </tr>
                        `;
                    });
                } else {
                    html += `
                        <tr>
                            <td colspan="5" class="text-center text-muted py-3">
                                <i class="fa-solid fa-inbox me-2"></i>No hay items en este ticket
                            </td>
                        </tr>
                    `;
                }

                html += `
                            </tbody>
                        </table>
                    </div>
                `;

                if (ticket.voided) {
                    html = `<div class="alert alert-danger mb-3"><i class="fa-solid fa-ban me-2"></i><strong>Ticket Anulado</strong><br>${ticket.void_reason || 'Sin razón especificada'}</div>` + html;
                }

                contenido.innerHTML = html;

            } catch (error) {
                console.error('Error cargando detalle del ticket:', error);
                contenido.innerHTML = `
                    <div class="alert alert-danger">
                        <i class="fa-solid fa-triangle-exclamation me-2"></i>
                        <strong>Error al cargar el detalle del ticket</strong><br>
                        <small class="text-muted">${error.message || 'Por favor intenta de nuevo'}</small>
                        <hr>
                        <small>Ticket ID: ${ticketId}</small>
                    </div>
                `;
            }
        }

        // Log para debugging
        console.log('Modal handlers initialized. Bootstrap version:', typeof bootstrap !== 'undefined' ? 'loaded' : 'NOT loaded');
    </script>

    <script type="module" src="{{ asset('assets/js/caja/main.js') }}"></script>
    {{-- Otros JS: helpers.js, state.js, etc., ya cargados en layout --}}
@endpush

