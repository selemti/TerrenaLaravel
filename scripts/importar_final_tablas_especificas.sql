-- IMPORTACIÓN FINAL DE LAS 10 TABLAS SELEMTI ESPECIFICADAS
-- Desde producción al sistema local

SET client_encoding = 'UTF8';
SET CONSTRAINTS ALL DEFERRED;

-- LIMPIAR TABLAS ANTES DE IMPORTAR
SELECT '=== LIMPIANDO TABLAS A IMPORTAR ===' as info;

DELETE FROM selemti.precorte_efectivo;
DELETE FROM selemti.precorte_otros;
DELETE FROM selemti.precorte;
DELETE FROM selemti.postcorte;
DELETE FROM selemti.sesion_cajon;
DELETE FROM selemti.auditoria;

-- IMPORTAR TABLAS EN ORDEN CORRECTO
SELECT '' as salto;
SELECT '=== IMPORTANDO SESIONES (250) ===' as info;
\i './BD/Diciembre/08_12_2025/todas_sesiones_productivas.sql'

SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES (113) ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precortes_productivos.sql'

SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES OTROS (196) ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precortes_otros_productivos.sql'

SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES EFECTIVO (922) ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precorte_efectivo_productivos.sql'

SELECT '' as salto;
SELECT '=== IMPORTANDO POSTCORTE (91) ===' as info;
\i './BD/Diciembre/08_12_2025/todos_postcorte_productivos.sql'

SELECT '' as salto;
SELECT '=== IMPORTANDO AUDITORIA (262) ===' as info;
\i './BD/Diciembre/08_12_2025/todos_auditoria_productivos.sql'

-- VERIFICACIÓN FINAL
SELECT '' as salto;
SELECT '=== VERIFICACIÓN FINAL ===' as info;

SELECT 'Tabla' as nombre, COUNT(*) as cantidad FROM (
    SELECT 'sesion_cajon' as tabla, COUNT(*) as cantidad FROM selemti.sesion_cajon
    UNION ALL
    SELECT 'precorte' as tabla, COUNT(*) as cantidad FROM selemti.precorte
    UNION ALL
    SELECT 'precorte_otros' as tabla, COUNT(*) as cantidad FROM selemti.precorte_otros
    UNION ALL
    SELECT 'precorte_efectivo' as tabla, COUNT(*) as cantidad FROM selemti.precorte_efectivo
    UNION ALL
    SELECT 'postcorte' as tabla, COUNT(*) as cantidad FROM selemti.postcorte
    UNION ALL
    SELECT 'auditoria' as tabla, COUNT(*) as cantidad FROM selemti.auditoria
    UNION ALL
    SELECT 'migrations (local)' as tabla, COUNT(*) as cantidad FROM selemti.migrations
    UNION ALL
    SELECT 'sessions (local)' as tabla, COUNT(*) as cantidad FROM selemti.sessions
    UNION ALL
    SELECT 'role_has_permissions (local)' as tabla, COUNT(*) as cantidad FROM selemti.role_has_permissions
    UNION ALL
    SELECT 'personal_access_tokens (local)' as tabla, COUNT(*) as cantidad FROM selemti.personal_access_tokens
) as conteos
GROUP BY tabla, cantidad
ORDER BY nombre;

SELECT '' as salto;
SELECT 'IMPORTACIÓN FINAL DE TABLAS ESPECIFICAS COMPLETADA' as resultado;

-- VERIFICAR INTEGRIDAD DE REFERENCIAS
SELECT '' as salto;
SELECT '=== VERIFICANDO INTEGRIDAD DE REFERENCIAS ===' as info;

SELECT 'Precortes sin sesión válida:' as problema, COUNT(*) as cantidad
FROM selemti.precorte p
LEFT JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
WHERE s.id IS NULL;

SELECT 'Postcortes sin sesión válida:' as problema, COUNT(*) as cantidad
FROM selemti.postcorte p
LEFT JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
WHERE s.id IS NULL;