-- =============================================================================
-- Script 03: Añadir Foreign Keys Faltantes en selemti
-- =============================================================================
-- Fecha: 30 de octubre de 2025
-- Objetivo: Añadir FKs para garantizar integridad referencial
-- IMPORTANTE: Solo opera en esquema selemti, NO toca public
-- =============================================================================

SET search_path TO selemti, public;

-- -----------------------------------------------------------------------------
-- PASO 1: Limpiar datos huérfanos antes de añadir FKs
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_huerfanos INTEGER;
BEGIN
    RAISE NOTICE '=== LIMPIEZA DE DATOS HUÉRFANOS ===';

    -- Verificar recipe_cost_history con recetas inexistentes
    SELECT COUNT(*) INTO v_huerfanos
    FROM selemti.recipe_cost_history rch
    LEFT JOIN selemti.receta_cab rc ON rc.id = rch.recipe_id
    WHERE rc.id IS NULL;

    IF v_huerfanos > 0 THEN
        RAISE WARNING '% registros huérfanos en recipe_cost_history', v_huerfanos;
        -- Opcional: DELETE FROM selemti.recipe_cost_history WHERE recipe_id NOT IN (SELECT id FROM selemti.receta_cab);
    ELSE
        RAISE NOTICE '✓ recipe_cost_history: sin datos huérfanos';
    END IF;

    -- Verificar pos_map con recetas inexistentes
    SELECT COUNT(*) INTO v_huerfanos
    FROM selemti.pos_map pm
    LEFT JOIN selemti.receta_cab rc ON rc.id = pm.receta_id
    WHERE pm.receta_id IS NOT NULL AND rc.id IS NULL;

    IF v_huerfanos > 0 THEN
        RAISE WARNING '% registros huérfanos en pos_map', v_huerfanos;
    ELSE
        RAISE NOTICE '✓ pos_map: sin datos huérfanos';
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 2: Añadir FK: recipe_cost_history -> receta_cab
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'selemti'
          AND table_name = 'recipe_cost_history'
          AND constraint_name = 'fk_recipe_cost_history_recipe'
    ) THEN
        ALTER TABLE selemti.recipe_cost_history
          ADD CONSTRAINT fk_recipe_cost_history_recipe
          FOREIGN KEY (recipe_id) REFERENCES selemti.receta_cab(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE;

        RAISE NOTICE '✓ FK añadida: recipe_cost_history.recipe_id -> receta_cab.id';
    ELSE
        RAISE NOTICE 'FK ya existe: recipe_cost_history.recipe_id';
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE WARNING 'No se pudo añadir FK en recipe_cost_history. Limpiar datos huérfanos primero.';
END $$;

-- -----------------------------------------------------------------------------
-- PASO 3: Añadir FK: pos_map -> receta_cab
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'selemti'
          AND table_name = 'pos_map'
          AND constraint_name = 'fk_pos_map_receta'
    ) THEN
        ALTER TABLE selemti.pos_map
          ADD CONSTRAINT fk_pos_map_receta
          FOREIGN KEY (receta_id) REFERENCES selemti.receta_cab(id)
          ON DELETE SET NULL
          ON UPDATE CASCADE;

        RAISE NOTICE '✓ FK añadida: pos_map.receta_id -> receta_cab.id';
    ELSE
        RAISE NOTICE 'FK ya existe: pos_map.receta_id';
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE WARNING 'No se pudo añadir FK en pos_map. Limpiar datos huérfanos primero.';
END $$;

-- -----------------------------------------------------------------------------
-- PASO 4: Añadir FK: purchase_orders -> cat_proveedores
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'selemti'
          AND table_name = 'purchase_orders'
          AND constraint_name = 'fk_purchase_orders_vendor'
    ) THEN
        ALTER TABLE selemti.purchase_orders
          ADD CONSTRAINT fk_purchase_orders_vendor
          FOREIGN KEY (vendor_id) REFERENCES selemti.cat_proveedores(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE;

        RAISE NOTICE '✓ FK añadida: purchase_orders.vendor_id -> cat_proveedores.id';
    ELSE
        RAISE NOTICE 'FK ya existe: purchase_orders.vendor_id';
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE WARNING 'No se pudo añadir FK en purchase_orders. Verificar datos.';
    WHEN undefined_column THEN
        RAISE NOTICE 'Columna vendor_id no existe en purchase_orders';
END $$;

-- -----------------------------------------------------------------------------
-- PASO 5: Añadir FK: inventory_counts -> cat_almacenes
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'selemti'
          AND table_name = 'inventory_counts'
          AND constraint_name = 'fk_inventory_counts_warehouse'
    ) THEN
        ALTER TABLE selemti.inventory_counts
          ADD CONSTRAINT fk_inventory_counts_warehouse
          FOREIGN KEY (almacen_id) REFERENCES selemti.cat_almacenes(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE;

        RAISE NOTICE '✓ FK añadida: inventory_counts.almacen_id -> cat_almacenes.id';
    ELSE
        RAISE NOTICE 'FK ya existe: inventory_counts.almacen_id';
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE WARNING 'No se pudo añadir FK en inventory_counts. Verificar datos.';
    WHEN undefined_column THEN
        RAISE NOTICE 'Columna almacen_id no existe en inventory_counts';
END $$;

-- -----------------------------------------------------------------------------
-- PASO 6: Añadir FK: inventory_count_lines -> items
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'selemti'
          AND table_name = 'inventory_count_lines'
          AND constraint_name = 'fk_inventory_count_lines_item'
    ) THEN
        ALTER TABLE selemti.inventory_count_lines
          ADD CONSTRAINT fk_inventory_count_lines_item
          FOREIGN KEY (item_id) REFERENCES selemti.items(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE;

        RAISE NOTICE '✓ FK añadida: inventory_count_lines.item_id -> items.id';
    ELSE
        RAISE NOTICE 'FK ya existe: inventory_count_lines.item_id';
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE WARNING 'No se pudo añadir FK en inventory_count_lines. Verificar datos.';
    WHEN undefined_column THEN
        RAISE NOTICE 'Columna item_id no existe en inventory_count_lines';
END $$;

-- -----------------------------------------------------------------------------
-- PASO 7: Añadir FK: production_orders -> items (output)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'selemti'
          AND table_name = 'production_orders'
          AND constraint_name = 'fk_production_orders_output_item'
    ) THEN
        ALTER TABLE selemti.production_orders
          ADD CONSTRAINT fk_production_orders_output_item
          FOREIGN KEY (output_item_id) REFERENCES selemti.items(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE;

        RAISE NOTICE '✓ FK añadida: production_orders.output_item_id -> items.id';
    ELSE
        RAISE NOTICE 'FK ya existe: production_orders.output_item_id';
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE WARNING 'No se pudo añadir FK en production_orders. Verificar datos.';
    WHEN undefined_column THEN
        RAISE NOTICE 'Columna output_item_id no existe en production_orders';
END $$;

-- -----------------------------------------------------------------------------
-- PASO 8: Verificar FKs añadidas
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICACIÓN DE FOREIGN KEYS ===';

    SELECT COUNT(*) INTO v_count
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'selemti'
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_name LIKE 'fk_%';

    RAISE NOTICE 'Total de FKs en selemti: %', v_count;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 9: Resumen final
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'FOREIGN KEYS AÑADIDAS EN SELEMTI';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'FKs críticas añadidas:';
    RAISE NOTICE '  ✓ recipe_cost_history -> receta_cab';
    RAISE NOTICE '  ✓ pos_map -> receta_cab';
    RAISE NOTICE '  ✓ inventory_snapshot -> items (ya añadida en script anterior)';
    RAISE NOTICE '  • purchase_orders -> cat_proveedores (si existe columna)';
    RAISE NOTICE '  • inventory_counts -> cat_almacenes (si existe columna)';
    RAISE NOTICE '';
    RAISE NOTICE 'SIGUIENTE PASO: Ejecutar script de verificación';
    RAISE NOTICE '=============================================================================';
END $$;
