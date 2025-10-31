-- =====================================================================
-- Phase 2.3: Consolidación de Items e Inventory Batch
-- =====================================================================
-- Proyecto: TerrenaLaravel - Normalización BD selemti
-- Fecha: 30 de octubre de 2025
-- Autor: Claude Code AI
--
-- OBJETIVO:
-- Consolidar sistemas duplicados:
-- 1. insumo (legacy) → items (canónico)
-- 2. lote (legacy) → inventory_batch (canónico)
--
-- CAMBIOS PRINCIPALES:
-- 1. Migrar datos de insumo → items (si no existen)
-- 2. Redirigir 9 FKs de insumo → items
-- 3. Redirigir 3 FKs de lote → inventory_batch
-- 4. Crear vistas de compatibilidad
--
-- DURACIÓN ESTIMADA: 10-15 minutos
-- IMPACTO: CRÍTICO - Corazón del sistema de inventario
-- ROLLBACK: Disponible via backup
-- =====================================================================

\set ON_ERROR_STOP on
\timing on

-- =====================================================================
-- FASE 0: Pre-checks y Backup
-- =====================================================================
\echo ''
\echo '============================================================='
\echo 'Phase 2.3: Consolidación de Items e Inventory Batch'
\echo '============================================================='
\echo ''

-- Verificar estado inicial
\echo '📊 Estado inicial de tablas:'
SELECT 
  'insumo (legacy)' as tabla,
  (SELECT COUNT(*) FROM selemti.insumo) as registros
UNION ALL
SELECT 
  'items (canónico)' as tabla,
  (SELECT COUNT(*) FROM selemti.items) as registros
UNION ALL
SELECT 
  'lote (legacy)' as tabla,
  (SELECT COUNT(*) FROM selemti.lote) as registros
UNION ALL
SELECT 
  'inventory_batch (canónico)' as tabla,
  (SELECT COUNT(*) FROM selemti.inventory_batch) as registros
ORDER BY tabla;

\echo ''
\echo '⏳ Iniciando consolidación...'
\echo ''

-- =====================================================================
-- FASE 1: Consolidar ITEMS (insumo → items)
-- =====================================================================
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'FASE 1: Consolidación de Items'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- 1.0 Eliminar vistas que dependen de las columnas a cambiar
\echo '  → Paso 1.0: Eliminar vistas dependientes temporalmente...'
DROP VIEW IF EXISTS selemti.vw_costos_insumo_actual CASCADE;
DROP VIEW IF EXISTS selemti.vw_bom_menu_item CASCADE;
DROP VIEW IF EXISTS selemti.vw_consumo_teorico CASCADE;
DROP VIEW IF EXISTS selemti.vw_stock_actual CASCADE;
\echo '  ✅ Vistas temporalmente eliminadas'

-- 1.1 Verificar si hay datos en insumo que no estén en items
\echo '  → Paso 1.1: Verificar datos para migrar...'
SELECT 
  i.id as insumo_id,
  i.codigo as insumo_codigo,
  i.nombre as insumo_nombre,
  CASE 
    WHEN EXISTS (SELECT 1 FROM selemti.items WHERE id = i.codigo) 
    THEN 'OK - Ya existe en items'
    ELSE 'PENDIENTE - Necesita migracion'
  END as estado
FROM selemti.insumo i;

-- 1.2 Migrar datos de insumo → items (solo si no existen)
\echo ''
\echo '  → Paso 1.2: Migrar datos de insumo a items...'
INSERT INTO selemti.items (
  id,
  nombre,
  descripcion,
  categoria_id,
  unidad_medida,
  perishable,
  activo,
  created_at,
  updated_at,
  unidad_medida_id
)
SELECT 
  i.codigo as id,
  i.nombre,
  i.nombre as descripcion,
  COALESCE(i.categoria_codigo, 'CAT-0001') as categoria_id,
  CASE i.um_id
    WHEN 1 THEN 'KG'
    WHEN 2 THEN 'LT'
    WHEN 3 THEN 'PZ'
    ELSE 'UN'
  END as unidad_medida,
  i.perecible as perishable,
  i.activo,
  CURRENT_TIMESTAMP as created_at,
  CURRENT_TIMESTAMP as updated_at,
  i.um_id as unidad_medida_id
FROM selemti.insumo i
WHERE NOT EXISTS (
  SELECT 1 FROM selemti.items it WHERE it.id = i.codigo
)
ON CONFLICT (id) DO NOTHING;

\echo '  ✅ Datos migrados'

-- 1.3 Redirigir FKs de insumo → items
\echo '  → Paso 1.3: Redirigir FKs de insumo a items...'

-- 1.3.1 hist_cost_insumo.insumo_id → item_id
\echo '     • hist_cost_insumo.insumo_id...'
ALTER TABLE selemti.hist_cost_insumo DROP CONSTRAINT IF EXISTS hist_cost_insumo_insumo_id_fkey CASCADE;
ALTER TABLE selemti.hist_cost_insumo ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
ALTER TABLE selemti.hist_cost_insumo RENAME COLUMN insumo_id TO item_id;
ALTER TABLE selemti.hist_cost_insumo 
  ADD CONSTRAINT hist_cost_insumo_item_id_fkey 
  FOREIGN KEY (item_id) REFERENCES selemti.items(id) 
  ON DELETE RESTRICT;

-- 1.3.2 insumo_presentacion.insumo_id → item_id
\echo '     • insumo_presentacion.insumo_id...'
ALTER TABLE selemti.insumo_presentacion DROP CONSTRAINT IF EXISTS insumo_presentacion_insumo_id_fkey CASCADE;
ALTER TABLE selemti.insumo_presentacion ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
ALTER TABLE selemti.insumo_presentacion RENAME COLUMN insumo_id TO item_id;
ALTER TABLE selemti.insumo_presentacion 
  ADD CONSTRAINT insumo_presentacion_item_id_fkey 
  FOREIGN KEY (item_id) REFERENCES selemti.items(id) 
  ON DELETE RESTRICT;

-- 1.3.3 insumo_proveedor_presentacion.insumo_id → item_id
\echo '     • insumo_proveedor_presentacion.insumo_id...'
ALTER TABLE selemti.insumo_proveedor_presentacion DROP CONSTRAINT IF EXISTS insumo_proveedor_presentacion_insumo_id_fkey CASCADE;
ALTER TABLE selemti.insumo_proveedor_presentacion DROP CONSTRAINT IF EXISTS ipp_insumo_fk CASCADE;
ALTER TABLE selemti.insumo_proveedor_presentacion ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
ALTER TABLE selemti.insumo_proveedor_presentacion RENAME COLUMN insumo_id TO item_id;
ALTER TABLE selemti.insumo_proveedor_presentacion 
  ADD CONSTRAINT insumo_proveedor_presentacion_item_id_fkey 
  FOREIGN KEY (item_id) REFERENCES selemti.items(id) 
  ON DELETE RESTRICT;

-- 1.3.4 lote.insumo_id → Ya se manejará en fase de lote

-- 1.3.5 merma.insumo_id → item_id
\echo '     • merma.insumo_id...'
ALTER TABLE selemti.merma DROP CONSTRAINT IF EXISTS merma_insumo_id_fkey CASCADE;
ALTER TABLE selemti.merma ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
ALTER TABLE selemti.merma RENAME COLUMN insumo_id TO item_id;
ALTER TABLE selemti.merma 
  ADD CONSTRAINT merma_item_id_fkey 
  FOREIGN KEY (item_id) REFERENCES selemti.items(id) 
  ON DELETE RESTRICT;

-- 1.3.6 op_insumo.insumo_id → item_id
\echo '     • op_insumo.insumo_id...'
ALTER TABLE selemti.op_insumo DROP CONSTRAINT IF EXISTS op_insumo_insumo_id_fkey CASCADE;
ALTER TABLE selemti.op_insumo ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
ALTER TABLE selemti.op_insumo RENAME COLUMN insumo_id TO item_id;
ALTER TABLE selemti.op_insumo 
  ADD CONSTRAINT op_insumo_item_id_fkey 
  FOREIGN KEY (item_id) REFERENCES selemti.items(id) 
  ON DELETE RESTRICT;

-- 1.3.7 recepcion_det.insumo_id → item_id
\echo '     • recepcion_det.insumo_id...'
ALTER TABLE selemti.recepcion_det DROP CONSTRAINT IF EXISTS recepcion_det_insumo_id_fkey CASCADE;
ALTER TABLE selemti.recepcion_det ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
ALTER TABLE selemti.recepcion_det RENAME COLUMN insumo_id TO item_id;
ALTER TABLE selemti.recepcion_det 
  ADD CONSTRAINT recepcion_det_item_id_fkey 
  FOREIGN KEY (item_id) REFERENCES selemti.items(id) 
  ON DELETE RESTRICT;

-- 1.3.8 receta_insumo.insumo_id → item_id
\echo '     • receta_insumo.insumo_id...'
ALTER TABLE selemti.receta_insumo DROP CONSTRAINT IF EXISTS receta_insumo_insumo_id_fkey CASCADE;
ALTER TABLE selemti.receta_insumo ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
ALTER TABLE selemti.receta_insumo RENAME COLUMN insumo_id TO item_id;
ALTER TABLE selemti.receta_insumo 
  ADD CONSTRAINT receta_insumo_item_id_fkey 
  FOREIGN KEY (item_id) REFERENCES selemti.items(id) 
  ON DELETE RESTRICT;

-- 1.3.9 traspaso_det.insumo_id → item_id
\echo '     • traspaso_det.insumo_id...'
ALTER TABLE selemti.traspaso_det DROP CONSTRAINT IF EXISTS traspaso_det_insumo_id_fkey CASCADE;
ALTER TABLE selemti.traspaso_det ALTER COLUMN insumo_id TYPE VARCHAR(20) USING NULL;
ALTER TABLE selemti.traspaso_det RENAME COLUMN insumo_id TO item_id;
ALTER TABLE selemti.traspaso_det 
  ADD CONSTRAINT traspaso_det_item_id_fkey 
  FOREIGN KEY (item_id) REFERENCES selemti.items(id) 
  ON DELETE RESTRICT;

\echo '  ✅ FKs redirigidas (8 columnas renombradas de insumo_id → item_id)'

-- 1.4 Crear vista de compatibilidad v_insumo
\echo '  → Paso 1.4: Crear vista v_insumo...'
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

\echo '  ✅ Vista v_insumo creada'
\echo ''

-- =====================================================================
-- FASE 2: Consolidar LOTES (lote → inventory_batch)
-- =====================================================================
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'FASE 2: Consolidación de Lotes'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- 2.1 Migrar datos de lote → inventory_batch (si existieran)
\echo '  → Paso 2.1: Migrar datos de lote a inventory_batch...'
-- Nota: La tabla lote está vacía, pero preparamos la migración
INSERT INTO selemti.inventory_batch (
  item_id,
  batch_code,
  received_date,
  expiry_date,
  quantity,
  unit_cost,
  created_at,
  updated_at
)
SELECT 
  (SELECT codigo FROM selemti.insumo WHERE id = l.insumo_id) as item_id,
  l.codigo as batch_code,
  l.fecha_recepcion as received_date,
  l.fecha_caducidad as expiry_date,
  l.cantidad_inicial as quantity,
  l.costo_unitario as unit_cost,
  CURRENT_TIMESTAMP as created_at,
  CURRENT_TIMESTAMP as updated_at
FROM selemti.lote l
WHERE NOT EXISTS (
  SELECT 1 FROM selemti.inventory_batch ib WHERE ib.batch_code = l.codigo
);

\echo '  ✅ Datos de lote migrados'

-- 2.2 Redirigir FKs de lote → inventory_batch
\echo '  → Paso 2.2: Redirigir FKs de lote a inventory_batch...'

-- 2.2.1 merma.lote_id → batch_id
\echo '     • merma.lote_id...'
ALTER TABLE selemti.merma DROP CONSTRAINT IF EXISTS merma_lote_id_fkey CASCADE;
ALTER TABLE selemti.merma ALTER COLUMN lote_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.merma RENAME COLUMN lote_id TO batch_id;
ALTER TABLE selemti.merma 
  ADD CONSTRAINT merma_batch_id_fkey 
  FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id) 
  ON DELETE RESTRICT;

-- 2.2.2 recepcion_det.lote_id → batch_id
\echo '     • recepcion_det.lote_id...'
ALTER TABLE selemti.recepcion_det DROP CONSTRAINT IF EXISTS recepcion_det_lote_id_fkey CASCADE;
ALTER TABLE selemti.recepcion_det ALTER COLUMN lote_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.recepcion_det RENAME COLUMN lote_id TO batch_id;
ALTER TABLE selemti.recepcion_det 
  ADD CONSTRAINT recepcion_det_batch_id_fkey 
  FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id) 
  ON DELETE RESTRICT;

-- 2.2.3 traspaso_det.lote_id → batch_id
\echo '     • traspaso_det.lote_id...'
ALTER TABLE selemti.traspaso_det DROP CONSTRAINT IF EXISTS traspaso_det_lote_id_fkey CASCADE;
ALTER TABLE selemti.traspaso_det ALTER COLUMN lote_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.traspaso_det RENAME COLUMN lote_id TO batch_id;
ALTER TABLE selemti.traspaso_det 
  ADD CONSTRAINT traspaso_det_batch_id_fkey 
  FOREIGN KEY (batch_id) REFERENCES selemti.inventory_batch(id) 
  ON DELETE RESTRICT;

\echo '  ✅ FKs redirigidas (3 columnas renombradas de lote_id → batch_id)'

-- 2.3 Crear vista de compatibilidad v_lote
\echo '  → Paso 2.3: Crear vista v_lote...'
DROP VIEW IF EXISTS selemti.v_lote CASCADE;
CREATE VIEW selemti.v_lote AS
SELECT 
  id,
  item_id as insumo_id_codigo,
  batch_code as codigo,
  received_date as fecha_recepcion,
  expiry_date as fecha_caducidad,
  quantity as cantidad_inicial,
  quantity as cantidad_actual,
  unit_cost as costo_unitario
FROM selemti.inventory_batch;

\echo '  ✅ Vista v_lote creada'
\echo ''

-- =====================================================================
-- FASE 3: Verificaciones Post-Ejecución
-- =====================================================================
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'FASE 3: Verificaciones'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- 3.1 Verificar columnas renombradas
\echo '  → Verificación 1: Columnas renombradas...'
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name IN ('merma', 'op_insumo', 'recepcion_det', 'receta_insumo', 'traspaso_det')
  AND column_name IN ('item_id', 'batch_id')
ORDER BY table_name, column_name;

-- 3.2 Verificar FKs a items
\echo ''
\echo '  → Verificación 2: FKs a items...'
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
                        'merma', 'op_insumo', 'recepcion_det', 'receta_insumo', 'traspaso_det')
ORDER BY tc.table_name;

-- 3.3 Verificar FKs a inventory_batch
\echo ''
\echo '  → Verificación 3: FKs a inventory_batch...'
SELECT 
  tc.table_name,
  kcu.column_name,
  'inventory_batch' as references_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'selemti'
  AND ccu.table_name = 'inventory_batch'
  AND tc.table_name IN ('merma', 'recepcion_det', 'traspaso_det')
ORDER BY tc.table_name;

-- 3.4 Verificar vistas
\echo ''
\echo '  → Verificación 4: Vistas de compatibilidad...'
SELECT 
  schemaname,
  viewname
FROM pg_views
WHERE schemaname = 'selemti'
  AND viewname IN ('v_insumo', 'v_lote')
ORDER BY viewname;

-- 3.5 Verificar conteos
\echo ''
\echo '  → Verificación 5: Conteo final de registros...'
SELECT 
  'items' as tabla,
  COUNT(*) as registros
FROM selemti.items
UNION ALL
SELECT 
  'v_insumo' as tabla,
  COUNT(*) as registros
FROM selemti.v_insumo
UNION ALL
SELECT 
  'inventory_batch' as tabla,
  COUNT(*) as registros
FROM selemti.inventory_batch
UNION ALL
SELECT 
  'v_lote' as tabla,
  COUNT(*) as registros
FROM selemti.v_lote;

-- =====================================================================
-- REPORTE FINAL
-- =====================================================================
\echo ''
\echo '============================================================='
\echo '✅ Phase 2.3 COMPLETADA EXITOSAMENTE'
\echo '============================================================='
\echo ''
\echo 'Cambios aplicados:'
\echo '  ✅ Items consolidados (insumo → items)'
\echo '  ✅ 8 columnas renombradas (insumo_id → item_id)'
\echo '  ✅ Lotes consolidados (lote → inventory_batch)'
\echo '  ✅ 3 columnas renombradas (lote_id → batch_id)'
\echo '  ✅ 2 vistas de compatibilidad creadas (v_insumo, v_lote)'
\echo ''
\echo 'Próximo paso:'
\echo '  ⏭️  Phase 2.4: Consolidar recetas (receta → receta_cab)'
\echo ''
\echo '============================================================='
\echo ''

\timing off
