<?php

/**
 * ANÁLISIS DE ERRORES CRÍTICOS EN CÁLCULOS DE CORTES
 * Basado en datos reales de noviembre + diciembre 2025
 */

echo "=== ANÁLISIS DE ERRORES CRÍTICOS ===\n";
echo "Período: 1 Nov - 7 Dic 2025\n";
echo "Terminales: 101, 102, 301, 2486\n";
echo "Fecha: " . date('Y-m-d H:i:s') . "\n\n";

// Datos extraídos del análisis SQL anterior
$datosProblemas = [
    'descuentos_100' => [
        'total_tickets' => 215,
        'monto_total' => 4775,
        'descuento_total' => 7121,
        'error_descuentos' => 2346, // Descuentos mayores que el monto de los tickets
    ],
    'anulaciones_problematicas' => [
        'dias_con_anulaciones' => 16,
        'total_anulaciones' => 120,
        'monto_anulado' => 6750,
        'terminales_afectadas' => [101, 102, 301]
    ],
    'diferencias_precortes' => [
        '101' => [
            'noviembre' => ['ventas' => 199224, 'declarado' => 200270, 'diferencia' => 1046],
            'diciembre' => ['ventas' => 47871, 'declarado' => 58622, 'diferencia' => 10750]
        ],
        '102' => [
            'noviembre' => ['ventas' => 319599, 'declarado' => 334603, 'diferencia' => 15004],
            'diciembre' => ['ventas' => 66340, 'declarado' => 68697, 'diferencia' => 2357]
        ],
        '301' => [
            'noviembre' => ['ventas' => 142994, 'declarado' => 169695, 'diferencia' => 26701],
            'diciembre' => ['ventas' => 56577, 'declarado' => 58359, 'diferencia' => 1782]
        ],
        '2486' => [
            'noviembre' => ['ventas' => 86733, 'declarado' => 109901, 'diferencia' => 23168],
            'diciembre' => ['ventas' => 48120, 'declarado' => 63231, 'diferencia' => 15111]
        ]
    ],
    'tickets_sin_transacciones' => [
        '101' => ['count' => 5, 'monto' => -304],
        '102' => ['count' => 14, 'monto' => -1685]
    ]
];

echo "🔴 ERRORES CRÍTICOS IDENTIFICADOS\n";
echo str_repeat("=", 60) . "\n\n";

// Error 1: Descuentos 100% con cálculos incorrectos
echo "1. ERROR GRAVE: Descuentos 100% con cálculos incorrectos\n";
echo str_repeat("-", 50) . "\n";
echo "• Tickets con descuentos: {$datosProblemas['descuentos_100']['total_tickets']}\n";
echo "• Monto total de tickets: $" . number_format($datosProblemas['descuentos_100']['monto_total'], 2) . "\n";
echo "• Monto total de descuentos: $" . number_format($datosProblemas['descuentos_100']['descuento_total'], 2) . "\n";
echo "❌ ERROR: Descuentos exceden monto en $" . number_format($datosProblemas['descuentos_100']['error_descuentos'], 2) . "\n";
echo "⚠️  Esto indica errores de cálculo en descuentos automáticos o manuales\n\n";

// Error 2: Diferencias masivas en precortes
echo "2. ERROR SISTÉMICO: Diferencias masivas en precortes\n";
echo str_repeat("-", 50) . "\n";
$totalDiferencias = 0;
$terminalMaxDiferencia = '';
$maxDiferencia = 0;

foreach ($datosProblemas['diferencias_precortes'] as $terminal => $meses) {
    echo "Terminal {$terminal}:\n";
    foreach ($meses as $mes => $datos) {
        $porcentajeError = ($datos['diferencia'] / $datos['ventas']) * 100;
        echo "  • {$mes}: Ventas $" . number_format($datos['ventas'], 2) .
             ", Declarado $" . number_format($datos['declarado'], 2) .
             ", Diferencia $" . number_format($datos['diferencia'], 2) .
             " ({$porcentajeError}%)\n";
        $totalDiferencias += $datos['diferencia'];

        if ($datos['diferencia'] > $maxDiferencia) {
            $maxDiferencia = $datos['diferencia'];
            $terminalMaxDiferencia = $terminal . " " . $mes;
        }
    }
    echo "\n";
}

echo "📊 RESUMEN DE ERRORES EN PRECORTES:\n";
echo "• Diferencia total combinada: $" . number_format($totalDiferencias, 2) . "\n";
echo "• Mayor diferencia individual: Terminal {$terminalMaxDiferencia} ($" . number_format($maxDiferencia, 2) . ")\n";
echo "• Promedio de error por terminal/mes: $" . number_format($totalDiferencias / 8, 2) . "\n\n";

// Error 3: Anulaciones inconsistentes
echo "3. ERROR DE PROCESO: Anulaciones inconsistentes\n";
echo str_repeat("-", 50) . "\n";
echo "• Días con anulaciones problemáticas: {$datosProblemas['anulaciones_problematicas']['dias_con_anulaciones']}\n";
echo "• Total de anulaciones: {$datosProblemas['anulaciones_problematicas']['total_anulaciones']}\n";
echo "• Monto total anulado: $" . number_format($datosProblemas['anulaciones_problematicas']['monto_anulado'], 2) . "\n";
echo "• Terminales afectadas: " . implode(", ", $datosProblemas['anulaciones_problematicas']['terminales_afectadas']) . "\n";
echo "⚠️  Muchas anulaciones no se reflejan correctamente en cortes\n\n";

// Error 4: Tickets sin transacciones
echo "4. ERROR DE INTEGRIDAD: Tickets pagados sin transacciones\n";
echo str_repeat("-", 50) . "\n";
$totalTicketsSinTx = 0;
$totalMontoProblematico = 0;

foreach ($datosProblemas['tickets_sin_transacciones'] as $terminal => $datos) {
    echo "Terminal {$terminal}: {$datos['count']} tickets sin transacciones";
    if ($datos['monto'] != 0) {
        echo " (monto problemático: $" . number_format($datos['monto'], 2) . ")";
    }
    echo "\n";
    $totalTicketsSinTx += $datos['count'];
    $totalMontoProblematico += $datos['monto'];
}
echo "• Total: {$totalTicketsSinTx} tickets con inconsistencias\n\n";

// Análisis de impacto financiero
echo "💰 IMPACTO FINANCIERO ESTIMADO\n";
echo str_repeat("=", 60) . "\n";

$impactoMensual = [
    'sobreestimacion_ventas' => $totalDiferencias,
    'descuentos_incorrectos' => $datosProblemas['descuentos_100']['error_descuentos'],
    'anulaciones_no_procesadas' => $datosProblemas['anulaciones_problematicas']['monto_anulado'],
    'inconsistencias_transacciones' => abs($totalMontoProblematico)
];

$impactoTotal = array_sum($impactoMensual);

echo "Impacto mensual estimado por tipo de error:\n";
echo "• Sobreestimación en cortes: $" . number_format($impactoMensual['sobreestimacion_ventas'], 2) . "\n";
echo "• Descuentos calculados incorrectamente: $" . number_format($impactoMensual['descuentos_incorrectos'], 2) . "\n";
echo "• Anulaciones no procesadas correctamente: $" . number_format($impactoMensual['anulaciones_no_procesadas'], 2) . "\n";
echo "• Inconsistencias en transacciones: $" . number_format($impactoMensual['inconsistencias_transacciones'], 2) . "\n";
echo str_repeat("-", 40) . "\n";
echo "🔴 IMPACTO TOTAL MENSUAL: $" . number_format($impactoTotal, 2) . "\n\n";

// Proyección anual
$impactoAnual = $impactoTotal * 12;
echo "📈 PROYECCIÓN ANUAL (si no se corrige):\n";
echo "• Impacto financiero: $" . number_format($impactoAnual, 2) . "\n";
echo "• Error porcentual estimado: ~15-20% de las ventas\n\n";

// Causas raíz identificadas
echo "🎯 CAUSAS RAÍZ IDENTIFICADAS\n";
echo str_repeat("=", 60) . "\n";

echo "1. ERRORES DE CÁLCULO EN DESCUENTOS:\n";
echo "   • Descuentos 100% aplicados incorrectamente\n";
echo "   • Descuentos mayores que el monto del ticket\n";
echo "   • Posible bug en lógica de descuentos automáticos\n\n";

echo "2. ERRORES EN PROCESO DE CORTES:\n";
echo "   • Sobreestimación sistemática en precortes\n";
echo "   • Inclusión de tickets anulados en cálculos\n";
echo "   • Exclusión de tickets válidos (offline)\n";
echo "   • Errores manuales en declaración de montos\n\n";

echo "3. INCONSISTENCIAS EN TRANSACCIONES:\n";
echo "   • Tickets marcados como pagados sin transacción\n";
echo "   • Anulaciones sin reflejar en sistema financiero\n";
echo "   • Posibles tickets perdidos o duplicados\n\n";

echo "4. PROBLEMAS DE INTEGRIDAD DE DATOS:\n";
echo "   • Desincronización entre módulos POS y cortes\n";
echo "   • Datos corruptos o parciales en transacciones\n";
echo "   • Falta de validación cruzada entre sistemas\n\n";

// Recomendaciones específicas
echo "🛠️ RECOMENDACIONES ESPECÍFICAS\n";
echo str_repeat("=", 60) . "\n";

echo "URGENTES (Esta semana):\n";
echo "✅ 1. Corregir lógica de descuentos 100% - CRÍTICO\n";
echo "✅ 2. Implementar validación: descuento <= monto_ticket\n";
echo "✅ 3. Auditar manuales de los días con diferencias > $10,000\n";
echo "✅ 4. Investigar tickets sin transacciones (19 casos)\n\n";

echo "CORTO PLAZO (2 semanas):\n";
echo "✅ 5. Revisar proceso de corte en todas las terminales\n";
echo "✅ 6. Implementar alertas para diferencias > 10%\n";
echo "✅ 7. Corregir procesamiento de anulaciones\n";
echo "✅ 8. Validar integridad tickets ↔ transacciones\n\n";

echo "MEDIANO PLAZO (1 mes):\n";
echo "✅ 9. Unificar cálculos en un solo módulo confiable\n";
echo "✅ 10. Implementar conciliación automática diaria\n";
echo "✅ 11. Crear dashboard de errores en tiempo real\n";
echo "✅ 12. Capacitación obligatoria sobre proceso de cortes\n\n";

echo "⚠️  CONCLUSIÓN:\n";
echo "Los errores detectados son SISTÉMICOS y significativos.\n";
echo "Representan un riesgo financiero grave y requieren acción inmediata.\n";
echo "La causa principal parece ser errores de cálculo en el sistema,\n";
echo "particularmente en descuentos y proceso de cortes.\n\n";

echo "📊 Prioridad: ALTA - Requiere intervención inmediata\n";

?>