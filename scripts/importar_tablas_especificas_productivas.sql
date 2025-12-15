-- IMPORTAR SOLAMENTE LAS 10 TABLAS SELEMTI ESPECIFICADAS
-- Preservando todo lo demás del esquema actual

SET client_encoding = 'UTF8';
SET CONSTRAINTS ALL DEFERRED;

-- LIMPIAR TABLAS ESPECIFICAS ANTES DE IMPORTAR
SELECT '=== LIMPIANDO TABLAS A IMPORTAR ===' as info;

DELETE FROM selemti.precorte_efectivo;
DELETE FROM selemti.precorte_otros;
DELETE FROM selemti.precorte;
DELETE FROM selemti.postcorte;
DELETE FROM selemti.sesion_cajon;
DELETE FROM selemti.auditoria;

-- MANTENER tablas locales: migrations, personal_access_tokens, role_has_permissions, sessions

-- IMPORTAR TABLAS EN ORDEN CORRECTO (sin dependencias)
SELECT '' as salto;
SELECT '=== IMPORTANDO SESIONES (250) ===' as info;
\i './BD/Diciembre/08_12_2025/todas_sesiones_productivas.sql'

SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES (113) ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precortes_productivos.sql'

SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES OTROS (196) ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precortes_otros_productivos.sql'

-- IMPORTAR PRECORTE EFECTIVO (desde dump principal - no extraído aún)
SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES EFECTIVO (922) ===' as info;

-- IMPORTAR POSTCORTE (desde dump principal - no extraído aún)
SELECT '' as salto;
SELECT '=== IMPORTANDO POSTCORTE (91) ===' as info;

-- IMPORTAR AUDITORIA (desde dump principal - no extraído aún)
SELECT '' as salto;
SELECT '=== IMPORTANDO AUDITORIA (262) ===' as info;

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
    SELECT 'migrations' as tabla, COUNT(*) as cantidad FROM selemti.migrations
    UNION ALL
    SELECT 'sessions' as tabla, COUNT(*) as cantidad FROM selemti.sessions
    UNION ALL
    SELECT 'role_has_permissions' as tabla, COUNT(*) as cantidad FROM selemti.role_has_permissions
    UNION ALL
    SELECT 'personal_access_tokens' as tabla, COUNT(*) as cantidad FROM selemti.personal_access_tokens
) as conteos
GROUP BY tabla, cantidad
ORDER BY nombre;

SELECT '' as salto;
SELECT 'IMPORTACIÓN DE TABLAS ESPECIFICAS COMPLETADA' as resultado;