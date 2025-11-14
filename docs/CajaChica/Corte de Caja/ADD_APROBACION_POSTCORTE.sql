-- ============================================================
-- Agregar sistema de aprobación para postcortes irregulares
-- Date: 2025-11-10
-- Purpose: Permitir aprobación de cortes con skipped_precorte=true
-- ============================================================

-- Paso 1: Agregar columnas a postcorte para aprobación
-- Nota: PostgreSQL 9.5 no soporta IF NOT EXISTS en ALTER COLUMN
DO $$
BEGIN
  -- requiere_aprobacion
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='requiere_aprobacion') THEN
    ALTER TABLE selemti.postcorte ADD COLUMN requiere_aprobacion BOOLEAN DEFAULT FALSE;
  END IF;

  -- aprobado_por
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='aprobado_por') THEN
    ALTER TABLE selemti.postcorte ADD COLUMN aprobado_por INTEGER REFERENCES selemti.users(id);
  END IF;

  -- aprobado_en
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='aprobado_en') THEN
    ALTER TABLE selemti.postcorte ADD COLUMN aprobado_en TIMESTAMP WITH TIME ZONE;
  END IF;

  -- motivo_irregular
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='motivo_irregular') THEN
    ALTER TABLE selemti.postcorte ADD COLUMN motivo_irregular TEXT;
  END IF;

  -- rechazado
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='rechazado') THEN
    ALTER TABLE selemti.postcorte ADD COLUMN rechazado BOOLEAN DEFAULT FALSE;
  END IF;

  -- motivo_rechazo
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='selemti' AND table_name='postcorte' AND column_name='motivo_rechazo') THEN
    ALTER TABLE selemti.postcorte ADD COLUMN motivo_rechazo TEXT;
  END IF;
END
$$;

-- Paso 2: Crear tabla de alertas para cortes
CREATE TABLE IF NOT EXISTS selemti.alertas_cortes (
  id BIGSERIAL PRIMARY KEY,
  postcorte_id BIGINT REFERENCES selemti.postcorte(id) ON DELETE CASCADE,
  sesion_id BIGINT REFERENCES selemti.sesion_cajon(id) ON DELETE CASCADE,
  tipo VARCHAR(50) NOT NULL, -- 'REQUIERE_APROBACION', 'APROBADO', 'RECHAZADO'
  destinatario_id INTEGER REFERENCES selemti.users(id),
  leida BOOLEAN DEFAULT FALSE,
  creada_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  leida_en TIMESTAMP WITH TIME ZONE
);

-- Paso 3: Crear índices para mejorar consultas
CREATE INDEX IF NOT EXISTS idx_alertas_cortes_destinatario
  ON selemti.alertas_cortes(destinatario_id, leida);

CREATE INDEX IF NOT EXISTS idx_alertas_cortes_postcorte
  ON selemti.alertas_cortes(postcorte_id);

CREATE INDEX IF NOT EXISTS idx_postcorte_requiere_aprobacion
  ON selemti.postcorte(requiere_aprobacion)
  WHERE requiere_aprobacion = TRUE;

-- Paso 4: Marcar postcortes existentes con skipped_precorte como requiere_aprobacion
UPDATE selemti.postcorte p
SET requiere_aprobacion = TRUE
FROM selemti.sesion_cajon s
WHERE p.sesion_id = s.id
  AND s.skipped_precorte = TRUE
  AND p.validado = FALSE
  AND p.requiere_aprobacion = FALSE;

-- Verificar resultados
SELECT
  'postcortes_requieren_aprobacion' as tipo,
  COUNT(*) as total
FROM selemti.postcorte
WHERE requiere_aprobacion = TRUE
UNION ALL
SELECT
  'alertas_cortes_creadas' as tipo,
  COUNT(*) as total
FROM selemti.alertas_cortes;
