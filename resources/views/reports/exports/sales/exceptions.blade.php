@php use Carbon\Carbon; @endphp
<h3>Excepciones</h3>
<p>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</p>
@if($branch)<p>Sucursal: {{ $branch }}</p>@endif
<table width="100%" border="1" cellspacing="0" cellpadding="4">
    <thead>
    <tr>
        <th>Fecha</th>
        <th>Sucursal</th>
        <th>Ticket</th>
        <th>Código</th>
        <th>Severidad</th>
        <th style="text-align:right">Valor</th>
    </tr>
    </thead>
    <tbody>
    @foreach($rows as $r)
        <tr>
            <td>{{ isset($r->folio_date) ? Carbon::parse($r->folio_date)->format('d/m/Y') : '' }}</td>
            <td>{{ $r->branch_key ?? '' }}</td>
            <td>{{ $r->ticket_id ?? '' }}</td>
            <td>{{ $r->error_code ?? '' }}</td>
            <td>{{ $r->severity ?? '' }}</td>
            <td style="text-align:right">{{ number_format((float)($r->diff ?? 0), 2) }}</td>
        </tr>
    @endforeach
    </tbody>
</table>
