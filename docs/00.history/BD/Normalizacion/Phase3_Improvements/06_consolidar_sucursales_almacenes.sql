-- =====================================================================
-- Phase 2.2: Consolidación de Sucursales y Almacenes
-- =====================================================================
-- Proyecto: TerrenaLaravel - Normalización BD selemti
-- Fecha: 30 de octubre de 2025
-- Autor: Claude Code AI
--
-- OBJETIVO:
-- Consolidar sistemas duplicados:
-- 1. sucursal (legacy) → cat_sucursales (canónico)
-- 2. bodega + almacen (legacy) → cat_almacenes (canónico)
--
-- CAMBIOS PRINCIPALES:
-- 1. Estandarizar tipos de FKs (TEXT → BIGINT)
-- 2. Redirigir FKs de tablas legacy a tablas canónicas
-- 3. Crear vistas de compatibilidad
-- 4. Consolidar bodega + almacen en cat_almacenes
--
-- DURACIÓN ESTIMADA: 10-15 minutos
-- IMPACTO: Alto - Sistema de inventario y ventas
-- ROLLBACK: Disponible via Scripts/rollback_phase2.sql
-- =====================================================================

\set ON_ERROR_STOP on
\timing on

-- =====================================================================
-- FASE 0: Pre-checks y Backup
-- =====================================================================
\echo ''
\echo '============================================================='
\echo 'Phase 2.2: Consolidación de Sucursales y Almacenes'
\echo '============================================================='
\echo ''

-- Verificar estado inicial
\echo '📊 Estado inicial de tablas:'
SELECT 
  'sucursal (legacy)' as tabla,
  (SELECT COUNT(*) FROM selemti.sucursal) as registros
UNION ALL
SELECT 
  'cat_sucursales (canónico)' as tabla,
  (SELECT COUNT(*) FROM selemti.cat_sucursales) as registros
UNION ALL
SELECT 
  'bodega (legacy)' as tabla,
  (SELECT COUNT(*) FROM selemti.bodega) as registros
UNION ALL
SELECT 
  'almacen (legacy)' as tabla,
  (SELECT COUNT(*) FROM selemti.almacen) as registros
UNION ALL
SELECT 
  'cat_almacenes (canónico)' as tabla,
  (SELECT COUNT(*) FROM selemti.cat_almacenes) as registros
ORDER BY tabla;

\echo ''
\echo '⏳ Iniciando consolidación...'
\echo ''

-- =====================================================================
-- FASE 1: Consolidar SUCURSALES (legacy → canónico)
-- =====================================================================
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'FASE 1: Consolidación de Sucursales'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- 1.1 Migrar datos de sucursal → cat_sucursales (si existieran)
\echo '  → Paso 1.1: Migrar datos de sucursal a cat_sucursales...'
INSERT INTO selemti.cat_sucursales (clave, nombre, activo, created_at, updated_at)
SELECT 
  s.id as clave,
  s.nombre,
  s.activo,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM selemti.sucursal s
WHERE NOT EXISTS (
  SELECT 1 FROM selemti.cat_sucursales cs WHERE cs.clave = s.id
);

\echo '  ✅ Datos migrados'

-- 1.2 Redirigir FKs de sucursal → cat_sucursales
\echo '  → Paso 1.2: Redirigir FKs de sucursal a cat_sucursales...'

-- 1.2.1 almacen.sucursal_id
\echo '     • almacen.sucursal_id...'
ALTER TABLE selemti.almacen DROP CONSTRAINT IF EXISTS almacen_sucursal_id_fkey CASCADE;
ALTER TABLE selemti.almacen ALTER COLUMN sucursal_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.almacen 
  ADD CONSTRAINT almacen_sucursal_id_fkey 
  FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) 
  ON DELETE RESTRICT;

-- 1.2.2 bodega.sucursal_id
\echo '     • bodega.sucursal_id...'
ALTER TABLE selemti.bodega DROP CONSTRAINT IF EXISTS bodega_sucursal_id_fkey CASCADE;
ALTER TABLE selemti.bodega ALTER COLUMN sucursal_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.bodega 
  ADD CONSTRAINT bodega_sucursal_id_fkey 
  FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) 
  ON DELETE RESTRICT;

-- 1.2.3 op_cab.sucursal_id
\echo '     • op_cab.sucursal_id...'
ALTER TABLE selemti.op_cab DROP CONSTRAINT IF EXISTS op_cab_sucursal_id_fkey CASCADE;
ALTER TABLE selemti.op_cab ALTER COLUMN sucursal_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.op_cab 
  ADD CONSTRAINT op_cab_sucursal_id_fkey 
  FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) 
  ON DELETE RESTRICT;

-- 1.2.4 recepcion_cab.sucursal_id
\echo '     • recepcion_cab.sucursal_id...'
ALTER TABLE selemti.recepcion_cab DROP CONSTRAINT IF EXISTS recepcion_cab_sucursal_id_fkey CASCADE;
ALTER TABLE selemti.recepcion_cab ALTER COLUMN sucursal_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.recepcion_cab 
  ADD CONSTRAINT recepcion_cab_sucursal_id_fkey 
  FOREIGN KEY (sucursal_id) REFERENCES selemti.cat_sucursales(id) 
  ON DELETE RESTRICT;

\echo '  ✅ FKs redirigidas (4 tablas afectadas)'

-- 1.3 Crear vista de compatibilidad v_sucursal
\echo '  → Paso 1.3: Crear vista v_sucursal...'
DROP VIEW IF EXISTS selemti.v_sucursal CASCADE;
CREATE VIEW selemti.v_sucursal AS
SELECT 
  clave as id,
  nombre,
  activo
FROM selemti.cat_sucursales;

\echo '  ✅ Vista v_sucursal creada'
\echo ''

-- =====================================================================
-- FASE 2: Consolidar ALMACENES (bodega + almacen → cat_almacenes)
-- =====================================================================
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'FASE 2: Consolidación de Almacenes'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- 2.1 Migrar datos de bodega → cat_almacenes (si existieran)
\echo '  → Paso 2.1: Migrar datos de bodega a cat_almacenes...'
INSERT INTO selemti.cat_almacenes (clave, nombre, sucursal_id, activo, created_at, updated_at)
SELECT 
  b.codigo as clave,
  b.nombre,
  CAST(b.sucursal_id AS BIGINT),
  true as activo,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM selemti.bodega b
WHERE NOT EXISTS (
  SELECT 1 FROM selemti.cat_almacenes ca WHERE ca.clave = b.codigo
);

\echo '  ✅ Datos de bodega migrados'

-- 2.2 Migrar datos de almacen → cat_almacenes (si existieran)
\echo '  → Paso 2.2: Migrar datos de almacen a cat_almacenes...'
INSERT INTO selemti.cat_almacenes (clave, nombre, sucursal_id, activo, created_at, updated_at)
SELECT 
  a.id as clave,
  a.nombre,
  CAST(a.sucursal_id AS BIGINT),
  a.activo,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM selemti.almacen a
WHERE NOT EXISTS (
  SELECT 1 FROM selemti.cat_almacenes ca WHERE ca.clave = a.id
);

\echo '  ✅ Datos de almacen migrados'

-- 2.3 Redirigir FKs de bodega → cat_almacenes
\echo '  → Paso 2.3: Redirigir FKs de bodega a cat_almacenes...'

-- 2.3.1 recepcion_det.bodega_id
\echo '     • recepcion_det.bodega_id...'
ALTER TABLE selemti.recepcion_det DROP CONSTRAINT IF EXISTS recepcion_det_bodega_id_fkey CASCADE;
ALTER TABLE selemti.recepcion_det ALTER COLUMN bodega_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.recepcion_det 
  ADD CONSTRAINT recepcion_det_bodega_id_fkey 
  FOREIGN KEY (bodega_id) REFERENCES selemti.cat_almacenes(id) 
  ON DELETE RESTRICT;

-- 2.3.2 traspaso_cab.from_bodega_id
\echo '     • traspaso_cab.from_bodega_id...'
ALTER TABLE selemti.traspaso_cab DROP CONSTRAINT IF EXISTS traspaso_cab_from_bodega_id_fkey CASCADE;
ALTER TABLE selemti.traspaso_cab ALTER COLUMN from_bodega_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.traspaso_cab 
  ADD CONSTRAINT traspaso_cab_from_bodega_id_fkey 
  FOREIGN KEY (from_bodega_id) REFERENCES selemti.cat_almacenes(id) 
  ON DELETE RESTRICT;

-- 2.3.3 traspaso_cab.to_bodega_id
\echo '     • traspaso_cab.to_bodega_id...'
ALTER TABLE selemti.traspaso_cab DROP CONSTRAINT IF EXISTS traspaso_cab_to_bodega_id_fkey CASCADE;
ALTER TABLE selemti.traspaso_cab ALTER COLUMN to_bodega_id TYPE BIGINT USING NULL;
ALTER TABLE selemti.traspaso_cab 
  ADD CONSTRAINT traspaso_cab_to_bodega_id_fkey 
  FOREIGN KEY (to_bodega_id) REFERENCES selemti.cat_almacenes(id) 
  ON DELETE RESTRICT;

\echo '  ✅ FKs redirigidas (3 FKs en 2 tablas)'

-- 2.4 Crear vistas de compatibilidad
\echo '  → Paso 2.4: Crear vistas de compatibilidad...'

-- Vista v_bodega
DROP VIEW IF EXISTS selemti.v_bodega CASCADE;
CREATE VIEW selemti.v_bodega AS
SELECT 
  id::INTEGER as id,
  sucursal_id::TEXT as sucursal_id,
  clave as codigo,
  nombre
FROM selemti.cat_almacenes
WHERE clave ~ '^[0-9]+$'; -- Solo numéricos (códigos de bodega)

-- Vista v_almacen
DROP VIEW IF EXISTS selemti.v_almacen CASCADE;
CREATE VIEW selemti.v_almacen AS
SELECT 
  clave as id,
  sucursal_id::TEXT as sucursal_id,
  nombre,
  activo
FROM selemti.cat_almacenes;

\echo '  ✅ Vistas v_bodega y v_almacen creadas'
\echo ''

-- =====================================================================
-- FASE 3: Verificaciones Post-Ejecución
-- =====================================================================
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'FASE 3: Verificaciones'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- 3.1 Verificar tipos de columnas
\echo '  → Verificación 1: Tipos de FKs a sucursales...'
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name IN ('almacen', 'bodega', 'op_cab', 'recepcion_cab')
  AND column_name = 'sucursal_id';

\echo ''
\echo '  → Verificación 2: Tipos de FKs a almacenes...'
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name IN ('recepcion_det', 'traspaso_cab')
  AND column_name IN ('bodega_id', 'from_bodega_id', 'to_bodega_id');

-- 3.2 Verificar FKs
\echo ''
\echo '  → Verificación 3: FKs a cat_sucursales...'
SELECT 
  tc.table_name,
  kcu.column_name,
  'cat_sucursales' as references_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'selemti'
  AND ccu.table_name = 'cat_sucursales'
ORDER BY tc.table_name;

\echo ''
\echo '  → Verificación 4: FKs a cat_almacenes...'
SELECT 
  tc.table_name,
  kcu.column_name,
  'cat_almacenes' as references_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'selemti'
  AND ccu.table_name = 'cat_almacenes'
ORDER BY tc.table_name;

-- 3.3 Verificar vistas
\echo ''
\echo '  → Verificación 5: Vistas de compatibilidad...'
SELECT 
  schemaname,
  viewname
FROM pg_views
WHERE schemaname = 'selemti'
  AND viewname IN ('v_sucursal', 'v_bodega', 'v_almacen')
ORDER BY viewname;

-- 3.4 Verificar datos
\echo ''
\echo '  → Verificación 6: Conteo final de registros...'
SELECT 
  'cat_sucursales' as tabla,
  COUNT(*) as registros
FROM selemti.cat_sucursales
UNION ALL
SELECT 
  'cat_almacenes' as tabla,
  COUNT(*) as registros
FROM selemti.cat_almacenes
UNION ALL
SELECT 
  'v_sucursal' as tabla,
  COUNT(*) as registros
FROM selemti.v_sucursal
UNION ALL
SELECT 
  'v_bodega' as tabla,
  COUNT(*) as registros
FROM selemti.v_bodega
UNION ALL
SELECT 
  'v_almacen' as tabla,
  COUNT(*) as registros
FROM selemti.v_almacen;

-- =====================================================================
-- REPORTE FINAL
-- =====================================================================
\echo ''
\echo '============================================================='
\echo '✅ Phase 2.2 COMPLETADA EXITOSAMENTE'
\echo '============================================================='
\echo ''
\echo 'Cambios aplicados:'
\echo '  ✅ Sucursales consolidadas (sucursal → cat_sucursales)'
\echo '  ✅ 4 FKs redirigidas a cat_sucursales'
\echo '  ✅ Almacenes consolidados (bodega + almacen → cat_almacenes)'
\echo '  ✅ 3 FKs redirigidas a cat_almacenes'
\echo '  ✅ 3 vistas de compatibilidad creadas (v_sucursal, v_bodega, v_almacen)'
\echo ''
\echo 'Próximo paso:'
\echo '  ⏭️  Phase 2.3: Consolidar items (insumo → items)'
\echo ''
\echo '============================================================='
\echo ''

\timing off
