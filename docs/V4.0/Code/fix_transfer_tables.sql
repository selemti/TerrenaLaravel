-- ============================================================
-- MIGRACIÓN: Corregir tablas transfer_cab y transfer_det
-- Fecha: 2025-11-17
-- Propósito: Agregar columnas faltantes para sincronizar con modelos
-- ============================================================

-- Backup de tablas antes de modificar
CREATE TABLE IF NOT EXISTS selemti.transfer_cab_backup_20251117 AS
SELECT * FROM selemti.transfer_cab;

CREATE TABLE IF NOT EXISTS selemti.transfer_det_backup_20251117 AS
SELECT * FROM selemti.transfer_det;

-- ============================================================
-- TRANSFER_CAB: Agregar columnas del workflow completo
-- ============================================================

-- Agregar columnas de usuarios del workflow
ALTER TABLE selemti.transfer_cab
ADD COLUMN IF NOT EXISTS aprobada_por INTEGER REFERENCES users(id),
ADD COLUMN IF NOT EXISTS posteada_por INTEGER REFERENCES users(id);

-- Agregar columnas de fechas del workflow
ALTER TABLE selemti.transfer_cab
ADD COLUMN IF NOT EXISTS fecha_solicitada TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS fecha_aprobada TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS fecha_despachada TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS fecha_recibida TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS fecha_posteada TIMESTAMP NULL;

-- Agregar columnas de observaciones
ALTER TABLE selemti.transfer_cab
ADD COLUMN IF NOT EXISTS observaciones TEXT NULL,
ADD COLUMN IF NOT EXISTS observaciones_recepcion TEXT NULL;

-- Agregar updated_at
ALTER TABLE selemti.transfer_cab
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NULL DEFAULT now();

-- Renombrar guia a numero_guia (solo si guia existe)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
        AND table_name = 'transfer_cab'
        AND column_name = 'guia'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
        AND table_name = 'transfer_cab'
        AND column_name = 'numero_guia'
    ) THEN
        ALTER TABLE selemti.transfer_cab RENAME COLUMN guia TO numero_guia;
        RAISE NOTICE 'Columna guia renombrada a numero_guia';
    END IF;
END $$;

-- ============================================================
-- TRANSFER_DET: Agregar columnas faltantes
-- ============================================================

-- Agregar cantidad_solicitada (solo si no existe)
ALTER TABLE selemti.transfer_det
ADD COLUMN IF NOT EXISTS cantidad_solicitada NUMERIC NULL;

-- Si cantidad existe y cantidad_solicitada es nueva, copiar datos
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
        AND table_name = 'transfer_det'
        AND column_name = 'cantidad'
    ) THEN
        -- Copiar valores de cantidad a cantidad_solicitada si está vacía
        UPDATE selemti.transfer_det
        SET cantidad_solicitada = cantidad
        WHERE cantidad_solicitada IS NULL;

        RAISE NOTICE 'Datos copiados de cantidad a cantidad_solicitada';
    END IF;
END $$;

-- Agregar columnas adicionales
ALTER TABLE selemti.transfer_det
ADD COLUMN IF NOT EXISTS unidad_medida VARCHAR(50) NULL,
ADD COLUMN IF NOT EXISTS observaciones TEXT NULL,
ADD COLUMN IF NOT EXISTS observaciones_recepcion TEXT NULL;

-- ============================================================
-- VERIFICACIÓN: Mostrar estructura final
-- ============================================================

SELECT 'TRANSFER_CAB COLUMNS:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'transfer_cab'
ORDER BY ordinal_position;

SELECT 'TRANSFER_DET COLUMNS:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'transfer_det'
ORDER BY ordinal_position;

-- ============================================================
-- ROLLBACK (comentado por seguridad)
-- ============================================================

/*
-- Para revertir cambios si algo sale mal:

DROP TABLE IF EXISTS selemti.transfer_cab;
DROP TABLE IF EXISTS selemti.transfer_det;

ALTER TABLE selemti.transfer_cab_backup_20251117 RENAME TO transfer_cab;
ALTER TABLE selemti.transfer_det_backup_20251117 RENAME TO transfer_det;
*/

-- ============================================================
-- NOTAS IMPORTANTES
-- ============================================================

/*
DESPUÉS DE EJECUTAR ESTE SCRIPT:

1. Verificar que TransferHeader.php y TransferLine.php no muestren
   columnas fantasma al ejecutar: php validate_inventory_models.php

2. Actualizar timestamps existentes:
   UPDATE selemti.transfer_cab
   SET fecha_solicitada = created_at
   WHERE fecha_solicitada IS NULL AND estado = 'SOLICITADA';

3. Considerar agregar índices para las nuevas columnas FK:
   CREATE INDEX idx_transfer_cab_aprobada_por ON selemti.transfer_cab(aprobada_por);
   CREATE INDEX idx_transfer_cab_posteada_por ON selemti.transfer_cab(posteada_por);

4. Actualizar stored procedures o triggers que usen estas tablas

5. Eliminar backups después de validar en producción:
   DROP TABLE selemti.transfer_cab_backup_20251117;
   DROP TABLE selemti.transfer_det_backup_20251117;
*/
