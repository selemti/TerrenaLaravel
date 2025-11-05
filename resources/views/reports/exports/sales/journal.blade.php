@php use Carbon\Carbon; @endphp
<h3>Journal</h3>
<p>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
@if($branch)<p>Sucursal: {{ $branch }}</p>@endif

<h4>Líneas</h4>
<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Ticket</th>
        <th>Item</th>
        <th style="text-align:right">Cant.</th>
        <th style="text-align:right">Total</th>
        <th style="text-align:right">Desc.</th>
    </tr>
    </thead>
    <tbody>
    @foreach($lines as $r)
        <tr>
            <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
            <td>{{ $r->ticket_id ?? '' }}</td>
            <td>{{ $r->item_name ?? '' }}</td>
            <td style="text-align:right">{{ number_format((float)($r->qty ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->line_total ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->line_discount ?? 0), 2) }}</td>
        </tr>
    @endforeach
    </tbody>
</table>

<h4>Pagos</h4>
<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Ticket</th>
        <th>Forma</th>
        <th style="text-align:right">Monto</th>
    </tr>
    </thead>
    <tbody>
    @foreach($payments as $r)
        <tr>
            <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
            <td>{{ $r->ticket_id ?? '' }}</td>
            <td>{{ $r->pay_norm ?? '' }}</td>
            <td style="text-align:right">{{ number_format((float)($r->paid_amount ?? 0), 2) }}</td>
        </tr>
    @endforeach
    </tbody>
</table>
