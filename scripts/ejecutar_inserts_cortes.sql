-- EJECUTAR DIRECTAMENTE LOS INSERTS DE TODOS LOS CORTES PRODUCTIVOS
SET client_encoding = 'UTF8';

-- IMPORTAR SESIONES (funciona porque son INSERTs válidos)
SELECT '=== IMPORTANDO SESIONES ===' as info;
\i './BD/Diciembre/08_12_2025/todas_sesiones_productivas.sql'

-- IMPORTAR PRECORTES
SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precortes_productivos.sql'

-- IMPORTAR PRECORTES OTROS
SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES OTROS ===' as info;
\i './BD/Diciembre/08_12_2025/todos_precortes_otros_productivos.sql'

-- VERIFICACIÓN FINAL
SELECT '' as salto;
SELECT '=== VERIFICACIÓN FINAL ===' as info;

SELECT 'Precortes importados:' as tipo, COUNT(*) as cantidad FROM selemti.precorte
UNION ALL
SELECT 'Sesiones importadas:' as tipo, COUNT(*) as cantidad FROM selemti.sesion_cajon
UNION ALL
SELECT 'Precortes_otros importados:' as tipo, COUNT(*) as cantidad FROM selemti.precorte_otros;

SELECT '' as salto;
SELECT 'IMPORTACIÓN COMPLETA DE INSERTS FINALIZADA' as resultado;