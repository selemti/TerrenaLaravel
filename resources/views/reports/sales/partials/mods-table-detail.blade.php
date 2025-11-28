{{-- Tabla para vista detail --}}
<table class="table table-hover align-middle mb-0">
    <thead class="table-light">
        <tr>
            <th>Fecha</th>
            <th>Ítem</th>
            <th>Modificador</th>
            <th class="text-end">Cantidad ítem</th>
            <th class="text-end">Selecciones</th>
            <th class="text-end">Monto extra</th>
            <th>Sucursal</th>
            <th class="text-center">Terminal</th>
            <th class="text-end">Ticket ID</th>
            <th class="text-end">TI ID</th>
        </tr>
    </thead>
    <tbody>
        @foreach($rows as $row)
            <tr>
                <td>{{ isset($row->fecha) ? \Carbon\Carbon::parse($row->fecha)->format('d/m/Y') : '—' }}</td>
                <td class="fw-semibold">{{ $row->item ?? '—' }}</td>
                <td>{{ $row->modificador ?? '—' }}</td>
                <td class="text-end">{{ number_format((float) ($row->cantidad_item ?? 0), 2) }}</td>
                <td class="text-end">{{ number_format((int) ($row->selecciones ?? 0)) }}</td>
                <td class="text-end">${{ number_format((float) ($row->monto_extra ?? 0), 2) }}</td>
                <td>{{ $row->sucursal ?? '—' }}</td>
                <td class="text-center">{{ $row->terminal ?? '—' }}</td>
                <td class="text-end text-muted small">{{ $row->ticket_id ?? '—' }}</td>
                <td class="text-end text-muted small">{{ $row->ticket_item_id ?? '—' }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
