<?php

/**
 * Script para restaurar selectivamente tablas del backup del 07_12_2025
 * Prioriza tablas del schema PUBLIC y las relacionadas con cortes/caja
 */

require __DIR__ . '/../vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

// Configuración
$backupFile = __DIR__ . '/../BD/Diciembre/07_12_2025/dump_UX_07_12_2025.sql';
$tempDir = __DIR__ . '/../temp_restore';
$publicTablesFile = $tempDir . '/public_tables.sql';
$cortesTablesFile = $tempDir . '/cortes_tables.sql';

// Tablas prioritarias del schema PUBLIC
$publicTables = [
    'ticket',
    'ticket_item',
    'ticket_item_modifier',
    'ticket_discount',
    'ticket_item_addon_relation',
    'ticket_item_cooking_instruction',
    'transactions',
    'payment',
    'terminal',
    'cash_drawer',
    'drawer_pull_report',
    'drawer_pull_report_voidtickets',
    'user',
    'restaurant',
    'shift',
    'tax',
    'menu_item',
    'menu_group',
    'menu_item_modifier_group',
    'menu_modifier',
    'menu_modifier_group'
];

// Tablas relacionadas con cortes (pueden incluir algunas de selemti)
$cortesTables = [
    'sesion_cajon',
    'precorte',
    'postcorte',
    'conciliacion',
    'corte_turno',
    'arqueo_caja',
    'movimiento_caja'
];

echo "=== Restauración Selectiva de Backup 07_12_2025 ===\n\n";

// Verificar que el backup existe
if (!file_exists($backupFile)) {
    echo "❌ ERROR: No se encuentra el archivo de backup: $backupFile\n";
    exit(1);
}

// Crear directorio temporal
if (!is_dir($tempDir)) {
    mkdir($tempDir, 0755, true);
}

echo "📁 Analizando backup...\n";

// Analizar el backup para identificar tablas
$backupContent = file_get_contents($backupFile);

// Extraer tablas del schema PUBLIC
echo "📋 Extrayendo tablas del schema PUBLIC...\n";
$publicTablesPattern = '/-- Name: (' . implode('|', $publicTables) . '); Type: TABLE; Schema: public.*?-- Data for Name: \1.*?(?=-- Name:|-- PostgreSQL database dump|--)/s';

if (preg_match_all($publicTablesPattern, $backupContent, $matches)) {
    file_put_contents($publicTablesFile, "-- Tablas del schema PUBLIC del backup 07_12_2025\n");
    file_put_contents($publicTablesFile, implode("\n", $matches[0]), FILE_APPEND);
    echo "✅ Se encontraron " . count($matches[0]) . " tablas PUBLIC\n";
} else {
    echo "⚠️  No se encontraron todas las tablas PUBLIC esperadas\n";
}

// Extraer tablas relacionadas con cortes
echo "📋 Extrayendo tablas relacionadas con cortes...\n";
$cortesTablesPattern = '/-- Name: (' . implode('|', $cortesTables) . '); Type: TABLE;.*?-- Data for Name: \1.*?(?=-- Name:|-- PostgreSQL database dump|--)/s';

if (preg_match_all($cortesTablesPattern, $backupContent, $matches)) {
    file_put_contents($cortesTablesFile, "-- Tablas de cortes del backup 07_12_2025\n");
    file_put_contents($cortesTablesFile, implode("\n", $matches[0]), FILE_APPEND);
    echo "✅ Se encontraron " . count($matches[0]) . " tablas de cortes\n";
} else {
    echo "⚠️  No se encontraron todas las tablas de cortes esperadas\n";
}

// Crear script SQL principal
$restoreScript = $tempDir . '/restore_selective.sql';
$sql = "-- Restauración Selectiva - Backup 07_12_2025
-- Target: Schema PUBLIC y tablas de cortes
-- Fecha: " . date('Y-m-d H:i:s') . "

-- Deshabilitar triggers
SET session_replication_role = replica;

-- Dropear tablas existentes (con cuidado)
";

// Añadir DROP TABLEs para tablas PUBLIC
foreach ($publicTables as $table) {
    $sql .= "DROP TABLE IF EXISTS public.{$table} CASCADE;\n";
}

$sql .= "\n-- Restaurar tablas PUBLIC\n";

if (file_exists($publicTablesFile)) {
    $sql .= file_get_contents($publicTablesFile);
}

$sql .= "\n-- Restaurar tablas de cortes\n";

if (file_exists($cortesTablesFile)) {
    $sql .= file_get_contents($cortesTablesFile);
}

$sql .= "\n-- Rehabilitar triggers
SET session_replication_role = DEFAULT;

-- Actualizar secuencias
SELECT setval(pg_get_serial_sequence('public.ticket', 'id'), coalesce(max(id), 1)) FROM public.ticket;
SELECT setval(pg_get_serial_sequence('public.ticket_item', 'id'), coalesce(max(id), 1)) FROM public.ticket_item;
SELECT setval(pg_get_serial_sequence('public.terminal', 'id'), coalesce(max(id), 1)) FROM public.terminal;

-- Analizar tablas para optimizar rendimiento
ANALYZE public.ticket;
ANALYZE public.ticket_item;
ANALYZE public.ticket_item_modifier;
ANALYZE public.transactions;
ANALYZE public.terminal;

-- Contar registros restaurados
SELECT 'ticket' as table_name, COUNT(*) as records FROM public.ticket
UNION ALL
SELECT 'ticket_item', COUNT(*) FROM public.ticket_item
UNION ALL
SELECT 'ticket_item_modifier', COUNT(*) FROM public.ticket_item_modifier
UNION ALL
SELECT 'transactions', COUNT(*) FROM public.transactions
UNION ALL
SELECT 'terminal', COUNT(*) FROM public.terminal;

COMMIT;

-- Finalizado: " . date('Y-m-d H:i:s') . "\n";

file_put_contents($restoreScript, $sql);

echo "\n✅ Scripts generados en: $tempDir\n";
echo "📄 Archivos creados:\n";
echo "   - public_tables.sql: Tablas del schema PUBLIC\n";
echo "   - cortes_tables.sql: Tablas de cortes\n";
echo "   - restore_selective.sql: Script principal\n\n";

// Verificar tamaño de los archivos
if (file_exists($restoreScript)) {
    $size = filesize($restoreScript);
    echo "📊 Tamaño del script de restauración: " . number_format($size/1024/1024, 2) . " MB\n";
}

echo "\n🚀 Para ejecutar la restauración:\n";
echo "   psql -h localhost -p 5433 -U postgres -d pos -f \"$restoreScript\"\n\n";

echo "⚠️  ADVERTENCIA: Esto sobrescribirá las tablas actuales. Hacer backup primero.\n";

?>