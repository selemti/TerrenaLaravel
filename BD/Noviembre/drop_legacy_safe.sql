-- ============================================
-- SCRIPT DE LIMPIEZA DE TABLAS LEGACY
-- Base de datos: pos @ localhost:5433
-- Fecha: 2 Noviembre 2025
-- ============================================
-- PRERREQUISITO: Backup completo ejecutado
-- VALIDACIÓN: Código revisado manualmente
-- AMBIENTE: Solo desarrollo, NUNCA producción
-- ============================================

BEGIN;

-- Log de inicio
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'INICIANDO LIMPIEZA DE TABLAS LEGACY';
    RAISE NOTICE 'Fecha/Hora: %', NOW();
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 1: Tablas con sufijo *_legacy
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 1: Eliminando tablas *_legacy...';
END $$;

DROP TABLE IF EXISTS selemti.conversiones_unidad_legacy CASCADE;
DROP TABLE IF EXISTS selemti.uom_conversion_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidad_medida_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidades_medida_legacy CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminadas 4 tablas *_legacy';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 2: Usuarios y Roles legacy
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 2: Verificando y eliminando usuarios/roles legacy...';
END $$;

-- Verificar 0 registros antes de drop
DO $$
DECLARE
    v_count_usuario INT := 0;
    v_count_rol INT := 0;
    v_count_user_roles INT := 0;
BEGIN
    -- Verificar si las tablas existen antes de contar
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'selemti' AND table_name = 'usuario') THEN
        SELECT COUNT(*) INTO v_count_usuario FROM selemti.usuario;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'selemti' AND table_name = 'rol') THEN
        SELECT COUNT(*) INTO v_count_rol FROM selemti.rol;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'selemti' AND table_name = 'user_roles') THEN
        SELECT COUNT(*) INTO v_count_user_roles FROM selemti.user_roles;
    END IF;

    RAISE NOTICE '  - Registros en usuario: %', v_count_usuario;
    RAISE NOTICE '  - Registros en rol: %', v_count_rol;
    RAISE NOTICE '  - Registros en user_roles: %', v_count_user_roles;

    IF v_count_usuario > 0 OR v_count_rol > 0 OR v_count_user_roles > 0 THEN
        RAISE EXCEPTION 'ABORT: Tablas usuario/rol/user_roles tienen datos. No es seguro eliminar.';
    END IF;
END $$;

DROP TABLE IF EXISTS selemti.usuario CASCADE;
DROP TABLE IF EXISTS selemti.rol CASCADE;
DROP TABLE IF EXISTS selemti.user_roles CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminadas 3 tablas: usuario, rol, user_roles';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 3: Catálogos legacy
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 3: Eliminando catálogos legacy...';
END $$;

-- Verificar FKs antes de eliminar
DO $$
DECLARE
    v_fk_count INT;
BEGIN
    SELECT COUNT(*) INTO v_fk_count
    FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'selemti'
      AND ccu.table_name IN ('sucursal', 'proveedor', 'almacen', 'bodega');

    IF v_fk_count > 0 THEN
        RAISE NOTICE '  ⚠ ADVERTENCIA: % FKs activas apuntan a tablas legacy', v_fk_count;
        RAISE NOTICE '    Se usará CASCADE para eliminarlas';
    ELSE
        RAISE NOTICE '  ✓ No hay FKs activas a catálogos legacy';
    END IF;
END $$;

DROP TABLE IF EXISTS selemti.sucursal CASCADE;
DROP TABLE IF EXISTS selemti.proveedor CASCADE;
DROP TABLE IF EXISTS selemti.almacen CASCADE;
DROP TABLE IF EXISTS selemti.bodega CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminadas 4 tablas: sucursal, proveedor, almacen, bodega';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 4: Inventario legacy
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 4: Eliminando tablas de inventario legacy...';
END $$;

DROP TABLE IF EXISTS selemti.insumo CASCADE;
DROP TABLE IF EXISTS selemti.lote CASCADE;
DROP TABLE IF EXISTS selemti.merma CASCADE;
DROP TABLE IF EXISTS selemti.stock_policy CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminadas 4 tablas: insumo, lote, merma, stock_policy';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 5: Transferencias legacy
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 5: Eliminando transferencias legacy...';
END $$;

DROP TABLE IF EXISTS selemti.traspaso_det CASCADE;
DROP TABLE IF EXISTS selemti.traspaso_cab CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminadas 2 tablas: traspaso_cab, traspaso_det';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 6: Producción legacy
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 6: Eliminando tablas de producción legacy...';
    RAISE NOTICE '  (Detalles primero, luego cabeceras)';
END $$;

-- Detalles primero
DROP TABLE IF EXISTS selemti.sol_prod_det CASCADE;
DROP TABLE IF EXISTS selemti.op_insumo CASCADE;
DROP TABLE IF EXISTS selemti.prod_det CASCADE;

-- Cabeceras después
DROP TABLE IF EXISTS selemti.sol_prod_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_produccion_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_cab CASCADE;
DROP TABLE IF EXISTS selemti.prod_cab CASCADE;

-- Yield
DROP TABLE IF EXISTS selemti.op_yield CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminadas 8 tablas de producción';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 7: Recetas legacy
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 7: Eliminando recetas legacy...';
END $$;

-- Detalles y versiones primero
DROP TABLE IF EXISTS selemti.receta_insumo CASCADE;
DROP TABLE IF EXISTS selemti.receta_det CASCADE;
DROP TABLE IF EXISTS selemti.receta_version CASCADE;
DROP TABLE IF EXISTS selemti.receta_shadow CASCADE;

-- Cabeceras después
DROP TABLE IF EXISTS selemti.receta_cab CASCADE;
DROP TABLE IF EXISTS selemti.receta CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminadas 6 tablas: receta_*, receta_cab, receta_det, etc.';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 8: Caja Chica legacy
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 8: Eliminando caja chica legacy...';
END $$;

-- Movimientos y arqueos primero
DROP TABLE IF EXISTS selemti.caja_fondo_mov CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo_arqueo CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo_adj CASCADE;

-- Fondos después
DROP TABLE IF EXISTS selemti.caja_fondo CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminadas 4 tablas: caja_fondo_*';
    RAISE NOTICE '';
END $$;

-- ============================================
-- PASO 9: Auditoría legacy (solo vacías)
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'PASO 9: Eliminando auditoría legacy...';
    RAISE NOTICE '  NOTA: NO se elimina selemti.auditoria (tiene 72 registros)';
    RAISE NOTICE '  NOTA: NO se elimina audit_log_global (es tabla actual)';
END $$;

DROP TABLE IF EXISTS selemti.audit_log CASCADE;

DO $$
BEGIN
    RAISE NOTICE '  ✓ Eliminada 1 tabla: audit_log';
    RAISE NOTICE '';
END $$;

-- ============================================
-- RESUMEN FINAL
-- ============================================

DO $$
DECLARE
    v_total_tables INT;
    v_cat_tables INT;
    v_legacy_remaining INT;
BEGIN
    -- Contar tablas totales en selemti
    SELECT COUNT(*) INTO v_total_tables
    FROM pg_tables
    WHERE schemaname = 'selemti';

    -- Contar tablas cat_*
    SELECT COUNT(*) INTO v_cat_tables
    FROM pg_tables
    WHERE schemaname = 'selemti'
      AND tablename LIKE 'cat_%';

    -- Verificar si quedan tablas legacy
    SELECT COUNT(*) INTO v_legacy_remaining
    FROM pg_tables
    WHERE schemaname = 'selemti'
      AND (
        tablename LIKE '%_legacy'
        OR tablename IN ('usuario', 'rol', 'sucursal', 'almacen', 'bodega', 'proveedor',
                         'insumo', 'lote', 'merma',
                         'receta', 'receta_cab', 'receta_det', 'receta_insumo', 'receta_version', 'receta_shadow',
                         'op_cab', 'op_produccion_cab', 'prod_cab', 'sol_prod_cab',
                         'op_insumo', 'prod_det', 'sol_prod_det', 'op_yield',
                         'traspaso_cab', 'traspaso_det',
                         'caja_fondo', 'caja_fondo_mov', 'caja_fondo_arqueo', 'caja_fondo_adj',
                         'audit_log')
      );

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'LIMPIEZA COMPLETADA';
    RAISE NOTICE 'Fecha/Hora: %', NOW();
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Estadísticas finales:';
    RAISE NOTICE '  - Tablas restantes en selemti: %', v_total_tables;
    RAISE NOTICE '  - Tablas cat_* (catálogos): %', v_cat_tables;
    RAISE NOTICE '  - Tablas legacy restantes: %', v_legacy_remaining;
    RAISE NOTICE '';

    IF v_legacy_remaining > 0 THEN
        RAISE WARNING 'Todavía quedan % tablas legacy', v_legacy_remaining;
    ELSE
        RAISE NOTICE '  ✅ Todas las tablas legacy fueron eliminadas exitosamente';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
END $$;

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando tablas cat_* (deben existir):';
END $$;

SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename LIKE 'cat_%'
ORDER BY tablename;

-- ============================================
-- COMMIT o ROLLBACK
-- ============================================

-- IMPORTANTE: Descomentar UNA de estas líneas:

ROLLBACK; -- Para DRY-RUN (ver los NOTICE sin hacer cambios)

-- COMMIT; -- Solo cuando estés 100% seguro (ejecutar después de dry-run exitoso)

-- ============================================
-- INSTRUCCIONES POST-EJECUCIÓN
-- ============================================

-- Si ejecutaste con ROLLBACK (dry-run):
--   1. Revisa todos los NOTICE y WARNING
--   2. Verifica que no hubo errores
--   3. Si todo está OK, cambia ROLLBACK por COMMIT y ejecuta de nuevo

-- Si ejecutaste con COMMIT:
--   1. Ejecuta validación post-drop:
--      psql -h localhost -p 5433 -U postgres -d pos -f docs/BD/validate_cleanup.sql
--   2. Ejecuta tests de Laravel:
--      php artisan test
--   3. Verifica Livewire components funcionan
--   4. Revisa logs: php artisan pail
