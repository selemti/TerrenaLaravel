-- IMPORTACIÓN FINAL CON ARCHIVOS LIMPIOS
-- Importar las 10 tablas específicas de producción

SET client_encoding = 'UTF8';

-- LIMPIAR TABLAS ANTES DE IMPORTAR
SELECT '=== LIMPIANDO TABLAS ===' as info;

DELETE FROM selemti.precorte_efectivo;
DELETE FROM selemti.precorte_otros;
DELETE FROM selemti.precorte;
DELETE FROM selemti.postcorte;
DELETE FROM selemti.sesion_cajon;
DELETE FROM selemti.auditoria;

-- IMPORTAR EN ORDEN CORRECTO
SELECT '' as separador;
SELECT '=== IMPORTANDO SESIONES (264) ===' as info;
\i './BD/Diciembre/08_12_2025/sesiones_limpias.sql'

SELECT '' as separador;
SELECT '=== IMPORTANDO PRECORTES (1344) ===' as info;
\i './BD/Diciembre/08_12_2025/precortes_limpios.sql'

SELECT '' as separador;
SELECT '=== IMPORTANDO PRECORTES OTROS ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precortes_otros_productivos.sql'

SELECT '' as separador;
SELECT '=== IMPORTANDO PRECORTES EFECTIVO ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precorte_efectivo_productivos.sql'

SELECT '' as separador;
SELECT '=== IMPORTANDO POSTCORTE ===' as info;
\i './BD/Diciembre/08_12_2025/todos_postcorte_productivos.sql'

SELECT '' as separador;
SELECT '=== IMPORTANDO AUDITORIA ===' as info;
\i './BD/Diciembre/08_12_2025/todos_auditoria_productivos.sql'

-- VERIFICACIÓN FINAL
SELECT '' as separador;
SELECT '=== VERIFICACIÓN FINAL ===' as info;

SELECT
    'sesion_cajon' as tabla,
    COUNT(*) as cantidad,
    MIN(id) as min_id,
    MAX(id) as max_id
FROM selemti.sesion_cajon

UNION ALL

SELECT
    'precorte' as tabla,
    COUNT(*) as cantidad,
    MIN(id) as min_id,
    MAX(id) as max_id
FROM selemti.precorte

UNION ALL

SELECT
    'precorte_otros' as tabla,
    COUNT(*) as cantidad,
    MIN(id) as min_id,
    MAX(id) as max_id
FROM selemti.precorte_otros

UNION ALL

SELECT
    'precorte_efectivo' as tabla,
    COUNT(*) as cantidad,
    MIN(id) as min_id,
    MAX(id) as max_id
FROM selemti.precorte_efectivo

UNION ALL

SELECT
    'postcorte' as tabla,
    COUNT(*) as cantidad,
    MIN(id) as min_id,
    MAX(id) as max_id
FROM selemti.postcorte

UNION ALL

SELECT
    'auditoria' as tabla,
    COUNT(*) as cantidad,
    MIN(id) as min_id,
    MAX(id) as max_id
FROM selemti.auditoria

ORDER BY tabla;

-- VERIFICAR INTEGRIDAD
SELECT '' as separador;
SELECT '=== VERIFICANDO INTEGRIDAD ===' as info;

SELECT
    'Precortes sin sesión' as problema,
    COUNT(*) as cantidad
FROM selemti.precorte p
LEFT JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
WHERE s.id IS NULL

UNION ALL

SELECT
    'Postcortes sin sesión' as problema,
    COUNT(*) as cantidad
FROM selemti.postcorte p
LEFT JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
WHERE s.id IS NULL;

SELECT '' as separador;
SELECT 'IMPORTACIÓN FINAL COMPLETADA' as resultado;