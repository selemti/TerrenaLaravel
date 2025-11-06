@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Balance por Forma de Pago',
    'pageTitle' => 'Balance por Forma de Pago',
])

@php
    use Carbon\Carbon;

    $branchFilter = $branchFilter ?? [];
    $terminalFilter = $terminalFilter ?? [];
    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
@endphp

@section('content')
<section class="report-shell">
    <style>
        .report-chip {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            border-radius: 999px;
            padding: 0.15rem 0.65rem;
            font-size: 0.75rem;
            border: 1px solid rgba(0, 0, 0, 0.08);
            background: #f8fafc;
        }
    </style>

    <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-wallet text-primary me-2"></i>
                Balance por forma de pago
            </h1>
            <p class="text-muted small mb-0">
                Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}
            </p>
            <p class="text-muted small mb-0">
                Sucursales:
                {{ !empty($branchFilter) ? implode(', ', $branchFilter) : 'Todas' }}
                · Terminales:
                {{ !empty($terminalFilter) ? implode(', ', $terminalFilter) : 'Todas' }}
            </p>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <button type="button" class="btn btn-outline-secondary" onclick="window.print()">
                <i class="fa-solid fa-print me-1"></i> Imprimir
            </button>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.sales.balance') }}" class="row g-3 align-items-end">
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Desde</label>
                    <input type="date" name="start" class="form-control" value="{{ request('start', $startDate->format('Y-m-d')) }}" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Hasta</label>
                    <input type="date" name="end" class="form-control" value="{{ request('end', $endDate->format('Y-m-d')) }}" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Sucursales</label>
                    <x-ui.compact-multi-select
                        name="branch[]"
                        :options="$branchOptions"
                        placeholder="Selecciona sucursales"
                        search-placeholder="Buscar sucursal"
                        clear-label="Limpiar"
                        done-label="Hecho"
                        empty-message="Sin sucursales disponibles." />
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Terminales</label>
                    <x-ui.compact-multi-select
                        name="terminal[]"
                        :options="$terminalOptions"
                        placeholder="Selecciona terminales"
                        search-placeholder="Buscar terminal"
                        clear-label="Limpiar"
                        done-label="Hecho"
                        empty-message="Sin terminales disponibles." />
                </div>
                <div class="col-12 d-flex flex-wrap gap-2 justify-content-end pt-2">
                    <button type="submit" class="btn btn-primary">
                        <i class="fa-solid fa-magnifying-glass me-1"></i> Aplicar filtros
                    </button>
                    <a href="{{ route('reports.sales.balance') }}" class="btn btn-outline-secondary">
                        <i class="fa-solid fa-rotate-left me-1"></i> Limpiar
                    </a>
                </div>
                <div class="col-12 text-md-end small text-muted">
                    Generado: <strong>{{ $generatedAt->format('d/m/Y H:i') }}</strong>
                </div>
            </form>
        </div>
    </div>

    @if(!empty($branchColors))
        <div class="d-flex flex-wrap gap-2 mb-4">
            @foreach($branchColors as $key => $color)
                <span class="report-chip">
                    <span class="report-dot" style="background-color: {{ $color }}"></span>
                    {{ $branchLabels[$key] ?? $key }}
                </span>
            @endforeach
        </div>
    @endif

    <div class="card border-0 shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-sm mb-0 align-middle">
                    <thead class="table-light">
                        <tr>
                            <th>Fecha</th>
                            <th>Sucursal</th>
                            <th>Forma de pago</th>
                            <th class="text-end">Monto</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($rows as $r)
                            <tr>
                                <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
                                <td>{{ $r->branch_key ?? '—' }}</td>
                                <td>{{ $r->payment ?? '—' }}</td>
                                <td class="text-end">{{ $formatMoney($r->monto ?? 0) }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="4" class="text-center text-muted py-4">Sin datos</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</section>
@endsection
