@extends('layouts.terrena', [
    'active' => 'reportes',
    'title' => 'Excepciones de Ventas',
    'pageTitle' => 'Excepciones de Ventas',
])

@php
    use Carbon\Carbon;
    use Illuminate\Support\Str;

    $branchFilter = $branchFilter ?? [];
    $terminalFilter = $terminalFilter ?? [];
    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
    $formatCount = fn ($value) => number_format((int) $value);
    $records = isset($records) ? collect($records) : collect();
    $categories = isset($categories)
        ? ($categories instanceof \Illuminate\Support\Collection ? $categories : collect($categories))
        : collect();
    $summary = $summary ?? [
        'total_records' => $records->count(),
        'total_tickets' => $records->pluck('ticket_id')->unique()->count(),
        'impact_sum' => $records->sum(fn ($row) => $row['impact'] ?? 0),
        'by_category' => [],
    ];
    $discountSummary = isset($discountSummary)
        ? ($discountSummary instanceof \Illuminate\Support\Collection ? $discountSummary : collect($discountSummary))
        : collect();
    $discountTotal = $discountSummary->sum('total_amount');
    $topCategories = $categories
        ->sortByDesc(fn ($cat) => $cat['impact'] ?? 0)
        ->take(3);
    $remainingCategories = max($categories->count() - $topCategories->count(), 0);
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

        .report-dot {
            width: 0.65rem;
            height: 0.65rem;
            border-radius: 999px;
            display: inline-block;
        }

        .exception-note {
            font-size: 0.85rem;
        }

        .exception-card-description {
            max-width: 640px;
        }

        .exception-row-toggle {
            cursor: pointer;
        }

        .exception-row-toggle .chevron {
            transition: transform 0.2s ease-in-out;
        }

        .exception-row-toggle:not(.collapsed) .chevron {
            transform: rotate(180deg);
        }

        .exception-detail {
            background: #f8fafc;
            border-radius: 0.75rem;
            border: 1px solid rgba(148, 163, 184, 0.2);
        }
    </style>

    <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
        <div>
            <h1 class="h3 mb-1">
                <i class="fa-solid fa-triangle-exclamation text-warning me-2"></i>
                Excepciones
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

    <div class="row g-3 mb-4">
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Registros detectados</div>
                    <div class="h5 mb-0">{{ $formatCount($summary['total_records'] ?? 0) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Tickets impactados</div>
                    <div class="h5 mb-0">{{ $formatCount($summary['total_tickets'] ?? 0) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Impacto global de excepciones</div>
                    <div class="h5 mb-1">{{ $formatMoney($summary['impact_sum'] ?? 0) }}</div>
                    @if(($discountTotal ?? 0) > 0)
                        <div>
                            <span class="badge bg-primary-subtle text-primary">
                                Descuentos {{ $formatMoney($discountTotal) }}
                            </span>
                        </div>
                    @endif
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body py-3">
                    <div class="text-muted small text-uppercase mb-1">Categorías activas</div>
                    <div class="h5 mb-1">{{ $formatCount($categories->count()) }}</div>
                    @if($categories->isNotEmpty())
                        <div class="small text-muted mb-1">Principales:</div>
                        <div class="d-flex flex-wrap gap-1">
                            @foreach($topCategories as $cat)
                                <span class="badge {{ $cat['badge_class'] ?? 'bg-secondary-subtle text-secondary' }}">
                                    {{ $cat['label'] ?? ($cat['key'] ?? 'Categoría') }}
                                </span>
                            @endforeach
                            @if($remainingCategories > 0)
                                <span class="badge bg-secondary-subtle text-secondary">
                                    +{{ $remainingCategories }} más
                                </span>
                            @endif
                        </div>
                    @else
                        <div class="small text-muted">Sin alertas activas</div>
                    @endif
                </div>
            </div>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" action="{{ route('reports.sales.exceptions') }}" class="row g-3 align-items-end align-items-xl-center">
                <div class="col-12 col-md-6 col-lg-3 col-xl-2">
                    <label class="form-label fw-semibold">Desde</label>
                    <input type="date"
                           name="start"
                           class="form-control"
                           max="{{ now()->format('Y-m-d') }}"
                           value="{{ request('start', $startDate->format('Y-m-d')) }}"
                           required>
                </div>
                <div class="col-12 col-md-6 col-lg-3 col-xl-2">
                    <label class="form-label fw-semibold">Hasta</label>
                    <input type="date"
                           name="end"
                           class="form-control"
                           max="{{ now()->format('Y-m-d') }}"
                           value="{{ request('end', $endDate->format('Y-m-d')) }}"
                           required>
                </div>
                <div class="col-12 col-md-6 col-lg-3 col-xl-4">
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
                <div class="col-12 col-md-6 col-lg-3 col-xl-2">
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
                <div class="col-12 col-xl-2 d-flex gap-2 justify-content-md-end">
                    <button type="submit" class="btn btn-primary flex-fill">
                        <i class="fa-solid fa-magnifying-glass me-1"></i> Aplicar filtros
                    </button>
                    <a href="{{ route('reports.sales.exceptions') }}" class="btn btn-outline-secondary flex-fill">
                        <i class="fa-solid fa-rotate-left me-1"></i> Limpiar
                    </a>
                </div>
                <div class="col-12 text-xl-end small text-muted">
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

    @if($discountSummary->isNotEmpty())
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-header bg-white d-flex justify-content-between align-items-center">
                <h5 class="mb-0 fw-semibold">
                    <i class="fa-solid fa-ticket-simple me-2 text-primary"></i>
                    Resumen de descuentos
                </h5>
                <div class="d-flex align-items-center gap-2">
                    <span class="text-muted small text-uppercase">Total descuentos</span>
                    <span class="badge bg-primary-subtle text-primary fs-6">
                        {{ $formatMoney($discountTotal) }}
                    </span>
                </div>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-sm align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Descuento</th>
                                <th class="text-end">Aplicaciones</th>
                                <th class="text-end">Tickets</th>
                                <th class="text-end">Total</th>
                                <th class="text-end">Promedio</th>
                                <th>Alcance</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($discountSummary as $discount)
                                @php
                                    $scopes = $discount['scopes'] ?? [];
                                    $scopeTicket = $scopes['ticket'] ?? 0;
                                    $scopeItem = $scopes['item'] ?? 0;
                                @endphp
                                <tr>
                                    <td>{{ $discount['name'] ?? '—' }}</td>
                                    <td class="text-end">{{ $formatCount($discount['applications'] ?? 0) }}</td>
                                    <td class="text-end">{{ $formatCount($discount['tickets'] ?? 0) }}</td>
                                    <td class="text-end">{{ $formatMoney($discount['total_amount'] ?? 0) }}</td>
                                    <td class="text-end">{{ $formatMoney($discount['average_amount'] ?? 0) }}</td>
                                    <td>
                                        <span class="badge bg-secondary-subtle text-secondary me-1">
                                            Ticket {{ $scopeTicket }}
                                        </span>
                                        <span class="badge bg-secondary-subtle text-secondary">
                                            Item {{ $scopeItem }}
                                        </span>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @endif

    @forelse($categories as $category)
        @php
            $categoryRows = $category['rows'] instanceof \Illuminate\Support\Collection
                ? $category['rows']
                : collect($category['rows'] ?? []);
            $impactLabel = $category['impact_label'] ?? 'Impacto';
        @endphp
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-header bg-white d-flex flex-column flex-lg-row justify-content-between align-items-lg-center">
                <div class="d-flex align-items-center gap-2">
                    <span class="badge {{ $category['badge_class'] ?? 'bg-secondary-subtle text-secondary' }}">
                        {{ ucfirst($category['severity'] ?? 'info') }}
                    </span>
                    <h5 class="mb-0 fw-semibold">
                        <i class="fa-solid {{ $category['icon'] ?? 'fa-circle-info' }} me-2 text-primary"></i>
                        {{ $category['label'] ?? ($category['key'] ?? 'Categoría') }}
                    </h5>
                </div>
                <div class="text-muted small mt-2 mt-lg-0">
                    {{ $category['count'] ?? 0 }} registros · {{ $category['tickets'] ?? 0 }} tickets
                </div>
            </div>
            <div class="card-body border-top">
                <p class="text-muted small mb-3 exception-card-description">
                    {{ $category['description'] ?? 'Sin descripción disponible.' }}
                </p>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Fecha</th>
                                <th>Sucursal</th>
                                <th>Ticket</th>
                                <th>Terminal</th>
                                <th class="text-end">Neto</th>
                                <th class="text-end">Cobros</th>
                                <th class="text-end">Ajustes</th>
                                <th class="text-end">{{ $impactLabel }}</th>
                                <th class="text-end">Detalle</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($categoryRows as $row)
                                @php
                                    $notes = collect($row['notes'] ?? []);
                                    $transactions = collect($row['transactions'] ?? []);
                                    $discounts = collect($row['discounts'] ?? []);
                                    $items = collect($row['items'] ?? []);
                                    $branchKey = strtoupper($row['branch_key'] ?? '');
                                    $branchName = $branchLabels[$branchKey] ?? ($branchKey ?: 'Sin sucursal');
                                    $detailId = 'exception-detail-' . Str::slug($category['key'] ?? 'categoria') . '-' . $loop->index;
                                    $primaryNote = $notes->first();
                                    $additionalNotes = max($notes->count() - 1, 0);
                                    $adjustmentTotal = (float) ($row['payment_adjustment_total'] ?? 0);
                                    $effectivePayments = (float) ($row['effective_payment_total'] ?? (($row['payment_total'] ?? 0) + ($row['payment_adjustment_total'] ?? 0)));
                                    $difference = (float) ($row['difference'] ?? (($row['net_total'] ?? 0) - $effectivePayments));
                                @endphp
                                <tr class="exception-row-toggle collapsed"
                                    data-bs-toggle="collapse"
                                    data-bs-target="#{{ $detailId }}"
                                    aria-expanded="false"
                                    aria-controls="{{ $detailId }}">
                                    <td>{{ !empty($row['folio_date']) ? Carbon::parse($row['folio_date'])->format('d/m/Y') : '—' }}</td>
                                    <td>
                                        <div class="d-flex align-items-center gap-2">
                                            <span class="badge rounded-pill text-uppercase"
                                                  style="background-color: {{ $branchColors[$branchKey] ?? '#475569' }}; color: #ffffff;">
                                                {{ $branchKey ?: '—' }}
                                            </span>
                                            <span class="small text-muted">{{ $branchName }}</span>
                                        </div>
                                    </td>
                                    <td>
                                        <div class="fw-semibold">#{{ $row['ticket_id'] ?? '—' }}</div>
                                        @if(!empty($row['ticket_number']))
                                            <div class="small text-muted">POS: {{ $row['ticket_number'] }}</div>
                                        @endif
                                    </td>
                                    <td>{{ $row['terminal_id'] ?? '—' }}</td>
                                    <td class="text-end">{{ $formatMoney($row['net_total'] ?? 0) }}</td>
                                    <td class="text-end">{{ $formatMoney($row['payment_total'] ?? 0) }}</td>
                                    <td class="text-end">
                                        @if(abs($adjustmentTotal) > 0.01)
                                            <span class="{{ $adjustmentTotal < 0 ? 'text-danger' : 'text-success' }} fw-semibold">
                                                {{ $adjustmentTotal < 0 ? '-' : '+' }}{{ $formatMoney(abs($adjustmentTotal)) }}
                                            </span>
                                        @else
                                            <span class="text-muted">—</span>
                                        @endif
                                    </td>
                                    <td class="text-end">{{ $formatMoney($row['impact'] ?? 0) }}</td>
                                    <td class="text-end">
        <span class="badge bg-light text-body border d-inline-flex align-items-center gap-1">
            <span>Ver detalle</span>
            <i class="fa-solid fa-chevron-down chevron small"></i>
        </span>
                                        @if($primaryNote)
                                            <div class="exception-note text-muted mt-1">{{ Str::limit($primaryNote, 80) }}</div>
                                        @endif
                                        <div class="d-flex flex-wrap gap-1 mt-1">
                                            @if($additionalNotes > 0)
                                                <span class="badge bg-secondary-subtle text-secondary">+{{ $additionalNotes }} notas</span>
                                            @endif
                                            @if($discounts->isNotEmpty())
                                                <span class="badge bg-primary-subtle text-primary">{{ $discounts->count() }} desc</span>
                                            @endif
                                            @if($transactions->isNotEmpty())
                                                <span class="badge bg-info-subtle text-info">{{ $transactions->count() }} mov</span>
                                            @endif
                                        </div>
                                    </td>
                                </tr>
                                <tr class="collapse" id="{{ $detailId }}">
                                    <td colspan="9">
                                        <div class="exception-detail p-3">
                                            <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                                                <div>
                                                    <h6 class="fw-semibold mb-1">
                                                        Detalle del ticket #{{ $row['ticket_id'] ?? '—' }}
                                                    </h6>
                                                    @if(!empty($row['ticket_number']))
                                                        <div class="small text-muted mb-1">POS {{ $row['ticket_number'] }}</div>
                                                    @endif
                                                    <div class="small text-muted">
                                                        Terminal {{ $row['terminal_id'] ?? '—' }} · {{ $branchName }}
                                                    </div>
                                                </div>
                                                <div>
                                                    <ul class="list-unstyled small mb-0">
                                                        <li><strong>Neto:</strong> {{ $formatMoney($row['net_total'] ?? 0) }}</li>
                                                        <li><strong>Cobros:</strong> {{ $formatMoney($row['payment_total'] ?? 0) }}</li>
                                                        <li>
                                                            <strong>Ajustes:</strong>
                                                            @if(abs($adjustmentTotal) > 0.01)
                                                                {{ $adjustmentTotal < 0 ? '-' : '+' }}{{ $formatMoney(abs($adjustmentTotal)) }}
                                                            @else
                                                                {{ $formatMoney(0) }}
                                                            @endif
                                                        </li>
                                                        <li><strong>Cobros netos:</strong> {{ $formatMoney($effectivePayments) }}</li>
                                                        <li>
                                                            <strong>Diferencia:</strong>
                                                            @php $differenceFormatted = $difference >= 0 ? $formatMoney($difference) : '-' . $formatMoney(abs($difference)); @endphp
                                                            <span class="{{ abs($difference) > 0.5 ? 'text-danger fw-semibold' : 'text-muted' }}">
                                                                {{ $differenceFormatted }}
                                                            </span>
                                                        </li>
                                                    </ul>
                                                </div>
                                            </div>
                                            <div class="row g-3">
                                                <div class="col-12">
                                                    <h6 class="fw-semibold mb-2">Items del ticket</h6>
                                                    @if($items->isNotEmpty())
                                                        <div class="table-responsive">
                                                            <table class="table table-sm table-striped mb-0">
                                                                <thead class="table-light">
                                                                    <tr>
                                                                        <th style="width: 70px">Cant.</th>
                                                                        <th>Producto</th>
                                                                        <th class="text-end" style="width: 120px">Precio Unit.</th>
                                                                        <th class="text-end" style="width: 120px">Subtotal</th>
                                                                        <th class="text-end" style="width: 120px">Descuento</th>
                                                                        <th class="text-end" style="width: 120px">Total</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    @foreach($items as $item)
                                                                        <tr>
                                                                            <td>{{ rtrim(rtrim(number_format($item['quantity'] ?? 0, 2), '0'), '.') }}</td>
                                                                            <td>
                                                                                <div class="fw-semibold">{{ $item['name'] ?? '—' }}</div>
                                                                                @if(!empty($item['group']))
                                                                                    <div class="small text-muted">{{ $item['group'] }}</div>
                                                                                @endif
                                                                            </td>
                                                                            <td class="text-end">{{ $formatMoney($item['unit_price'] ?? 0) }}</td>
                                                                            <td class="text-end">{{ $formatMoney($item['sub_total'] ?? 0) }}</td>
                                                                            <td class="text-end">
                                                                                @if(($item['discount_amount'] ?? 0) > 0)
                                                                                    <span class="text-danger">-{{ $formatMoney($item['discount_amount'] ?? 0) }}</span>
                                                                                @else
                                                                                    {{ $formatMoney(0) }}
                                                                                @endif
                                                                            </td>
                                                                            <td class="text-end">{{ $formatMoney($item['total_amount'] ?? 0) }}</td>
                                                                        </tr>
                                                                    @endforeach
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                    @else
                                                        <p class="small text-muted mb-0">Sin items registrados.</p>
                                                    @endif
                                                </div>
                                                <div class="col-12 col-md-4">
                                                    <h6 class="fw-semibold mb-2">Notas</h6>
                                                    @if($notes->isNotEmpty())
                                                        <ul class="list-unstyled small mb-0">
                                                            @foreach($notes as $note)
                                                                <li class="mb-1">{{ $note }}</li>
                                                            @endforeach
                                                        </ul>
                                                    @else
                                                        <p class="small text-muted mb-0">Sin notas registradas.</p>
                                                    @endif
                                                </div>
                                                <div class="col-12 col-md-4">
                                                    <h6 class="fw-semibold mb-2">Descuentos</h6>
                                                    @if($discounts->isNotEmpty())
                                                        <div class="d-flex flex-wrap gap-1">
                                                            @foreach($discounts as $discount)
                                                                @php
                                                                    $badgeLabel = ($discount['scope'] ?? 'ticket') === 'item' ? 'Item' : 'Ticket';
                                                                    $applications = (int) ($discount['applications'] ?? 0);
                                                                @endphp
                                                                <span class="badge bg-primary-subtle text-primary">
                                                                    {{ $discount['name'] ?? '—' }}
                                                                    · {{ $formatMoney($discount['amount'] ?? 0) }}
                                                                    <span class="ms-1">{{ $badgeLabel }}</span>
                                                                    @if($applications > 1)
                                                                        <span class="ms-1">x{{ $applications }}</span>
                                                                    @endif
                                                                </span>
                                                            @endforeach
                                                        </div>
                                                    @else
                                                        <p class="small text-muted mb-0">Sin descuentos en este ticket.</p>
                                                    @endif
                                                </div>
                                                <div class="col-12 col-md-4">
                                                    <h6 class="fw-semibold mb-2">Movimientos</h6>
                                                    @if($transactions->isNotEmpty())
                                                        <div class="d-flex flex-wrap gap-1">
                                                            @foreach($transactions as $tx)
                                                                @php
                                                                    $txLabel = trim($tx['payment_type'] ?? '');
                                                                    if (!empty($tx['transaction_type']) && $tx['transaction_type'] !== $tx['payment_type']) {
                                                                        $txLabel .= ' / ' . $tx['transaction_type'];
                                                                    }
                                                                    $txLabel = $txLabel !== '' ? $txLabel : 'SIN TIPO';
                                                                    $amount = (float) ($tx['amount'] ?? 0);
                                                                    $displayAmount = ($amount < 0 ? '-' : '+') . $formatMoney(abs($amount));
                                                                    $txClass = 'bg-success-subtle text-success';
                                                                    if (!empty($tx['is_refund'])) {
                                                                        $txClass = 'bg-warning-subtle text-warning';
                                                                    } elseif (!empty($tx['is_void'])) {
                                                                        $txClass = 'bg-dark-subtle text-dark';
                                                                    } elseif (!empty($tx['is_adjustment'])) {
                                                                        $txClass = 'bg-danger-subtle text-danger';
                                                                    }
                                                                @endphp
                                                                <span class="badge {{ $txClass }}">
                                                                    {{ $txLabel }} · {{ $displayAmount }}
                                                                    @if(!empty($tx['voided']))
                                                                        <span class="ms-1">void</span>
                                                                    @endif
                                                                </span>
                                                            @endforeach
                                                        </div>
                                                    @else
                                                        <p class="small text-muted mb-0">Sin movimientos registrados.</p>
                                                    @endif
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="9" class="text-center text-muted py-4">Sin registros para esta categoría.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    @empty
        <div class="card border-0 shadow-sm">
            <div class="card-body text-center py-5">
                <i class="fa-solid fa-circle-check text-success mb-3" style="font-size: 2.5rem;"></i>
                <h5 class="fw-semibold mb-1">Sin excepciones detectadas</h5>
                <p class="text-muted mb-0">No se encontraron anomalías en el rango seleccionado.</p>
            </div>
        </div>
    @endforelse
</section>
@endsection
