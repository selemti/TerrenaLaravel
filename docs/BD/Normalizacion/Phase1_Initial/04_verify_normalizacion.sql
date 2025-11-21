-- =============================================================================
-- Script 04: Verificación Post-Normalización en selemti
-- =============================================================================
-- Fecha: 30 de octubre de 2025
-- Objetivo: Verificar que la normalización se aplicó correctamente
-- IMPORTANTE: Solo verifica esquema selemti, NO toca public
-- =============================================================================

SET search_path TO selemti, public;

\echo '============================================================================='
\echo 'VERIFICACIÓN DE NORMALIZACIÓN - ESQUEMA SELEMTI'
\echo '============================================================================='
\echo ''

-- -----------------------------------------------------------------------------
-- 1. VERIFICAR TABLA CANÓNICA DE UNIDADES
-- -----------------------------------------------------------------------------
\echo '1. TABLA CANÓNICA DE UNIDADES (unidades_medida_legacy)'
\echo '---------------------------------------------------------------------'

SELECT
    COUNT(*) as total_unidades,
    COUNT(*) FILTER (WHERE es_base = true) as unidades_base,
    COUNT(DISTINCT tipo) as tipos_unidad
FROM selemti.unidades_medida_legacy;

\echo ''
\echo 'Unidades base (deben ser KG, L, PZ o EA):'
SELECT codigo, nombre, tipo
FROM selemti.unidades_medida_legacy
WHERE es_base = true
ORDER BY codigo;

\echo ''

-- -----------------------------------------------------------------------------
-- 2. VERIFICAR VISTAS DE COMPATIBILIDAD
-- -----------------------------------------------------------------------------
\echo '2. VISTAS DE COMPATIBILIDAD'
\echo '---------------------------------------------------------------------'

SELECT
    schemaname,
    viewname,
    CASE
        WHEN viewname LIKE '%compat%' THEN '✓ OK'
        ELSE 'Verificar'
    END as status
FROM pg_views
WHERE schemaname = 'selemti'
  AND viewname LIKE '%unidad%'
ORDER BY viewname;

\echo ''

-- -----------------------------------------------------------------------------
-- 3. VERIFICAR TIPO DE inventory_snapshot.item_id
-- -----------------------------------------------------------------------------
\echo '3. TIPO DE COLUMNA inventory_snapshot.item_id'
\echo '---------------------------------------------------------------------'

SELECT
    column_name,
    data_type,
    CASE
        WHEN data_type = 'character varying' THEN '✓ CORRECTO'
        WHEN data_type = 'uuid' THEN '✗ INCORRECTO (debe ser VARCHAR)'
        ELSE '? REVISAR'
    END as status
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name = 'inventory_snapshot'
  AND column_name = 'item_id';

\echo ''

-- -----------------------------------------------------------------------------
-- 4. VERIFICAR FOREIGN KEYS CRÍTICAS
-- -----------------------------------------------------------------------------
\echo '4. FOREIGN KEYS CRÍTICAS'
\echo '---------------------------------------------------------------------'

SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column,
    '✓' as status
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'selemti'
  AND tc.table_name IN ('inventory_snapshot', 'recipe_cost_history', 'pos_map', 'items')
ORDER BY tc.table_name, kcu.column_name;

\echo ''

-- -----------------------------------------------------------------------------
-- 5. VERIFICAR INTEGRIDAD REFERENCIAL
-- -----------------------------------------------------------------------------
\echo '5. INTEGRIDAD REFERENCIAL'
\echo '---------------------------------------------------------------------'

-- Items con unidades válidas
\echo 'Items con unidades válidas:'
SELECT
    COUNT(*) as total_items,
    COUNT(i.unidad_medida_id) as con_unidad,
    COUNT(*) - COUNT(i.unidad_medida_id) as sin_unidad
FROM selemti.items i;

\echo ''
\echo 'Items con unidades huérfanas (debe ser 0):'
SELECT COUNT(*) as huerfanos
FROM selemti.items i
LEFT JOIN selemti.unidades_medida_legacy u ON u.id = i.unidad_medida_id
WHERE i.unidad_medida_id IS NOT NULL AND u.id IS NULL;

\echo ''

-- Snapshots con items válidos
\echo 'Snapshots con items válidos:'
SELECT
    COUNT(*) as total_snapshots,
    COUNT(s.item_id) - COUNT(i.id) as huerfanos
FROM selemti.inventory_snapshot s
LEFT JOIN selemti.items i ON i.id = s.item_id;

\echo ''

-- -----------------------------------------------------------------------------
-- 6. VERIFICAR ELIMINACIÓN DE CAMPOS REDUNDANTES
-- -----------------------------------------------------------------------------
\echo '6. CAMPOS REDUNDANTES (deben estar marcados para eliminación)'
\echo '---------------------------------------------------------------------'

SELECT
    table_name,
    column_name,
    data_type,
    CASE
        WHEN column_name = 'unidad_medida' AND table_name = 'items' THEN '⚠️ Pendiente eliminación'
        ELSE '✓ OK'
    END as status
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name IN ('items', 'receta_det')
  AND column_name = 'unidad_medida'
ORDER BY table_name;

\echo ''

-- -----------------------------------------------------------------------------
-- 7. RESUMEN DE NORMALIZACIÓN
-- -----------------------------------------------------------------------------
\echo '7. RESUMEN DE NORMALIZACIÓN'
\echo '---------------------------------------------------------------------'

DO $$
DECLARE
    v_unidades INTEGER;
    v_fks INTEGER;
    v_vistas INTEGER;
    v_tipo_correcto BOOLEAN;
BEGIN
    -- Contar unidades
    SELECT COUNT(*) INTO v_unidades FROM selemti.unidades_medida_legacy;

    -- Contar FKs
    SELECT COUNT(*) INTO v_fks
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'selemti'
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_name LIKE 'fk_%';

    -- Contar vistas de compatibilidad
    SELECT COUNT(*) INTO v_vistas
    FROM pg_views
    WHERE schemaname = 'selemti'
      AND viewname LIKE '%compat%';

    -- Verificar tipo de inventory_snapshot
    SELECT data_type = 'character varying' INTO v_tipo_correcto
    FROM information_schema.columns
    WHERE table_schema = 'selemti'
      AND table_name = 'inventory_snapshot'
      AND column_name = 'item_id';

    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════════';
    RAISE NOTICE 'RESUMEN DE NORMALIZACIÓN - SELEMTI';
    RAISE NOTICE '═══════════════════════════════════════════════════════════════';
    RAISE NOTICE 'Unidades en tabla canónica: %', v_unidades;
    RAISE NOTICE 'Vistas de compatibilidad: %', v_vistas;
    RAISE NOTICE 'Foreign keys añadidas: %', v_fks;
    RAISE NOTICE 'Tipo inventory_snapshot.item_id: %', CASE WHEN v_tipo_correcto THEN '✓ VARCHAR(20)' ELSE '✗ Incorrecto' END;
    RAISE NOTICE '';

    IF v_unidades >= 20 AND v_fks >= 3 AND v_tipo_correcto THEN
        RAISE NOTICE '✓✓✓ NORMALIZACIÓN COMPLETADA EXITOSAMENTE ✓✓✓';
    ELSE
        RAISE WARNING '⚠️ Revisar elementos pendientes';
    END IF;

    RAISE NOTICE '═══════════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

\echo ''
\echo '============================================================================='
\echo 'VERIFICACIÓN COMPLETADA'
\echo '============================================================================='
