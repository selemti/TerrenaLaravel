@php use Carbon\Carbon; @endphp
@php use Carbon\Carbon; @endphp
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Cajón vs efectivo - {{ $startDate->format('Y-m-d') }}_{{ $endDate->format('Y-m-d') }}</title>
    <style>
        body { font-family: "DejaVu Sans", Arial, sans-serif; font-size: 12px; color: #1f2937; margin: 24px; }
        h1 { font-size: 20px; margin-bottom: 4px; }
        h2 { font-size: 16px; margin-top: 24px; margin-bottom: 8px; }
        p { margin: 4px 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { border: 1px solid #d1d5db; padding: 6px 8px; text-align: left; }
        th { background-color: #f3f4f6; font-weight: bold; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .small { font-size: 11px; color: #6b7280; }
    </style>
</head>
<body>
    <h1>Reporte - Cajón vs efectivo</h1>
    <p><strong>Desde:</strong> {{ $startDate->format('d/m/Y') }}</p>
    <p><strong>Hasta:</strong> {{ $endDate->format('d/m/Y') }}</p>
    <p><strong>Sucursal:</strong> {{ $branch ?? 'Todas' }}</p>
    <p><strong>Severidad:</strong> {{ $severity ?? 'Todas' }}</p>
    <p class="small">Generado: {{ $generatedAt->format('d/m/Y H:i') }}</p>

    <h2>Resumen general</h2>
    <table>
        <tbody>
            <tr>
                <td>Terminales evaluadas</td>
                <td class="text-right">{{ $summary['total_terminals'] }}</td>
            </tr>
            <tr>
                <td>Terminales con discrepancia</td>
                <td class="text-right">{{ $summary['discrepancies_count'] }}</td>
            </tr>
            <tr>
                <td>Total esperado</td>
                <td class="text-right">${{ number_format($summary['total_expected'], 2) }}</td>
            </tr>
            <tr>
                <td>Total registrado</td>
                <td class="text-right">${{ number_format($summary['total_registered'], 2) }}</td>
            </tr>
            <tr>
                <td>Diferencia neta</td>
                <td class="text-right">${{ number_format($summary['total_difference'], 2) }}</td>
            </tr>
        </tbody>
    </table>

    <h2>Severidad</h2>
    <table>
        <thead>
            <tr>
                <th>Tipo</th>
                <th class="text-right">Cantidad</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>CRITICAL</td>
                <td class="text-right">{{ $summary['critical_count'] }}</td>
            </tr>
            <tr>
                <td>WARN</td>
                <td class="text-right">{{ $summary['warning_count'] }}</td>
            </tr>
            <tr>
                <td>INFO</td>
                <td class="text-right">{{ $summary['info_count'] }}</td>
            </tr>
        </tbody>
    </table>

    <h2>Detalle por terminal</h2>
    <table>
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Terminal</th>
                <th>Sucursal</th>
                <th class="text-right">Esperado</th>
                <th class="text-right">Registrado</th>
                <th class="text-right">Diferencia</th>
                <th class="text-center">Severidad</th>
            </tr>
        </thead>
        <tbody>
            @foreach($rows as $row)
                <tr>
                    <td>{{ isset($row->report_date) ? Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                    <td>{{ $row->terminal ?? $row->terminal_name ?? 'N/D' }}</td>
                    <td>{{ $row->branch_key ?? $row->branch ?? $row->sucursal ?? 'N/D' }}</td>
                    <td class="text-right">${{ number_format((float) ($row->efectivo_esperado ?? 0), 2) }}</td>
                    <td class="text-right">${{ number_format((float) ($row->efectivo_registrado ?? 0), 2) }}</td>
                    <td class="text-right">${{ number_format((float) ($row->diferencia ?? 0), 2) }}</td>
                    <td class="text-center">{{ strtoupper((string) ($row->severidad ?? 'INFO')) }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <h2>Resumen por sucursal</h2>
    <table>
        <thead>
            <tr>
                <th>Sucursal</th>
                <th class="text-right">Esperado</th>
                <th class="text-right">Registrado</th>
                <th class="text-right">Diferencia</th>
            </tr>
        </thead>
        <tbody>
            @foreach($summary['branches'] as $branchRow)
                <tr>
                    <td>{{ $branchRow['label'] ?? $branchRow['key'] }}</td>
                    <td class="text-right">${{ number_format($branchRow['expected'] ?? 0, 2) }}</td>
                    <td class="text-right">${{ number_format($branchRow['registered'] ?? 0, 2) }}</td>
                    <td class="text-right">${{ number_format($branchRow['difference'] ?? 0, 2) }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
