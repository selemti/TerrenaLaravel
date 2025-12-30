-- Corregir usuarios faltantes para habilitar sincronización
-- Crear usuarios que existen en public.users pero no en selemti.users

-- 1. Insertar usuarios faltantes en selemti.users
INSERT INTO selemti.users (id, name, email, password, email_verified_at, created_at, updated_at) VALUES
(6, 'Jose Eumir', 'usuario6@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(7, 'Aldo Abraham', 'usuario7@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(8, 'Jose Huesca', 'usuario8@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(9, 'Isabella Fernández', 'usuario9@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(10, 'Alexis Manuel', 'usuario10@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(11, 'Juan David Marinez', 'usuario11@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(12, 'Luis Ronaldo', 'usuario12@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(13, 'Yair Zarate', 'usuario13@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(14, 'Alejandro Fernández', 'usuario14@selemti.com', '$2y$10$placeholder', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- 2. Asignar roles básicos a los usuarios nuevos
INSERT INTO selemti.role_has_permissions (role_id, permission_id)
SELECT
    2, -- Role básico/usuario normal
    p.id
FROM selemti.permissions p
WHERE p.name IN ('caja.view', 'reports.view', 'inventory.view')
  AND NOT EXISTS (
    SELECT 1 FROM selemti.role_has_permissions rhp
    WHERE rhp.role_id = 2 AND rhp.permission_id = p.id
)
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 3. Verificar que ahora todos los usuarios estén mapeados
SELECT 'Verificación de mapeo completo:' as info;
SELECT
    pu.auto_id,
    pu.first_name,
    CASE WHEN su.id IS NOT NULL THEN '✅ Existe en selemti.users' ELSE '❌ Faltante' END as status_selemti,
    su.id as selemti_id
FROM public.users pu
LEFT JOIN selemti.users su ON pu.auto_id = su.id
WHERE pu.active = true
ORDER BY pu.auto_id;

-- 4. Verificar terminales asignadas
SELECT 'Terminales con usuarios asignados:' as info;
SELECT
    t.id,
    t.name as terminal_name,
    t.assigned_user,
    pu.first_name as assigned_user_name,
    CASE WHEN su.id IS NOT NULL THEN '✅' ELSE '❌' END as sincronizacion_ok
FROM public.terminal t
LEFT JOIN public.users pu ON t.assigned_user = pu.auto_id
LEFT JOIN selemti.users su ON pu.auto_id = su.id
WHERE t.active = true
ORDER BY t.id;

SELECT 'USUARIOS CORREGIDOS - Listo para reactivar trigger' as resultado;