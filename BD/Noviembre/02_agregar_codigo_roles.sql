-- =============================================================================
-- SCRIPT: 02_agregar_codigo_roles.sql (OPCIONAL)
-- Fecha: 2025-11-02
-- Objetivo: Agregar campo 'codigo' a selemti.roles para códigos cortos de roles
--           SOLO ejecutar si se necesita un código corto (ej: ADM, GER, VEN)
-- =============================================================================

-- NOTA: El campo 'name' ya sirve como identificador único en Spatie Laravel Permission
-- Este script es OPCIONAL y solo debe ejecutarse si hay un requisito de negocio
-- para tener códigos cortos adicionales

BEGIN;

ALTER TABLE selemti.roles
  ADD COLUMN IF NOT EXISTS codigo VARCHAR(20) NULL;

COMMENT ON COLUMN selemti.roles.codigo IS 'Código corto del rol (ej: ADM, GER, VEN)';

-- Agregar constraint de unicidad
ALTER TABLE selemti.roles
  ADD CONSTRAINT roles_codigo_unique UNIQUE (codigo);

COMMIT;

-- Verificación
SELECT
  column_name,
  data_type,
  character_maximum_length,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name = 'roles'
  AND column_name = 'codigo';

-- Resultado esperado: 1 fila (codigo VARCHAR(20) NULL)
