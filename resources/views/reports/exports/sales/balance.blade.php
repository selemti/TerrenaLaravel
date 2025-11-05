@php use Carbon\Carbon; @endphp
<h3>Balance por forma de pago</h3>
<p>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
@if($branch)<p>Sucursal: {{ $branch }}</p>@endif

<h4>Detalle</h4>
<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Sucursal</th>
        <th>Forma</th>
        <th style="text-align:right">Monto</th>
    </tr>
    </thead>
    <tbody>
    @foreach($rows as $r)
        <tr>
            <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
            <td>{{ $r->branch_key ?? '' }}</td>
            <td>{{ $r->payment ?? '' }}</td>
            <td style="text-align:right">{{ number_format((float)($r->monto ?? 0), 2) }}</td>
        </tr>
    @endforeach
    </tbody>
</table>

<h4>Pivot por día / sucursal</h4>
<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Sucursal</th>
        <th style="text-align:right">Efectivo</th>
        <th style="text-align:right">Crédito</th>
        <th style="text-align:right">Débito</th>
        <th style="text-align:right">Otras</th>
        <th style="text-align:right">Venta neta</th>
    </tr>
    </thead>
    <tbody>
    @foreach($pivotRows as $p)
        <tr>
            <td>{{ isset($p['folio_date']) ? Carbon::parse($p['folio_date'])->format('d/m/Y') : '' }}</td>
            <td>{{ $p['branch_key'] ?? '' }}</td>
            <td style="text-align:right">{{ number_format((float)($p['cash'] ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($p['credit'] ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($p['debit'] ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($p['other'] ?? 0), 2) }}</td>
            <td style="text-align:right">{{ number_format((float)($p['net'] ?? 0), 2) }}</td>
        </tr>
    @endforeach
    </tbody>
</table>
