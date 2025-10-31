-- Script para eliminar campos redundantes en la tabla items e implementar referencias adecuadas
-- Fecha: jueves, 30 de octubre de 2025

-- Identificación de campos redundantes o duplicados:
-- 1. En items: unidad_medida (varchar) y unidad_medida_id (integer) representan lo mismo
-- 2. En items: categoria_id (varchar con formato CAT-XXXX) y category_id (bigint) posiblemente duplicados

-- Análisis de los campos redundantes:
/*
- unidad_medida: campo de texto (varchar) con valores como 'KG', 'L', 'PZ' (limitado por check)
- unidad_medida_id: campo numérico (integer) que debería apuntar a una tabla de unidades
- categoria_id: campo de texto (varchar) en formato 'CAT-XXXX' 
- category_id: campo numérico (bigint) que podría apuntar a una tabla de categorías
*/

-- Estrategia:
-- 1. Eliminar unidad_medida (el campo de texto) y mantener solo unidad_medida_id
-- 2. Eliminar category_id (el campo numérico) y mantener categoria_id (el campo de texto con formato CAT-XXXX) 
--    ya que aparentemente hay una constraint que impone el formato CAT-XXXX que es más descriptiva

-- Creamos la tabla items sin campos redundantes
CREATE TABLE items_optimized (
    id character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    categoria_id character varying(10) NOT NULL,  -- Mantenemos este con formato CAT-XXXX
    unidad_medida_id integer NOT NULL,           -- Mantenemos este como referencia a cat_unidades
    perishable boolean DEFAULT false,
    temperatura_min integer,
    temperatura_max integer,
    costo_promedio numeric(10,2) DEFAULT 0.00,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    factor_conversion numeric(12,6) DEFAULT 1.0,
    unidad_compra_id integer,
    factor_compra numeric(12,6) DEFAULT 1.0,
    tipo producto_tipo,
    unidad_salida_id integer,
    item_code character varying(32),
    es_producible boolean DEFAULT false NOT NULL,
    es_consumible_operativo boolean DEFAULT false NOT NULL,
    es_empaque_to_go boolean DEFAULT false NOT NULL,
    -- Eliminamos unidad_medida (el campo de texto redundante)
    -- Eliminamos category_id (el campo numérico redundante)
    
    -- Constraints actualizados
    CONSTRAINT items_optimized_id_check CHECK (((id)::text ~ '^[A-Z0-9\-]{1,20}$'::text)),
    CONSTRAINT items_optimized_nombre_check CHECK ((length((nombre)::text) >= 2)),
    CONSTRAINT items_optimized_categoria_id_check CHECK (((categoria_id)::text ~~ 'CAT-%'::text)),
    CONSTRAINT items_optimized_check CHECK (((temperatura_max IS NULL) OR (temperatura_min IS NULL) OR (temperatura_max >= temperatura_min))),
    CONSTRAINT items_optimized_costo_promedio_check CHECK ((costo_promedio >= (0)::numeric))
);

-- Copiamos los datos desde la tabla original
INSERT INTO items_optimized
SELECT 
    id, 
    nombre, 
    descripcion, 
    categoria_id,
    unidad_medida_id,  -- Tomamos el ID que apunta a la tabla de unidades
    perishable, 
    temperatura_min, 
    temperatura_max, 
    costo_promedio, 
    activo,
    created_at, 
    updated_at, 
    factor_conversion, 
    unidad_compra_id, 
    factor_compra, 
    tipo,
    unidad_salida_id,
    item_code,
    es_producible,
    es_consumible_operativo,
    es_empaque_to_go
FROM items;

-- Renombramos tablas para mantener compatibilidad
ALTER TABLE items RENAME TO items_old;
ALTER TABLE items_optimized RENAME TO items;

-- Recreamos constraints y índices
ALTER TABLE items ADD CONSTRAINT items_pkey PRIMARY KEY (id);
CREATE INDEX idx_items_categoria_id ON items (categoria_id);
CREATE INDEX idx_items_unidad_medida_id ON items (unidad_medida_id);
CREATE INDEX idx_items_tipo ON items (tipo);

-- Creamos vistas para mantener compatibilidad con aplicaciones antiguas
-- que esperaban los campos redundantes
CREATE OR REPLACE VIEW v_items_legacy AS
SELECT 
    i.id,
    i.nombre,
    i.descripcion,
    i.categoria_id,
    -- Recreamos unidad_medida como texto para compatibilidad con aplicaciones existentes
    (SELECT clave FROM cat_unidades WHERE id = i.unidad_medida_id) AS unidad_medida,
    i.unidad_medida_id,
    i.perishable,
    i.temperatura_min,
    i.temperatura_max,
    i.costo_promedio,
    i.activo,
    i.created_at,
    i.updated_at,
    i.factor_conversion,
    i.unidad_compra_id,
    i.factor_compra,
    i.tipo,
    i.unidad_salida_id,
    i.item_code,
    i.es_producible,
    i.es_consumible_operativo,
    i.es_empaque_to_go
FROM items i;

-- Verificamos integridad referencial
-- Validamos que todos los unidad_medida_id tengan correspondencia en cat_unidades
-- (asumiendo que cat_unidades existe y tiene un campo id)
/*
SELECT i.id, i.nombre, i.unidad_medida_id
FROM items i
LEFT JOIN cat_unidades u ON i.unidad_medida_id = u.id
WHERE u.id IS NULL AND i.unidad_medida_id IS NOT NULL;
*/

-- Validamos que todos los categoria_id sigan el formato CAT-XXXX
/*
SELECT id, nombre, categoria_id
FROM items
WHERE NOT (categoria_id ~~ 'CAT-%');
*/

-- Fin del script de optimización de campos redundantes