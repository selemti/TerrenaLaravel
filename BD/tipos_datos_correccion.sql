-- Script para corregir tipos de datos inconsistentes
-- Fecha: jueves, 30 de octubre de 2025

-- Revisamos las principales inconsistencias encontradas:

-- 1. En la tabla inventory_snapshot, item_id es UUID pero debería ser VARCHAR(20) para coincidir con items.id
-- Este cambio ya fue incluido en el script anterior para inventory_snapshot, pero aquí lo detallamos:

-- Verificación de los tipos de datos antes de la actualización
SELECT 
    table_name, 
    column_name, 
    data_type, 
    character_maximum_length 
FROM information_schema.columns 
WHERE table_name IN ('inventory_snapshot', 'items', 'mov_inv', 'receta_det', 'pos_map') 
AND column_name LIKE '%item_id%'
ORDER BY table_name;

-- 2. En otras tablas relacionadas con inventario y movimientos, necesitamos asegurar consistencia
-- Revisamos posibles tablas adicionales que puedan tener inconsistencias en el tipo de item_id

-- Tablas que referencian items.id:
-- - mov_inv (item_id character varying(20)) ✓ CONSISTENTE
-- - receta_det (item_id character varying(20)) ✓ CONSISTENTE
-- - item_vendor (item_id character varying(20)) ✓ CONSISTENTE
-- - inventory_snapshot (item_id uuid) ✗ INCONSISTENTE - Corregido en script anterior

-- 3. Revisamos también receta_id en pos_map
-- Actualmente pos_map.receta_id es de tipo text
-- Mientras que receta_cab.id es character varying(20)
-- Esto también es una inconsistencia que debemos corregir:

-- Creamos una tabla temporal para pos_map con tipo de dato corregido
CREATE TABLE pos_map_temp (
    pos_system text NOT NULL,
    plu text NOT NULL,
    tipo text NOT NULL,
    receta_id character varying(20), -- Cambiado de 'text' a 'character varying(20)' para coincidir con receta_cab.id
    receta_version_id integer,
    valid_from date NOT NULL,
    valid_to date,
    sys_from timestamp without time zone DEFAULT now() NOT NULL,
    sys_to timestamp without time zone,
    meta json,
    vigente_desde timestamp without time zone,
    CONSTRAINT pos_map_tipo_check CHECK ((tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text, 'COMBO'::text])))
);

-- Copiamos los datos
INSERT INTO pos_map_temp
SELECT pos_system, plu, tipo, receta_id::character varying(20), receta_version_id,
       valid_from, valid_to, sys_from, sys_to, meta, vigente_desde
FROM pos_map;

-- Renombramos tablas para mantener compatibilidad
ALTER TABLE pos_map RENAME TO pos_map_old;
ALTER TABLE pos_map_temp RENAME TO pos_map;

-- Recreando índices y constraints
CREATE INDEX idx_pos_map_plu ON pos_map USING btree (plu);
CREATE INDEX ix_pos_map_plu ON pos_map USING btree (pos_system, plu, vigente_desde);
ALTER TABLE pos_map ADD CONSTRAINT pos_map_pkey PRIMARY KEY (pos_system, plu, valid_from, sys_from);

-- 4. Revisamos también la tabla recipe_cost_history - tiene recipe_id bigint pero receta_cab.id es character varying(20)
-- Esto es otro caso de inconsistencia importante:

CREATE TABLE recipe_cost_history_temp (
    id bigint NOT NULL,
    recipe_id character varying(20) NOT NULL, -- Cambiado de bigint a character varying(20) para coincidir con receta_cab.id
    recipe_version_id bigint,
    snapshot_at timestamp without time zone NOT NULL,
    currency_code character varying(10) DEFAULT 'MXN'::character varying,
    batch_cost numeric(14,6),
    portion_cost numeric(14,6),
    batch_size numeric(14,6),
    yield_portions numeric(14,6),
    notes text,
    created_at timestamp without time zone DEFAULT now()
);

-- Copiamos datos
INSERT INTO recipe_cost_history_temp
SELECT id, recipe_id::character varying(20), recipe_version_id, snapshot_at,
       currency_code, batch_cost, portion_cost, batch_size, yield_portions, notes, created_at
FROM recipe_cost_history;

-- Renombramos tablas
ALTER TABLE recipe_cost_history RENAME TO recipe_cost_history_old;
ALTER TABLE recipe_cost_history_temp RENAME TO recipe_cost_history;

-- Recreando índices y constraints
ALTER TABLE recipe_cost_history ADD CONSTRAINT recipe_cost_history_pkey PRIMARY KEY (id);
-- Nota: Aquí habría que actualizar la FK si existe

-- 5. Revisamos también receta_version - tiene receta_id character varying(20) que SI es consistente ✓
-- Esta ya es consistente: receta_version.receta_id es character varying(20), como receta_cab.id ✓

-- 6. Creamos vistas de compatibilidad para aplicaciones que esperen los tipos antiguos
CREATE OR REPLACE VIEW v_pos_map_compatibility AS
SELECT 
    pos_system,
    plu,
    tipo,
    receta_id::text as receta_id, -- Mantenemos compatibilidad casteando a text si es necesario
    receta_version_id,
    valid_from,
    valid_to,
    sys_from,
    sys_to,
    meta,
    vigente_desde
FROM pos_map;

-- 7. Creamos vistas para recipe_cost_history
CREATE OR REPLACE VIEW v_recipe_cost_history_compat AS
SELECT 
    id,
    recipe_id::text as recipe_id, -- Compatibilidad
    recipe_version_id,
    snapshot_at,
    currency_code,
    batch_cost,
    portion_cost,
    batch_size,
    yield_portions,
    notes,
    created_at
FROM recipe_cost_history;

-- Fin del script de corrección de tipos de datos