@php use Carbon\Carbon; @endphp
<h3>Uso de menú</h3>
<p>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
@if($branch)<p>Sucursal: {{ $branch }}</p>@endif
<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Sucursal</th>
        <th>Item</th>
        <th style="text-align:right">Cant.</th>
        <th style="text-align:right">Neto</th>
    </tr>
    </thead>
    <tbody>
    @foreach($rows as $r)
        <tr>
            <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
            <td>{{ $r->branch_key ?? '' }}</td>
            <td>{{ $r->item_name ?? '' }}</td>
            <td style="text-align:right">{{ number_format((float)($r->qty ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->neto ?? 0), 2) }}</td>
        </tr>
    @endforeach
    </tbody>
</table>
