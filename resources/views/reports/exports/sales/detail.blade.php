@php use Carbon\Carbon; @endphp
<h3>Detalle de ventas</h3>
<p>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
@if($branch)<p>Sucursal: {{ $branch }}</p>@endif
@if($terminal)<p>Terminal: {{ $terminal }}</p>@endif
<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Sucursal</th>
        <th>Terminal</th>
        <th>Ticket</th>
        <th>Item</th>
        <th style="text-align:right">Cant.</th>
        <th style="text-align:right">Unitario</th>
        <th style="text-align:right">Descuento</th>
        <th style="text-align:right">Neto</th>
    </tr>
    </thead>
    <tbody>
    @foreach($rows as $r)
        <tr>
            <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
            <td>{{ $r->branch_key ?? '' }}</td>
            <td>{{ $r->terminal_id ?? '' }}</td>
            <td>{{ $r->ticket_id ?? '' }}</td>
            <td>{{ $r->item_name ?? '' }}</td>
            <td style="text-align:right">{{ number_format((float)($r->qty ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->unit_price ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->line_discount ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->line_neto ?? 0), 2) }}</td>
        </tr>
    @endforeach
    </tbody>
</table>
