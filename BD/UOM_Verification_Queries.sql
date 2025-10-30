-- ====================================================================
-- UOM VERIFICATION QUERIES
-- TerrenaLaravel - Verificación de Normalización Completa
-- ====================================================================
--
-- Ejecutar después de aplicar UOM_Normalization_PG95.sql
-- para verificar que todo se aplicó correctamente
--
-- Uso:
-- psql -h localhost -p 5433 -U postgres -d pos -f BD/UOM_Verification_Queries.sql
-- ====================================================================

SET search_path TO selemti, public;

\echo '===================================================================='
\echo 'VERIFICACIÓN 1: Conteo de UOM y Conversiones'
\echo '===================================================================='

SELECT
    'Total UOM activas' as metrica,
    COUNT(*) as valor
FROM cat_unidades
WHERE activo = true

UNION ALL

SELECT
    'Conversiones totales' as metrica,
    COUNT(*) as valor
FROM cat_uom_conversion

UNION ALL

SELECT
    'Conversiones exactas' as metrica,
    COUNT(*) as valor
FROM cat_uom_conversion
WHERE is_exact = true

UNION ALL

SELECT
    'Conversiones aproximadas' as metrica,
    COUNT(*) as valor
FROM cat_uom_conversion
WHERE is_exact = false

UNION ALL

SELECT
    'Conversiones globales' as metrica,
    COUNT(*) as valor
FROM cat_uom_conversion
WHERE scope = 'global'

UNION ALL

SELECT
    'Conversiones culinarias (house)' as metrica,
    COUNT(*) as valor
FROM cat_uom_conversion
WHERE scope = 'house';


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 2: Catálogo Completo de UOM'
\echo '===================================================================='

SELECT
    clave,
    nombre,
    CASE
        WHEN clave IN ('KG', 'G', 'MG', 'LB', 'OZ', 'TON', 'GR') THEN 'Masa'
        WHEN clave IN ('L', 'ML', 'M3', 'FLOZ', 'CUP', 'TBSP', 'TSP', 'GAL', 'LT', 'MC', 'TAZA', 'CDSP', 'CDTA') THEN 'Volumen'
        WHEN clave IN ('PZ', 'PZA', 'CAJA', 'COST', 'PAQ', 'PLAT', 'PORC') THEN 'Unidad'
        WHEN clave IN ('HR', 'MIN') THEN 'Tiempo'
        ELSE 'Otro'
    END as categoria,
    CASE
        WHEN clave IN ('KG', 'L', 'PZ') THEN '★ BASE ★'
        ELSE ''
    END as es_base_operativa,
    activo
FROM cat_unidades
ORDER BY
    CASE
        WHEN categoria = 'Masa' THEN 1
        WHEN categoria = 'Volumen' THEN 2
        WHEN categoria = 'Unidad' THEN 3
        WHEN categoria = 'Tiempo' THEN 4
        ELSE 5
    END,
    clave;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 3: Roundtrip Tests (Ida y Vuelta)'
\echo '===================================================================='

-- Test 1: KG → G → KG
WITH kg_to_g AS (
    SELECT factor FROM cat_uom_conversion
    WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'KG')
      AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'G')
),
g_to_kg AS (
    SELECT factor FROM cat_uom_conversion
    WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'G')
      AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'KG')
)
SELECT
    'KG → G → KG' as ruta,
    (SELECT factor FROM kg_to_g) as kg_to_g,
    (SELECT factor FROM g_to_kg) as g_to_kg,
    (SELECT factor FROM kg_to_g) * (SELECT factor FROM g_to_kg) as roundtrip_factor,
    CASE
        WHEN ABS((SELECT factor FROM kg_to_g) * (SELECT factor FROM g_to_kg) - 1.0) < 0.0001
        THEN '✓ EXACTO'
        ELSE '✗ ERROR'
    END as status

UNION ALL

-- Test 2: L → ML → L
SELECT
    'L → ML → L' as ruta,
    (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'L') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'ML')),
    (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'ML') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'L')),
    (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'L') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'ML'))
    * (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'ML') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'L')),
    CASE
        WHEN ABS(
            (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'L') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'ML'))
            * (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'ML') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'L'))
            - 1.0) < 0.0001
        THEN '✓ EXACTO'
        ELSE '✗ ERROR'
    END

UNION ALL

-- Test 3: CUP → ML → CUP (aproximado)
SELECT
    'CUP → ML → CUP' as ruta,
    (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'CUP') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'ML')),
    (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'ML') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'CUP')),
    (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'CUP') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'ML'))
    * (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'ML') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'CUP')),
    CASE
        WHEN ABS(
            (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'CUP') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'ML'))
            * (SELECT factor FROM cat_uom_conversion WHERE origen_id = (SELECT id FROM cat_unidades WHERE clave = 'ML') AND destino_id = (SELECT id FROM cat_unidades WHERE clave = 'CUP'))
            - 1.0) < 0.01
        THEN '✓ APROXIMADO (OK)'
        ELSE '✗ ERROR'
    END;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 4: Vistas de Compatibilidad'
\echo '===================================================================='

SELECT
    table_name,
    table_type,
    CASE
        WHEN table_type = 'VIEW' THEN '✓ OK'
        ELSE '✗ ERROR'
    END as status
FROM information_schema.tables
WHERE table_schema = 'selemti'
  AND table_name IN ('unidad_medida', 'unidades_medida', 'uom_conversion', 'conversiones_unidad')
ORDER BY table_name;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 5: Tablas Legacy Renombradas'
\echo '===================================================================='

SELECT
    table_name,
    table_type,
    CASE
        WHEN table_type = 'BASE TABLE' THEN '✓ OK'
        ELSE '✗ ERROR'
    END as status
FROM information_schema.tables
WHERE table_schema = 'selemti'
  AND table_name IN ('unidad_medida_legacy', 'unidades_medida_legacy', 'uom_conversion_legacy', 'conversiones_unidad_legacy')
ORDER BY table_name;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 6: Conversiones Métricas (Masa)'
\echo '===================================================================='

SELECT
    o.clave as desde,
    d.clave as hasta,
    c.factor,
    CASE WHEN c.is_exact THEN 'Exacta' ELSE 'Aprox' END as tipo,
    c.scope,
    c.notes
FROM cat_uom_conversion c
JOIN cat_unidades o ON c.origen_id = o.id
JOIN cat_unidades d ON c.destino_id = d.id
WHERE o.clave IN ('KG', 'G', 'MG')
  AND d.clave IN ('KG', 'G', 'MG')
  AND o.clave <> d.clave
ORDER BY o.clave, d.clave;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 7: Conversiones Métricas (Volumen)'
\echo '===================================================================='

SELECT
    o.clave as desde,
    d.clave as hasta,
    c.factor,
    CASE WHEN c.is_exact THEN 'Exacta' ELSE 'Aprox' END as tipo,
    c.scope,
    c.notes
FROM cat_uom_conversion c
JOIN cat_unidades o ON c.origen_id = o.id
JOIN cat_unidades d ON c.destino_id = d.id
WHERE o.clave IN ('L', 'ML', 'M3')
  AND d.clave IN ('L', 'ML', 'M3')
  AND o.clave <> d.clave
ORDER BY o.clave, d.clave;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 8: Conversiones Imperiales'
\echo '===================================================================='

SELECT
    o.clave as desde,
    d.clave as hasta,
    c.factor,
    CASE WHEN c.is_exact THEN 'Exacta' ELSE 'Aprox' END as tipo,
    c.scope,
    c.notes
FROM cat_uom_conversion c
JOIN cat_unidades o ON c.origen_id = o.id
JOIN cat_unidades d ON c.destino_id = d.id
WHERE (o.clave IN ('LB', 'OZ') OR d.clave IN ('LB', 'OZ', 'G'))
  AND c.scope = 'global'
ORDER BY o.clave, d.clave;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 9: Conversiones Culinarias (House Scope)'
\echo '===================================================================='

SELECT
    o.clave as desde,
    d.clave as hasta,
    c.factor,
    CASE WHEN c.is_exact THEN 'Exacta' ELSE 'Aprox' END as tipo,
    c.scope,
    c.notes
FROM cat_uom_conversion c
JOIN cat_unidades o ON c.origen_id = o.id
JOIN cat_unidades d ON c.destino_id = d.id
WHERE c.scope = 'house'
ORDER BY
    CASE
        WHEN o.clave = 'CUP' THEN 1
        WHEN o.clave = 'TBSP' THEN 2
        WHEN o.clave = 'TSP' THEN 3
        WHEN o.clave = 'FLOZ' THEN 4
        ELSE 5
    END,
    d.clave;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 10: Foreign Keys en cat_uom_conversion'
\echo '===================================================================='

SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    '✓ OK' as status
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'selemti'
  AND tc.table_name = 'cat_uom_conversion';


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN 11: Índices en Tablas Canónicas'
\echo '===================================================================='

SELECT
    tablename,
    indexname,
    indexdef,
    '✓ OK' as status
FROM pg_indexes
WHERE schemaname = 'selemti'
  AND tablename IN ('cat_unidades', 'cat_uom_conversion')
ORDER BY tablename, indexname;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN FINAL: Resumen de Estado'
\echo '===================================================================='

WITH verification_summary AS (
    SELECT
        'UOM activas' as item,
        COUNT(*)::text as resultado,
        CASE WHEN COUNT(*) >= 13 THEN '✓ PASS' ELSE '✗ FAIL' END as status
    FROM cat_unidades
    WHERE activo = true

    UNION ALL

    SELECT
        'Conversiones totales' as item,
        COUNT(*)::text as resultado,
        CASE WHEN COUNT(*) >= 26 THEN '✓ PASS' ELSE '✗ FAIL' END as status
    FROM cat_uom_conversion

    UNION ALL

    SELECT
        'Vistas de compatibilidad' as item,
        COUNT(*)::text as resultado,
        CASE WHEN COUNT(*) = 4 THEN '✓ PASS' ELSE '✗ FAIL' END as status
    FROM information_schema.tables
    WHERE table_schema = 'selemti'
      AND table_type = 'VIEW'
      AND table_name IN ('unidad_medida', 'unidades_medida', 'uom_conversion', 'conversiones_unidad')

    UNION ALL

    SELECT
        'Tablas legacy renombradas' as item,
        COUNT(*)::text as resultado,
        CASE WHEN COUNT(*) = 4 THEN '✓ PASS' ELSE '✗ FAIL' END as status
    FROM information_schema.tables
    WHERE table_schema = 'selemti'
      AND table_type = 'BASE TABLE'
      AND table_name IN ('unidad_medida_legacy', 'unidades_medida_legacy', 'uom_conversion_legacy', 'conversiones_unidad_legacy')

    UNION ALL

    SELECT
        'Foreign Keys en cat_uom_conversion' as item,
        COUNT(*)::text as resultado,
        CASE WHEN COUNT(*) = 2 THEN '✓ PASS' ELSE '✗ FAIL' END as status
    FROM information_schema.table_constraints
    WHERE constraint_type = 'FOREIGN KEY'
      AND table_schema = 'selemti'
      AND table_name = 'cat_uom_conversion'
)
SELECT
    item,
    resultado,
    status
FROM verification_summary
ORDER BY
    CASE
        WHEN status LIKE '%PASS%' THEN 1
        ELSE 2
    END,
    item;


\echo ''
\echo '===================================================================='
\echo 'VERIFICACIÓN COMPLETA'
\echo '===================================================================='
\echo 'Si todos los status muestran ✓, la normalización fue exitosa.'
\echo 'Ver documentación completa en: docs/UOM_STRATEGY_TERRENA.md'
\echo '===================================================================='
