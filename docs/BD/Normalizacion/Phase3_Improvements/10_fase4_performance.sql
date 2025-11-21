-- =====================================================================
-- FASE 4: Optimización de Performance
-- =====================================================================
-- Optimiza índices y actualiza estadísticas para mejor performance
-- =====================================================================

\set ON_ERROR_STOP on
\timing on

\echo ''
\echo '============================================================='
\echo 'FASE 4: Optimización de Performance'
\echo '============================================================='
\echo ''

-- =====================================================================
-- 4.1: Crear índices en columnas FK que no los tienen
-- =====================================================================
\echo 'Creando índices en Foreign Keys...'

-- Índices en tablas principales
CREATE INDEX IF NOT EXISTS idx_merma_item_id ON selemti.merma(item_id);
CREATE INDEX IF NOT EXISTS idx_merma_batch_id ON selemti.merma(batch_id);
CREATE INDEX IF NOT EXISTS idx_merma_usuario_id ON selemti.merma(usuario_id);

CREATE INDEX IF NOT EXISTS idx_op_insumo_item_id ON selemti.op_insumo(item_id);
CREATE INDEX IF NOT EXISTS idx_op_insumo_batch_id ON selemti.op_insumo(batch_id);

CREATE INDEX IF NOT EXISTS idx_recepcion_det_item_id ON selemti.recepcion_det(item_id);
CREATE INDEX IF NOT EXISTS idx_recepcion_det_batch_id ON selemti.recepcion_det(batch_id);
CREATE INDEX IF NOT EXISTS idx_recepcion_det_bodega_id ON selemti.recepcion_det(bodega_id);

CREATE INDEX IF NOT EXISTS idx_traspaso_det_item_id ON selemti.traspaso_det(item_id);
CREATE INDEX IF NOT EXISTS idx_traspaso_det_batch_id ON selemti.traspaso_det(batch_id);

CREATE INDEX IF NOT EXISTS idx_receta_insumo_item_id ON selemti.receta_insumo(item_id);
CREATE INDEX IF NOT EXISTS idx_receta_insumo_receta_version_id ON selemti.receta_insumo(receta_version_id);

-- Índices en tablas de catálogos
CREATE INDEX IF NOT EXISTS idx_items_categoria_id ON selemti.items(categoria_id);
CREATE INDEX IF NOT EXISTS idx_items_unidad_medida_id ON selemti.items(unidad_medida_id);
CREATE INDEX IF NOT EXISTS idx_items_activo ON selemti.items(activo) WHERE activo = true;

CREATE INDEX IF NOT EXISTS idx_receta_cab_activo ON selemti.receta_cab(activo) WHERE activo = true;
CREATE INDEX IF NOT EXISTS idx_receta_cab_categoria_plato ON selemti.receta_cab(categoria_plato);

-- Índices en tablas de movimientos
CREATE INDEX IF NOT EXISTS idx_mov_inv_item_id ON selemti.mov_inv(item_id);
CREATE INDEX IF NOT EXISTS idx_mov_inv_fecha ON selemti.mov_inv(fecha);
CREATE INDEX IF NOT EXISTS idx_mov_inv_tipo ON selemti.mov_inv(tipo_movimiento);

CREATE INDEX IF NOT EXISTS idx_inventory_batch_item_id ON selemti.inventory_batch(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_batch_estado ON selemti.inventory_batch(estado);

-- =====================================================================
-- 4.2: Índices compuestos para queries comunes
-- =====================================================================
\echo ''
\echo 'Creando índices compuestos...'

-- Para búsquedas de inventario activo por sucursal
CREATE INDEX IF NOT EXISTS idx_items_activo_categoria ON selemti.items(activo, categoria_id) WHERE activo = true;

-- Para queries de recetas activas
CREATE INDEX IF NOT EXISTS idx_receta_cab_activo_categoria ON selemti.receta_cab(activo, categoria_plato) WHERE activo = true;

-- Para movimientos por fecha y tipo
CREATE INDEX IF NOT EXISTS idx_mov_inv_fecha_tipo ON selemti.mov_inv(fecha, tipo_movimiento);

-- Para búsquedas de lotes por item y estado
CREATE INDEX IF NOT EXISTS idx_inventory_batch_item_estado ON selemti.inventory_batch(item_id, estado);

-- =====================================================================
-- 4.3: Índices para búsquedas de texto
-- =====================================================================
\echo ''
\echo 'Creando índices para búsquedas...'

-- Índices para búsquedas por nombre/código
CREATE INDEX IF NOT EXISTS idx_items_nombre_lower ON selemti.items(LOWER(nombre));
CREATE INDEX IF NOT EXISTS idx_receta_cab_nombre_lower ON selemti.receta_cab(LOWER(nombre_plato));

-- =====================================================================
-- 4.4: Actualizar estadísticas de todas las tablas
-- =====================================================================
\echo ''
\echo 'Actualizando estadísticas...'

ANALYZE selemti.users;
ANALYZE selemti.roles;
ANALYZE selemti.cat_sucursales;
ANALYZE selemti.cat_almacenes;
ANALYZE selemti.items;
ANALYZE selemti.inventory_batch;
ANALYZE selemti.receta_cab;
ANALYZE selemti.receta_det;
ANALYZE selemti.mov_inv;
ANALYZE selemti.merma;
ANALYZE selemti.op_cab;
ANALYZE selemti.op_insumo;
ANALYZE selemti.recepcion_cab;
ANALYZE selemti.recepcion_det;
ANALYZE selemti.traspaso_cab;
ANALYZE selemti.traspaso_det;

-- =====================================================================
-- 4.5: Verificar índices creados
-- =====================================================================
\echo ''
\echo 'Verificando índices creados...'

SELECT 
    'Índices en items' as tabla,
    COUNT(*) as total_indices
FROM pg_indexes
WHERE schemaname = 'selemti' AND tablename = 'items'
UNION ALL
SELECT 
    'Índices en receta_cab',
    COUNT(*)
FROM pg_indexes
WHERE schemaname = 'selemti' AND tablename = 'receta_cab'
UNION ALL
SELECT 
    'Índices en mov_inv',
    COUNT(*)
FROM pg_indexes
WHERE schemaname = 'selemti' AND tablename = 'mov_inv'
UNION ALL
SELECT 
    'Índices en inventory_batch',
    COUNT(*)
FROM pg_indexes
WHERE schemaname = 'selemti' AND tablename = 'inventory_batch';

\echo ''
\echo '============================================================='
\echo 'FASE 4 COMPLETADA'
\echo '============================================================='
\echo ''

\timing off
