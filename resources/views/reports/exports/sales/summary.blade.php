@php use Carbon\Carbon; @endphp
<h3>Resumen de ventas</h3>
<p>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
@if($branch)<p>Sucursal: {{ $branch }}</p>@endif
<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Sucursal</th>
        <th style="text-align:right">Tickets</th>
        <th style="text-align:right">Bruto</th>
        <th style="text-align:right">Descuento</th>
        <th style="text-align:right">Neto</th>
        <th style="text-align:right">Propina</th>
        <th style="text-align:right">Servicio</th>
    </tr>
    </thead>
    <tbody>
    @foreach($rows as $r)
        <tr>
            <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
            <td>{{ $r->branch_key ?? '' }}</td>
            <td style="text-align:right">{{ (int)($r->tickets ?? 0) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->bruto ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->descuento ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->neto ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->propina ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($r->cargo_servicio ?? 0), 2) }}</td>
        </tr>
    @endforeach
    </tbody>
 </table>
