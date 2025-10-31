-- Script de Normalización de Base de Datos - Terrena Laravel
-- Fecha: jueves, 30 de octubre de 2025
-- Objetivo: Corregir inconsistencias y mejorar la estructura de la base de datos

-- 1. Corrección de tipos de datos inconsistentes
-- Cambio de item_id en inventory_snapshot de UUID a VARCHAR(20) para coincidir con items.id

-- Primero, creamos una tabla temporal con la estructura corregida
CREATE TABLE inventory_snapshot_temp (
    snapshot_date date NOT NULL,
    branch_id text NOT NULL,
    item_id character varying(20) NOT NULL, -- Cambiado de uuid a character varying(20)
    teorico_qty numeric(18,6) DEFAULT 0 NOT NULL,
    fisico_qty numeric(18,6),
    teorico_cost numeric(14,6),
    valor_teorico numeric(18,6),
    variance_qty numeric(18,6),
    variance_cost numeric(18,6),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Copiamos los datos existentes (si existen)
INSERT INTO inventory_snapshot_temp 
SELECT snapshot_date, branch_id, item_id::text, teorico_qty, fisico_qty, teorico_cost, 
       valor_teorico, variance_qty, variance_cost, created_at, updated_at
FROM inventory_snapshot;

-- Renombramos las tablas para mantener compatibilidad
ALTER TABLE inventory_snapshot RENAME TO inventory_snapshot_old;
ALTER TABLE inventory_snapshot_temp RENAME TO inventory_snapshot;

-- Creamos índices apropiados
CREATE INDEX idx_inventory_snapshot_item_date ON inventory_snapshot (item_id, snapshot_date);
CREATE INDEX idx_inventory_snapshot_branch_date ON inventory_snapshot (branch_id, snapshot_date);

-- 2. Eliminación de campos redundantes en la tabla items
-- Creamos una nueva tabla items con la estructura normalizada
CREATE TABLE items_normalized (
    id character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    categoria_id character varying(10) NOT NULL, -- o mejor usar category_id como entero con FK
    unidad_medida_id integer NOT NULL, -- Eliminamos unidad_medida (varchar)
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
    CONSTRAINT items_normalized_id_check CHECK (((id)::text ~ '^[A-Z0-9\-]{1,20}$'::text)),
    CONSTRAINT items_normalized_nombre_check CHECK ((length((nombre)::text) >= 2)),
    CONSTRAINT items_normalized_categoria_id_check CHECK (((categoria_id)::text ~~ 'CAT-%'::text)),
    CONSTRAINT items_normalized_check CHECK (((temperatura_max IS NULL) OR (temperatura_min IS NULL) OR (temperatura_max >= temperatura_min))),
    CONSTRAINT items_normalized_costo_promedio_check CHECK ((costo_promedio >= (0)::numeric))
);

-- Copiamos los datos manteniendo solo unidad_medida_id y eliminando unidad_medida (como texto)
INSERT INTO items_normalized 
SELECT id, nombre, descripcion, categoria_id, unidad_medida_id, 
       perishable, temperatura_min, temperatura_max, costo_promedio, 
       activo, created_at, updated_at, factor_conversion, unidad_compra_id, 
       factor_compra, tipo, unidad_salida_id, item_code, es_producible, 
       es_consumible_operativo, es_empaque_to_go
FROM items;

-- Renombramos las tablas para mantener compatibilidad
ALTER TABLE items RENAME TO items_old;
ALTER TABLE items_normalized RENAME TO items;

-- Recreando constraints
ALTER TABLE ONLY items ADD CONSTRAINT items_pkey PRIMARY KEY (id);
-- Asumimos que categoria_id y unidad_medida_id son FKs a otras tablas

-- 3. Creamos vistas para mantener compatibilidad durante la transición
-- Vista para mantener acceso a campos antiguos si es necesario
CREATE OR REPLACE VIEW v_items_compatibility AS
SELECT 
    i.id,
    i.nombre,
    i.descripcion,
    i.categoria_id,
    -- Mapeamos unidad_medida_id a su nombre legible para compatibilidad
    (SELECT clave FROM cat_unidades WHERE id = i.unidad_medida_id) as unidad_medida,
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

-- 4. Aseguramos integridad referencial con constraints apropiados
-- Añadiendo constraints para referencias foráneas
-- (En un entorno real, estos constraints deben ajustarse a las tablas reales existentes)
-- ALTER TABLE ONLY items ADD CONSTRAINT items_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES categorias(id);
-- ALTER TABLE ONLY items ADD CONSTRAINT items_unidad_medida_id_fkey FOREIGN KEY (unidad_medida_id) REFERENCES cat_unidades(id);

-- Índices para mejorar rendimiento en las relaciones comunes
CREATE INDEX idx_items_categoria_id ON items (categoria_id);
CREATE INDEX idx_items_unidad_medida_id ON items (unidad_medida_id);
CREATE INDEX idx_items_tipo ON items (tipo);

-- 5. Actualizamos la tabla pos_map para usar el tipo correcto de receta_id
-- Asumiendo que receta_cab.id es character varying(20) como vimos en el análisis
-- Esta actualización debe hacerse considerando que receta_id actualmente es 'text'
-- pero debería ser compatible con receta_cab.id

-- Fin del script de normalización