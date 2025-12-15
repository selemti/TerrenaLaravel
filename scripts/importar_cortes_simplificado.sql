-- IMPORTACIÓN SIMPLIFICADA DE TODOS LOS CORTES PRODUCTIVOS
-- Importar directamente sin funciones complejas

SET client_encoding = 'UTF8';

-- IMPORTAR SESIONES (estas funcionaron)
SELECT '=== IMPORTANDO SESIONES ===' as info;

\copy selemti.sesion_cajon FROM './BD/Diciembre/08_12_2025/todas_sesiones_productivas.sql'

-- IMPORTAR PRECORTES
SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES ===' as info;

\copy selemti.precorte FROM './BD/Diciembre/08_12_2025/todos_precortes_productivos.sql'

-- IMPORTAR PRECORTES OTROS
SELECT '' as salto;
SELECT '=== IMPORTANDO PRECORTES OTROS ===' as info;

\copy selemti.precorte_otros FROM './BD/Diciembre/08_12_2025/todos_precortes_otros_productivos.sql'

-- VERIFICACIÓN FINAL
SELECT '' as salto;
SELECT '=== VERIFICACIÓN FINAL ===' as info;

SELECT 'Precortes importados:' as tipo, COUNT(*) as cantidad FROM selemti.precorte
UNION ALL
SELECT 'Sesiones importadas:' as tipo, COUNT(*) as cantidad FROM selemti.sesion_cajon
UNION ALL
SELECT 'Precortes_otros importados:' as tipo, COUNT(*) as cantidad FROM selemti.precorte_otros;

SELECT '' as salto;
SELECT 'IMPORTACIÓN COMPLETA FINALIZADA' as resultado;