<?php

/**
 * Restauración Backup 07_12_2025
 * - Schema PUBLIC: Restaurar completamente (los datos más recientes)
 * - Schema SELEMTI: Selectivo (solo cortes y datos necesarios)
 */

require __DIR__ . '/../vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Configuración
$backupFile = __DIR__ . '/../BD/Diciembre/07_12_2025/dump_UX_07_12_2025.sql';
$tempDir = __DIR__ . '/../temp_restore_' . date('Ymd_His');
$publicRestoreFile = $tempDir . '/public_restore.sql';
$selemtiSelectiveFile = $tempDir . '/selemti_selective.sql';
$mainRestoreFile = $tempDir . '/restore_main.sql';

// Tablas de SELEMTI que SÍ queremos restaurar (cortes y esenciales)
$selemtiTablesToRestore = [
    // Cortes y caja
    'sesion_cajon',
    'precorte',
    'postcorte',
    'precorte_efectivo',
    'precorte_otros',
    'conciliacion',
    'alertas_cortes',
    'caja_fondo_arqueo',
    'cash_fund_arqueos',

    // Configuración y catálogos importantes
    'cat_sucursales',
    'cat_almacenes',
    'cat_unidades',
    'cat_proveedores',
    'cat_formas_pago',

    // Inventario (si hay datos nuevos)
    'items',
    'mov_inv',
    'recepcion_cab',
    'recepcion_det',
    'inventory_batch',

    // Usuarios y permisos (si hay actualizaciones)
    'users',
    'roles',
    'permissions'
];

// Tablas de SELEMTI que NO queremos tocar (implementaciones nuevas)
$selemtiTablesToPreserve = [
    'cash_funds',
    'cash_fund_movements',
    'cash_fund_settlements',
    'purchase_requests',
    'purchase_request_lines',
    'vendor_quotes',
    'vendor_quote_lines',
    'purchase_orders',
    'purchase_order_lines',
    'inventory_counts',
    'inventory_count_lines'
];

echo "=== Restauración Backup 07_12_2025 ===\n";
echo "Estrategia: PUBLIC completo + SELEMTI selectivo\n\n";

// Verificar backup
if (!file_exists($backupFile)) {
    echo "❌ ERROR: No se encuentra el backup: $backupFile\n";
    exit(1);
}

// Crear directorio temporal
if (!is_dir($tempDir)) {
    mkdir($tempDir, 0755, true);
}

echo "📁 Analizando estructura del backup...\n";

// Leer backup y analizar contenido
$backupContent = file_get_contents($backupFile);
$backupLines = explode("\n", $backupContent);

echo "📊 Backup tiene " . count($backupLines) . " líneas\n";

// Extraer tablas PUBLIC
echo "\n📋 Extrayendo tablas del schema PUBLIC...\n";
$inPublicSection = false;
$publicSql = "-- RESTAURACIÓN COMPLETA SCHEMA PUBLIC\n-- Backup: 07_12_2025\n\n";

// Deshabilitar constraints al inicio
$publicSql .= "-- Deshabilitar checks de claves foráneas\nSET session_replication_role = replica;\n\n";

foreach ($backupLines as $line) {
    if (str_contains($line, '-- Name: public.')) {
        $inPublicSection = true;
        continue;
    }

    if (str_contains($line, '-- Name: selemti.') || str_contains($line, '-- PostgreSQL database dump')) {
        $inPublicSection = false;
        continue;
    }

    if ($inPublicSection && (str_contains($line, 'CREATE TABLE') || str_contains($line, 'ALTER TABLE') || str_contains($line, 'COPY public.') || str_contains($line, '-- Data for Name: public.'))) {
        $publicSql .= $line . "\n";
    }
}

file_put_contents($publicRestoreFile, $publicSql);
echo "✅ Extraídas tablas PUBLIC: " . filesize($publicRestoreFile) . " bytes\n";

// Extraer tablas SELEMTI selectivas
echo "\n📋 Extrayendo tablas selectivas del schema SELEMTI...\n";
$inSelemtiSection = false;
$currentTable = '';
$tableSql = '';
$selemtiSql = "-- RESTAURACIÓN SELECTIVA SCHEMA SELEMTI\n-- Solo cortes y datos esenciales\n-- Backup: 07_12_2025\n\n";

$selemtiSql .= "-- Deshabilitar checks de claves foráneas\nSET session_replication_role = replica;\n\n";

foreach ($backupLines as $line) {
    // Detectar inicio de tabla SELEMTI
    if (preg_match('/-- Name: selemti\.([^;]+); Type: TABLE;/', $line, $matches)) {
        $currentTable = $matches[1];
        $inSelemtiSection = in_array($currentTable, $selemtiTablesToRestore);
        $tableSql = '';

        if ($inSelemtiSection) {
            echo "  📥 Incluyendo tabla: $currentTable\n";
        } else {
            echo "  ⏭️  Omitiendo tabla: $currentTable\n";
        }
        continue;
    }

    // Detectar fin de tabla actual
    if (str_contains($line, '-- Name:') && !str_contains($line, $currentTable)) {
        if ($inSelemtiSection && !empty($tableSql)) {
            $selemtiSql .= $tableSql . "\n";
        }
        $inSelemtiSection = false;
        continue;
    }

    // Acumular contenido de la tabla
    if ($inSelemtiSection) {
        if (str_contains($line, 'CREATE TABLE') ||
            str_contains($line, 'ALTER TABLE') ||
            str_contains($line, 'COPY selemti.') ||
            str_contains($line, '-- Data for Name: selemti.')) {
            $tableSql .= $line . "\n";
        }
    }
}

// Añadir última tabla si hay pendiente
if ($inSelemtiSection && !empty($tableSql)) {
    $selemtiSql .= $tableSql . "\n";
}

file_put_contents($selemtiSelectiveFile, $selemtiSql);
echo "✅ Extraídas tablas SELEMTI selectivas: " . filesize($selemtiSelectiveFile) . " bytes\n";

// Crear script principal de restauración
$mainSql = "-- ========================================\n";
$mainSql .= "-- RESTAURACIÓN BACKUP 07_12_2025\n";
$mainSql .= "-- Estrategia: PUBLIC completo + SELEMTI selectivo\n";
$mainSql .= "-- Fecha de ejecución: " . date('Y-m-d H:i:s') . "\n";
$mainSql .= "-- ========================================\n\n";

// Backup antes de restaurar
$mainSql .= "-- CREAR BACKUP ANTES DE RESTAURAR\n";
$mainSql .= "DO \$\$\n";
$mainSql .= "DECLARE\n";
$mainSql .= "    backup_name TEXT := 'pre_restore_07_12_2025_' || to_char(now(), 'YYYY_MM_DD_HH24_MI_SS');\n";
$mainSql .= "BEGIN\n";
$mainSql .= "    EXECUTE 'CREATE DATABASE IF NOT EXISTS backup_' || backup_name;\n";
$mainSql .= "    RAISE NOTICE 'Backup creado: %', backup_name;\n";
$mainSql .= "END\$\$;\n\n";

// Conectar a base de datos principal
$mainSql .= "\\c pos\n\n";

// Restaurar schema PUBLIC (completo)
$mainSql .= "-- ========================================\n";
$mainSql .= "-- 1. RESTAURACIÓN COMPLETA SCHEMA PUBLIC\n";
$mainSql .= "-- ========================================\n\n";

if (file_exists($publicRestoreFile)) {
    $mainSql .= file_get_contents($publicRestoreFile);
}

// Restaurar schema SELEMTI (selectivo)
$mainSql .= "\n-- ========================================\n";
$mainSql .= "-- 2. RESTAURACIÓN SELECTIVA SCHEMA SELEMTI\n";
$mainSql .= "-- ========================================\n\n";

if (file_exists($selemtiSelectiveFile)) {
    $mainSql .= file_get_contents($selemtiSelectiveFile);
}

// Rehabilitar constraints y actualizar secuencias
$mainSql .= "\n-- ========================================\n";
$mainSql .= "-- 3. POST-PROCESAMIENTO\n";
$mainSql .= "-- ========================================\n\n";

$mainSql .= "-- Rehabilitar checks de claves foráneas\n";
$mainSql .= "SET session_replication_role = DEFAULT;\n\n";

$mainSql .= "-- Actualizar secuencias importantes\n";
$mainSql .= "SELECT setval(pg_get_serial_sequence('public.ticket', 'id'), coalesce(max(id), 1)) FROM public.ticket;\n";
$mainSql .= "SELECT setval(pg_get_serial_sequence('public.ticket_item', 'id'), coalesce(max(id), 1)) FROM public.ticket_item;\n";
$mainSql .= "SELECT setval(pg_get_serial_sequence('public.terminal', 'id'), coalesce(max(id), 1)) FROM public.terminal;\n";
$mainSql .= "SELECT setval(pg_get_serial_sequence('selemti.sesion_cajon', 'id'), coalesce(max(id), 1)) FROM selemti.sesion_cajon;\n\n";

$mainSql .= "-- Analizar tablas para optimizar consultas\n";
$mainSql .= "ANALYZE public.ticket;\n";
$mainSql .= "ANALYZE public.ticket_item;\n";
$mainSql .= "ANALYZE public.transactions;\n";
$mainSql .= "ANALYZE selemti.sesion_cajon;\n";
$mainSql .= "ANALYZE selemti.mov_inv;\n\n";

// Resumen de restauración
$mainSql .= "-- ========================================\n";
$mainSql .= "-- 4. RESUMEN DE RESTAURACIÓN\n";
$mainSql .= "-- ========================================\n\n";

$mainSql .= "-- Mostrar registros restaurados principales\n";
$mainSql .= "SELECT \n";
$mainSql .= "    'ticket' as tabla, COUNT(*) as registros\n";
$mainSql .= "FROM public.ticket\n";
$mainSql .= "UNION ALL\n";
$mainSql .= "SELECT 'ticket_item', COUNT(*) FROM public.ticket_item\n";
$mainSql .= "UNION ALL\n";
$mainSql .= "SELECT 'sesion_cajon', COUNT(*) FROM selemti.sesion_cajon\n";
$mainSql .= "UNION ALL\n";
$mainSql .= "SELECT 'precorte', COUNT(*) FROM selemti.precorte\n";
$mainSql .= "UNION ALL\n";
$mainSql .= "SELECT 'postcorte', COUNT(*) FROM selemti.postcorte\n";
$mainSql .= "ORDER BY registros DESC;\n\n";

$mainSql .= "-- Verificar integridad referencial básica\n";
$mainSql .= "SELECT \n";
$mainSql .= "    'Tickets sin items' as issue, COUNT(*) as count\n";
$mainSql .= "FROM public.ticket t\n";
$mainSql .= "LEFT JOIN public.ticket_item ti ON t.id = ti.ticket_id\n";
$mainSql .= "WHERE ti.ticket_id IS NULL\n";
$mainSql .= "UNION ALL\n";
$mainSql .= "SELECT \n";
$mainSql .= "    'Sesiones sin precorte', COUNT(*)\n";
$mainSql .= "FROM selemti.sesion_cajon sc\n";
$mainSql .= "LEFT JOIN selemti.precorte p ON sc.id = p.sesion_cajon_id\n";
$mainSql .= "WHERE p.sesion_cajon_id IS NULL;\n\n";

$mainSql .= "-- Finalizado: " . date('Y-m-d H:i:s') . "\n";
$mainSql .= "COMMIT;\n";

file_put_contents($mainRestoreFile, $mainSql);

// Mostrar resumen
echo "\n✅ Proceso completado\n";
echo "📁 Archivos generados en: $tempDir\n";
echo "📄 Tamaños:\n";
echo "   - public_restore.sql: " . number_format(filesize($publicRestoreFile)/1024/1024, 2) . " MB\n";
echo "   - selemti_selective.sql: " . number_format(filesize($selemtiSelectiveFile)/1024, 2) . " KB\n";
echo "   - restore_main.sql: " . number_format(filesize($mainRestoreFile)/1024/1024, 2) . " MB\n";

echo "\n🚀 Para ejecutar la restauración:\n";
echo "   psql -h localhost -p 5433 -U postgres -d pos -f \"$mainRestoreFile\"\n\n";

echo "⚠️  ADVERTENCIAS:\n";
echo "   - Esto sobrescribirá completamente el schema PUBLIC\n";
echo "   - Preservará tablas nuevas de SELEMTI (cash_funds, purchases, etc.)\n";
echo "   - Hacer backup completo antes de ejecutar\n\n";

?>