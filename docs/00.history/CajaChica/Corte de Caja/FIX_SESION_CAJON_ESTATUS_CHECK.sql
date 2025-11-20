-- ============================================================
-- Fix CHECK constraint for sesion_cajon.estatus
-- Date: 2025-11-10
-- Problem: Constraint doesn't include 'EN_CORTE' state
-- ============================================================

-- Drop the old constraint
ALTER TABLE selemti.sesion_cajon
  DROP CONSTRAINT IF EXISTS sesion_cajon_estatus_check;

-- Create new constraint with 'EN_CORTE' included
ALTER TABLE selemti.sesion_cajon
  ADD CONSTRAINT sesion_cajon_estatus_check
  CHECK (estatus = ANY (ARRAY['ACTIVA'::text, 'LISTO_PARA_CORTE'::text, 'EN_CORTE'::text, 'CERRADA'::text]));

-- Verify constraint was created
SELECT
  conname AS constraint_name,
  consrc AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'selemti.sesion_cajon'::regclass
  AND conname = 'sesion_cajon_estatus_check';
