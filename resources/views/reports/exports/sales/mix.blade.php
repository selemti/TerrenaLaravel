@php use Carbon\Carbon; @endphp
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Mix de ventas - {{ $startDate->format('Y-m-d') }}_{{ $endDate->format('Y-m-d') }}</title>
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
        .muted { color: #6b7280; }
    </style>
</head>
<body>
    <h1>Reporte - Mix de ventas</h1>
    <p><strong>Desde:</strong> {{ $startDate->format('d/m/Y') }}</p>
    <p><strong>Hasta:</strong> {{ $endDate->format('d/m/Y') }}</p>
    <p><strong>Sucursal:</strong> {{ $branch ?? 'Todas' }}</p>
    <p class="small">Generado: {{ $generatedAt->format('d/m/Y H:i') }}</p>

    <h2>Resumen general</h2>
    <table>
        <tbody>
            <tr>
                <td>Ventas totales</td>
                <td class="text-right">${{ number_format($summary['total_general'] ?? 0, 2) }}</td>
            </tr>
            <tr>
                <td>Formas de pago activas</td>
                <td class="text-right">{{ $summary['metrics']['total_methods'] ?? 0 }}</td>
            </tr>
            <tr>
                <td>Sucursales con operaciones</td>
                <td class="text-right">{{ $summary['metrics']['total_branches'] ?? 0 }}</td>
            </tr>
        </tbody>
    </table>

    <h2>Distribución por forma de pago</h2>
    <table>
        <thead>
            <tr>
                <th>Forma</th>
                <th class="text-right">Monto</th>
                <th class="text-right">Participación</th>
            </tr>
        </thead>
        <tbody>
            @foreach($summary['payments'] ?? [] as $payment)
                <tr>
                    <td>{{ $payment['label'] ?? $payment['key'] }}</td>
                    <td class="text-right">${{ number_format($payment['amount'] ?? 0, 2) }}</td>
                    <td class="text-right">{{ number_format($payment['percentage'] ?? 0, 2) }}%</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <h2>Detalle por sucursal</h2>
    <table>
        <thead>
            <tr>
                <th>Sucursal</th>
                <th class="text-right">Monto</th>
                <th class="text-right">Participación</th>
            </tr>
        </thead>
        <tbody>
            @foreach($summary['branches'] ?? [] as $row)
                <tr>
                    <td>{{ $row['label'] ?? $row['key'] }}</td>
                    <td class="text-right">${{ number_format($row['amount'] ?? 0, 2) }}</td>
                    <td class="text-right">{{ number_format($row['percentage'] ?? 0, 2) }}%</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <h2>Detalle de registros</h2>
    <table>
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Sucursal</th>
                <th>Forma de pago</th>
                <th class="text-right">Monto</th>
            </tr>
        </thead>
        <tbody>
            @foreach($rows as $row)
                <tr>
                    <td>{{ isset($row->report_date) ? Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                    <td>{{ $row->branch_key ?? $row->branch ?? $row->branch_name ?? 'N/D' }}</td>
                    <td>{{ $row->normalized_payment ?? $row->payment_method ?? 'N/D' }}</td>
                    <td class="text-right">${{ number_format((float) ($row->total ?? 0), 2) }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
