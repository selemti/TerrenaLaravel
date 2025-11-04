@php use Carbon\Carbon; @endphp
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Ítems y modificadores - {{ $startDate->format('Y-m-d') }}_{{ $endDate->format('Y-m-d') }}</title>
    <style>
        body { font-family: "DejaVu Sans", Arial, sans-serif; font-size: 12px; color: #1f2937; margin: 24px; }
        h1 { font-size: 20px; margin-bottom: 4px; }
        h2 { font-size: 16px; margin-top: 24px; margin-bottom: 8px; }
        p { margin: 4px 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { border: 1px solid #d1d5db; padding: 6px 8px; text-align: left; }
        th { background-color: #f3f4f6; font-weight: bold; }
        .text-right { text-align: right; }
        .small { font-size: 11px; color: #6b7280; }
    </style>
</head>
<body>
    <h1>Reporte - Ítems con modificadores</h1>
    <p><strong>Desde:</strong> {{ $startDate->format('d/m/Y') }}</p>
    <p><strong>Hasta:</strong> {{ $endDate->format('d/m/Y') }}</p>
    <p><strong>Sucursal:</strong> {{ $branch ?? 'Todas' }}</p>
    <p class="small">Generado: {{ $generatedAt->format('d/m/Y H:i') }}</p>

    <h2>Resumen general</h2>
    <table>
        <tbody>
            <tr>
                <td>Ítems únicos</td>
                <td class="text-right">{{ $summary['total_items'] }}</td>
            </tr>
            <tr>
                <td>Modificadores únicos</td>
                <td class="text-right">{{ $summary['total_modifiers'] }}</td>
            </tr>
            <tr>
                <td>Combinaciones registradas</td>
                <td class="text-right">{{ $summary['total_combinations'] }}</td>
            </tr>
            <tr>
                <td>Monto adicional</td>
                <td class="text-right">${{ number_format($summary['total_amount'], 2) }}</td>
            </tr>
            <tr>
                <td>Selecciones</td>
                <td class="text-right">{{ number_format($summary['total_selections']) }}</td>
            </tr>
            <tr>
                <td>Promedio por selección</td>
                <td class="text-right">${{ number_format($summary['avg_amount_per_selection'], 2) }}</td>
            </tr>
        </tbody>
    </table>

    <h2>Top modificadores</h2>
    <table>
        <thead>
            <tr>
                <th>Modificador</th>
                <th class="text-right">Selecciones</th>
                <th class="text-right">Monto</th>
            </tr>
        </thead>
        <tbody>
            @foreach($summary['top_modifiers'] as $modifier)
                <tr>
                    <td>{{ $modifier['modifier'] }}</td>
                    <td class="text-right">{{ number_format($modifier['times_selected']) }}</td>
                    <td class="text-right">${{ number_format($modifier['amount'], 2) }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <h2>Detalle por ítem y modificador</h2>
    <table>
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Ítem</th>
                <th>Modificador</th>
                <th class="text-right">Cantidad ítem</th>
                <th class="text-right">Selecciones</th>
                <th class="text-right">Monto extra</th>
                <th>Sucursal</th>
            </tr>
        </thead>
        <tbody>
            @foreach($rows as $row)
                <tr>
                    <td>{{ isset($row->report_date) ? Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                    <td>{{ $row->item_name ?? 'N/D' }}</td>
                    <td>{{ $row->modifier_name ?? 'N/D' }}</td>
                    <td class="text-right">{{ number_format((float) ($row->qty_item ?? 0), 2) }}</td>
                    <td class="text-right">{{ number_format((int) ($row->mods_count ?? 0)) }}</td>
                    <td class="text-right">${{ number_format((float) ($row->mods_total_amount ?? 0), 2) }}</td>
                    <td>{{ $row->branch_key ?? 'N/D' }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
