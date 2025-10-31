-- Script para implementar trigger que evita solapes de vigencia en pos_map
-- Fecha: jueves, 30 de octubre de 2025

-- Creamos función de trigger para validar solapes de vigencia
CREATE OR REPLACE FUNCTION validate_pos_map_vigencia()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificamos si hay otro mapeo para el mismo plu con fechas solapadas
    -- Considerando la combinación de pos_system y plu
    IF EXISTS (
        SELECT 1 FROM pos_map p2 
        WHERE p2.plu = NEW.plu 
        AND p2.pos_system = NEW.pos_system
        AND p2.id != NEW.id  -- Excluimos el registro actual en actualizaciones
        AND (
            -- Nuevo rango empieza antes de que termine el existente y termina después del inicio existente
            (NEW.valid_from <= COALESCE(p2.valid_to, 'infinity'::date) 
             AND NEW.valid_to >= p2.valid_from)
            OR
            -- Caso contrario: existente empieza antes de que termine el nuevo
            (p2.valid_from <= COALESCE(NEW.valid_to, 'infinity'::date) 
             AND p2.valid_to >= NEW.valid_from)
        )
        -- Solo validamos solapes para registros activos (no borrados lógicamente)
        AND p2.sys_to IS NULL
    ) THEN
        RAISE EXCEPTION 'Las fechas de vigencia se solapan con otro mapeo para este PLU: % en sistema %', 
                        NEW.plu, NEW.pos_system;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creamos el trigger para validación de solapes
DROP TRIGGER IF EXISTS trig_validate_pos_map_vigencia ON pos_map;
CREATE TRIGGER trig_validate_pos_map_vigencia
    BEFORE INSERT OR UPDATE ON pos_map
    FOR EACH ROW
    EXECUTE FUNCTION validate_pos_map_vigencia();

-- También creamos un trigger para validación adicional en UPDATE
-- que impide cambios que causarían solapes
CREATE OR REPLACE FUNCTION validate_pos_map_update_vigencia()
RETURNS TRIGGER AS $$
BEGIN
    -- Si solo se actualiza sys_to (soft delete), permitimos el cambio
    IF NEW.sys_to IS DISTINCT FROM OLD.sys_to THEN
        RETURN NEW;
    END IF;

    -- Para otros updates, verificamos solape
    IF EXISTS (
        SELECT 1 FROM pos_map p2 
        WHERE p2.plu = NEW.plu 
        AND p2.pos_system = NEW.pos_system
        AND p2.id != NEW.id
        AND p2.sys_to IS NULL  -- Solo consideramos registros activos
        AND (
            (NEW.valid_from <= COALESCE(p2.valid_to, 'infinity'::date) 
             AND NEW.valid_to >= p2.valid_from)
            OR
            (p2.valid_from <= COALESCE(NEW.valid_to, 'infinity'::date) 
             AND p2.valid_to >= NEW.valid_from)
        )
    ) THEN
        RAISE EXCEPTION 'Las fechas de vigencia se solapan con otro mapeo para este PLU: % en sistema %', 
                        NEW.plu, NEW.pos_system;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creamos el trigger para actualizaciones
DROP TRIGGER IF EXISTS trig_validate_pos_map_update_vigencia ON pos_map;
CREATE TRIGGER trig_validate_pos_map_update_vigencia
    BEFORE UPDATE ON pos_map
    FOR EACH ROW
    EXECUTE FUNCTION validate_pos_map_update_vigencia();

-- Creamos un índice para mejorar el rendimiento de la validación de solapes
CREATE INDEX IF NOT EXISTS idx_pos_map_vigencia_lookup 
ON pos_map (pos_system, plu, valid_from, valid_to) 
WHERE sys_to IS NULL;

-- Opcional: Procedimiento para validar solapes existentes antes de aplicar el trigger
/*
CREATE OR REPLACE PROCEDURE validar_solapes_pos_map()
LANGUAGE plpgsql
AS $$
DECLARE
    solape RECORD;
BEGIN
    FOR solape IN
        SELECT 
            p1.id as id1, p1.pos_system, p1.plu,
            p1.valid_from as from1, p1.valid_to as to1,
            p2.id as id2, 
            p2.valid_from as from2, p2.valid_to as to2
        FROM pos_map p1
        JOIN pos_map p2 ON (
            p1.plu = p2.plu 
            AND p1.pos_system = p2.pos_system
            AND p1.id < p2.id  -- Evita duplicados en la comparación
            AND p1.sys_to IS NULL AND p2.sys_to IS NULL  -- Ambos activos
            AND (
                (p1.valid_from <= COALESCE(p2.valid_to, 'infinity'::date) 
                 AND p1.valid_to >= p2.valid_from)
                OR
                (p2.valid_from <= COALESCE(p1.valid_to, 'infinity'::date) 
                 AND p2.valid_to >= p1.valid_from)
            )
        )
    LOOP
        RAISE NOTICE 'Solape detectado: ID % y ID % para PLU % en sistema % (Fechas: %-% y %-%)', 
                     solape.id1, solape.id2, solape.plu, solape.pos_system,
                     solape.from1, solape.to1, solape.from2, solape.to2;
    END LOOP;
END;
$$;

-- Para ejecutar la validación:
-- CALL validar_solapes_pos_map();
*/

-- Creamos una vista para identificar solapes existentes (útil para limpieza)
CREATE OR REPLACE VIEW v_pos_map_solapes AS
SELECT 
    p1.id as id1, 
    p1.pos_system, 
    p1.plu,
    p1.tipo,
    p1.receta_id,
    p1.valid_from as from1, 
    p1.valid_to as to1,
    p2.id as id2, 
    p2.valid_from as from2, 
    p2.valid_to as to2,
    CASE 
        WHEN p1.valid_from <= COALESCE(p2.valid_to, 'infinity'::date) 
             AND p1.valid_to >= p2.valid_from 
        THEN 'RANGO_S1_DENTRO_S2'
        WHEN p2.valid_from <= COALESCE(p1.valid_to, 'infinity'::date) 
             AND p2.valid_to >= p1.valid_from 
        THEN 'RANGO_S2_DENTRO_S1'
    END as tipo_solape
FROM pos_map p1
JOIN pos_map p2 ON (
    p1.plu = p2.plu 
    AND p1.pos_system = p2.pos_system
    AND p1.id < p2.id  -- Evita duplicados
    AND p1.sys_to IS NULL AND p2.sys_to IS NULL  -- Ambos activos
    AND (
        (p1.valid_from <= COALESCE(p2.valid_to, 'infinity'::date) 
         AND p1.valid_to >= p2.valid_from)
        OR
        (p2.valid_from <= COALESCE(p1.valid_to, 'infinity'::date) 
         AND p2.valid_to >= p1.valid_from)
    )
);

-- Fin del script para trigger de validación de solapes en pos_map