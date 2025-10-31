-- Script para actualizar constraints y checks para mejorar integridad referencial
-- Fecha: jueves, 30 de octubre de 2025

-- 1. Mejoramos los constraints en la tabla items
-- Aseguramos referencias adecuadas y validaciones más estrictas

-- Ya tenemos la tabla items optimizada, ahora agregamos constraints apropiados
ALTER TABLE items 
ADD CONSTRAINT fk_items_unidad_medida 
FOREIGN KEY (unidad_medida_id) REFERENCES cat_unidades(id);

ALTER TABLE items 
ADD CONSTRAINT fk_items_categoria 
FOREIGN KEY (categoria_id) REFERENCES item_categories(id);  -- Asumiendo que existe item_categories

-- Si la tabla item_categories no existe, podríamos crearla:
/*
CREATE TABLE IF NOT EXISTS item_categories (
    id bigint PRIMARY KEY,
    nombre character varying(50) NOT NULL,
    prefijo character varying(10) NOT NULL,  -- El prefijo 'CAT' que se usa en categoria_id
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);
*/

-- 2. Agregamos constraints a la tabla mov_inv
-- Validamos que item_id exista en items
ALTER TABLE mov_inv 
ADD CONSTRAINT fk_mov_inv_item 
FOREIGN KEY (item_id) REFERENCES items(id);

-- Validamos que sucursal_id exista (asumiendo que hay una tabla de sucursales)
-- ALTER TABLE mov_inv 
-- ADD CONSTRAINT fk_mov_inv_sucursal 
-- FOREIGN KEY (sucursal_id) REFERENCES sucursales(id);

-- 3. En la tabla inventory_snapshot, validamos referencias
ALTER TABLE inventory_snapshot 
ADD CONSTRAINT fk_inventory_snapshot_item 
FOREIGN KEY (item_id) REFERENCES items(id);

-- 4. En la tabla receta_det, validamos referencias
ALTER TABLE receta_det 
ADD CONSTRAINT fk_receta_det_item 
FOREIGN KEY (item_id) REFERENCES items(id);

-- 5. En la tabla pos_map, validamos referencias
-- Ya corregimos receta_id en el script de tipos de datos
ALTER TABLE pos_map 
ADD CONSTRAINT fk_pos_map_receta 
FOREIGN KEY (receta_id) REFERENCES receta_cab(id);

-- 6. En recipe_cost_history, validamos referencias
-- Ya corregimos recipe_id en el script de tipos de datos
ALTER TABLE recipe_cost_history 
ADD CONSTRAINT fk_recipe_cost_history_recipe 
FOREIGN KEY (recipe_id) REFERENCES receta_cab(id);

-- 7. Mejoramos checks en la tabla mov_inv
-- Validamos que cantidad no sea cero
ALTER TABLE mov_inv 
ADD CONSTRAINT chk_mov_cantidad_no_cero 
CHECK (cantidad != 0);

-- Validamos que costo_unit no sea negativo
ALTER TABLE mov_inv 
ADD CONSTRAINT chk_mov_costo_no_negativo 
CHECK (costo_unit >= 0);

-- 8. Mejoramos checks en la tabla items
-- Validamos rango de temperatura
ALTER TABLE items 
ADD CONSTRAINT chk_temperatura_rango 
CHECK (temperatura_min <= temperatura_max);

-- 9. En receta_det, validamos que cantidad sea positiva
ALTER TABLE receta_det 
ADD CONSTRAINT chk_receta_det_cantidad_positiva 
CHECK (cantidad > 0);

-- 10. En receta_cab, validamos que porciones sea positiva
ALTER TABLE receta_cab 
ADD CONSTRAINT chk_receta_porciones_positivas 
CHECK (porciones_standard > 0);

-- 11. Creamos índices para mejorar rendimiento de las nuevas FKs
CREATE INDEX IF NOT EXISTS idx_mov_inv_item_id ON mov_inv(item_id);
CREATE INDEX IF NOT EXISTS idx_mov_inv_sucursal ON mov_inv(sucursal_id);
CREATE INDEX IF NOT EXISTS idx_mov_inv_tipo ON mov_inv(tipo);
CREATE INDEX IF NOT EXISTS idx_mov_inv_fecha ON mov_inv(created_at);

CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_item ON inventory_snapshot(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_branch ON inventory_snapshot(branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_snapshot_date ON inventory_snapshot(snapshot_date);

CREATE INDEX IF NOT EXISTS idx_receta_det_item ON receta_det(item_id);
CREATE INDEX IF NOT EXISTS idx_receta_det_receta_version ON receta_det(receta_version_id);

CREATE INDEX IF NOT EXISTS idx_pos_map_receta ON pos_map(receta_id);
CREATE INDEX IF NOT EXISTS idx_pos_map_tipo ON pos_map(tipo);

-- 12. Validamos integridad referencial antes de completar
-- (Las siguientes consultas ayudan a verificar la consistencia)

-- Verificar movimientos sin ítem correspondiente
/*
SELECT m.id, m.item_id
FROM mov_inv m
LEFT JOIN items i ON m.item_id = i.id
WHERE i.id IS NULL;
*/

-- Verificar entradas en receta_det sin ítem correspondiente
/*
SELECT rd.id, rd.item_id
FROM receta_det rd
LEFT JOIN items i ON rd.item_id = i.id
WHERE i.id IS NULL;
*/

-- Verificar entradas en pos_map sin receta correspondiente
/*
SELECT pm.pos_system, pm.plu, pm.receta_id
FROM pos_map pm
LEFT JOIN receta_cab rc ON pm.receta_id = rc.id
WHERE pm.receta_id IS NOT NULL AND rc.id IS NULL;
*/

-- 13. Agregamos constraints para evitar valores duplicados donde no se espera
-- Por ejemplo, en pos_map, asegurar unicidad razonable
-- Ya existe un constraint de PK en (pos_system, plu, valid_from, sys_from)

-- 14. Agregamos triggers para mantener integridad (ejemplo conceptual)
-- En PostgreSQL, podríamos crear funciones y triggers para validaciones complejas
-- Por ejemplo, para validar que las fechas de vigencia en pos_map no se solapen para el mismo plu
/*
CREATE OR REPLACE FUNCTION validate_pos_map_dates()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar si hay otro mapeo para el mismo plu con fechas solapadas
    IF EXISTS (
        SELECT 1 FROM pos_map p2 
        WHERE p2.plu = NEW.plu 
        AND p2.pos_system = NEW.pos_system
        AND p2.id != NEW.id
        AND (
            (NEW.valid_from BETWEEN p2.valid_from AND COALESCE(p2.valid_to, 'infinity'))
            OR 
            (NEW.valid_to BETWEEN p2.valid_from AND COALESCE(p2.valid_to, 'infinity'))
            OR
            (p2.valid_from BETWEEN NEW.valid_from AND COALESCE(NEW.valid_to, 'infinity'))
        )
    ) THEN
        RAISE EXCEPTION 'Las fechas de vigencia se solapan con otro mapeo para este PLU';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig_validate_pos_map_dates
    BEFORE INSERT OR UPDATE ON pos_map
    FOR EACH ROW
    EXECUTE FUNCTION validate_pos_map_dates();
*/

-- Fin del script de mejora de constraints