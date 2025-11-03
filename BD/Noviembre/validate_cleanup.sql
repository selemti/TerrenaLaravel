-- ============================================
-- SCRIPT DE VALIDACIÓN POST-LIMPIEZA
-- Base de datos: pos @ localhost:5433
-- ============================================

\echo '============================================'
\echo 'VALIDACIÓN POST-LIMPIEZA DE TABLAS LEGACY'
\echo '============================================'
\echo ''

-- 1. Contar tablas por schema
\echo '1. Conteo de tablas por schema:'
\echo '--------------------------------'
SELECT schemaname, COUNT(*) as total_tables
FROM pg_tables
WHERE schemaname IN ('selemti', 'public')
GROUP BY schemaname
ORDER BY schemaname;

\echo ''

-- 2. Verificar tablas cat_* existen
\echo '2. Verificando tablas cat_* (catálogos maestros):'
\echo '--------------------------------------------------'
SELECT
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'selemti' AND tablename = 'cat_sucursales')
        THEN '✓ cat_sucursales EXISTS'
        ELSE '✗ cat_sucursales MISSING'
    END AS cat_sucursales,
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'selemti' AND tablename = 'cat_almacenes')
        THEN '✓ cat_almacenes EXISTS'
        ELSE '✗ cat_almacenes MISSING'
    END AS cat_almacenes,
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'selemti' AND tablename = 'cat_proveedores')
        THEN '✓ cat_proveedores EXISTS'
        ELSE '✗ cat_proveedores MISSING'
    END AS cat_proveedores,
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'selemti' AND tablename = 'cat_unidades')
        THEN '✓ cat_unidades EXISTS'
        ELSE '✗ cat_unidades MISSING'
    END AS cat_unidades,
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'selemti' AND tablename = 'cat_uom_conversion')
        THEN '✓ cat_uom_conversion EXISTS'
        ELSE '✗ cat_uom_conversion MISSING'
    END AS cat_uom_conversion;

\echo ''

-- 3. Verificar que NO existen tablas legacy
\echo '3. Verificando que NO existen tablas legacy:'
\echo '--------------------------------------------'
SELECT
    tablename,
    '⚠ LEGACY TABLE STILL EXISTS' as status
FROM pg_tables
WHERE schemaname = 'selemti'
  AND (
    tablename LIKE '%_legacy'
    OR tablename IN (
        'usuario', 'rol', 'user_roles',
        'sucursal', 'almacen', 'bodega', 'proveedor',
        'insumo', 'lote', 'merma', 'stock_policy',
        'receta', 'receta_cab', 'receta_det', 'receta_insumo', 'receta_version', 'receta_shadow',
        'op_cab', 'op_produccion_cab', 'prod_cab', 'sol_prod_cab',
        'op_insumo', 'prod_det', 'sol_prod_det', 'op_yield',
        'traspaso_cab', 'traspaso_det',
        'transfer_cab', 'transfer_det',
        'caja_fondo', 'caja_fondo_mov', 'caja_fondo_arqueo', 'caja_fondo_adj',
        'audit_log'
    )
  )
ORDER BY tablename;

-- Si no devuelve filas, la limpieza fue exitosa

\echo ''

-- 4. Verificar tablas de operaciones actuales
\echo '4. Verificando tablas de operaciones actuales:'
\echo '-----------------------------------------------'
SELECT
    tablename,
    '✓ EXISTS' as status
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename IN (
      'items', 'inventory_batch', 'inventory_wastes', 'mov_inv',
      'production_orders', 'production_order_inputs', 'production_order_outputs',
      'recipe_versions', 'recipe_version_items',
      'cash_funds', 'cash_fund_movements',
      'purchase_orders', 'purchase_order_lines',
      'recepcion_cab', 'recepcion_det'
  )
ORDER BY tablename;

\echo ''

-- 5. Verificar foreign keys rotas
\echo '5. Verificando foreign keys rotas:'
\echo '-----------------------------------'
SELECT
    tc.table_name,
    tc.constraint_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'selemti'
  AND NOT EXISTS (
      SELECT 1
      FROM pg_tables
      WHERE schemaname = ccu.table_schema
        AND tablename = ccu.table_name
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Si no devuelve filas, no hay FKs rotas

\echo ''

-- 6. Resumen de limpieza
\echo '6. Resumen de limpieza:'
\echo '------------------------'
DO $$
DECLARE
    v_total_selemti INT;
    v_total_public INT;
    v_cat_tables INT;
    v_legacy_remaining INT;
    v_operations_tables INT;
    v_broken_fks INT;
BEGIN
    -- Totales
    SELECT COUNT(*) INTO v_total_selemti FROM pg_tables WHERE schemaname = 'selemti';
    SELECT COUNT(*) INTO v_total_public FROM pg_tables WHERE schemaname = 'public';

    -- Catálogos
    SELECT COUNT(*) INTO v_cat_tables
    FROM pg_tables
    WHERE schemaname = 'selemti' AND tablename LIKE 'cat_%';

    -- Legacy restantes
    SELECT COUNT(*) INTO v_legacy_remaining
    FROM pg_tables
    WHERE schemaname = 'selemti'
      AND (
        tablename LIKE '%_legacy'
        OR tablename IN (
            'usuario', 'rol', 'sucursal', 'almacen', 'bodega', 'proveedor',
            'insumo', 'lote', 'merma',
            'receta', 'receta_cab', 'receta_det', 'receta_insumo', 'receta_version', 'receta_shadow',
            'op_cab', 'op_produccion_cab', 'prod_cab', 'sol_prod_cab',
            'op_insumo', 'prod_det', 'sol_prod_det', 'op_yield',
            'traspaso_cab', 'traspaso_det',
            'caja_fondo', 'caja_fondo_mov', 'caja_fondo_arqueo', 'caja_fondo_adj',
            'audit_log')
      );

    -- Tablas de operaciones
    SELECT COUNT(*) INTO v_operations_tables
    FROM pg_tables
    WHERE schemaname = 'selemti'
      AND tablename IN (
          'items', 'inventory_batch', 'mov_inv', 'production_orders',
          'recipe_versions', 'cash_funds', 'purchase_orders'
      );

    -- FKs rotas
    SELECT COUNT(*) INTO v_broken_fks
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'selemti'
      AND NOT EXISTS (
          SELECT 1 FROM pg_tables
          WHERE schemaname = ccu.table_schema AND tablename = ccu.table_name
      );

    RAISE NOTICE '';
    RAISE NOTICE '  Total tablas selemti: %', v_total_selemti;
    RAISE NOTICE '  Total tablas public: %', v_total_public;
    RAISE NOTICE '  Tablas cat_* (catálogos): %', v_cat_tables;
    RAISE NOTICE '  Tablas operaciones actuales: % de 7', v_operations_tables;
    RAISE NOTICE '  Tablas legacy restantes: %', v_legacy_remaining;
    RAISE NOTICE '  Foreign keys rotas: %', v_broken_fks;
    RAISE NOTICE '';

    IF v_legacy_remaining = 0 AND v_broken_fks = 0 AND v_cat_tables = 5 THEN
        RAISE NOTICE '  ✅ VALIDACIÓN EXITOSA - Limpieza completada correctamente';
    ELSE
        IF v_legacy_remaining > 0 THEN
            RAISE WARNING '  ⚠ Todavía quedan % tablas legacy', v_legacy_remaining;
        END IF;
        IF v_broken_fks > 0 THEN
            RAISE WARNING '  ⚠ Se detectaron % foreign keys rotas', v_broken_fks;
        END IF;
        IF v_cat_tables < 5 THEN
            RAISE WARNING '  ⚠ Faltan tablas cat_* (esperadas 5, encontradas %)', v_cat_tables;
        END IF;
    END IF;

    RAISE NOTICE '';
END $$;

\echo ''
\echo '============================================'
\echo 'VALIDACIÓN COMPLETADA'
\echo '============================================'
