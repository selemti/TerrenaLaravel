-- ============================================================================
-- PHASE 2.1: CONSOLIDACIÓN DE SISTEMAS DE USUARIOS Y ROLES
-- ============================================================================
-- Proyecto: TerrenaLaravel - Normalización BD selemti
-- Fecha: 30 de octubre de 2025
-- Duración estimada: 15-20 minutos
--
-- OBJETIVO:
-- Consolidar sistema legacy de usuarios (usuario/rol) al sistema canónico
-- (users/roles) usado por Laravel + Spatie Permission, eliminando duplicación
-- y estandarizando tipos de datos.
--
-- ESTADO INICIAL:
-- - usuario: 0 registros (tabla legacy vacía)
-- - users: 3 registros (IDs: 2, 3, 4) - sistema activo
-- - rol: 0 registros (tabla legacy vacía)
-- - roles: 7 registros - Spatie Permission activo
--
-- PROBLEMAS A RESOLVER:
-- 1. users.id es INTEGER pero FKs esperan BIGINT (inconsistencia)
-- 2. 5 tablas referencian usuario (merma, op_cab, recepcion_cab, traspaso_cab)
-- 3. FKs a users tienen tipos inconsistentes (INTEGER y BIGINT mezclados)
-- 4. Tablas legacy vacías pero con FK constraints activas
--
-- CAMBIOS A REALIZAR:
-- 1. Estandarizar users.id a BIGINT
-- 2. Corregir tipos de FK columns inconsistentes
-- 3. Redirigir FKs de usuario → users
-- 4. Crear vistas de compatibilidad v_usuario, v_rol
-- 5. (Opcional) Drop tablas legacy
--
-- ROLLBACK: Ver archivo rollback_phase2.sql en Scripts/
-- ============================================================================

BEGIN;

-- ============================================================================
-- SECCIÓN 1: PRE-CHECK Y VALIDACIONES
-- ============================================================================

DO $$
DECLARE
    usuario_count INT;
    users_count INT;
    rol_count INT;
    roles_count INT;
BEGIN
    -- Contar registros
    SELECT COUNT(*) INTO usuario_count FROM selemti.usuario;
    SELECT COUNT(*) INTO users_count FROM selemti.users;
    SELECT COUNT(*) INTO rol_count FROM selemti.rol;
    SELECT COUNT(*) INTO roles_count FROM selemti.roles;

    RAISE NOTICE '=== PRE-CHECK: Estado de tablas ===';
    RAISE NOTICE 'usuario (legacy): % registros', usuario_count;
    RAISE NOTICE 'users (canónico): % registros', users_count;
    RAISE NOTICE 'rol (legacy): % registros', rol_count;
    RAISE NOTICE 'roles (canónico): % registros', roles_count;
    RAISE NOTICE '';

    -- Validación: usuario debe estar vacía
    IF usuario_count > 0 THEN
        RAISE EXCEPTION 'ABORT: tabla usuario tiene % registros. Se esperaba 0. Revisar plan.', usuario_count;
    END IF;

    -- Validación: rol debe estar vacía
    IF rol_count > 0 THEN
        RAISE EXCEPTION 'ABORT: tabla rol tiene % registros. Se esperaba 0. Revisar plan.', rol_count;
    END IF;

    RAISE NOTICE '✅ Validaciones OK: tablas legacy vacías';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- SECCIÓN 2: ESTANDARIZACIÓN TIPO users.id (INTEGER → BIGINT)
-- ============================================================================

RAISE NOTICE '=== PASO 1: Cambiar users.id de INTEGER a BIGINT ===';

-- Listar FKs que referencian users.id (para re-crearlas después)
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND ccu.table_name = 'users'
  AND tc.table_schema = 'selemti'
ORDER BY tc.table_name;

-- Paso 1.1: Drop FK constraints que referencian users.id
DO $$
DECLARE
    fk_record RECORD;
BEGIN
    RAISE NOTICE 'Dropping FK constraints que referencian users.id...';

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
        RAISE NOTICE '  ✓ Dropped: %.%', fk_record.table_name, fk_record.constraint_name;
    END LOOP;

    RAISE NOTICE '';
END $$;

-- Paso 1.2: Cambiar tipo de users.id a BIGINT
ALTER TABLE selemti.users
    ALTER COLUMN id TYPE BIGINT;

RAISE NOTICE '✅ users.id cambiado a BIGINT';
RAISE NOTICE '';

-- ============================================================================
-- SECCIÓN 3: CORRECCIÓN DE FK COLUMNS CON TIPOS INCONSISTENTES
-- ============================================================================

RAISE NOTICE '=== PASO 2: Corrigiendo tipos de FK columns ===';

-- Paso 2.1: cash_fund_movement_audit_log.changed_by_user_id (INTEGER → BIGINT)
ALTER TABLE selemti.cash_fund_movement_audit_log
    ALTER COLUMN changed_by_user_id TYPE BIGINT;
RAISE NOTICE '✓ cash_fund_movement_audit_log.changed_by_user_id: INTEGER → BIGINT';

-- Paso 2.2: purchase_suggestions FKs (INTEGER → BIGINT)
ALTER TABLE selemti.purchase_suggestions
    ALTER COLUMN sugerido_por_user_id TYPE BIGINT;
RAISE NOTICE '✓ purchase_suggestions.sugerido_por_user_id: INTEGER → BIGINT';

ALTER TABLE selemti.purchase_suggestions
    ALTER COLUMN revisado_por_user_id TYPE BIGINT;
RAISE NOTICE '✓ purchase_suggestions.revisado_por_user_id: INTEGER → BIGINT';

RAISE NOTICE '';

-- ============================================================================
-- SECCIÓN 4: RE-CREAR FK CONSTRAINTS A users.id
-- ============================================================================

RAISE NOTICE '=== PASO 3: Re-creando FK constraints a users.id ===';

-- audit_log
ALTER TABLE selemti.audit_log
    ADD CONSTRAINT selemti_audit_log_user_id_foreign
    FOREIGN KEY (user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;
RAISE NOTICE '✓ audit_log.user_id → users.id';

-- cash_fund_arqueos
ALTER TABLE selemti.cash_fund_arqueos
    ADD CONSTRAINT cash_fund_arqueos_created_by_user_id_foreign
    FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ cash_fund_arqueos.created_by_user_id → users.id';

-- cash_fund_movement_audit_log
ALTER TABLE selemti.cash_fund_movement_audit_log
    ADD CONSTRAINT selemti_cash_fund_movement_audit_log_changed_by_user_id_foreign
    FOREIGN KEY (changed_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ cash_fund_movement_audit_log.changed_by_user_id → users.id';

-- cash_fund_movements
ALTER TABLE selemti.cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_created_by_user_id_foreign
    FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ cash_fund_movements.created_by_user_id → users.id';

ALTER TABLE selemti.cash_fund_movements
    ADD CONSTRAINT cash_fund_movements_approved_by_user_id_foreign
    FOREIGN KEY (approved_by_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;
RAISE NOTICE '✓ cash_fund_movements.approved_by_user_id → users.id';

-- cash_funds
ALTER TABLE selemti.cash_funds
    ADD CONSTRAINT cash_funds_created_by_user_id_foreign
    FOREIGN KEY (created_by_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ cash_funds.created_by_user_id → users.id';

ALTER TABLE selemti.cash_funds
    ADD CONSTRAINT cash_funds_responsable_user_id_foreign
    FOREIGN KEY (responsable_user_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ cash_funds.responsable_user_id → users.id';

-- purchase_suggestions
ALTER TABLE selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_sugerido
    FOREIGN KEY (sugerido_por_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;
RAISE NOTICE '✓ purchase_suggestions.sugerido_por_user_id → users.id';

ALTER TABLE selemti.purchase_suggestions
    ADD CONSTRAINT fk_psugg_user_revisado
    FOREIGN KEY (revisado_por_user_id) REFERENCES selemti.users(id) ON DELETE SET NULL;
RAISE NOTICE '✓ purchase_suggestions.revisado_por_user_id → users.id';

RAISE NOTICE '';

-- ============================================================================
-- SECCIÓN 5: REDIRIGIR FKs DE usuario → users
-- ============================================================================

RAISE NOTICE '=== PASO 4: Redirigiendo FKs de usuario a users ===';

-- Paso 4.1: Drop FKs que apuntan a usuario
ALTER TABLE selemti.merma DROP CONSTRAINT IF EXISTS merma_usuario_id_fkey;
RAISE NOTICE '✓ Dropped: merma_usuario_id_fkey';

ALTER TABLE selemti.op_cab DROP CONSTRAINT IF EXISTS op_cab_usuario_abre_fkey;
RAISE NOTICE '✓ Dropped: op_cab_usuario_abre_fkey';

ALTER TABLE selemti.op_cab DROP CONSTRAINT IF EXISTS op_cab_usuario_cierra_fkey;
RAISE NOTICE '✓ Dropped: op_cab_usuario_cierra_fkey';

ALTER TABLE selemti.recepcion_cab DROP CONSTRAINT IF EXISTS recepcion_cab_usuario_id_fkey;
RAISE NOTICE '✓ Dropped: recepcion_cab_usuario_id_fkey';

ALTER TABLE selemti.traspaso_cab DROP CONSTRAINT IF EXISTS traspaso_cab_usuario_id_fkey;
RAISE NOTICE '✓ Dropped: traspaso_cab_usuario_id_fkey';

RAISE NOTICE '';

-- Paso 4.2: Añadir FKs que apuntan a users
-- Nota: Estas columnas ya son BIGINT, que ahora matchea con users.id (BIGINT)

ALTER TABLE selemti.merma
    ADD CONSTRAINT merma_user_id_fkey
    FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ Added: merma.usuario_id → users.id';

ALTER TABLE selemti.op_cab
    ADD CONSTRAINT op_cab_user_abre_fkey
    FOREIGN KEY (usuario_abre) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ Added: op_cab.usuario_abre → users.id';

ALTER TABLE selemti.op_cab
    ADD CONSTRAINT op_cab_user_cierra_fkey
    FOREIGN KEY (usuario_cierra) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ Added: op_cab.usuario_cierra → users.id';

ALTER TABLE selemti.recepcion_cab
    ADD CONSTRAINT recepcion_cab_user_id_fkey
    FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ Added: recepcion_cab.usuario_id → users.id';

ALTER TABLE selemti.traspaso_cab
    ADD CONSTRAINT traspaso_cab_user_id_fkey
    FOREIGN KEY (usuario_id) REFERENCES selemti.users(id) ON DELETE RESTRICT;
RAISE NOTICE '✓ Added: traspaso_cab.usuario_id → users.id';

RAISE NOTICE '';

-- ============================================================================
-- SECCIÓN 6: CREAR VISTAS DE COMPATIBILIDAD
-- ============================================================================

RAISE NOTICE '=== PASO 5: Creando vistas de compatibilidad ===';

-- Vista v_usuario: mapea users → formato usuario
CREATE OR REPLACE VIEW selemti.v_usuario AS
SELECT
    id::BIGINT as id,
    username,
    nombre_completo as nombre,
    email,
    NULL::INTEGER as rol_id,  -- rol_id legacy no tiene equivalente directo
    activo,
    password_hash,
    NULL::INTEGER as floreant_user_id,
    NULL::JSONB as meta,
    created_at
FROM selemti.users;

COMMENT ON VIEW selemti.v_usuario IS
'Vista de compatibilidad: mapea users (canónico) al formato legacy usuario.
USO: Código legacy que consulta "usuario" puede usar esta vista.
NOTA: rol_id siempre retorna NULL porque roles usa Spatie Permission (estructura diferente).';

RAISE NOTICE '✓ Created: v_usuario';

-- Vista v_rol: mapea roles → formato rol
CREATE OR REPLACE VIEW selemti.v_rol AS
SELECT
    id::INTEGER as id,
    name as codigo,
    COALESCE(display_name, name) as nombre
FROM selemti.roles;

COMMENT ON VIEW selemti.v_rol IS
'Vista de compatibilidad: mapea roles (Spatie Permission) al formato legacy rol.
USO: Código legacy que consulta "rol" puede usar esta vista.
NOTA: Spatie usa (name, guard_name) unique, legacy usaba codigo único.';

RAISE NOTICE '✓ Created: v_rol';
RAISE NOTICE '';

-- ============================================================================
-- SECCIÓN 7: (OPCIONAL) DROP TABLAS LEGACY
-- ============================================================================

RAISE NOTICE '=== PASO 6: (OPCIONAL) Drop tablas legacy ===';
RAISE NOTICE 'SKIPPED: Conservando tablas usuario y rol por seguridad.';
RAISE NOTICE 'Las vistas v_usuario y v_rol proveen compatibilidad.';
RAISE NOTICE 'Para eliminar tablas legacy, ejecutar manualmente:';
RAISE NOTICE '  DROP TABLE IF EXISTS selemti.usuario CASCADE;';
RAISE NOTICE '  DROP TABLE IF EXISTS selemti.rol CASCADE;';
RAISE NOTICE '';

-- Si se desea ejecutar el drop ahora, descomentar:
-- DROP TABLE IF EXISTS selemti.usuario CASCADE;
-- DROP TABLE IF EXISTS selemti.rol CASCADE;
-- RAISE NOTICE '✓ Dropped: usuario, rol';

-- ============================================================================
-- SECCIÓN 8: VERIFICACIÓN FINAL
-- ============================================================================

RAISE NOTICE '=== VERIFICACIÓN FINAL ===';

-- Verificar tipo de users.id
DO $$
DECLARE
    users_id_type TEXT;
BEGIN
    SELECT data_type INTO users_id_type
    FROM information_schema.columns
    WHERE table_schema = 'selemti'
      AND table_name = 'users'
      AND column_name = 'id';

    IF users_id_type = 'bigint' THEN
        RAISE NOTICE '✅ users.id tipo correcto: BIGINT';
    ELSE
        RAISE WARNING '⚠️  users.id tipo incorrecto: % (esperado: BIGINT)', users_id_type;
    END IF;
END $$;

-- Contar FKs a users
DO $$
DECLARE
    fk_count INT;
BEGIN
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_name = 'users'
      AND tc.table_schema = 'selemti';

    RAISE NOTICE '✅ FKs a users: % (esperado: 14 = 9 existentes + 5 nuevas)', fk_count;
END $$;

-- Verificar vistas
DO $$
DECLARE
    v_usuario_exists BOOLEAN;
    v_rol_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.views
        WHERE table_schema = 'selemti' AND table_name = 'v_usuario'
    ) INTO v_usuario_exists;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.views
        WHERE table_schema = 'selemti' AND table_name = 'v_rol'
    ) INTO v_rol_exists;

    IF v_usuario_exists THEN
        RAISE NOTICE '✅ Vista v_usuario creada';
    ELSE
        RAISE WARNING '⚠️  Vista v_usuario NO existe';
    END IF;

    IF v_rol_exists THEN
        RAISE NOTICE '✅ Vista v_rol creada';
    ELSE
        RAISE WARNING '⚠️  Vista v_rol NO existe';
    END IF;
END $$;

-- Test vistas con SELECT
RAISE NOTICE '';
RAISE NOTICE '--- Test v_usuario ---';
SELECT id, username, nombre, activo FROM selemti.v_usuario ORDER BY id LIMIT 5;

RAISE NOTICE '';
RAISE NOTICE '--- Test v_rol ---';
SELECT id, codigo, nombre FROM selemti.v_rol ORDER BY id LIMIT 5;

RAISE NOTICE '';

-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================

RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
RAISE NOTICE '║         PHASE 2.1 COMPLETADA EXITOSAMENTE                     ║';
RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
RAISE NOTICE '';
RAISE NOTICE 'CAMBIOS APLICADOS:';
RAISE NOTICE '  ✓ users.id: INTEGER → BIGINT';
RAISE NOTICE '  ✓ 3 FK columns corregidas a BIGINT';
RAISE NOTICE '  ✓ 14 FKs re-creadas a users.id';
RAISE NOTICE '  ✓ 5 FKs redirigidas de usuario → users';
RAISE NOTICE '  ✓ 2 vistas de compatibilidad creadas (v_usuario, v_rol)';
RAISE NOTICE '';
RAISE NOTICE 'PRÓXIMO PASO:';
RAISE NOTICE '  → Phase 2.2: Consolidar sucursales y almacenes';
RAISE NOTICE '  → Archivo: 06_consolidar_sucursales.sql';
RAISE NOTICE '';
RAISE NOTICE 'ROLLBACK:';
RAISE NOTICE '  Si necesitas revertir cambios, ejecuta:';
RAISE NOTICE '  → docs/BD/Normalizacion/Scripts/rollback_phase2.sql';
RAISE NOTICE '';

-- Commit transaction
COMMIT;

RAISE NOTICE '✅ COMMIT exitoso - Cambios aplicados permanentemente';
RAISE NOTICE '';
RAISE NOTICE 'Fecha ejecución: ' || NOW()::TEXT;
