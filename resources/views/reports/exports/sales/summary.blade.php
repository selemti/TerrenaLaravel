@php
    use Carbon\Carbon;

    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
    $formatSigned = fn ($value) => ($value < 0 ? '-$' : '$') . number_format(abs((float) $value), 2);
@endphp

<h3>Resumen de ventas</h3>
<p>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
@if(!empty($branchFilter))
    <p>Sucursales: {{ implode(', ', $branchFilter) }}</p>
@endif
@if(!empty($terminalFilter))
    <p>Terminales: {{ implode(', ', $terminalFilter) }}</p>
@endif

<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Sucursal</th>
        <th>Terminales</th>
        <th style="text-align:right">Tickets</th>
        <th style="text-align:right">Bruto</th>
        <th style="text-align:right">Descuentos</th>
        <th style="text-align:right">Anul./Devol.</th>
        <th style="text-align:right">Venta neta</th>
        <th style="text-align:right">Pagos netos</th>
        <th style="text-align:right">Brecha</th>
        <th style="text-align:right">% Ajuste</th>
        <th>Alertas</th>
    </tr>
    </thead>
    <tbody>
    @foreach($rows as $row)
        @php
            $terminals = $row['terminals'] ?? [];
            $delta = $row['payments_delta'] ?? 0;
            $discountRate = $row['discount_rate'] ?? 0;
            $alerts = $row['exception_codes_list'] ?? [];
        @endphp
        <tr>
            <td>{{ Carbon::parse($row['folio_date'])->format('d/m/Y') }}</td>
            <td>{{ $row['branch_label'] ?? $row['branch_key'] }}</td>
            <td>{{ !empty($terminals) ? implode(', ', $terminals) : '—' }}</td>
            <td style="text-align:right">{{ number_format($row['tickets']) }}</td>
            <td style="text-align:right">{{ $formatMoney($row['bruto']) }}</td>
            <td style="text-align:right">{{ $formatSigned(-1 * $row['descuento']) }}</td>
            <td style="text-align:right">{{ $formatSigned(-1 * $row['anulaciones']) }}</td>
            <td style="text-align:right">{{ $formatMoney($row['neto']) }}</td>
            <td style="text-align:right">{{ $formatMoney($row['pagos_netos']) }}</td>
            <td style="text-align:right">{{ $formatSigned($delta) }}</td>
            <td style="text-align:right">
                @if($discountRate)
                    {{ number_format($discountRate, 1) }}%
                @else
                    —
                @endif
            </td>
            <td>{{ !empty($alerts) ? implode(', ', $alerts) : '—' }}</td>
        </tr>
    @endforeach
    </tbody>
    <tfoot>
        @php
            $totalDelta = $totals['delta_pagos'] ?? 0;
            $totalAdjustPct = ($totals['bruto'] ?? 0) > 0
                ? (($totals['descuento'] + $totals['anulaciones']) / max(0.01, $totals['bruto'])) * 100
                : 0;
        @endphp
        <tr>
            <th colspan="3">Totales</th>
            <th style="text-align:right">{{ number_format($totals['tickets']) }}</th>
            <th style="text-align:right">{{ $formatMoney($totals['bruto']) }}</th>
            <th style="text-align:right">{{ $formatSigned(-1 * $totals['descuento']) }}</th>
            <th style="text-align:right">{{ $formatSigned(-1 * $totals['anulaciones']) }}</th>
            <th style="text-align:right">{{ $formatMoney($totals['neto']) }}</th>
            <th style="text-align:right">{{ $formatMoney($totals['pagos_netos']) }}</th>
            <th style="text-align:right">{{ $formatSigned($totalDelta) }}</th>
            <th style="text-align:right">
                @if($totalAdjustPct)
                    {{ number_format($totalAdjustPct, 1) }}%
                @else
                    —
                @endif
            </th>
            <th></th>
        </tr>
    </tfoot>
</table>
