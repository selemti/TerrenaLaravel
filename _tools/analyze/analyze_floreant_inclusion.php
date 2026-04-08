<?php
/**
 * Analyze what Floreant POS specifically includes
 */

echo "=== ANÁLISIS DE QUÉ INCLUYE FLOREANT POS ===\\n\\n";

// Conexión a PostgreSQL
$pdo = new PDO('pgsql:host=localhost;port=5433;dbname=pos', 'postgres', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Floreant Items Grand Total: $631.00
$floreantTotal = 631.00;

// 1. SQL completo incluyendo todo
$sqlAll = "
SELECT ti.item_name, SUM(ti.total_price) as total, COUNT(*) as count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
GROUP BY ti.item_name
ORDER BY total DESC
";

$stmt = $pdo->query($sqlAll);
$allItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Todos los items agrupados:\\n";
echo "=======================\\n";
$sqlTotal = 0;
foreach ($allItems as $item) {
    echo "- {$item['item_name']}: \${$item['total']} ({$item['count']} registros)\\n";
    $sqlTotal += $item['total'];
}
echo "\\nTotal SQL: \${$sqlTotal}\\n";
echo "Floreant esperado: \${$floreantTotal}\\n";
$difference = $sqlTotal - $floreantTotal;
echo "Diferencia: \${$difference}\\n\\n";

// 2. ¿Qué pasaría si excluimos items individuales con descuento 100%?
$sqlExcludeIndividualDiscounts = "
SELECT ti.item_name, SUM(ti.total_price) as total, COUNT(*) as count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ti.discount != 100  -- Excluir items con descuento individual 100%
GROUP BY ti.item_name
ORDER BY total DESC
";

$stmt = $pdo->query($sqlExcludeIndividualDiscounts);
$filteredItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Items excluyendo descuentos individuales 100%:\\n";
echo "============================================\\n";
$filteredTotal = 0;
foreach ($filteredItems as $item) {
    echo "- {$item['item_name']}: \${$item['total']} ({$item['count']} registros)\\n";
    $filteredTotal += $item['total'];
}
echo "\\nTotal filtrado: \${$filteredTotal}\\n";
$differenceFiltered = $filteredTotal - $floreantTotal;
echo "Diferencia con Floreant: \${$differenceFiltered}\\n\\n";

// 3. Buscar items específicos que podrían estar causando la diferencia
echo "BUSCANDO ITEMS CON DIFERENCIAS:\\n";
echo "=============================\\n";

$itemsToCheck = ['Quesadilla', 'Picada', 'Tostada', 'Empanada', 'Taco de Guisado', 'Picada Terrena'];

foreach ($itemsToCheck as $itemName) {
    $sqlCheck = "
    SELECT ti.item_name, ti.item_count, ti.item_price, ti.total_price, ti.discount,
           t.id as ticket_id, t.total_price as ticket_total
    FROM public.ticket t
    JOIN public.ticket_item ti ON ti.ticket_id = t.id
    WHERE DATE(t.folio_date) = '2025-12-16'
      AND t.paid = true
      AND t.voided = false
      AND ti.item_name = '{$itemName}'
    ORDER BY ti.total_price DESC
    ";

    $stmt = $pdo->query($sqlCheck);
    $specificItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($specificItems) {
        echo "\\n--- {$itemName} ---\\n";
        foreach ($specificItems as $item) {
            $status = "";
            if ($item['ticket_total'] == 0) {
                $status = " [TICKET 100% DESCUENTO]";
            }
            if ($item['discount'] > 0) {
                $status .= " [TIENE DESCUENTO]";
            }
            echo "- Ticket {$item['ticket_id']}: {$item['item_count']} x \${$item['item_price']} = \${$item['total_price']}{$status}\\n";
        }
    }
}

// 4. Teoría: ¿Floreant aplica lógica específica a "Quesadilla"?
echo "\\n4. ANÁLISIS ESPECÍFICO DE QUESADILLA:\\n";
echo "=====================================\\n";

$sqlQuesadilla = "
SELECT ti.item_name, ti.item_count, ti.item_price, ti.total_price, ti.discount,
       t.id as ticket_id, t.total_price as ticket_total, t.total_discount as ticket_discount
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ti.item_name = 'Quesadilla'
ORDER BY ti.total_price DESC
";

$stmt = $pdo->query($sqlQuesadilla);
$quesadillas = $stmt->fetchAll(PDO::FETCH_ASSOC);

$totalQuesadilla = 0;
foreach ($quesadillas as $q) {
    echo "- Ticket {$q['ticket_id']}: {$q['item_count']} x \${$q['item_price']} = \${$q['total_price']} (Desc: \${$q['discount']})\\n";
    $totalQuesadilla += $q['total_price'];
}

echo "\\nTotal Quesadilla SQL: \${$totalQuesadilla}\\n";

// Si calculamos sin la Quesadilla con descuento
$totalWithoutDiscountedQuesadilla = $totalQuesadilla - 13.2;
echo "Sin Quesadilla con descuento: \${$totalWithoutDiscountedQuesadilla}\\n";
echo "Total SQL sin esa quesadilla: \${$sqlTotal - 13.2}\\n";

// 5. Probar teoría: ¿Floreant excluye items cuando ticket != item_price * quantity?
echo "\\n5. TEORÍA: Excluir items donde ticket_total != item_price * quantity:\\n";
echo "=====================================================================\\n";

$sqlTheory = "
SELECT ti.item_name, ti.item_count, ti.item_price, ti.total_price, ti.discount,
       t.id as ticket_id, t.total_price as ticket_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND ti.total_price != ti.item_price * ti.item_count
";

$stmt = $pdo->query($sqlTheory);
$mismatchedItems = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($mismatchedItems) {
    echo "Items donde total_price != item_price * item_count:\\n";
    foreach ($mismatchedItems as $item) {
        $expected = $item['item_price'] * $item['item_count'];
        echo "- {$item['item_name']}: Ticket {$item['ticket_id']}, Expected: \${$expected}, Actual: \${$item['total_price']}\\n";
    }
} else {
    echo "No se encontraron items con mismatch (todos coinciden)\\n";
}

// 6. Otra teoría: ¿Floreant usa closing_date en vez de folio_date?
echo "\\n6. TEORÍA: Usar closing_date en vez de folio_date:\\n";
echo "=================================================\\n";

$sqlClosingDate = "
SELECT SUM(ti.total_price) as total_closing_date
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.closing_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
";

$stmt = $pdo->query($sqlClosingDate);
$result = $stmt->fetch(PDO::FETCH_ASSOC);
$closingDateTotal = $result['total_closing_date'];

echo "Total usando closing_date: \${$closingDateTotal}\\n";
echo "Diferencia con Floreant: \${$closingDateTotal - $floreantTotal}\\n\\n";

echo "=== CONCLUSIONES ===\\n";
echo "1. La diferencia de \${$sqlTotal - $floreantTotal} indica que Floreant excluye algo\\n";
echo "2. Excluir ticket 46291 da \${$sqlTotal - 68} = \${$sqlTotal - 68}, todavía \${$sqlTotal - 68 - $floreantTotal} de diferencia\\n";
echo "3. La Quesadilla con descuento podría ser parte del problema\\n";
echo "4. Necesitamos identificar exactamente cuál es la lógica de filtrado de Floreant\\n";

$pdo = null;