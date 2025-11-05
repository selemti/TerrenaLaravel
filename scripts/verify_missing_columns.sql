-- ═══════════════════════════════════════════════════════════════════════════════════
-- SCRIPT PARA SINCRONIZAR MIGRACIONES - VERIFICACIÓN PRE-EJECUCIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Este script verifica qué cambios faltan antes de ejecutar las migraciones
-- Fecha: 2025-11-05
-- ───────────────────────────────────────────────────────────────────────────────────

\echo '═══════════════════════════════════════════════════════════════════════════════════'
\echo 'VERIFICACIÓN DE CAMBIOS FALTANTES'
\echo '═══════════════════════════════════════════════════════════════════════════════════'
\echo ''

-- 1. Verificar columnas en recepcion_cab
\echo '1. Tabla: selemti.recepcion_cab'
\echo '   Columnas que deben existir:'
SELECT 
    column_name,
    CASE 
        WHEN column_name IN (
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
            AND table_name = 'recepcion_cab'
        ) THEN '✓ EXISTE'
        ELSE '✗ FALTA'
    END as estado
FROM (VALUES 
    ('almacen_origen_id'),
    ('estado'),
    ('total_presentaciones'),
    ('total_canonico')
) AS cols(column_name);

\echo ''

-- 2. Verificar columnas en items
\echo '2. Tabla: selemti.items'
\echo '   Columnas operacionales:'
SELECT 
    column_name,
    CASE 
        WHEN column_name IN (
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
            AND table_name = 'items'
        ) THEN '✓ EXISTE'
        ELSE '✗ FALTA'
    END as estado
FROM (VALUES 
    ('es_producible'),
    ('es_consumible_operativo'),
    ('es_empaque_to_go'),
    ('is_sellable'),
    ('is_purchasable')
) AS cols(column_name);

\echo ''

-- 3. Verificar columnas en inv_consumo_pos
\echo '3. Tabla: selemti.inv_consumo_pos'
\echo '   Columnas de procesamiento:'
SELECT 
    column_name,
    CASE 
        WHEN column_name IN (
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
            AND table_name = 'inv_consumo_pos'
        ) THEN '✓ EXISTE'
        ELSE '✗ FALTA'
    END as estado
FROM (VALUES 
    ('requiere_reproceso'),
    ('procesado'),
    ('revertido'),
    ('fecha_proceso')
) AS cols(column_name);

\echo ''

-- 4. Verificar columnas en roles
\echo '4. Tabla: selemti.roles'
\echo '   Campos de visualización:'
SELECT 
    column_name,
    CASE 
        WHEN column_name IN (
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
            AND table_name = 'roles'
        ) THEN '✓ EXISTE'
        ELSE '✗ FALTA'
    END as estado
FROM (VALUES 
    ('display_name'),
    ('description'),
    ('color')
) AS cols(column_name);

\echo ''

-- 5. Verificar columnas en insumo
\echo '5. Tabla: selemti.insumo'
\echo '   Campos de codificación:'
SELECT 
    column_name,
    CASE 
        WHEN column_name IN (
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
            AND table_name = 'insumo'
        ) THEN '✓ EXISTE'
        ELSE '✗ FALTA'
    END as estado
FROM (VALUES 
    ('codigo'),
    ('codigo_alterno'),
    ('categoria_codigo'),
    ('subcategoria_codigo'),
    ('consecutivo')
) AS cols(column_name);

\echo ''
\echo '═══════════════════════════════════════════════════════════════════════════════════'
\echo 'RESUMEN: Las columnas marcadas con ✗ FALTA necesitan ser creadas'
\echo '═══════════════════════════════════════════════════════════════════════════════════'
