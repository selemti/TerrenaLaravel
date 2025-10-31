-- ============================================================================
-- ROLLBACK SCRIPT - PHASE 2 (All Consolidations)
-- ============================================================================
-- Proyecto: TerrenaLaravel - Normalización BD selemti
-- Fecha: 30 de octubre de 2025
--
-- PROPÓSITO:
-- Revertir todos los cambios de Phase 2 (consolidaciones) si es necesario.
-- Este script restaura el estado anterior a Phase 2.
--
-- ADVERTENCIA:
-- - Este rollback es DESTRUCTIVO para datos creados después de Phase 2
-- - Solo ejecutar si hay problemas graves post-migración
-- - Requiere backup reciente de la BD
--
-- USO:
-- psql -h localhost -p 5433 -U postgres -d pos -f rollback_phase2.sql
-- ============================================================================

BEGIN;

RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
RAISE NOTICE '║               ROLLBACK PHASE 2 - USUARIOS                     ║';
RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
RAISE NOTICE '';

-- ============================================================================
-- PASO 1: DROP VISTAS DE COMPATIBILIDAD
-- ============================================================================

RAISE NOTICE '=== Eliminando vistas de compatibilidad ===';

DROP VIEW IF EXISTS selemti.v_usuario CASCADE;
RAISE NOTICE '✓ Dropped: v_usuario';

DROP VIEW IF EXISTS selemti.v_rol CASCADE;
RAISE NOTICE '✓ Dropped: v_rol';

RAISE NOTICE '';

-- ============================================================================
-- PASO 2: REVERTIR FKs A usuario (desde users)
-- ============================================================================

RAISE NOTICE '=== Revirtiendo FKs a tabla usuario ===';

-- Drop FKs nuevas que apuntan a users
ALTER TABLE selemti.merma DROP CONSTRAINT IF EXISTS merma_user_id_fkey;
ALTER TABLE selemti.op_cab DROP CONSTRAINT IF EXISTS op_cab_user_abre_fkey;
ALTER TABLE selemti.op_cab DROP CONSTRAINT IF EXISTS op_cab_user_cierra_fkey;
ALTER TABLE selemti.recepcion_cab DROP CONSTRAINT IF EXISTS recepcion_cab_user_id_fkey;
ALTER TABLE selemti.traspaso_cab DROP CONSTRAINT IF EXISTS traspaso_cab_user_id_fkey;

RAISE NOTICE '✓ Dropped FKs nuevas a users';

-- Restaurar FKs antiguas a usuario (si la tabla existe)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'selemti' AND table_name = 'usuario') THEN

        ALTER TABLE selemti.merma
            ADD CONSTRAINT merma_usuario_id_fkey
            FOREIGN KEY (usuario_id) REFERENCES selemti.usuario(id);

        ALTER TABLE selemti.op_cab
            ADD CONSTRAINT op_cab_usuario_abre_fkey
            FOREIGN KEY (usuario_abre) REFERENCES selemti.usuario(id);

        ALTER TABLE selemti.op_cab
            ADD CONSTRAINT op_cab_usuario_cierra_fkey
            FOREIGN KEY (usuario_cierra) REFERENCES selemti.usuario(id);

        ALTER TABLE selemti.recepcion_cab
            ADD CONSTRAINT recepcion_cab_usuario_id_fkey
            FOREIGN KEY (usuario_id) REFERENCES selemti.usuario(id);

        ALTER TABLE selemti.traspaso_cab
            ADD CONSTRAINT traspaso_cab_usuario_id_fkey
            FOREIGN KEY (usuario_id) REFERENCES selemti.usuario(id);

        RAISE NOTICE '✓ Restored FKs antiguas a usuario';
    ELSE
        RAISE WARNING '⚠️  Tabla usuario no existe - no se pueden restaurar FKs';
    END IF;
END $$;

RAISE NOTICE '';

-- ============================================================================
-- PASO 3: REVERTIR TIPO users.id (BIGINT → INTEGER)
-- ============================================================================

RAISE NOTICE '=== Revirtiendo users.id a INTEGER ===';

-- Drop FKs temporalmente
DO $$
DECLARE
    fk_record RECORD;
BEGIN
    FOR fk_record IN
        SELECT tc.constraint_name, tc.table_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND ccu.table_name = 'users'
          AND tc.table_schema = 'selemti'
    LOOP
        EXECUTE format('ALTER TABLE selemti.%I DROP CONSTRAINT IF EXISTS %I',
            fk_record.table_name, fk_record.constraint_name);
    END LOOP;
END $$;

RAISE NOTICE '✓ Dropped FKs temporalmente';

-- Revertir tipo
ALTER TABLE selemti.users
    ALTER COLUMN id TYPE INTEGER;

RAISE NOTICE '✓ users.id revertido a INTEGER';

-- Revertir tipos de FK columns
ALTER TABLE selemti.cash_fund_movement_audit_log
    ALTER COLUMN changed_by_user_id TYPE INTEGER;

ALTER TABLE selemti.purchase_suggestions
    ALTER COLUMN sugerido_por_user_id TYPE INTEGER;

ALTER TABLE selemti.purchase_suggestions
    ALTER COLUMN revisado_por_user_id TYPE INTEGER;

RAISE NOTICE '✓ FK columns revertidas a INTEGER';

-- Re-crear FKs con tipo original
ALTER TABLE selemti.audit_log
    ADD CONSTRAINT selemti_audit_log_user_id_foreign
    FOREIGN KEY (user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;

ALTER TABLE selemti.cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_created_by_user_id_foreign
    FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign
    FOREIGN KEY (changed_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_created_by_user_id_foreign
    FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_approved_by_user_id_foreign
    FOREIGN KEY (approved_by_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;

ALTER TABLE selemti.cash_funds
    ADD CONSTRAINT cash_funds_created_by_user_id_foreign
    FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.cash_funds
    ADD CONSTRAINT cash_funds_responsable_user_id_foreign
    FOREIGN KEY (responsable_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_sugerido
    FOREIGN KEY (sugerido_por_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;

ALTER TABLE selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_revisado
    FOREIGN KEY (revisado_por_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;

RAISE NOTICE '✓ FKs re-creadas';
RAISE NOTICE '';

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

RAISE NOTICE '=== Verificación final ===';

DO $$
DECLARE
    users_id_type TEXT;
BEGIN
    SELECT data_type INTO users_id_type
    FROM information_schema.columns
    WHERE table_schema = 'selemti'
      AND table_name = 'users'
      AND column_name = 'id';

    RAISE NOTICE 'users.id tipo: %', users_id_type;

    IF users_id_type = 'integer' THEN
        RAISE NOTICE '✅ Rollback exitoso: users.id es INTEGER';
    ELSE
        RAISE WARNING '⚠️  Rollback incompleto: users.id es %', users_id_type;
    END IF;
END $$;

RAISE NOTICE '';
RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
RAISE NOTICE '║              ROLLBACK COMPLETADO                              ║';
RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
RAISE NOTICE '';
RAISE NOTICE 'Estado restaurado a pre-Phase 2.1';
RAISE NOTICE 'Fecha: ' || NOW()::TEXT;
RAISE NOTICE '';

COMMIT;
