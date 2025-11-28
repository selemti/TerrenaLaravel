{{-- Tabla para vista summary_item_mods --}}
@php
    $hasFecha = $rows->isNotEmpty() && isset($rows->first()->fecha);
@endphp

<table class="table table-hover align-middle mb-0">
    <thead class="table-light">
        <tr>
            @if($hasFecha)
                <th>Fecha</th>
            @endif
            <th>Categoría</th>
            <th>Grupo menú</th>
            <th>Menú Item</th>
            <th>Grupo mod</th>
            <th>Modificador</th>
            <th class="text-end">Precio extra</th>
            <th>Sucursal</th>
            <th class="text-center">Terminal</th>
            <th class="text-end">Unidades</th>
            <th class="text-end">Selecciones</th>
            <th class="text-end">Monto extra</th>
        </tr>
    </thead>
    <tbody>
        @foreach($rows as $row)
            <tr>
                @if($hasFecha)
                    <td>{{ isset($row->fecha) ? \Carbon\Carbon::parse($row->fecha)->format('d/m/Y') : '—' }}</td>
                @endif
                <td>{{ $row->categoria ?? '—' }}</td>
                <td>{{ $row->grupo_menu ?? '—' }}</td>
                <td class="fw-semibold">{{ $row->menu_item ?? '—' }}</td>
                <td>{{ $row->grupo_modificador ?? '—' }}</td>
                <td>{{ $row->modificador ?? '—' }}</td>
                <td class="text-end">${{ number_format((float) ($row->precio_extra_mod ?? 0), 2) }}</td>
                <td>{{ $row->sucursal ?? '—' }}</td>
                <td class="text-center">{{ $row->terminal ?? '—' }}</td>
                <td class="text-end">{{ number_format((int) ($row->unidades_item ?? 0)) }}</td>
                <td class="text-end">{{ number_format((int) ($row->selecciones_modificador ?? 0)) }}</td>
                <td class="text-end fw-semibold">${{ number_format((float) ($row->monto_extra_modificador ?? 0), 2) }}</td>
            </tr>
        @endforeach
    </tbody>
</table>
