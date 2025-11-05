@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Journal de Ventas',
    'pageTitle' => 'Journal de Ventas',
])

@php use Carbon\Carbon; @endphp

@section('content')
<section class="report-shell">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1"><i class="fa-solid fa-book text-primary me-2"></i> Journal</h1>
            <p class="text-muted small mb-0">Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
            <p class="text-muted small mb-0">Sucursal: {{ $branch ? strtoupper($branch) : 'Todas' }} · Terminal: {{ $terminal ?: 'Todas' }}</p>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()"><i class="fa-solid fa-print me-1"></i> Imprimir</button>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.sales.journal') }}" class="row g-3 align-items-end">
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Desde</label>
                    <input type="date" name="start" class="form-control" value="{{ request('start', $startDate->format('Y-m-d')) }}" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Hasta</label>
                    <input type="date" name="end" class="form-control" value="{{ request('end', $endDate->format('Y-m-d')) }}" required>
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold">Sucursal</label>
                    <input type="text" name="branch" class="form-control" placeholder="SELEMTI" value="{{ request('branch', $branch) }}">
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold">Terminal(es)</label>
                    <input type="text" name="terminal" class="form-control" placeholder="101,102" value="{{ request('terminal', $terminal) }}">
                </div>
                <div class="col-md-2 d-flex gap-2">
                    <button type="submit" class="btn btn-primary flex-fill"><i class="fa-solid fa-magnifying-glass me-1"></i> Buscar</button>
                    <a href="{{ route('reports.sales.journal') }}" class="btn btn-outline-secondary flex-fill"><i class="fa-solid fa-rotate-left me-1"></i> Limpiar</a>
                </div>
                <div class="col-12 text-md-end small text-muted">Generado: <strong>{{ $generatedAt->format('d/m/Y H:i') }}</strong></div>
            </form>
        </div>
    </div>

    <div class="row g-4">
        <div class="col-lg-7">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-header bg-white"><h5 class="mb-0 fw-semibold">Líneas</h5></div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-sm mb-0 align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Fecha</th>
                                    <th>Ticket</th>
                                    <th>Item</th>
                                    <th class="text-end">Cant.</th>
                                    <th class="text-end">Total</th>
                                    <th class="text-end">Desc.</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($lines as $r)
                                    <tr>
                                        <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
                                        <td>{{ $r->ticket_id ?? '—' }}</td>
                                        <td>{{ $r->item_name ?? '—' }}</td>
                                        <td class="text-end">{{ number_format((float)($r->qty ?? 0), 2) }}</td>
                                        <td class="text-end">${{ number_format((float)($r->line_total ?? 0), 2) }}</td>
                                        <td class="text-end">${{ number_format((float)($r->line_discount ?? 0), 2) }}</td>
                                    </tr>
                                @empty
                                    <tr><td colspan="6" class="text-center text-muted py-4">Sin datos</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-lg-5">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-header bg-white"><h5 class="mb-0 fw-semibold">Pagos</h5></div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-sm mb-0 align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Fecha</th>
                                    <th>Ticket</th>
                                    <th>Forma</th>
                                    <th class="text-end">Monto</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($payments as $r)
                                    <tr>
                                        <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
                                        <td>{{ $r->ticket_id ?? '—' }}</td>
                                        <td>{{ $r->pay_norm ?? '—' }}</td>
                                        <td class="text-end">${{ number_format((float)($r->paid_amount ?? 0), 2) }}</td>
                                    </tr>
                                @empty
                                    <tr><td colspan="4" class="text-center text-muted py-4">Sin datos</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection

