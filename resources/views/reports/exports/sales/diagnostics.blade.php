@php use Carbon\Carbon; @endphp
@php
    use Carbon\Carbon;

    $diagLabels = [
        'vw_diag_neto_vs_cobros' => 'Neto vs cobros',
        'vw_diag_discount_header_vs_lines' => 'Descuentos encabezado vs líneas',
        'vw_diag_paid_but_no_payments' => 'Tickets pagados sin pagos',
        'vw_diag_unnormalized_payments' => 'Pagos sin normalizar',
        'vw_diag_service_charge_vs_paid' => 'Servicio vs pagos',
        'vw_diag_drawer_vs_cash_transactions' => 'Cajón vs efectivo',
        'vw_diag_orphans_tickets' => 'Tickets huérfanos',
        'vw_diag_orphans_tx' => 'Transacciones huérfanas',
        'vw_diag_high_discounts' => 'Descuentos altos',
    ];
@endphp
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Diagnósticos diarios - {{ $startDate->format('Y-m-d') }}_{{ $endDate->format('Y-m-d') }}</title>
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
    <h1>Reporte - Diagnósticos diarios</h1>
    <p><strong>Desde:</strong> {{ $startDate->format('d/m/Y') }}</p>
    <p><strong>Hasta:</strong> {{ $endDate->format('d/m/Y') }}</p>
    <p><strong>Severidad:</strong> {{ $severity ?? 'Todas' }}</p>
    <p class="small">Generado: {{ $generatedAt->format('d/m/Y H:i') }}</p>

    <h2>Resumen general</h2>
    <table>
        <tbody>
            <tr>
                <td>Verificaciones totales</td>
                <td class="text-right">{{ $summary['total_checks'] }}</td>
            </tr>
            <tr>
                <td>Coincidencias con filtros</td>
                <td class="text-right">{{ $summary['filtered_count'] }}</td>
            </tr>
            <tr>
                <td>Filas afectadas</td>
                <td class="text-right">{{ number_format($summary['total_rows_affected']) }}</td>
            </tr>
        </tbody>
    </table>

    <h2>Distribución por severidad</h2>
    <table>
        <thead>
            <tr>
                <th>Severidad</th>
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

    <h2>Vistas monitorizadas</h2>
    <table>
        <thead>
            <tr>
                <th>Vista / flujo</th>
                <th>Fecha</th>
                <th class="text-center">Severidad</th>
                <th class="text-right">Filas detectadas</th>
            </tr>
        </thead>
        <tbody>
            @foreach($summary['views'] as $viewRow)
                <tr>
                    <td>{{ $viewRow['view'] }}</td>
                    <td>{{ $viewRow['report_date'] ? Carbon::parse($viewRow['report_date'])->format('d/m/Y') : '—' }}</td>
                    <td class="text-center">{{ $viewRow['severity'] }}</td>
                    <td class="text-right">{{ number_format($viewRow['count']) }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <h2>Detalle de diagnósticos</h2>
    <table>
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Vista origen</th>
                <th class="text-center">Severidad</th>
                <th class="text-right">Filas afectadas</th>
            </tr>
        </thead>
        <tbody>
            @foreach($rows as $row)
                <tr>
                    <td>{{ isset($row->report_date) ? Carbon::parse($row->report_date)->format('d/m/Y') : $startDate->format('d/m/Y') }}</td>
                    <td>{{ $diagLabels[$row->source_view ?? ''] ?? ($row->source_view ?? 'N/D') }}</td>
                    <td class="text-center">{{ strtoupper((string) ($row->severity ?? 'INFO')) }}</td>
                    <td class="text-right">{{ number_format((int) ($row->rows ?? 0)) }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
