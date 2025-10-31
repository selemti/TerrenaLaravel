-- Script para manejar inventory_snapshot.item_id con vista o migración atómica
-- Fecha: jueves, 30 de octubre de 2025

-- Dada la cantidad potencial de datos históricos en inventory_snapshot,
-- evaluamos dos enfoques: vista de compatibilidad o migración atómica

-- OPCIÓN A: Vista de compatibilidad (recomendada para tablas grandes)
-- Esta vista permite consultas con ambos formatos sin reescribir datos
CREATE OR REPLACE VIEW v_inventory_snapshot_compat AS
SELECT 
    snapshot_date,
    branch_id,
    -- Intentamos convertir el UUID a VARCHAR(20) si es posible
    -- En PostgreSQL, los UUID ya no se representan como UUID en la tabla optimizada
    -- ya que se cambió a VARCHAR(20), pero mantenemos esta vista para consistencia
    item_id::character varying(20) AS item_id,
    teorico_qty,
    fisico_qty,
    teorico_cost,
    valor_teorico,
    variance_qty,
    variance_cost,
    created_at,
    updated_at
FROM inventory_snapshot;

-- OPCIÓN B: Migración atómica (si la tabla no es demasiado grande)
-- Solo se aplica si se determina que la tabla no es demasiado grande

-- Validamos que todos los item_id en inventory_snapshot existen en items
-- antes de aplicar la FK
/*
SELECT COUNT(*) as orphans
FROM inventory_snapshot s
LEFT JOIN items i ON s.item_id = i.id
WHERE s.item_id IS NOT NULL AND i.id IS NULL;
*/

-- Aplicamos la FK para asegurar integridad referencial
ALTER TABLE inventory_snapshot 
ADD CONSTRAINT fk_inventory_snapshot_item 
FOREIGN KEY (item_id) REFERENCES items(id);

-- Creamos índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_item_date ON inventory_snapshot (item_id, snapshot_date);
CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_branch_date ON inventory_snapshot (branch_id, snapshot_date);
CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_item_id ON inventory_snapshot (item_id);

-- Validamos datos antes y después de la migración
-- (Las siguientes consultas pueden usarse para verificar la integridad)

-- Conteo antes/después
/*
SELECT 'Antes' as momento, COUNT(*) as conteo FROM inventory_snapshot_old
UNION
SELECT 'Después' as momento, COUNT(*) as conteo FROM inventory_snapshot;
*/

-- Consulta de verificación de integridad
/*
SELECT s.snapshot_date, s.branch_id, s.item_id, i.nombre
FROM inventory_snapshot s
LEFT JOIN items i ON s.item_id = i.id
WHERE i.id IS NULL AND s.item_id IS NOT NULL;
*/

-- OPCIÓN C: Procedimiento para migración gradual (en caso de tablas muy grandes)
-- Este procedimiento migraría en bloques pequeños para no bloquear el sistema
/*
CREATE OR REPLACE PROCEDURE migrar_inventory_snapshot_gradual(limite integer DEFAULT 10000)
LANGUAGE plpgsql
AS $$
DECLARE
    total_migrado integer := 0;
BEGIN
    LOOP
        -- Actualizar un bloque de registros 
        -- (adaptar según estructura real)
        UPDATE inventory_snapshot 
        SET item_id = item_id::text  -- conversión necesaria
        WHERE id IN (
            SELECT id FROM inventory_snapshot 
            WHERE item_id IS NOT NULL AND LENGTH(item_id::text) != 22  -- Condición de conversión
            LIMIT limite
        );
        
        GET DIAGNOSTICS total_migrado = ROW_COUNT;
        
        EXIT WHEN total_migrado = 0;
        
        -- Pausa para no bloquear el sistema
        PERFORM pg_sleep(0.1);
    END LOOP;
END;
$$;
*/

-- Fin del script para manejo atómico de inventory_snapshot