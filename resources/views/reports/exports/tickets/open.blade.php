@php
    use Carbon\Carbon;

    $formatMoney = fn ($value) => '$' . number_format((float) $value, 2);
    $formatDate = fn ($date) => $date ? Carbon::parse($date)->format('d/m/Y H:i') : '-';
    $formatHours = fn ($hours) => number_format((float) $hours, 1) . 'h';
@endphp

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Reporte de Cuentas Abiertas/Pagadas</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 10pt;
            margin: 20px;
        }
        h1 {
            font-size: 18pt;
            margin-bottom: 5px;
        }
        h2 {
            font-size: 14pt;
            margin-top: 20px;
            margin-bottom: 10px;
            border-bottom: 2px solid #333;
            padding-bottom: 5px;
        }
        .header-info {
            margin-bottom: 20px;
            font-size: 9pt;
            color: #666;
        }
        .summary-grid {
            display: table;
            width: 100%;
            margin-bottom: 20px;
        }
        .summary-item {
            display: table-cell;
            width: 25%;
            padding: 10px;
            border: 1px solid #ddd;
            background-color: #f9f9f9;
        }
        .summary-label {
            font-size: 8pt;
            text-transform: uppercase;
            color: #666;
            margin-bottom: 3px;
        }
        .summary-value {
            font-size: 14pt;
            font-weight: bold;
        }
        .summary-sub {
            font-size: 8pt;
            color: #666;
            margin-top: 3px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 6px 8px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f0f0f0;
            font-weight: bold;
            font-size: 9pt;
        }
        td {
            font-size: 9pt;
        }
        .text-end {
            text-align: right;
        }
        .text-center {
            text-align: center;
        }
        .font-monospace {
            font-family: 'Courier New', monospace;
        }
        .text-danger {
            color: #dc3545;
            font-weight: bold;
        }
        .alert {
            padding: 12px;
            margin-bottom: 20px;
            border: 1px solid #f59e0b;
            background-color: #fef3c7;
            border-radius: 4px;
        }
        .alert-icon {
            font-weight: bold;
            margin-right: 5px;
        }
        tfoot td {
            font-weight: bold;
            background-color: #f0f0f0;
        }
        .footer {
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #ddd;
            font-size: 8pt;
            color: #666;
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>Reporte de Cuentas Abiertas/Pagadas</h1>
    <div class="header-info">
        <div>Rango: {{ $startDate->format('d/m/Y') }} — {{ $endDate->format('d/m/Y') }}</div>
        @if($branch)
            <div>Sucursal: {{ $branch }}</div>
        @endif
        <div>Generado: {{ $generatedAt->format('d/m/Y H:i:s') }}</div>
    </div>

    {{-- Resumen --}}
    <div class="summary-grid">
        <div class="summary-item">
            <div class="summary-label">Cuentas Abiertas</div>
            <div class="summary-value" style="color: #f59e0b;">{{ $summary['total_open'] }}</div>
            <div class="summary-sub">{{ $formatMoney($summary['amount_open']) }}</div>
        </div>
        <div class="summary-item">
            <div class="summary-label">Cuentas Pagadas</div>
            <div class="summary-value" style="color: #10b981;">{{ $summary['total_paid'] }}</div>
            <div class="summary-sub">{{ $formatMoney($summary['amount_paid']) }}</div>
        </div>
        <div class="summary-item">
            <div class="summary-label">Monto Total Abierto</div>
            <div class="summary-value">{{ $formatMoney($summary['amount_open']) }}</div>
        </div>
        <div class="summary-item">
            <div class="summary-label">Cuenta Más Antigua</div>
            @if($summary['oldest_open'])
                <div class="summary-value">{{ $formatHours($summary['oldest_open']->hours_open ?? 0) }}</div>
                <div class="summary-sub">Ticket #{{ $summary['oldest_open']->id ?? '-' }}</div>
            @else
                <div class="summary-value">-</div>
            @endif
        </div>
    </div>

    {{-- Alerta si hay cuentas antiguas --}}
    @if($summary['oldest_open'] && $summary['oldest_open']->hours_open > 24)
        <div class="alert">
            <span class="alert-icon">⚠</span>
            <strong>Atención:</strong> Hay cuentas abiertas con más de 24 horas.
            La cuenta más antigua tiene {{ $formatHours($summary['oldest_open']->hours_open) }} abierta.
            Esto puede afectar los cortes de caja.
        </div>
    @endif

    {{-- Tabla de Cuentas Abiertas --}}
    @if(count($openTickets) > 0 && ($status === 'all' || $status === 'open'))
        <h2>Cuentas Abiertas ({{ count($openTickets) }})</h2>
        <table>
            <thead>
                <tr>
                    <th>Ticket ID</th>
                    <th>Folio</th>
                    <th>Fecha Creación</th>
                    <th>Tiempo Abierto</th>
                    <th>Terminal</th>
                    <th>Sucursal</th>
                    <th class="text-end">Monto</th>
                </tr>
            </thead>
            <tbody>
                @foreach($openTickets as $ticket)
                    <tr>
                        <td class="font-monospace">#{{ $ticket->id }}</td>
                        <td>{{ $ticket->daily_folio ?? '-' }}</td>
                        <td>{{ $formatDate($ticket->create_date) }}</td>
                        <td class="{{ $ticket->hours_open > 24 ? 'text-danger' : '' }}">
                            {{ $formatHours($ticket->hours_open) }}
                        </td>
                        <td>{{ $ticket->terminal_name }}</td>
                        <td>{{ $ticket->branch_name }}</td>
                        <td class="text-end font-monospace">{{ $formatMoney($ticket->total_price) }}</td>
                    </tr>
                @endforeach
            </tbody>
            <tfoot>
                <tr>
                    <td colspan="6" class="text-end">Total:</td>
                    <td class="text-end font-monospace">{{ $formatMoney($summary['amount_open']) }}</td>
                </tr>
            </tfoot>
        </table>
    @endif

    {{-- Tabla de Cuentas Pagadas --}}
    @if(count($paidTickets) > 0 && ($status === 'all' || $status === 'paid'))
        <h2>Cuentas Pagadas ({{ count($paidTickets) }})</h2>
        <table>
            <thead>
                <tr>
                    <th>Ticket ID</th>
                    <th>Folio</th>
                    <th>Fecha Creación</th>
                    <th>Fecha Cierre</th>
                    <th>Terminal</th>
                    <th>Sucursal</th>
                    <th class="text-end">Monto</th>
                </tr>
            </thead>
            <tbody>
                @foreach($paidTickets as $ticket)
                    <tr>
                        <td class="font-monospace">#{{ $ticket->id }}</td>
                        <td>{{ $ticket->daily_folio ?? '-' }}</td>
                        <td>{{ $formatDate($ticket->create_date) }}</td>
                        <td>{{ $formatDate($ticket->closing_date) }}</td>
                        <td>{{ $ticket->terminal_name }}</td>
                        <td>{{ $ticket->branch_name }}</td>
                        <td class="text-end font-monospace">{{ $formatMoney($ticket->total_price) }}</td>
                    </tr>
                @endforeach
            </tbody>
            <tfoot>
                <tr>
                    <td colspan="6" class="text-end">Total:</td>
                    <td class="text-end font-monospace">{{ $formatMoney($summary['amount_paid']) }}</td>
                </tr>
            </tfoot>
        </table>
    @endif

    <div class="footer">
        Reporte generado por Terrena ERP • {{ $generatedAt->format('d/m/Y H:i:s') }}
    </div>
</body>
</html>
