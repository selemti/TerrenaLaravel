-- Script para revisar y optimizar la tabla cat_unidades
-- Fecha: jueves, 30 de octubre de 2025

-- Revisamos la estructura actual de cat_unidades
-- Basado en nuestro análisis anterior, la tabla cat_unidades tiene:
/*
CREATE TABLE cat_unidades (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    clave character varying(16),
    nombre character varying(64),
    activo boolean DEFAULT true NOT NULL
);
*/

-- Esta estructura es adecuada para reemplazar el campo unidad_medida (texto) en items
-- pero necesitamos asegurar que tenga los datos necesarios y las relaciones adecuadas

-- 1. Verificamos si existen unidades de medida básicas
-- Si no existen, las creamos
INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
SELECT 'PZ', 'Pieza', true, now(), now()
WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'PZ');

INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
SELECT 'KG', 'Kilogramo', true, now(), now()
WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'KG');

INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
SELECT 'L', 'Litro', true, now(), now()
WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'L');

INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
SELECT 'M', 'Metro', true, now(), now()
WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'M');

-- 2. Creamos índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_cat_unidades_clave ON cat_unidades (clave);
CREATE INDEX IF NOT EXISTS idx_cat_unidades_nombre ON cat_unidades (nombre);
CREATE INDEX IF NOT EXISTS idx_cat_unidades_activo ON cat_unidades (activo);

-- 3. Creamos vistas que mapean los valores antiguos de unidad_medida a cat_unidades
-- para mantener compatibilidad durante la transición
CREATE OR REPLACE VIEW v_unidades_medida_compat AS
SELECT 
    id,
    clave AS codigo,  -- Para compatibilidad con código que espera 'codigo'
    clave,
    nombre,
    activo,
    created_at,
    updated_at
FROM cat_unidades;

-- 4. Validamos que todos los valores de unidad_medida_id en items tengan correspondencia
-- en cat_unidades
/*
SELECT i.id, i.nombre, i.unidad_medida_id
FROM items i
LEFT JOIN cat_unidades u ON i.unidad_medida_id = u.id
WHERE u.id IS NULL AND i.unidad_medida_id IS NOT NULL;
*/

-- 5. Si es necesario, creamos una tabla de conversiones entre unidades
CREATE TABLE IF NOT EXISTS cat_unidades_conversion (
    id bigserial PRIMARY KEY,
    unidad_origen_id bigint NOT NULL,
    unidad_destino_id bigint NOT NULL,
    factor numeric(12,6) NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp(0) without time zone DEFAULT now(),
    updated_at timestamp(0) without time zone DEFAULT now(),
    
    CONSTRAINT uk_unidades_conversion UNIQUE (unidad_origen_id, unidad_destino_id),
    CONSTRAINT chk_factor_positivo CHECK (factor > 0),
    
    -- Estas FKs serían válidas si cat_unidades existe
    -- CONSTRAINT fk_unidad_origen FOREIGN KEY (unidad_origen_id) REFERENCES cat_unidades(id),
    -- CONSTRAINT fk_unidad_destino FOREIGN KEY (unidad_destino_id) REFERENCES cat_unidades(id)
);

-- 6. Aseguramos que la tabla cat_unidades tiene un constraint adecuado
ALTER TABLE cat_unidades 
ADD CONSTRAINT chk_clave_unidad_format 
CHECK (clave ~ '^[A-Z][A-Z0-9]{1,4}$');  -- Ej: PZ, KG, L, CM, MT

-- 7. Actualizamos el campo nombre para que no sea nulo
ALTER TABLE cat_unidades 
ALTER COLUMN nombre SET NOT NULL;

-- Nota: Si la tabla cat_unidades no existía, este sería el script para crearla:
/*
CREATE TABLE cat_unidades (
    id bigserial PRIMARY KEY,
    clave character varying(16) NOT NULL UNIQUE,
    nombre character varying(64) NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now(),
    updated_at timestamp(0) without time zone DEFAULT now(),
    
    CONSTRAINT chk_clave_unidad_format CHECK (clave ~ '^[A-Z][A-Z0-9]{1,4}$'),
    CONSTRAINT chk_nombre_no_vacio CHECK (length(trim(nombre)) > 0)
);

CREATE INDEX idx_cat_unidades_clave ON cat_unidades (clave);
CREATE INDEX idx_cat_unidades_nombre ON cat_unidades (nombre);
CREATE INDEX idx_cat_unidades_activo ON cat_unidades (activo);
*/

-- Fin del script para optimizar cat_unidades