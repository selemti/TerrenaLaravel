{{-- Tabla para vista legacy (función original f_item_mods_on) --}}
<table class="table table-hover align-middle mb-0">
    <thead class="table-light">
        <tr>
            <th>Fecha</th>
            <th>Ítem</th>
            <th>Modificador</th>
            <th class="text-end">Cantidad ítem</th>
            <th class="text-end">Veces seleccionado</th>
            <th class="text-end">Monto extra</th>
            <th>Sucursal</th>
        </tr>
    </thead>
    <tbody>
        @foreach($rows as $row)
            <tr>
                <td>{{ isset($row->report_date) ? \Carbon\Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                <td class="fw-semibold">{{ $row->item_name ?? '—' }}</td>
                <td>{{ $row->modifier_name ?? '—' }}</td>
                <td class="text-end">{{ number_format((float) ($row->qty_item ?? 0), 2) }}</td>
                <td class="text-end">{{ number_format((int) ($row->mods_count ?? 0)) }}</td>
                <td class="text-end">${{ number_format((float) ($row->mods_total_amount ?? 0), 2) }}</td>
                <td>{{ $row->branch_key ?? '—' }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
