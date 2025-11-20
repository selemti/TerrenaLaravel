-- =============================================================================
-- Script 02: Corregir Tipo de inventory_snapshot.item_id
-- =============================================================================
-- Fecha: 30 de octubre de 2025
-- Objetivo: Cambiar inventory_snapshot.item_id de UUID a VARCHAR(20)
--           para compatibilidad con items.id
-- IMPORTANTE: Solo opera en esquema selemti, NO toca public
-- =============================================================================

SET search_path TO selemti, public;

-- -----------------------------------------------------------------------------
-- PASO 1: Verificar estado actual
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_tipo TEXT;
    v_count INTEGER;
BEGIN
    RAISE NOTICE '=== ESTADO ACTUAL DE inventory_snapshot ===';

    -- Obtener tipo actual
    SELECT data_type INTO v_tipo
    FROM information_schema.columns
    WHERE table_schema = 'selemti'
      AND table_name = 'inventory_snapshot'
      AND column_name = 'item_id';

    RAISE NOTICE 'Tipo actual de item_id: %', v_tipo;

    -- Contar registros
    SELECT COUNT(*) INTO v_count FROM selemti.inventory_snapshot;
    RAISE NOTICE 'Registros en inventory_snapshot: %', v_count;

    IF v_count > 0 THEN
        RAISE EXCEPTION 'ATENCIÓN: La tabla contiene % registros. Revisar migración de datos.', v_count;
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 2: Cambiar tipo de columna item_id
-- -----------------------------------------------------------------------------
-- Como la tabla está vacía, podemos hacer el cambio directamente

ALTER TABLE selemti.inventory_snapshot
  ALTER COLUMN item_id TYPE VARCHAR(20) USING item_id::TEXT;

-- -----------------------------------------------------------------------------
-- PASO 3: Añadir foreign key a items
-- -----------------------------------------------------------------------------
-- Verificar que no existe la FK primero
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_schema = 'selemti'
          AND table_name = 'inventory_snapshot'
          AND constraint_name = 'fk_inventory_snapshot_item'
    ) THEN
        ALTER TABLE selemti.inventory_snapshot
          ADD CONSTRAINT fk_inventory_snapshot_item
          FOREIGN KEY (item_id) REFERENCES selemti.items(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE;

        RAISE NOTICE '✓ Foreign key añadida: inventory_snapshot.item_id -> items.id';
    ELSE
        RAISE NOTICE 'Foreign key ya existe';
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 4: Verificar cambios
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_tipo TEXT;
    v_fk_exists BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICACIÓN DE CAMBIOS ===';

    -- Verificar nuevo tipo
    SELECT data_type INTO v_tipo
    FROM information_schema.columns
    WHERE table_schema = 'selemti'
      AND table_name = 'inventory_snapshot'
      AND column_name = 'item_id';

    RAISE NOTICE 'Nuevo tipo de item_id: %', v_tipo;

    -- Verificar FK
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_schema = 'selemti'
          AND table_name = 'inventory_snapshot'
          AND constraint_name = 'fk_inventory_snapshot_item'
    ) INTO v_fk_exists;

    IF v_fk_exists THEN
        RAISE NOTICE '✓ Foreign key verificada correctamente';
    ELSE
        RAISE WARNING '¡FK no encontrada!';
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 5: Recrear índices si es necesario
-- -----------------------------------------------------------------------------
-- Los índices se deben haber preservado, pero verificamos

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'selemti'
          AND tablename = 'inventory_snapshot'
          AND indexname = 'idx_invshot_item_date'
    ) THEN
        CREATE INDEX idx_invshot_item_date
        ON selemti.inventory_snapshot(item_id, snapshot_date);

        RAISE NOTICE '✓ Índice recreado: idx_invshot_item_date';
    ELSE
        RAISE NOTICE 'Índice ya existe: idx_invshot_item_date';
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 6: Resumen final
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'CORRECCIÓN DE inventory_snapshot COMPLETADA';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'Cambios aplicados:';
    RAISE NOTICE '  ✓ item_id: UUID -> VARCHAR(20)';
    RAISE NOTICE '  ✓ FK añadida: item_id -> items.id';
    RAISE NOTICE '  ✓ Índices verificados';
    RAISE NOTICE '';
    RAISE NOTICE 'SIGUIENTE PASO: Actualizar servicios que usan inventory_snapshot';
    RAISE NOTICE '=============================================================================';
END $$;
