{{-- Tabla para vista summary_items --}}
<table class="table table-hover align-middle mb-0">
    <thead class="table-light">
        <tr>
            <th>Categoría</th>
            <th>Grupo menú</th>
            <th>Menú Item</th>
            <th class="text-end">Precio ítem</th>
            <th class="text-end">Unidades</th>
            <th class="text-end">Ingreso bruto</th>
            <th class="text-end">Descuento</th>
            <th class="text-end">Ingreso neto</th>
        </tr>
    </thead>
    <tbody>
        @foreach($rows as $row)
            <tr>
                <td>{{ $row->categoria ?? '—' }}</td>
                <td>{{ $row->grupo_menu ?? '—' }}</td>
                <td class="fw-semibold">{{ $row->menu_item ?? '—' }}</td>
                <td class="text-end">${{ number_format((float) ($row->precio_item ?? 0), 2) }}</td>
                <td class="text-end">{{ number_format((int) ($row->unidades_vendidas ?? 0)) }}</td>
                <td class="text-end">${{ number_format((float) ($row->ingreso_bruto_item ?? 0), 2) }}</td>
                <td class="text-end text-danger">${{ number_format((float) ($row->descuento_item ?? 0), 2) }}</td>
                <td class="text-end fw-semibold">${{ number_format((float) ($row->ingreso_neto_item ?? 0), 2) }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
