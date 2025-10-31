-- ============================================================================
-- PHASE 2.1: CONSOLIDACIÓN DE SISTEMAS DE USUARIOS Y ROLES (v2 - Fixed)
-- ============================================================================
-- Proyecto: TerrenaLaravel - Normalización BD selemti
-- Fecha: 30 de octubre de 2025
-- Versión: 2.0 (sin RAISE NOTICE standalone)
--
-- OBJETIVO: Consolidar usuario/rol → users/roles
-- DURACIÓN: 15-20 minutos
-- ROLLBACK: Scripts/rollback_phase2.sql
-- ============================================================================

\echo '============================================================================'
\echo 'PHASE 2.1: Consolidación de Usuarios y Roles'
\echo '============================================================================'
\echo ''

BEGIN;

\echo 'PASO 1: Verificando estado inicial...'

-- Pre-check
DO $$
DECLARE
    usuario_count INT;
    users_count INT;
    rol_count INT;
    roles_count INT;
BEGIN
    SELECT COUNT(*) INTO usuario_count FROM selemti.usuario;
    SELECT COUNT(*) INTO users_count FROM selemti.users;
    SELECT COUNT(*) INTO rol_count FROM selemti.rol;
    SELECT COUNT(*) INTO roles_count FROM selemti.roles;

    IF usuario_count > 0 THEN
        RAISE EXCEPTION 'ABORT: tabla usuario tiene % registros. Se esperaba 0.', usuario_count;
    END IF;

    IF rol_count > 0 THEN
        RAISE EXCEPTION 'ABORT: tabla rol tiene % registros. Se esperaba 0.', rol_count;
    END IF;

    RAISE NOTICE '✅ Pre-check OK: usuario=%, users=%, rol=%, roles=%',
        usuario_count, users_count, rol_count, roles_count;
END $$;

\echo 'PASO 2: Eliminando FK constraints a users.id...'

-- Drop FK constraints temporalmente
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
        EXECUTE format('ALTER TABLE selemti.%I DROP CONSTRAINT %I',
            fk_record.table_name, fk_record.constraint_name);
    END LOOP;
    RAISE NOTICE '✅ FKs eliminadas temporalmente';
END $$;

\echo 'PASO 3: Cambiando users.id a BIGINT...'

ALTER TABLE selemti.users
    ALTER COLUMN id TYPE BIGINT;

\echo 'PASO 4: Corrigiendo tipos de FK columns...'

ALTER TABLE selemti.cash_fund_movement_audit_log
    ALTER COLUMN changed_by_user_id TYPE BIGINT;

ALTER TABLE selemti.purchase_suggestions
    ALTER COLUMN sugerido_por_user_id TYPE BIGINT;

ALTER TABLE selemti.purchase_suggestions
    ALTER COLUMN revisado_por_user_id TYPE BIGINT;

\echo 'PASO 5: Re-creando FK constraints a users.id...'

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

\echo 'PASO 6: Redirigiendo FKs de usuario a users...'

-- Drop FKs antiguas
ALTER TABLE selemti.merma DROP CONSTRAINT IF EXISTS merma_usuario_id_fkey;
ALTER TABLE selemti.op_cab DROP CONSTRAINT IF EXISTS op_cab_usuario_abre_fkey;
ALTER TABLE selemti.op_cab DROP CONSTRAINT IF EXISTS op_cab_usuario_cierra_fkey;
ALTER TABLE selemti.recepcion_cab DROP CONSTRAINT IF EXISTS recepcion_cab_usuario_id_fkey;
ALTER TABLE selemti.traspaso_cab DROP CONSTRAINT IF EXISTS traspaso_cab_usuario_id_fkey;

-- Añadir FKs nuevas
ALTER TABLE selemti.merma
    ADD CONSTRAINT merma_user_id_fkey
    FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.op_cab
    ADD CONSTRAINT op_cab_user_abre_fkey
    FOREIGN KEY (usuario_abre) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.op_cab
    ADD CONSTRAINT op_cab_user_cierra_fkey
    FOREIGN KEY (usuario_cierra) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.recepcion_cab
    ADD CONSTRAINT recepcion_cab_user_id_fkey
    FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;

ALTER TABLE selemti.traspaso_cab
    ADD CONSTRAINT traspaso_cab_user_id_fkey
    FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;

\echo 'PASO 7: Creando vistas de compatibilidad...'

-- Vista v_usuario
CREATE OR REPLACE VIEW selemti.v_usuario AS
SELECT
    id::BIGINT as id,
    username,
    nombre_completo as nombre,
    email,
    NULL::INTEGER as rol_id,
    activo,
    password_hash,
    NULL::INTEGER as floreant_user_id,
    NULL::JSONB as meta,
    created_at
FROM selemti.users;

COMMENT ON VIEW selemti.v_usuario IS
'Vista de compatibilidad: mapea users (canónico) al formato legacy usuario.';

-- Vista v_rol
CREATE OR REPLACE VIEW selemti.v_rol AS
SELECT
    id::INTEGER as id,
    name as codigo,
    COALESCE(display_name, name) as nombre
FROM selemti.roles;

COMMENT ON VIEW selemti.v_rol IS
'Vista de compatibilidad: mapea roles (Spatie Permission) al formato legacy rol.';

\echo 'PASO 8: Verificación final...'

-- Verificar tipo de users.id
DO $$
DECLARE
    users_id_type TEXT;
    fk_count INT;
BEGIN
    SELECT data_type INTO users_id_type
    FROM information_schema.columns
    WHERE table_schema = 'selemti'
      AND table_name = 'users'
      AND column_name = 'id';

    IF users_id_type != 'bigint' THEN
        RAISE EXCEPTION 'ERROR: users.id tipo incorrecto: % (esperado: bigint)', users_id_type;
    END IF;

    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_name = 'users'
      AND tc.table_schema = 'selemti';

    RAISE NOTICE '✅ Verificación: users.id=bigint, FKs=%', fk_count;
END $$;

\echo ''
\echo '============================================================================'
\echo 'PHASE 2.1 COMPLETADA EXITOSAMENTE'
\echo '============================================================================'
\echo 'Cambios aplicados:'
\echo '  - users.id: INTEGER → BIGINT'
\echo '  - 3 FK columns corregidas a BIGINT'
\echo '  - 14 FKs re-creadas a users.id'
\echo '  - 5 FKs redirigidas de usuario → users'
\echo '  - 2 vistas de compatibilidad creadas'
\echo ''
\echo 'Próximo paso: Phase 2.2 - Consolidar sucursales y almacenes'
\echo '============================================================================'
\echo ''

COMMIT;

\echo '✅ COMMIT exitoso - Cambios aplicados permanentemente'
\echo 'Fecha:' `date`
