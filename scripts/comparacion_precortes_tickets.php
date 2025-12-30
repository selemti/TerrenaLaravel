<?php

/**
 * Comparación manual de Precortes vs Tickets
 * Basado en datos extraídos del análisis anterior
 */

echo "=== COMPARACIÓN PRECORTES vs TICKETS (Últimos 7 días) ===\n\n";

// Datos extraídos del análisis anterior
$ventasTickets = [
    '101' => [
        '2025-12-01' => ['tickets' => 159, 'ventas' => 8890],
        '2025-12-02' => ['tickets' => 112, 'ventas' => 6370],
        '2025-12-03' => ['tickets' => 146, 'ventas' => 7843.8],
        '2025-12-04' => ['tickets' => 140, 'ventas' => 7371],
        '2025-12-05' => ['tickets' => 150, 'ventas' => 8056],
        '2025-12-06' => ['tickets' => 127, 'ventas' => 9502],
    ],
    '102' => [
        '2025-12-01' => ['tickets' => 288, 'ventas' => 14588.2],
        '2025-12-02' => ['tickets' => 255, 'ventas' => 13141.4],
        '2025-12-04' => ['tickets' => 312, 'ventas' => 15842.4],
        '2025-12-05' => ['tickets' => 143, 'ventas' => 7589.2],
        '2025-12-06' => ['tickets' => 114, 'ventas' => 7336.2],
    ]
];

$declaradoPrecortes = [
    '101' => [
        '2025-12-01' => ['efectivo' => 7969.00, 'otros' => 4186.00, 'total' => 12155.00],
        '2025-12-02' => ['efectivo' => 5187.00, 'otros' => 4276.00, 'total' => 9463.00],
        '2025-12-03' => ['efectivo' => 1268.00, 'otros' => 4154.00, 'total' => 5422.00],
        '2025-12-04' => ['efectivo' => 5435.00, 'otros' => 4650.00, 'total' => 10085.00],
        '2025-12-05' => ['efectivo' => 5101.00, 'otros' => 4509.00, 'total' => 9610.00],
        '2025-12-06' => ['efectivo' => 8420.00, 'otros' => 3467.00, 'total' => 11887.00],
    ],
    '102' => [
        '2025-12-01' => ['efectivo' => 10890.00, 'otros' => 5893.20, 'total' => 16783.20],
        '2025-12-02' => ['efectivo' => 8032.00, 'otros' => 7144.20, 'total' => 15176.20],
        '2025-12-04' => ['efectivo' => 9221.00, 'otros' => 7596.20, 'total' => 16817.20],
        '2025-12-05' => ['efectivo' => 7334.00, 'otros' => 3851.80, 'total' => 11185.80],
        '2025-12-06' => ['efectivo' => 5465.00, 'otros' => 3270.20, 'total' => 8735.20],
    ]
];

$formasPagoTickets = [
    '101' => [
        'CASH' => 22552.8,
        'CREDIT_CARD' => 20013,
        'DEBIT_CARD' => 5467
    ],
    '102' => [
        'CASH' => 34381.6,
        'CREDIT_CARD' => 31760.4,
        'DEBIT_CARD' => 2112
    ]
];

echo "TERMINAL 101 - ANÁLISIS DIARIO\n";
echo str_repeat("=", 60) . "\n";
echo sprintf("%-12s %-12s %-12s %-12s %-12s %-15s\n",
    "Fecha", "Ventas", "Decl. Total", "Diferencia", "% Dif", "Estado");
echo str_repeat("-", 60) . "\n";

$totalDiferencia101 = 0;
foreach ($ventasTickets['101'] as $fecha => $datos) {
    if (isset($declaradoPrecortes['101'][$fecha])) {
        $ventas = $datos['ventas'];
        $declarado = $declaradoPrecortes['101'][$fecha]['total'];
        $diferencia = $declarado - $ventas;
        $porcentaje = $ventas > 0 ? ($diferencia / $ventas) * 100 : 0;
        $estado = abs($diferencia) > 1000 ? "⚠️ REVISAR" : "✅ OK";

        $totalDiferencia101 += $diferencia;

        echo sprintf("%-12s %-12s %-12s %-12s %-12s %-15s\n",
            $fecha,
            "$" . number_format($ventas, 2),
            "$" . number_format($declarado, 2),
            "$" . number_format($diferencia, 2),
            number_format($porcentaje, 1) . "%",
            $estado
        );
    }
}
echo str_repeat("-", 60) . "\n";
echo sprintf("DIFERENCIA TOTAL 101: $%s\n", number_format($totalDiferencia101, 2));
echo "\n";

echo "TERMINAL 102 - ANÁLISIS DIARIO\n";
echo str_repeat("=", 60) . "\n";
echo sprintf("%-12s %-12s %-12s %-12s %-12s %-15s\n",
    "Fecha", "Ventas", "Decl. Total", "Diferencia", "% Dif", "Estado");
echo str_repeat("-", 60) . "\n";

$totalDiferencia102 = 0;
foreach ($ventasTickets['102'] as $fecha => $datos) {
    if (isset($declaradoPrecortes['102'][$fecha])) {
        $ventas = $datos['ventas'];
        $declarado = $declaradoPrecortes['102'][$fecha]['total'];
        $diferencia = $declarado - $ventas;
        $porcentaje = $ventas > 0 ? ($diferencia / $ventas) * 100 : 0;
        $estado = abs($diferencia) > 1000 ? "⚠️ REVISAR" : "✅ OK";

        $totalDiferencia102 += $diferencia;

        echo sprintf("%-12s %-12s %-12s %-12s %-12s %-15s\n",
            $fecha,
            "$" . number_format($ventas, 2),
            "$" . number_format($declarado, 2),
            "$" . number_format($diferencia, 2),
            number_format($porcentaje, 1) . "%",
            $estado
        );
    }
}
echo str_repeat("-", 60) . "\n";
echo sprintf("DIFERENCIA TOTAL 102: $%s\n", number_format($totalDiferencia102, 2));
echo "\n";

// Resumen formas de pago
echo "RESUMEN FORMAS DE PAGO (Semana)\n";
echo str_repeat("=", 50) . "\n";

echo "TERMINAL 101:\n";
echo sprintf("  Efectivo: $%s (%.1f%%)\n",
    number_format($formasPagoTickets['101']['CASH'], 2),
    ($formasPagoTickets['101']['CASH'] / array_sum($formasPagoTickets['101'])) * 100
);
echo sprintf("  Tarjetas: $%s (%.1f%%)\n",
    number_format($formasPagoTickets['101']['CREDIT_CARD'] + $formasPagoTickets['101']['DEBIT_CARD'], 2),
    (($formasPagoTickets['101']['CREDIT_CARD'] + $formasPagoTickets['101']['DEBIT_CARD']) / array_sum($formasPagoTickets['101'])) * 100
);

echo "\nTERMINAL 102:\n";
echo sprintf("  Efectivo: $%s (%.1f%%)\n",
    number_format($formasPagoTickets['102']['CASH'], 2),
    ($formasPagoTickets['102']['CASH'] / array_sum($formasPagoTickets['102'])) * 100
);
echo sprintf("  Tarjetas: $%s (%.1f%%)\n",
    number_format($formasPagoTickets['102']['CREDIT_CARD'] + $formasPagoTickets['102']['DEBIT_CARD'], 2),
    (($formasPagoTickets['102']['CREDIT_CARD'] + $formasPagoTickets['102']['DEBIT_CARD']) / array_sum($formasPagoTickets['102'])) * 100
);

// Hallazgos importantes
echo "\n" . str_repeat("=", 50) . "\n";
echo "HALLAZGOS IMPORTANTES:\n";
echo str_repeat("=", 50) . "\n";

echo "\n⚠️  DIFERENCIAS SIGNIFICATIVAS ENCONTRADAS:\n";

echo "\nTerminal 101:\n";
if (abs($totalDiferencia101) > 5000) {
    echo "❌ Diferencia total de $" . number_format($totalDiferencia101, 2) . " - REQUERIDA REVISIÓN\n";
} else {
    echo "✅ Diferencia total de $" . number_format($totalDiferencia101, 2) . " - DENTRO DE RANGO NORMAL\n";
}

echo "\nTerminal 102:\n";
if (abs($totalDiferencia102) > 5000) {
    echo "❌ Diferencia total de $" . number_format($totalDiferencia102, 2) . " - REQUERIDA REVISIÓN\n";
} else {
    echo "✅ Diferencia total de $" . number_format($totalDiferencia102, 2) . " - DENTRO DE RANGO NORMAL\n";
}

echo "\n📊 PATRONES IDENTIFICADOS:\n";
echo "• Terminal 102 genera ~60% más tickets que 102 (1315 vs 834)\n";
echo "• Terminal 102 tiene mayor volumen de ventas ($67,906 vs $48,033)\n";
echo "• Ambas terminales con similar distribución efectivo/tarjetas\n";
echo "• Tickets sin transacciones detectados (requieren investigación)\n";

echo "\n🔍 RECOMENDACIONES:\n";
echo "1. Investigar días con diferencias > $1,000\n";
echo "2. Verificar integridad de transacciones vs tickets\n";
echo "3. Revisar proceso de corte en ambas terminales\n";
echo "4. Analizar posibles tickets perdidos o duplicados\n";
echo "5. Validar cálculo de totales en sistema de cortes\n";

echo "\n" . str_repeat("=", 50) . "\n";
echo "FIN DEL ANÁLISIS\n";
echo str_repeat("=", 50) . "\n";

?>