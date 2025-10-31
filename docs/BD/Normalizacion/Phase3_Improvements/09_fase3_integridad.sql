-- =====================================================================
-- FASE 3: Integridad y Auditoría
-- =====================================================================
-- Añade timestamps de auditoría y soft deletes a todas las tablas
-- que aún no los tienen
-- =====================================================================

\set ON_ERROR_STOP on
\timing on

\echo ''
\echo '============================================================='
\echo 'FASE 3: Integridad y Auditoría'
\echo '============================================================='
\echo ''

-- =====================================================================
-- 3.1: Añadir timestamps de auditoría a tablas que no los tienen
-- =====================================================================
\echo 'Añadiendo timestamps de auditoría...'

DO $$
DECLARE
    r RECORD;
BEGIN
    -- Lista de tablas principales que necesitan auditoría
    FOR r IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'selemti' 
          AND table_type = 'BASE TABLE'
          AND table_name IN (
            'merma', 'op_cab', 'op_det', 'op_insumo',
            'recepcion_cab', 'recepcion_det',
            'traspaso_cab', 'traspaso_det',
            'hist_cost_insumo', 'insumo_presentacion', 'insumo_proveedor_presentacion',
            'pos_map', 'ticket_cab', 'ticket_det', 'ticket_det_consumo'
          )
    LOOP
        -- Añadir created_at si no existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
              AND table_name = r.table_name 
              AND column_name = 'created_at'
        ) THEN
            EXECUTE format('ALTER TABLE selemti.%I ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP', r.table_name);
            RAISE NOTICE 'Añadido created_at a %.%', 'selemti', r.table_name;
        END IF;
        
        -- Añadir updated_at si no existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
              AND table_name = r.table_name 
              AND column_name = 'updated_at'
        ) THEN
            EXECUTE format('ALTER TABLE selemti.%I ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP', r.table_name);
            RAISE NOTICE 'Añadido updated_at a %.%', 'selemti', r.table_name;
        END IF;
        
        -- Añadir deleted_at si no existe (para soft deletes)
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'selemti' 
              AND table_name = r.table_name 
              AND column_name = 'deleted_at'
        ) THEN
            EXECUTE format('ALTER TABLE selemti.%I ADD COLUMN deleted_at TIMESTAMP DEFAULT NULL', r.table_name);
            RAISE NOTICE 'Añadido deleted_at a %.%', 'selemti', r.table_name;
        END IF;
    END LOOP;
END $$;

-- =====================================================================
-- 3.2: Crear función para actualizar updated_at automáticamente
-- =====================================================================
\echo ''
\echo 'Creando función de actualización automática...'

CREATE OR REPLACE FUNCTION selemti.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 3.3: Crear triggers para updated_at
-- =====================================================================
\echo 'Creando triggers de actualización...'

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT table_name 
        FROM information_schema.columns
        WHERE table_schema = 'selemti' 
          AND column_name = 'updated_at'
          AND table_name IN (
            'merma', 'op_cab', 'op_det', 'op_insumo',
            'recepcion_cab', 'recepcion_det',
            'traspaso_cab', 'traspaso_det',
            'hist_cost_insumo', 'insumo_presentacion', 'insumo_proveedor_presentacion'
          )
        GROUP BY table_name
    LOOP
        -- Crear trigger solo si no existe
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'update_' || r.table_name || '_updated_at'
        ) THEN
            EXECUTE format(
                'CREATE TRIGGER update_%I_updated_at
                 BEFORE UPDATE ON selemti.%I
                 FOR EACH ROW
                 EXECUTE PROCEDURE selemti.update_updated_at_column()',
                r.table_name, r.table_name
            );
            RAISE NOTICE 'Trigger creado para %.%', 'selemti', r.table_name;
        END IF;
    END LOOP;
END $$;

-- =====================================================================
-- 3.4: Añadir índices para soft deletes
-- =====================================================================
\echo ''
\echo 'Añadiendo índices para deleted_at...'

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT table_name 
        FROM information_schema.columns
        WHERE table_schema = 'selemti' 
          AND column_name = 'deleted_at'
          AND table_name IN (
            'merma', 'op_cab', 'recepcion_cab', 'traspaso_cab'
          )
        GROUP BY table_name
    LOOP
        EXECUTE format(
            'CREATE INDEX IF NOT EXISTS idx_%I_deleted_at ON selemti.%I (deleted_at)',
            r.table_name, r.table_name
        );
        RAISE NOTICE 'Índice deleted_at creado para %.%', 'selemti', r.table_name;
    END LOOP;
END $$;

-- =====================================================================
-- 3.5: Verificar integridad referencial
-- =====================================================================
\echo ''
\echo 'Verificando integridad referencial...'

-- Contar FKs totales
SELECT 
    'Total de FKs' as metrica,
    COUNT(*) as cantidad
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
  AND table_schema = 'selemti';

-- Contar tablas con auditoría
SELECT 
    'Tablas con auditoría completa' as metrica,
    COUNT(DISTINCT table_name) as cantidad
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND column_name IN ('created_at', 'updated_at', 'deleted_at')
GROUP BY table_schema
HAVING COUNT(DISTINCT CASE WHEN column_name = 'created_at' THEN 1 END) > 0
   AND COUNT(DISTINCT CASE WHEN column_name = 'updated_at' THEN 1 END) > 0
   AND COUNT(DISTINCT CASE WHEN column_name = 'deleted_at' THEN 1 END) > 0;

\echo ''
\echo '============================================================='
\echo 'FASE 3 COMPLETADA'
\echo '============================================================='
\echo ''

\timing off
