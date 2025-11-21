-- =====================================================================
-- Phase 2.3: Consolidación de Items (Versión Simplificada)
-- =====================================================================
-- Este script detecta automáticamente qué columnas ya fueron renombradas
-- y solo hace los cambios necesarios
-- =====================================================================

\set ON_ERROR_STOP on
\timing on

\echo ''
\echo '============================================================='
\echo 'Phase 2.3: Consolidación de Items (Simplificada)'
\echo '============================================================='
\echo ''

-- Eliminar vistas dependientes
\echo 'Eliminando vistas dependientes...'
DROP VIEW IF EXISTS selemti.vw_stock_valorizado CASCADE;
DROP VIEW IF EXISTS selemti.vw_costos_insumo_actual CASCADE;
DROP VIEW IF EXISTS selemti.vw_bom_menu_item CASCADE;
DROP VIEW IF EXISTS selemti.vw_consumo_teorico CASCADE;
DROP VIEW IF EXISTS selemti.vw_stock_actual CASCADE;
DROP VIEW IF EXISTS selemti.vw_consumo_vs_movimientos CASCADE;
DROP VIEW IF EXISTS selemti.vw_stock_brechas CASCADE;
DROP VIEW IF EXISTS selemti.vw_receta_completa CASCADE;

\echo 'Consolidando items...'

-- Hacer los cambios solo si la columna existe
DO $$
DECLARE
    r RECORD;
BEGIN
    -- hist_cost_insumo
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='hist_cost_insumo' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.hist_cost_insumo DROP CONSTRAINT IF EXISTS hist_cost_insumo_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.hist_cost_insumo ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.hist_cost_insumo RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.hist_cost_insumo ADD CONSTRAINT hist_cost_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'hist_cost_insumo.insumo_id → item_id ✓';
    END IF;
    
    -- insumo_presentacion
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='insumo_presentacion' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.insumo_presentacion DROP CONSTRAINT IF EXISTS insumo_presentacion_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.insumo_presentacion ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.insumo_presentacion RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.insumo_presentacion ADD CONSTRAINT insumo_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'insumo_presentacion.insumo_id → item_id ✓';
    END IF;
    
    -- insumo_proveedor_presentacion
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='insumo_proveedor_presentacion' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.insumo_proveedor_presentacion DROP CONSTRAINT IF EXISTS insumo_proveedor_presentacion_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.insumo_proveedor_presentacion DROP CONSTRAINT IF EXISTS ipp_insumo_fk CASCADE;
        ALTER TABLE selemti.insumo_proveedor_presentacion ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.insumo_proveedor_presentacion RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.insumo_proveedor_presentacion ADD CONSTRAINT insumo_proveedor_presentacion_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'insumo_proveedor_presentacion.insumo_id → item_id ✓';
    END IF;
    
    -- merma.insumo_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='merma' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.merma DROP CONSTRAINT IF EXISTS merma_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.merma ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.merma RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.merma ADD CONSTRAINT merma_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'merma.insumo_id → item_id ✓';
    END IF;
    
    -- op_insumo
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='op_insumo' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.op_insumo DROP CONSTRAINT IF EXISTS op_insumo_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.op_insumo ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.op_insumo RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.op_insumo ADD CONSTRAINT op_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'op_insumo.insumo_id → item_id ✓';
    END IF;
    
    -- recepcion_det.insumo_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='recepcion_det' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.recepcion_det DROP CONSTRAINT IF EXISTS recepcion_det_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.recepcion_det ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.recepcion_det RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.recepcion_det ADD CONSTRAINT recepcion_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'recepcion_det.insumo_id → item_id ✓';
    END IF;
    
    -- receta_insumo
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='receta_insumo' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.receta_insumo DROP CONSTRAINT IF EXISTS receta_insumo_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.receta_insumo ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.receta_insumo RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.receta_insumo ADD CONSTRAINT receta_insumo_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'receta_insumo.insumo_id → item_id ✓';
    END IF;
    
    -- traspaso_det.insumo_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='traspaso_det' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.traspaso_det DROP CONSTRAINT IF EXISTS traspaso_det_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.traspaso_det ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.traspaso_det RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.traspaso_det ADD CONSTRAINT traspaso_det_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'traspaso_det.insumo_id → item_id ✓';
    END IF;
    
    -- lote.insumo_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='lote' AND column_name='insumo_id') THEN
        ALTER TABLE selemti.lote DROP CONSTRAINT IF EXISTS lote_insumo_id_fkey CASCADE;
        ALTER TABLE selemti.lote ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
        ALTER TABLE selemti.lote RENAME COLUMN insumo_id TO item_id;
        ALTER TABLE selemti.lote ADD CONSTRAINT lote_item_id_fkey FOREIGN KEY (item_id) REFERENCES selemti.items(id);
        RAISE NOTICE 'lote.insumo_id → item_id ✓';
    END IF;
    
    -- merma.lote_id → batch_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='merma' AND column_name='lote_id') THEN
        ALTER TABLE selemti.merma DROP CONSTRAINT IF EXISTS merma_lote_id_fkey CASCADE;
        ALTER TABLE selemti.merma ALTER COLUMN lote_id TYPE BIGINT USING NULL;
        ALTER TABLE selemti.merma RENAME COLUMN lote_id TO batch_id;
        ALTER TABLE selemti.merma ADD CONSTRAINT merma_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);
        RAISE NOTICE 'merma.lote_id → batch_id ✓';
    END IF;
    
    -- recepcion_det.lote_id → batch_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='recepcion_det' AND column_name='lote_id') THEN
        ALTER TABLE selemti.recepcion_det DROP CONSTRAINT IF EXISTS recepcion_det_lote_id_fkey CASCADE;
        ALTER TABLE selemti.recepcion_det ALTER COLUMN lote_id TYPE BIGINT USING NULL;
        ALTER TABLE selemti.recepcion_det RENAME COLUMN lote_id TO batch_id;
        ALTER TABLE selemti.recepcion_det ADD CONSTRAINT recepcion_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);
        RAISE NOTICE 'recepcion_det.lote_id → batch_id ✓';
    END IF;
    
    -- traspaso_det.lote_id → batch_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='traspaso_det' AND column_name='lote_id') THEN
        ALTER TABLE selemti.traspaso_det DROP CONSTRAINT IF EXISTS traspaso_det_lote_id_fkey CASCADE;
        ALTER TABLE selemti.traspaso_det ALTER COLUMN lote_id TYPE BIGINT USING NULL;
        ALTER TABLE selemti.traspaso_det RENAME COLUMN lote_id TO batch_id;
        ALTER TABLE selemti.traspaso_det ADD CONSTRAINT traspaso_det_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);
        RAISE NOTICE 'traspaso_det.lote_id → batch_id ✓';
    END IF;
    
    -- op_insumo.lote_id → batch_id (si existe)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='op_insumo' AND column_name='lote_id') THEN
        ALTER TABLE selemti.op_insumo DROP CONSTRAINT IF EXISTS op_insumo_lote_id_fkey CASCADE;
        ALTER TABLE selemti.op_insumo ALTER COLUMN lote_id TYPE BIGINT USING NULL;
        ALTER TABLE selemti.op_insumo RENAME COLUMN lote_id TO batch_id;
        ALTER TABLE selemti.op_insumo ADD CONSTRAINT op_insumo_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id);
        RAISE NOTICE 'op_insumo.lote_id → batch_id ✓';
    END IF;
END $$;

-- Crear vistas de compatibilidad
\echo 'Creando vistas de compatibilidad...'
DROP VIEW IF EXISTS selemti.v_insumo CASCADE;
CREATE VIEW selemti.v_insumo AS
SELECT 
  CAST(ROW_NUMBER() OVER (ORDER BY id) AS BIGINT) as id,
  id as codigo,
  nombre,
  unidad_medida_id as um_id,
  perishable as perecible,
  0.00 as merma_pct,
  activo,
  NULL::jsonb as meta,
  categoria_id as categoria_codigo,
  NULL as subcategoria_codigo,
  CAST(SUBSTRING(id FROM '[0-9]+$') AS INTEGER) as consecutivo,
  id as sku
FROM selemti.items;

DROP VIEW IF EXISTS selemti.v_lote CASCADE;
CREATE VIEW selemti.v_lote AS
SELECT 
  id,
  item_id as insumo_id_codigo,
  lote_proveedor as codigo,
  fecha_recepcion,
  fecha_caducidad,
  cantidad_original as cantidad_inicial,
  cantidad_actual,
  unit_cost as costo_unitario
FROM selemti.inventory_batch;

\echo ''
\echo '============================================================='
\echo 'Phase 2.3 COMPLETADA'
\echo '============================================================='
\echo ''

-- Verificar resultado
SELECT 
  tc.table_name,
  kcu.column_name,
  'items' as references_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'selemti'
  AND ccu.table_name = 'items'
  AND tc.table_name IN ('hist_cost_insumo', 'insumo_presentacion', 'insumo_proveedor_presentacion', 
                        'merma', 'op_insumo', 'recepcion_det', 'receta_insumo', 'traspaso_det', 'lote')
ORDER BY tc.table_name;

\timing off
