-- =============================================================================
-- SCRIPT: 10_migrar_items_a_cat_unidades.sql
-- Fecha: 2025-11-03
-- Objetivo: Migrar tabla items de unidades_medida_legacy → cat_unidades
-- =============================================================================
-- CONTEXTO:
-- La tabla selemti.items actualmente tiene FKs a selemti.unidades_medida_legacy
-- pero queremos usar SOLO las tablas canónicas (cat_unidades)
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1. VERIFICACIÓN INICIAL
-- =============================================================================

DO $$
DECLARE
    v_count_items INTEGER;
    v_count_unidades INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count_items FROM selemti.items;
    SELECT COUNT(*) INTO v_count_unidades FROM selemti.cat_unidades;

    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'VERIFICACIÓN INICIAL';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'Items actuales: %', v_count_items;
    RAISE NOTICE 'Unidades disponibles: %', v_count_unidades;
    RAISE NOTICE '';
END $$;

-- =============================================================================
-- 2. ELIMINAR FOREIGN KEYS LEGACY
-- =============================================================================

-- FK: unidad_medida_id → unidades_medida_legacy
ALTER TABLE selemti.items
  DROP CONSTRAINT IF EXISTS items_unidad_medida_id_fkey;

-- FK: unidad_compra_id → unidades_medida_legacy
ALTER TABLE selemti.items
  DROP CONSTRAINT IF EXISTS items_unidad_compra_id_fkey;

-- FK: unidad_salida_id → unidades_medida_legacy
ALTER TABLE selemti.items
  DROP CONSTRAINT IF EXISTS items_unidad_salida_id_fkey;

-- =============================================================================
-- 3. CREAR NUEVAS FOREIGN KEYS → cat_unidades
-- =============================================================================

-- FK: unidad_medida_id → cat_unidades (Unidad BASE - inventario)
ALTER TABLE selemti.items
  ADD CONSTRAINT items_unidad_medida_id_fkey
  FOREIGN KEY (unidad_medida_id)
  REFERENCES selemti.cat_unidades(id)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;

-- FK: unidad_compra_id → cat_unidades (Unidad de COMPRA)
ALTER TABLE selemti.items
  ADD CONSTRAINT items_unidad_compra_id_fkey
  FOREIGN KEY (unidad_compra_id)
  REFERENCES selemti.cat_unidades(id)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;

-- FK: unidad_salida_id → cat_unidades (Unidad de SALIDA/RECETA)
ALTER TABLE selemti.items
  ADD CONSTRAINT items_unidad_salida_id_fkey
  FOREIGN KEY (unidad_salida_id)
  REFERENCES selemti.cat_unidades(id)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;

-- =============================================================================
-- 4. AGREGAR COMENTARIOS DOCUMENTALES
-- =============================================================================

COMMENT ON COLUMN selemti.items.unidad_medida_id IS
  'Unidad BASE de inventario (KG, L, PZ) - FK a cat_unidades';

COMMENT ON COLUMN selemti.items.unidad_compra_id IS
  'Unidad de COMPRA del proveedor (CAJA, PAQUETE, COSTAL, etc) - FK a cat_unidades';

COMMENT ON COLUMN selemti.items.factor_compra IS
  'Factor de conversión: 1 unidad_compra = X unidades_base. Ej: 1 CAJA = 12 L';

COMMENT ON COLUMN selemti.items.unidad_salida_id IS
  'Unidad de SALIDA para recetas (ML, TAZA, PORCION, etc) - FK a cat_unidades';

COMMENT ON COLUMN selemti.items.factor_conversion IS
  'Factor adicional de conversión si se requiere (legacy, en desuso)';

-- =============================================================================
-- 5. ACTUALIZAR ÍNDICES (si es necesario)
-- =============================================================================

-- Verificar que el índice en unidad_medida_id siga existiendo
DROP INDEX IF EXISTS selemti.idx_items_unidad_medida_id;

CREATE INDEX idx_items_unidad_medida_id
  ON selemti.items(unidad_medida_id)
  WHERE activo = true;

-- Agregar índice para unidad_compra_id (si no existe)
DROP INDEX IF EXISTS selemti.idx_items_unidad_compra_id;

CREATE INDEX idx_items_unidad_compra_id
  ON selemti.items(unidad_compra_id)
  WHERE activo = true AND unidad_compra_id IS NOT NULL;

-- Agregar índice para unidad_salida_id (si no existe)
DROP INDEX IF EXISTS selemti.idx_items_unidad_salida_id;

CREATE INDEX idx_items_unidad_salida_id
  ON selemti.items(unidad_salida_id)
  WHERE activo = true AND unidad_salida_id IS NOT NULL;

-- =============================================================================
-- 6. VALIDACIÓN FINAL
-- =============================================================================

DO $$
DECLARE
    v_fk_count INTEGER;
BEGIN
    -- Contar FKs que apuntan a cat_unidades
    SELECT COUNT(*) INTO v_fk_count
    FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu
      ON tc.constraint_name = ccu.constraint_name
    WHERE tc.table_schema = 'selemti'
      AND tc.table_name = 'items'
      AND tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_name = 'cat_unidades';

    RAISE NOTICE '';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'VALIDACIÓN FINAL';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'Foreign Keys items → cat_unidades: %', v_fk_count;

    IF v_fk_count >= 3 THEN
        RAISE NOTICE '✅ Migración EXITOSA - items ahora usa cat_unidades';
    ELSE
        RAISE WARNING '⚠️  Faltan algunas FKs, revisar manualmente';
    END IF;
    RAISE NOTICE '';
END $$;

COMMIT;

-- =============================================================================
-- VERIFICACIÓN DE ESTRUCTURA
-- =============================================================================

-- Mostrar las FKs actuales de items
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_schema = 'selemti'
  AND tc.table_name = 'items'
  AND tc.constraint_type = 'FOREIGN KEY'
  AND kcu.column_name LIKE '%unidad%'
ORDER BY kcu.column_name;

-- =============================================================================
-- RESUMEN
-- =============================================================================

SELECT
  '✅ MIGRACIÓN COMPLETADA' as status,
  'items ahora usa cat_unidades en lugar de unidades_medida_legacy' as descripcion;
