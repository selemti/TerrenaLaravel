<?php
/**
 * Test script para validar las fórmulas de totales contra la BD del 16/12/2025
 */

require_once __DIR__ . '/vendor/autoload.php';
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Collection;

echo "=== VALIDACIÓN DE FÓRMULAS DE TOTALES - 16/12/2025 ===\n\n";

// Conexión a la BD PostgreSQL
try {
    $pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✓ Conexión a PostgreSQL establecida\n\n";
} catch (Exception $e) {
    echo "✗ Error de conexión: " . $e->getMessage() . "\n";
    exit;
}

// Función para ejecutar queries y mostrar resultados
function executeQuery($pdo, $query, $label) {
    echo "--- $label ---\n";
    try {
        $stmt = $pdo->query($query);
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (!empty($result)) {
            foreach ($result as $row) {
                foreach ($row as $key => $value) {
                    echo "$key: $value\n";
                }
            }
        } else {
            echo "No se encontraron resultados\n";
        }
    } catch (Exception $e) {
        echo "✗ Error: " . $e->getMessage() . "\n";
    }
    echo "\n";
}

// Query 1: Fórmula items_net_plus_mods_net (sin incluir descuentos 100%)
$query1 = "
SELECT
    'items_net_plus_mods_net (sin 100% discount)' as formula,
    COUNT(DISTINCT t.id) as tickets,
    COUNT(DISTINCT ti.id) as items,
    COUNT(DISTINCT tim.id) as modifiers,
    SUM(COALESCE(ti.total_price, 0)) as items_net,
    SUM(COALESCE(tim.total_price, 0)) as mods_net,
    SUM(COALESCE(ti.total_price, 0)) + SUM(COALESCE(tim.total_price, 0)) as total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  -- Excluir ticket con descuento 100%
  AND t.total_price != 0
";

// Query 2: Fórmula items_net_plus_mods_net (incluyendo descuentos 100%)
$query2 = "
SELECT
    'items_net_plus_mods_net (con 100% discount)' as formula,
    COUNT(DISTINCT t.id) as tickets,
    COUNT(DISTINCT ti.id) as items,
    COUNT(DISTINCT tim.id) as modifiers,
    SUM(COALESCE(ti.total_price, 0)) as items_net,
    SUM(COALESCE(tim.total_price, 0)) as mods_net,
    SUM(COALESCE(ti.total_price, 0)) + SUM(COALESCE(tim.total_price, 0)) as total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

// Query 3: Fórmula ticket_total
$query3 = "
SELECT
    'ticket_total' as formula,
    COUNT(DISTINCT t.id) as tickets,
    SUM(t.total_price) as total_tickets
FROM public.ticket t
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

// Query 4: Fórmula payments_net
$query4 = "
SELECT
    'payments_net' as formula,
    COUNT(DISTINCT tr.ticket_id) as tickets_with_payments,
    SUM(CASE WHEN tr.payment_type NOT IN ('VOID', 'REFUND') THEN tr.amount ELSE 0 END) as total_payments
FROM public.transactions tr
JOIN public.ticket t ON t.id = tr.ticket_id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND tr.voided = false
";

// Query 5: Totales con descuentos aplicados
$query5 = "
SELECT
    'items_net_plus_mods_net_con_descuentos' as formula,
    COUNT(DISTINCT t.id) as tickets,
    COUNT(DISTINCT ti.id) as items,
    COUNT(DISTINCT tim.id) as modifiers,
    SUM(COALESCE(ti.total_price, 0)) - SUM(COALESCE(ti.discount, 0)) as items_net,
    SUM(COALESCE(tim.total_price, 0)) as mods_net,
    (SUM(COALESCE(ti.total_price, 0)) - SUM(COALESCE(ti.discount, 0))) + SUM(COALESCE(tim.total_price, 0)) as total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price != 0
";

// Query 6: Análisis del ticket con 100% descuento
$query6 = "
SELECT
    'ticket_100_discount_analysis' as analysis,
    t.id as ticket_id,
    t.folio_date,
    t.sub_total,
    t.total_discount,
    t.total_price,
    COUNT(ti.id) as items_count,
    SUM(ti.total_price) as items_total,
    SUM(ti.discount) as items_discount
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price = 0
  AND t.total_discount > 0
GROUP BY t.id, t.folio_date, t.sub_total, t.total_discount, t.total_price
";

// Ejecutar todos los queries
executeQuery($pdo, $query1, "FÓRMULA 1: Items + Mods Net (excluyendo 100% discount)");
executeQuery($pdo, $query2, "FÓRMULA 2: Items + Mods Net (incluyendo 100% discount)");
executeQuery($pdo, $query3, "FÓRMULA 3: Total de Tickets");
executeQuery($pdo, $query4, "FÓRMULA 4: Total de Pagos");
executeQuery($pdo, $query5, "FÓRMULA 5: Items + Mods Net con descuentos aplicados");
executeQuery($pdo, $query6, "ANÁLISIS: Ticket con 100% descuento");

// Totales de Terrena vs Esperado
echo "=== COMPARACIÓN FINAL ===\n\n";
echo "Terrena HTML Output:\n";
echo "- Ventas Totales: $716.20\n";
echo "- Base (Items): $666.20\n";
echo "- Modificadores: $50.00\n\n";

echo "Esperado (basado en análisis):\n";
echo "- Items Net (sin 100% discount): ~$1,109.40\n";
echo "- Items Net (con 100% discount): $1,177.40\n";
echo "- Modificadores: $50.00\n\n";

echo "Discrepancia Principal:\n";
echo "- La base Terrena ($666.20) es menor que el cálculo SQL ($1,109.40+)\n";
echo "- Posibles causas:\n";
echo "  1. Filtros adicionales aplicados en el código de Terrena\n";
echo "  2. Lógica de cálculo diferente (quizás solo items pagados completos)\n";
echo "  3. Descuentos aplicados a nivel de item que no se ven en el SQL base\n\n";

echo "=== RECOMENDACIÓN ===\n";
echo "1. Extraer los totales exactos del PDF Floreant para establecer baseline\n";
echo "2. Implementar las fórmulas calculadas y comparar con Terrena\n";
echo "3. Ajustar la lógica de Terrena para que coincida con la fórmula deseada\n";

$pdo = null;
echo "\n✓ Prueba completada\n";
?>