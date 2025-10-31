-- Script para actualizar índices para joins de alto tráfico
-- Fecha: jueves, 30 de octubre de 2025

-- Índices para las tablas con joins más comunes y consultas frecuentes

-- 1. índice en mov_inv para búsquedas por item_id, tipo y fechas
CREATE INDEX IF NOT EXISTS idx_mov_inv_composite ON mov_inv (item_id, tipo, created_at);
-- Este índice es útil para la mayoría de consultas de kardex e inventario

-- 2. índice en mov_inv para consultas por sucursal y fecha
CREATE INDEX IF NOT EXISTS idx_mov_inv_sucursal_fecha ON mov_inv (sucursal_id, created_at);
-- Útil para reportes por sucursal

-- 3. índice en mov_inv para consultas de movimientos específicos por tipo
CREATE INDEX IF NOT EXISTS idx_mov_inv_tipo_fecha ON mov_inv (tipo, created_at);
-- Útil para auditorías y reportes de movimientos

-- 4. índices en inventory_snapshot para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_composite ON inventory_snapshot (item_id, branch_id, snapshot_date);
-- Combinación más común en consultas de snapshot

-- 5. índice en inventory_snapshot para búsquedas solo por fecha
CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_fecha ON inventory_snapshot (snapshot_date);
-- Para consultas que buscan snapshots de una fecha específica

-- 6. índices en receta_det para joins frecuentes
CREATE INDEX IF NOT EXISTS idx_receta_det_item_version ON receta_det (item_id, receta_version_id);
-- Para cálculos de recetas que necesitan relacionar items con versiones

-- 7. índice en receta_det para consultas por receta_version_id
CREATE INDEX IF NOT EXISTS idx_receta_det_receta_version ON receta_det (receta_version_id);
-- Para cálculos de costos por receta

-- 8. índices en pos_map para búsquedas frecuentes
CREATE INDEX IF NOT EXISTS idx_pos_map_composite ON pos_map (tipo, plu, valid_from, valid_to);
-- Combinación común en consultas de mapeo POS

-- 9. índice en pos_map para búsquedas por receta_id (importante para cálculos de costos)
CREATE INDEX IF NOT EXISTS idx_pos_map_receta_id ON pos_map (receta_id);
-- Crítico para consultas que van de receta a mapeo POS

-- 10. índices en items para búsquedas frecuentes
CREATE INDEX IF NOT EXISTS idx_items_categoria_tipo ON items (categoria_id, tipo);
-- Combinación común en búsquedas de insumos

-- 11. índice en items para búsquedas por tipo
CREATE INDEX IF NOT EXISTS idx_items_tipo ON items (tipo);
-- Para consultas que filtran por tipo de producto

-- 12. índices en inventory_count_lines para consultas por conteo
CREATE INDEX IF NOT EXISTS idx_inventory_count_lines_count ON inventory_count_lines (inventory_count_id);
-- Para acceso rápido a líneas de conteo

-- 13. índices en recipe_cost_history para búsquedas por receta y fecha
CREATE INDEX IF NOT EXISTS idx_recipe_cost_history_recipe_date ON recipe_cost_history (recipe_id, snapshot_at);
-- Para consultas de historia de costos por receta

-- 14. índice en recipe_cost_history para búsquedas solo por fecha
CREATE INDEX IF NOT EXISTS idx_recipe_cost_history_date ON recipe_cost_history (snapshot_at);
-- Para consultas de costos históricos

-- Estadísticas para el query planner
-- Estas no son índices, pero ayudan al rendimiento de las consultas
ANALYZE mov_inv;
ANALYZE inventory_snapshot;
ANALYZE receta_det;
ANALYZE pos_map;
ANALYZE items;

-- Índices compuestos para consultas de alto rendimiento
-- Estos índices están diseñados según las consultas típicas del sistema

-- Consultas de consumo teórico por item y fecha
-- Usado en cálculo de consumos POS
CREATE INDEX IF NOT EXISTS idx_mov_inv_item_fecha_tipo ON mov_inv (item_id, created_at, tipo);

-- Consultas para verificación de snapshots
-- Usado en auditoría de inventarios
CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_branch_item ON inventory_snapshot (branch_id, item_id);

-- Consultas para mapeos vigentes
-- Usado en cálculo de costos y consumos POS
CREATE INDEX IF NOT EXISTS idx_pos_map_plu_vigente ON pos_map (plu, valid_from, valid_to) 
WHERE valid_to IS NULL OR valid_to >= CURRENT_DATE;

-- Validamos el rendimiento de índices críticos
-- Estas consultas pueden usarse como referencia para pruebas de rendimiento
/*
EXPLAIN ANALYZE SELECT * FROM mov_inv 
WHERE item_id = 'ITEM001' AND tipo = 'CONSUMO_OP' AND created_at >= '2025-01-01'
LIMIT 100;

EXPLAIN ANALYZE SELECT * FROM inventory_snapshot 
WHERE item_id = 'ITEM001' AND branch_id = '1' AND snapshot_date = '2025-10-29';

EXPLAIN ANALYZE SELECT * FROM pos_map 
WHERE receta_id = 'REC001' AND valid_from <= '2025-10-29' 
AND (valid_to IS NULL OR valid_to >= '2025-10-29');
*/

-- Fin del script de actualización de índices