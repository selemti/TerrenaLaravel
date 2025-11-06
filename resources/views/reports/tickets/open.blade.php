@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Reporte de Cuentas Abiertas/Pagadas',
    'pageTitle' => 'Cuentas Abiertas/Pagadas',
])

@php
    use Carbon\Carbon;

    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
    $formatDate = fn ($date) => $date ? Carbon::parse($date)->format('d/m/Y H:i') : '-';
    $formatHours = fn ($hours) => number_format((float) $hours, 1) . 'h';
@endphp

@section('content')
<style>
    .ticket-table tbody tr:hover {
        background-color: rgba(37,99,235,0.04);
    }
    .status-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        border-radius: 999px;
        padding: 0.15rem 0.65rem;
        font-size: 0.75rem;
        font-weight: 500;
    }
    .status-open {
        background-color: #fef3c7;
        color: #92400e;
        border: 1px solid #fbbf24;
    }
    .status-paid {
        background-color: #d1fae5;
        color: #065f46;
        border: 1px solid #10b981;
    }
    .alert-warning {
        background-color: #fef3c7;
        border-color: #fbbf24;
        color: #92400e;
    }
</style>

<section class="report-shell">
    {{-- Encabezado --}}
    <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-receipt text-primary me-2"></i>
                Reporte de Cuentas Abiertas/Pagadas
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}
            </p>
            @if($branch)
                <p class="text-muted small mb-0">
                    Sucursal: {{ $branch }}
                </p>
            @endif
        </div>
        <div class="d-flex flex-wrap gap-2">
            <a href="{{ route('reports.tickets.open.export.pdf', [
                    'start_date' => $startDate->format('Y-m-d'),
                    'end_date' => $endDate->format('Y-m-d'),
                    'status' => $status,
                    'branch' => $branch,
                ]) }}" class="btn btn-outline-danger">
                <i class="fa-solid fa-file-pdf me-1"></i> PDF
            </a>
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card border-0 shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.tickets.open') }}" class="row g-3">
                <div class="col-md-3">
                    <label class="form-label small text-muted">Fecha Inicio</label>
                    <input type="date" name="start_date" class="form-control"
                           value="{{ $startDate->format('Y-m-d') }}" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label small text-muted">Fecha Fin</label>
                    <input type="date" name="end_date" class="form-control"
                           value="{{ $endDate->format('Y-m-d') }}" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label small text-muted">Estado</label>
                    <select name="status" class="form-select">
                        <option value="all" {{ $status === 'all' ? 'selected' : '' }}>Todas</option>
                        <option value="open" {{ $status === 'open' ? 'selected' : '' }}>Solo Abiertas</option>
                        <option value="paid" {{ $status === 'paid' ? 'selected' : '' }}>Solo Pagadas</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label small text-muted">Sucursal</label>
                    <select name="branch" class="form-select">
                        <option value="">Todas</option>
                        @foreach($branches as $b)
                            <option value="{{ $b['key'] }}" {{ $branch === $b['key'] ? 'selected' : '' }}>
                                {{ $b['label'] }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-12">
                    <button type="submit" class="btn btn-primary">
                        <i class="fa-solid fa-filter me-1"></i> Aplicar Filtros
                    </button>
                    <a href="{{ route('reports.tickets.open') }}" class="btn btn-outline-secondary">
                        <i class="fa-solid fa-undo me-1"></i> Limpiar
                    </a>
                </div>
            </form>
        </div>
    </div>

    {{-- Resumen --}}
    <div class="row g-3 mb-4">
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Cuentas Abiertas</div>
                    <div class="h4 mb-0 text-warning">{{ $summary['total_open'] }}</div>
                    <div class="small text-muted mt-1">{{ $formatMoney($summary['amount_open']) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Cuentas Pagadas</div>
                    <div class="h4 mb-0 text-success">{{ $summary['total_paid'] }}</div>
                    <div class="small text-muted mt-1">{{ $formatMoney($summary['amount_paid']) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Monto Total Abierto</div>
                    <div class="h4 mb-0">{{ $formatMoney($summary['amount_open']) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Cuenta Más Antigua</div>
                    @if($summary['oldest_open'])
                        <div class="h6 mb-0">{{ $formatHours($summary['oldest_open']->hours_open ?? 0) }}</div>
                        <div class="small text-muted mt-1">Ticket #{{ $summary['oldest_open']->id ?? '-' }}</div>
                    @else
                        <div class="h6 mb-0 text-muted">-</div>
                    @endif
                </div>
            </div>
        </div>
    </div>

    {{-- Alerta si hay cuentas antiguas --}}
    @if($summary['oldest_open'] && $summary['oldest_open']->hours_open > 24)
        <div class="alert alert-warning d-flex align-items-center mb-4" role="alert">
            <i class="fa-solid fa-triangle-exclamation me-2"></i>
            <div>
                <strong>Atención:</strong> Hay cuentas abiertas con más de 24 horas.
                La cuenta más antigua tiene {{ $formatHours($summary['oldest_open']->hours_open) }} abierta.
                Esto puede afectar los cortes de caja.
            </div>
        </div>
    @endif

    {{-- Tabla de Cuentas Abiertas --}}
    @if($status === 'all' || $status === 'open')
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-header bg-white border-bottom">
                <h5 class="mb-0">
                    <i class="fa-solid fa-folder-open text-warning me-2"></i>
                    Cuentas Abiertas ({{ count($openTickets) }})
                </h5>
            </div>
            <div class="card-body p-0">
                @if(count($openTickets) > 0)
                    <div class="table-responsive">
                        <table class="table table-hover ticket-table mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Ticket ID</th>
                                    <th>Folio</th>
                                    <th>Fecha Creación</th>
                                    <th>Tiempo Abierto</th>
                                    <th>Terminal</th>
                                    <th>Sucursal</th>
                                    <th class="text-end">Monto</th>
                                    <th class="text-center">Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($openTickets as $ticket)
                                    <tr>
                                        <td class="font-monospace">#{{ $ticket->id }}</td>
                                        <td>{{ $ticket->daily_folio ?? '-' }}</td>
                                        <td>{{ $formatDate($ticket->create_date) }}</td>
                                        <td>
                                            <span class="{{ $ticket->hours_open > 24 ? 'text-danger fw-bold' : '' }}">
                                                {{ $formatHours($ticket->hours_open) }}
                                            </span>
                                        </td>
                                        <td>{{ $ticket->terminal_name }}</td>
                                        <td>{{ $ticket->branch_name }}</td>
                                        <td class="text-end font-monospace">{{ $formatMoney($ticket->total_price) }}</td>
                                        <td class="text-center">
                                            <span class="status-badge status-open">
                                                <i class="fa-solid fa-clock"></i> Abierta
                                            </span>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                            <tfoot class="table-light">
                                <tr>
                                    <td colspan="6" class="text-end fw-bold">Total:</td>
                                    <td class="text-end font-monospace fw-bold">{{ $formatMoney($summary['amount_open']) }}</td>
                                    <td></td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                @else
                    <div class="p-4 text-center text-muted">
                        <i class="fa-solid fa-circle-check fa-2x mb-2 text-success"></i>
                        <p class="mb-0">No hay cuentas abiertas en este periodo</p>
                    </div>
                @endif
            </div>
        </div>
    @endif

    {{-- Tabla de Cuentas Pagadas --}}
    @if($status === 'all' || $status === 'paid')
        <div class="card border-0 shadow-sm">
            <div class="card-header bg-white border-bottom">
                <h5 class="mb-0">
                    <i class="fa-solid fa-circle-check text-success me-2"></i>
                    Cuentas Pagadas ({{ count($paidTickets) }})
                </h5>
            </div>
            <div class="card-body p-0">
                @if(count($paidTickets) > 0)
                    <div class="table-responsive">
                        <table class="table table-hover ticket-table mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Ticket ID</th>
                                    <th>Folio</th>
                                    <th>Fecha Creación</th>
                                    <th>Fecha Cierre</th>
                                    <th>Terminal</th>
                                    <th>Sucursal</th>
                                    <th class="text-end">Monto</th>
                                    <th class="text-center">Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($paidTickets as $ticket)
                                    <tr>
                                        <td class="font-monospace">#{{ $ticket->id }}</td>
                                        <td>{{ $ticket->daily_folio ?? '-' }}</td>
                                        <td>{{ $formatDate($ticket->create_date) }}</td>
                                        <td>{{ $formatDate($ticket->closing_date) }}</td>
                                        <td>{{ $ticket->terminal_name }}</td>
                                        <td>{{ $ticket->branch_name }}</td>
                                        <td class="text-end font-monospace">{{ $formatMoney($ticket->total_price) }}</td>
                                        <td class="text-center">
                                            <span class="status-badge status-paid">
                                                <i class="fa-solid fa-circle-check"></i> Pagada
                                            </span>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                            <tfoot class="table-light">
                                <tr>
                                    <td colspan="6" class="text-end fw-bold">Total:</td>
                                    <td class="text-end font-monospace fw-bold">{{ $formatMoney($summary['amount_paid']) }}</td>
                                    <td></td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                @else
                    <div class="p-4 text-center text-muted">
                        <i class="fa-solid fa-inbox fa-2x mb-2"></i>
                        <p class="mb-0">No hay cuentas pagadas en este periodo</p>
                    </div>
                @endif
            </div>
        </div>
    @endif
</section>

@push('styles')
<style>
    @media print {
        .btn, .card-header button, form { display: none !important; }
        .report-shell { padding: 0; }
        body { font-size: 10pt; }
    }
</style>
@endpush
@endsection
