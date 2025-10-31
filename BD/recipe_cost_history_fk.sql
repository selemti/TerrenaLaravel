-- Script para asegurar FK en recipe_cost_history tras conversión de tipo de dato
-- Fecha: jueves, 30 de octubre de 2025

-- En el script anterior, se cambió recipe_cost_history.recipe_id de bigint a character varying(20)
-- Ahora aplicamos la FK que referencia a receta_cab.id

-- Primero, verificamos que todos los recipe_id existan en receta_cab antes de aplicar la FK
/*
SELECT DISTINCT rc.recipe_id
FROM recipe_cost_history rc
LEFT JOIN receta_cab rcab ON rc.recipe_id = rcab.id
WHERE rcab.id IS NULL AND rc.recipe_id IS NOT NULL;
*/

-- Si no hay recipes huérfanos, aplicamos la constraint
-- Aseguramos que la FK se aplique después de la conversión de tipo

-- Aplicamos la FK a recipe_cost_history.recipe_id → receta_cab.id
ALTER TABLE recipe_cost_history 
ADD CONSTRAINT fk_recipe_cost_history_recipe 
FOREIGN KEY (recipe_id) REFERENCES receta_cab(id);

-- Creamos el índice para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_recipe_cost_history_recipe_id ON recipe_cost_history (recipe_id);

-- Validamos la integridad referencial después de aplicar la FK
-- Esta consulta debe devolver 0 filas si todo está correcto
/*
SELECT COUNT(*) as orphans
FROM recipe_cost_history rc
LEFT JOIN receta_cab r ON rc.recipe_id = r.id
WHERE rc.recipe_id IS NOT NULL AND r.id IS NULL;
*/

-- Creamos una vista de compatibilidad para aplicaciones que esperaban el valor antiguo
CREATE OR REPLACE VIEW v_recipe_cost_history_compat AS
SELECT 
    rch.id,
    rch.recipe_id,
    rch.recipe_version_id,
    rch.snapshot_at,
    rch.currency_code,
    rch.batch_cost,
    rch.portion_cost,
    rch.batch_size,
    rch.yield_portions,
    rch.notes,
    rch.created_at,
    rc.nombre_plato AS recipe_nombre  -- Incluimos nombre para compatibilidad
FROM recipe_cost_history rch
LEFT JOIN receta_cab rc ON rch.recipe_id = rc.id;

-- Fin del script para asegurar FK en recipe_cost_history