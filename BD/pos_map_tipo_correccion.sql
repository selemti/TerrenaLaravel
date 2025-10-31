-- Script para corregir el CHECK de pos_map.tipo a los valores correctos (MENU/MODIFIER)
-- Fecha: jueves, 30 de octubre de 2025

-- Actualmente en la base de datos, el CHECK de pos_map.tipo permite 'PLATO', 'MODIFICADOR', 'COMBO'
-- Pero en la aplicación se usan 'MENU', 'MODIFIER'
-- Para mantener compatibilidad, permitiremos ambos conjuntos de valores en la transición

-- Creamos una tabla temporal con el CHECK corregido
CREATE TABLE pos_map_corregido AS SELECT * FROM pos_map LIMIT 0;

-- Creamos la estructura con el CHECK correcto que permite ambos conjuntos
-- Esto permitirá la transición gradual de PLATO→MENU, MODIFICADOR→MODIFIER
ALTER TABLE pos_map_corregido ADD CONSTRAINT pos_map_tipo_check 
CHECK ((tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text, 'COMBO'::text, 'MENU'::text, 'MODIFIER'::text])));

-- Copiamos los datos
INSERT INTO pos_map_corregido SELECT * FROM pos_map_old;

-- Renombramos las tablas
ALTER TABLE pos_map RENAME TO pos_map_backup;
ALTER TABLE pos_map_corregido RENAME TO pos_map;

-- Recreando índices
CREATE INDEX IF NOT EXISTS idx_pos_map_plu ON pos_map USING btree (plu);
CREATE INDEX IF NOT EXISTS ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);

-- Creamos vistas de compatibilidad para manejar los tipos antiguos vs nuevos
CREATE OR REPLACE VIEW v_pos_map_tipos_compat AS
SELECT 
    pos_system,
    plu,
    CASE 
        WHEN tipo = 'PLATO' THEN 'MENU'
        WHEN tipo = 'MODIFICADOR' THEN 'MODIFIER'
        ELSE tipo
    END AS tipo_normalizado,
    tipo AS tipo_original,
    receta_id,
    receta_version_id,
    valid_from,
    valid_to,
    sys_from,
    sys_to,
    meta,
    vigente_desde
FROM pos_map;

-- Opcional: Actualizar datos existentes para usar el nuevo formato
-- UPDATE pos_map SET tipo = 'MENU' WHERE tipo = 'PLATO';
-- UPDATE pos_map SET tipo = 'MODIFIER' WHERE tipo = 'MODIFICADOR';

-- Nota: Considerar hacer esta actualización en una fase posterior de migración
-- para permitir compatibilidad gradual.

-- Fin del script de corrección de CHECK en pos_map.tipo