-- =============================================================================
-- SCRIPT: 01_agregar_campos_users.sql
-- Fecha: 2025-11-02
-- Objetivo: Agregar campos únicos de selemti.usuario a selemti.users
--           antes de eliminar la tabla selemti.usuario
-- =============================================================================

BEGIN;

-- Agregar campos únicos de selemti.usuario a selemti.users
ALTER TABLE selemti.users
  ADD COLUMN IF NOT EXISTS floreant_user_id INTEGER NULL,
  ADD COLUMN IF NOT EXISTS meta JSONB NULL;

-- Comentarios de documentación
COMMENT ON COLUMN selemti.users.floreant_user_id IS 'Link al usuario en el sistema POS Floreant (public.users.user_id)';
COMMENT ON COLUMN selemti.users.meta IS 'Metadata flexible en formato JSON para almacenar propiedades adicionales del usuario';

-- Índice para búsquedas por floreant_user_id
CREATE INDEX IF NOT EXISTS idx_users_floreant_user_id
  ON selemti.users(floreant_user_id)
  WHERE floreant_user_id IS NOT NULL;

-- FK opcional a public.users (comentado por defecto)
-- Descomentar si se requiere integridad referencial estricta con el sistema POS
-- ALTER TABLE selemti.users
--   ADD CONSTRAINT fk_users_floreant_user
--   FOREIGN KEY (floreant_user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;

COMMIT;

-- Verificación
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name = 'users'
  AND column_name IN ('floreant_user_id', 'meta')
ORDER BY column_name;

-- Resultado esperado: 2 filas (floreant_user_id INTEGER NULL, meta JSONB NULL)
