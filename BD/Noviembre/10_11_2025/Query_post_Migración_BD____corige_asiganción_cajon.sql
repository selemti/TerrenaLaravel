-- =====================================================
-- Script para solucionar problema con drawer_assigned_history
-- Problema identificado: El trigger fn_dah_after_insert falla porque
-- no encuentra terminales asignados a los usuarios
-- =====================================================

-- 1. DESACTIVAR TEMPORALMENTE EL TRIGGER
-- Este trigger está causando el error al intentar asignar cajón
ALTER TABLE drawer_assigned_history DISABLE TRIGGER trg_selemti_dah_ai;

-- 2. VERIFICAR USUARIOS EXISTENTES
-- Primero veamos qué usuarios están intentando usar el cajón
SELECT DISTINCT a_user, COUNT(*) as operaciones
FROM drawer_assigned_history
GROUP BY a_user
ORDER BY a_user;

-- 3. VERIFICAR TERMINALES Y SUS ASIGNACIONES ACTUALES
SELECT id, name, location, assigned_user,
       CASE 
         WHEN assigned_user IS NULL THEN 'Sin asignar'
         ELSE 'Usuario ' || assigned_user::text
       END as asignacion
FROM terminal
ORDER BY id;

-- 4. ASIGNAR USUARIOS A TERMINALES
-- Basado en los datos del dump, necesitamos asignar usuarios a terminales
-- Los usuarios más frecuentes en drawer_assigned_history son: 1, 6, 7, 8, 11, 12, 14

-- Opción A: Asignación manual específica (RECOMENDADO)
-- Ajusta estos valores según tu configuración real
UPDATE terminal SET assigned_user = 1 WHERE id = 101;   -- Terminal Principal 1
UPDATE terminal SET assigned_user = 6 WHERE id = 102;   -- Terminal Principal 2  
UPDATE terminal SET assigned_user = 7 WHERE id = 201;   -- Terminal NB
UPDATE terminal SET assigned_user = 8 WHERE id = 301;   -- Terminal NB 2
UPDATE terminal SET assigned_user = 11 WHERE id = 401;  -- Terminal ENTRADA
UPDATE terminal SET assigned_user = 12 WHERE id = 1090; -- Terminal TORRE
UPDATE terminal SET assigned_user = 14 WHERE id = 1091; -- Terminal 1091

-- Opción B: Asignación automática rotativa (USAR SOLO SI NO TIENES CONFIGURACIÓN ESPECÍFICA)
-- Descomenta las siguientes líneas si prefieres una asignación automática
/*
DO $$
DECLARE
    v_terminals CURSOR FOR SELECT id FROM terminal WHERE id != 9939 ORDER BY id;
    v_users INTEGER[] := ARRAY[1,6,7,8,11,12,14];
    v_idx INTEGER := 1;
    v_term_id INTEGER;
BEGIN
    FOR v_term_id IN SELECT id FROM terminal WHERE id != 9939 ORDER BY id LOOP
        UPDATE terminal 
        SET assigned_user = v_users[v_idx] 
        WHERE id = v_term_id;
        
        v_idx := v_idx + 1;
        IF v_idx > array_length(v_users, 1) THEN
            v_idx := 1;
        END IF;
    END LOOP;
END $$;
*/

-- 5. VERIFICAR LA ASIGNACIÓN
SELECT id, name, location, assigned_user 
FROM terminal 
ORDER BY id;

-- 6. CREAR UNA VERSIÓN MEJORADA DEL TRIGGER (OPCIONAL)
-- Esta versión maneja mejor los casos donde no hay terminal asignado
CREATE OR REPLACE FUNCTION selemti.fn_dah_after_insert_safe() 
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE 
    v_term RECORD;
BEGIN
    IF NEW.operation = 'ASIGNAR' THEN
        -- Buscar terminal asignado al usuario
        SELECT * INTO v_term FROM public.terminal
        WHERE assigned_user = NEW.a_user
        ORDER BY id LIMIT 1;
        
        -- Si no hay terminal asignado, buscar uno libre y asignarlo
        IF v_term IS NULL THEN
            SELECT * INTO v_term FROM public.terminal
            WHERE assigned_user IS NULL
            AND has_cash_drawer = true
            ORDER BY id LIMIT 1;
            
            IF v_term IS NOT NULL THEN
                -- Asignar el terminal libre al usuario
                UPDATE public.terminal 
                SET assigned_user = NEW.a_user 
                WHERE id = v_term.id;
                
                -- Log de asignación automática
                INSERT INTO selemti.auditoria(quien, que, payload)
                VALUES(NEW.a_user, 'TERMINAL_ASIGNADO_AUTOMATICAMENTE',
                       jsonb_build_object('terminal_id', v_term.id, 
                                        'dah_id', NEW.id, 
                                        'operation', NEW.operation, 
                                        'time', NEW."time"));
            ELSE
                -- No hay terminales disponibles, solo registrar en auditoría
                INSERT INTO selemti.auditoria(quien, que, payload)
                VALUES(NEW.a_user, 'NO_HAY_TERMINAL_DISPONIBLE',
                       jsonb_build_object('dah_id', NEW.id, 
                                        'operation', NEW.operation, 
                                        'time', NEW."time"));
                RETURN NEW;
            END IF;
        END IF;
        
        -- Insertar en sesión cajón
        INSERT INTO selemti.sesion_cajon(
            terminal_id, terminal_nombre, sucursal, cajero_usuario_id,
            apertura_ts, estatus, opening_float, dah_evento_id
        ) VALUES (
            v_term.id, 
            COALESCE(v_term.name, 'Terminal '||v_term.id), 
            COALESCE(v_term.location, ''),
            NEW.a_user, 
            COALESCE(NEW."time", now()), 
            'ACTIVA', 
            COALESCE(v_term.current_balance, 0), 
            NEW.id
        ) ON CONFLICT DO NOTHING; -- Evitar duplicados
        
    ELSIF NEW.operation = 'CERRAR' THEN
        SELECT * INTO v_term FROM public.terminal
        WHERE assigned_user = NEW.a_user
        ORDER BY id LIMIT 1;
        
        IF v_term IS NOT NULL THEN
            UPDATE selemti.sesion_cajon
            SET cierre_ts = COALESCE(NEW."time", now()),
                estatus = 'LISTO_PARA_CORTE',
                closing_float = COALESCE(v_term.current_balance, 0),
                dah_evento_id = COALESCE(dah_evento_id, NEW.id)
            WHERE terminal_id = v_term.id
              AND cajero_usuario_id = NEW.a_user
              AND cierre_ts IS NULL;
              
            -- Opcionalmente liberar el terminal
            -- UPDATE public.terminal SET assigned_user = NULL WHERE id = v_term.id;
        END IF;
    END IF;
    
    RETURN NEW;
END $$;

-- 7. REACTIVAR EL TRIGGER (con la función original o la mejorada)

-- Opción A: Usar la función original (si ya resolviste las asignaciones)
ALTER TABLE drawer_assigned_history ENABLE TRIGGER trg_selemti_dah_ai;

-- Opción B: Usar la función mejorada (descomentar si creaste la función safe)
-- DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON drawer_assigned_history;
-- CREATE TRIGGER trg_selemti_dah_ai_safe 
-- AFTER INSERT ON drawer_assigned_history 
-- FOR EACH ROW 
-- EXECUTE FUNCTION selemti.fn_dah_after_insert_safe();

-- 8. PROBAR LA ASIGNACIÓN DE CAJÓN
-- Intenta asignar un cajón para verificar que funciona
-- INSERT INTO drawer_assigned_history (time, operation, a_user) 
-- VALUES (now(), 'ASIGNAR', 1);

-- 9. VERIFICAR SESIONES DE CAJÓN ACTIVAS
SELECT 
    sc.id,
    sc.terminal_id,
    t.name as terminal_name,
    sc.cajero_usuario_id,
    sc.apertura_ts,
    sc.cierre_ts,
    sc.estatus
FROM selemti.sesion_cajon sc
JOIN terminal t ON t.id = sc.terminal_id
WHERE sc.estatus = 'ACTIVA'
ORDER BY sc.apertura_ts DESC;

-- =====================================================
-- NOTAS IMPORTANTES:
-- 
-- 1. El problema principal es que los terminales no tienen usuarios asignados
--    (assigned_user = NULL en casi todos los registros)
-- 
-- 2. El trigger fn_dah_after_insert busca un terminal WHERE assigned_user = NEW.a_user
--    pero no encuentra ninguno, causando el error
--
-- 3. DEBES configurar qué usuario usa qué terminal según tu operación real
--
-- 4. Si prefieres asignación dinámica, usa la función fn_dah_after_insert_safe
--    que asigna automáticamente terminales libres
--
-- 5. Después de ejecutar este script, deberías poder asignar cajones sin error
-- =====================================================