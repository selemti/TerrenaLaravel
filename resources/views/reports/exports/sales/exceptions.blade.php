@php
    use Carbon\Carbon;

    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
    $categories = isset($categories)
        ? ($categories instanceof \Illuminate\Support\Collection ? $categories : collect($categories))
        : collect();
    $summary = $summary ?? [];
    $discountSummary = isset($discountSummary)
        ? ($discountSummary instanceof \Illuminate\Support\Collection ? $discountSummary : collect($discountSummary))
        : collect();
@endphp

<h3>Excepciones de Ventas</h3>
<p>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
@if($branch)<p>Sucursal: {{ $branch }}</p>@endif
@if($terminal)<p>Terminal: {{ $terminal }}</p>@endif
<p>Generado: {{ $generatedAt->format('d/m/Y H:i') }}</p>

@if(!empty($summary))
    <table width="100%" border="1" cellspacing="0" cellpadding="4" style="margin-bottom: 12px;">
        <thead>
        <tr>
            <th>Total registros</th>
            <th>Tickets impactados</th>
            <th>Impacto</th>
        </tr>
        </thead>
        <tbody>
        <tr>
            <td>{{ $summary['total_records'] ?? 0 }}</td>
            <td>{{ $summary['total_tickets'] ?? 0 }}</td>
            <td>{{ $formatMoney($summary['impact_sum'] ?? 0) }}</td>
        </tr>
        </tbody>
    </table>
@endif

@if($discountSummary->isNotEmpty())
    <table width="100%" border="1" cellspacing="0" cellpadding="4" style="margin-bottom: 12px;">
        <thead>
        <tr>
            <th>Descuento</th>
            <th>Aplicaciones</th>
            <th>Tickets</th>
            <th>Total</th>
            <th>Promedio</th>
            <th>Ticket</th>
            <th>Item</th>
        </tr>
        </thead>
        <tbody>
        @foreach($discountSummary as $discount)
            @php
                $scopes = $discount['scopes'] ?? [];
            @endphp
            <tr>
                <td>{{ $discount['name'] ?? '—' }}</td>
                <td style="text-align:right">{{ $discount['applications'] ?? 0 }}</td>
                <td style="text-align:right">{{ $discount['tickets'] ?? 0 }}</td>
                <td style="text-align:right">{{ $formatMoney($discount['total_amount'] ?? 0) }}</td>
                <td style="text-align:right">{{ $formatMoney($discount['average_amount'] ?? 0) }}</td>
                <td style="text-align:right">{{ $scopes['ticket'] ?? 0 }}</td>
                <td style="text-align:right">{{ $scopes['item'] ?? 0 }}</td>
            </tr>
        @endforeach
        </tbody>
    </table>
@endif

@if($categories->isEmpty())
    <p><em>No se detectaron excepciones en el rango seleccionado.</em></p>
@else
    @foreach($categories as $category)
        @php
            $rows = $category['rows'] instanceof \Illuminate\Support\Collection
                ? $category['rows']
                : collect($category['rows'] ?? []);
            $impactLabel = $category['impact_label'] ?? 'Impacto';
        @endphp

        <h4 style="margin-bottom: 4px;">
            {{ $category['label'] ?? ($category['key'] ?? 'Categoría') }}
            ({{ $category['count'] ?? 0 }} registros · {{ $category['tickets'] ?? 0 }} tickets)
        </h4>
        <p style="margin-top: 0; font-size: 11px; color: #555;">
            {{ $category['description'] ?? 'Sin descripción disponible.' }}
        </p>

        <table width="100%" border="1" cellspacing="0" cellpadding="4" style="margin-bottom: 18px;">
            <thead>
            <tr>
                <th>Fecha</th>
                <th>Sucursal</th>
                <th>Ticket</th>
                <th>Terminal</th>
                <th style="text-align:right">Neto</th>
                <th style="text-align:right">Pagos</th>
                <th style="text-align:right">{{ $impactLabel }}</th>
                <th>Notas</th>
            </tr>
            </thead>
            <tbody>
            @forelse($rows as $row)
                @php
                    $notes = $row['notes'] ?? [];
                    $transactions = $row['transactions'] ?? [];
                    $notesSummary = implode('; ', $notes);
                    $txSummary = implode('; ', array_map(function ($tx) use ($formatMoney) {
                        $paymentType = strtoupper($tx['payment_type'] ?? '');
                        $transactionType = strtoupper($tx['transaction_type'] ?? '');
                        $label = $paymentType !== '' ? $paymentType : 'SIN TIPO';
                        if ($transactionType !== '' && $transactionType !== $paymentType) {
                            $label .= '/' . $transactionType;
                        }
                        $label .= ' ' . $formatMoney($tx['amount'] ?? 0);
                        if (!empty($tx['voided'])) {
                            $label .= ' (void)';
                        }
                        return $label;
                    }, $transactions));
                    $combinedNotes = trim($notesSummary . ($txSummary !== '' ? ' | Tx: ' . $txSummary : ''));
                @endphp
                <tr>
                    <td>{{ !empty($row['folio_date']) ? Carbon::parse($row['folio_date'])->format('d/m/Y') : '—' }}</td>
                    <td>{{ $row['branch_key'] ?? '—' }}</td>
                    <td>#{{ $row['ticket_id'] ?? '—' }}</td>
                    <td>{{ $row['terminal_id'] ?? '—' }}</td>
                    <td style="text-align:right">{{ $formatMoney($row['net_total'] ?? 0) }}</td>
                    <td style="text-align:right">{{ $formatMoney($row['payment_total'] ?? 0) }}</td>
                    <td style="text-align:right">{{ $formatMoney($row['impact'] ?? 0) }}</td>
                    <td>{{ $combinedNotes !== '' ? $combinedNotes : '—' }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="8" style="text-align:center; color:#666;">Sin registros para esta categoría.</td>
                </tr>
            @endforelse
            </tbody>
        </table>
    @endforeach
@endif
