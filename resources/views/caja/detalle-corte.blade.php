@extends('layouts.terrena')

@section('title', $title)

@section('page-title')
    <div class="d-flex align-items-center justify-content-between mb-2">
        <div class="d-flex align-items-center gap-2">
            <h2 class="mb-0"><i class="fa-solid fa-file-invoice-dollar me-2"></i> {{ $title }}</h2>
        </div>
        <a href="{{ route('caja.historico') }}" class="btn btn-outline-secondary">
            <i class="fa-solid fa-arrow-left me-2"></i> Volver
        </a>
    </div>
@endsection

@section('content')

<div class="dashboard-grid">
    <div class="mb-3">
        <p class="text-muted mb-0">Detalle completo de la sesión de caja</p>
    </div>

    {{-- Información de la Sesión --}}
    <div class="row g-3 mb-4">
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header py-2">
                    <strong><i class="fa-solid fa-info-circle me-2"></i>Información de Sesión</strong>
                </div>
                <div class="card-body">
                    <table class="table table-sm mb-0">
                        <tbody>
                            <tr>
                                <th width="40%">ID Sesión:</th>
                                <td><strong>#{{ $sesion->id }}</strong></td>
                            </tr>
                            <tr>
                                <th>Terminal:</th>
                                <td>{{ $sesion->terminal_id }} - {{ $sesion->terminal_nombre }}</td>
                            </tr>
                            <tr>
                                <th>Sucursal:</th>
                                <td>{{ $sesion->sucursal }}</td>
                            </tr>
                            <tr>
                                <th>Cajero:</th>
                                <td>
                                    <div>{{ $sesion->cajero_nombre ?? 'N/A' }}</div>
                                    <small class="text-muted">User ID: {{ $sesion->cajero_user_id ?? '-' }}</small>
                                </td>
                            </tr>
                            <tr>
                                <th>Apertura:</th>
                                <td>{{ \Carbon\Carbon::parse($sesion->apertura_ts)->format('d/m/Y H:i:s') }}</td>
                            </tr>
                            <tr>
                                <th>Cierre:</th>
                                <td>
                                    @if($sesion->cierre_ts)
                                        {{ \Carbon\Carbon::parse($sesion->cierre_ts)->format('d/m/Y H:i:s') }}
                                    @else
                                        <span class="badge bg-warning">Abierta</span>
                                    @endif
                                </td>
                            </tr>
                            <tr>
                                <th>Estatus:</th>
                                <td>
                                    @php
                                        $statusClass = match($sesion->estatus) {
                                            'ACTIVA' => 'success',
                                            'LISTO_PARA_CORTE' => 'warning',
                                            'EN_CORTE' => 'info',
                                            'CERRADA' => 'secondary',
                                            default => 'light'
                                        };
                                    @endphp
                                    <span class="badge bg-{{ $statusClass }}">{{ $sesion->estatus }}</span>
                                </td>
                            </tr>
                            <tr>
                                <th>Fondo Inicial:</th>
                                <td><strong>${{ number_format($sesion->opening_float, 2) }}</strong></td>
                            </tr>
                            @if($sesion->closing_float)
                                <tr>
                                    <th>Fondo Final:</th>
                                    <td><strong>${{ number_format($sesion->closing_float, 2) }}</strong></td>
                                </tr>
                            @endif
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        {{-- Resumen de Cortes --}}
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header py-2">
                    <strong><i class="fa-solid fa-calculator me-2"></i>Resumen de Cortes</strong>
                </div>
                <div class="card-body">
                    {{-- Precorte --}}
                    @if($precorte)
                        <h6 class="text-primary mb-3">
                            <i class="fa-solid fa-clipboard-list me-2"></i>Precorte #{{ $precorte->id }}
                        </h6>
                        <table class="table table-sm mb-4">
                            <tbody>
                                <tr>
                                    <th width="50%">Sistema (Efectivo):</th>
                                    <td class="text-end">${{ number_format($precorte->sistema_efectivo, 2) }}</td>
                                </tr>
                                <tr>
                                    <th>Declarado (Efectivo):</th>
                                    <td class="text-end">${{ number_format($precorte->declarado_efectivo, 2) }}</td>
                                </tr>
                                <tr class="{{ $precorte->diferencia_efectivo == 0 ? 'table-success' : ($precorte->diferencia_efectivo > 0 ? 'table-primary' : 'table-danger') }}">
                                    <th>Diferencia:</th>
                                    <td class="text-end">
                                        <strong>${{ number_format($precorte->diferencia_efectivo, 2) }}</strong>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    @else
                        <div class="alert alert-warning mb-4">
                            <i class="fa-solid fa-exclamation-triangle me-2"></i>
                            No se ha realizado el precorte
                        </div>
                        {{-- Enlace para iniciar precorte --}}
                        @if($sesion->estatus !== 'CERRADA' && $sesion->cierre_ts)
                            <div class="d-grid gap-2">
                                <a href="{{ route('caja.cortes', [
                                    'date' => \Carbon\Carbon::parse($sesion->apertura_ts)->format('Y-m-d'),
                                    'sesion_id' => $sesion->id,
                                    'auto_open' => 'wizard',
                                    'return' => 'cortes/historico/' . $sesion->id
                                ]) }}" class="btn btn-primary">
                                    <i class="fa-solid fa-play me-2"></i> Iniciar Precorte
                                </a>
                            </div>
                        @endif
                    @endif

                    {{-- Postcorte --}}
                    @if($postcorte)
                        <h6 class="text-success mb-3">
                            <i class="fa-solid fa-check-circle me-2"></i>Postcorte #{{ $postcorte->id }}
                            @if($postcorte->validado)
                                <span class="badge bg-success ms-2">Validado</span>
                            @else
                                <span class="badge bg-warning ms-2">Pendiente</span>
                            @endif
                        </h6>
                        <table class="table table-sm mb-3">
                            <tbody>
                                <tr>
                                    <th width="50%">Sistema (Efectivo):</th>
                                    <td class="text-end">${{ number_format($postcorte->sistema_efectivo_esperado, 2) }}</td>
                                </tr>
                                <tr>
                                    <th>Declarado (Efectivo):</th>
                                    <td class="text-end">${{ number_format($postcorte->declarado_efectivo, 2) }}</td>
                                </tr>
                                <tr class="{{ $postcorte->diferencia_efectivo == 0 ? 'table-success' : ($postcorte->diferencia_efectivo > 0 ? 'table-primary' : 'table-danger') }}">
                                    <th>Diferencia:</th>
                                    <td class="text-end">
                                        <strong>${{ number_format($postcorte->diferencia_efectivo, 2) }}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <th colspan="2" class="text-center bg-light">Veredictos</th>
                                </tr>
                                <tr>
                                    <th>Efectivo:</th>
                                    <td class="text-end">
                                        @php
                                            $verdClass = match($postcorte->veredicto_efectivo) {
                                                'CUADRA' => 'success',
                                                'A_FAVOR' => 'primary',
                                                'EN_CONTRA' => 'danger',
                                                default => 'secondary'
                                            };
                                        @endphp
                                        <span class="badge bg-{{ $verdClass }}">{{ $postcorte->veredicto_efectivo }}</span>
                                    </td>
                                </tr>
                                <tr>
                                    <th>Tarjetas:</th>
                                    <td class="text-end">
                                        @php
                                            $verdClass = match($postcorte->veredicto_tarjetas) {
                                                'CUADRA' => 'success',
                                                'A_FAVOR' => 'primary',
                                                'EN_CONTRA' => 'danger',
                                                default => 'secondary'
                                            };
                                        @endphp
                                        <span class="badge bg-{{ $verdClass }}">{{ $postcorte->veredicto_tarjetas }}</span>
                                    </td>
                                </tr>
                                <tr>
                                    <th>Transferencias:</th>
                                    <td class="text-end">
                                        @php
                                            $verdClass = match($postcorte->veredicto_transferencias) {
                                                'CUADRA' => 'success',
                                                'A_FAVOR' => 'primary',
                                                'EN_CONTRA' => 'danger',
                                                default => 'secondary'
                                            };
                                        @endphp
                                        <span class="badge bg-{{ $verdClass }}">{{ $postcorte->veredicto_transferencias }}</span>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                        @if($postcorte->notas)
                            <div class="alert alert-info">
                                <strong><i class="fa-solid fa-sticky-note me-2"></i>Notas:</strong>
                                <p class="mb-0 mt-2">{{ $postcorte->notas }}</p>
                            </div>
                        @endif
                    @else
                        <div class="alert alert-warning">
                            <i class="fa-solid fa-exclamation-triangle me-2"></i>
                            No se ha realizado el postcorte
                        </div>
                        {{-- Enlace para continuar a postcorte --}}
                        @if($precorte)
                            <div class="d-grid gap-2">
                                <a href="{{ route('caja.cortes', [
                                    'date' => \Carbon\Carbon::parse($sesion->apertura_ts)->format('Y-m-d'),
                                    'sesion_id' => $sesion->id,
                                    'auto_open' => 'wizard',
                                    'return' => 'cortes/historico/' . $sesion->id
                                ]) }}" class="btn btn-success">
                                    <i class="fa-solid fa-forward me-2"></i> Continuar a Postcorte
                                </a>
                            </div>
                        @endif
                    @endif

                    {{-- Enlaces de acciones para postcorte existente --}}
                    @if($postcorte)
                        <div class="mt-3">
                            @if(!$postcorte->validado)
                                <a href="{{ route('caja.cortes', [
                                    'date' => \Carbon\Carbon::parse($sesion->apertura_ts)->format('Y-m-d'),
                                    'sesion_id' => $sesion->id,
                                    'auto_open' => 'wizard',
                                    'action' => 'validar',
                                    'return' => 'cortes/historico/' . $sesion->id
                                ]) }}" class="btn btn-warning w-100 mb-2">
                                    <i class="fa-solid fa-check-circle me-2"></i> Validar Postcorte
                                </a>
                            @endif

                            @if($postcorte->requiere_aprobacion && !$postcorte->aprobado_por && !$postcorte->rechazado)
                                <div class="d-grid gap-2">
                                    <a href="{{ route('caja.cortes', [
                                        'date' => \Carbon\Carbon::parse($sesion->apertura_ts)->format('Y-m-d'),
                                        'sesion_id' => $sesion->id,
                                        'auto_open' => 'wizard',
                                        'action' => 'aprobar',
                                        'return' => 'cortes/historico/' . $sesion->id
                                    ]) }}" class="btn btn-success">
                                        <i class="fa-solid fa-thumbs-up me-2"></i> Aprobar
                                    </a>
                                    <a href="{{ route('caja.cortes', [
                                        'date' => \Carbon\Carbon::parse($sesion->apertura_ts)->format('Y-m-d'),
                                        'sesion_id' => $sesion->id,
                                        'auto_open' => 'wizard',
                                        'action' => 'rechazar',
                                        'return' => 'cortes/historico/' . $sesion->id
                                    ]) }}" class="btn btn-danger">
                                        <i class="fa-solid fa-thumbs-down me-2"></i> Rechazar
                                    </a>
                                </div>
                            @endif
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </div>

    {{-- Tickets de la Sesión --}}
    <div class="card">
        <div class="card-header py-2">
            <strong><i class="fa-solid fa-receipt me-2"></i>Tickets de la Sesión
                <span class="badge bg-primary ms-2">{{ count($tickets) }}</span>
            </strong>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover table-sm align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>ID</th>
                            <th>Fecha Creación</th>
                            <th>Fecha Cierre</th>
                            <th class="text-end">Total</th>
                            <th class="text-center">Pagado</th>
                            <th class="text-center">Anulado</th>
                            <th class="text-center">Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($tickets as $ticket)
                            <tr>
                                <td><strong>#{{ $ticket->id }}</strong></td>
                                <td>{{ \Carbon\Carbon::parse($ticket->create_date)->format('d/m/Y H:i') }}</td>
                                <td>
                                    @if($ticket->closing_date)
                                        {{ \Carbon\Carbon::parse($ticket->closing_date)->format('d/m/Y H:i') }}
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                <td class="text-end">${{ number_format($ticket->total_price, 2) }}</td>
                                <td class="text-center">
                                    @if($ticket->paid)
                                        <i class="fa-solid fa-check-circle text-success"></i>
                                    @else
                                        <i class="fa-solid fa-times-circle text-danger"></i>
                                    @endif
                                </td>
                                <td class="text-center">
                                    @if($ticket->voided)
                                        <i class="fa-solid fa-ban text-danger"></i>
                                    @else
                                        <i class="fa-solid fa-circle text-success" style="font-size: 0.5rem;"></i>
                                    @endif
                                </td>
                                <td class="text-center">
                                    @if($ticket->status)
                                        <span class="badge bg-secondary">{{ $ticket->status }}</span>
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="7" class="text-center py-4 text-muted">
                                    <i class="fa-solid fa-inbox fa-2x mb-2 d-block"></i>
                                    No se encontraron tickets para esta sesión
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

@endsection
