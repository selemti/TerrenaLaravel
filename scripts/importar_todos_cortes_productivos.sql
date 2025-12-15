-- IMPORTACIÓN COMPLETA DE TODOS LOS CORTES PRODUCTIVOS
-- Importa: 1,344 precortes + 268 sesiones + precortes_otros
-- Preserva: estructura local + usuarios locales + datos públicos

-- Establecer encoding para evitar problemas
SET client_encoding = 'UTF8';

-- IMPORTAR PRECORTES PRINCIPALES
SELECT '=== IMPORTANDO PRECORTES PRINCIPALES ===' as info;

-- Limpiar duplicados si existen
DELETE FROM selemti.precorte WHERE id IN (
    SELECT DISTINCT regexp_replace(substring(regexp_replace(line, 'INSERT INTO selemti\.precorte VALUES \(', '', ''), '\', '', ''), '\', '', '')::bigint
    FROM regexp_split_to_array(unnest(string_to_array(ARRAY[(
        'placeholder'
    )], 'placeholder')), E'\\n') AS t(line)
    WHERE line LIKE 'INSERT INTO selemti.precorte VALUES%'
);

-- Importar todos los precortes
\copy ./BD/Diciembre/08_12_2025/todos_precortes_productivos.sql

-- IMPORTAR SESIONES
SELECT '';
SELECT '=== IMPORTANDO SESIONES ===' as info;

-- Limpiar duplicados si existen
DELETE FROM selemti.sesion_cajon WHERE id IN (
    SELECT DISTINCT regexp_replace(substring(regexp_replace(line, 'INSERT INTO selemti\.sesion_cajon VALUES \(', '', ''), '\', '', ''), '\', '', '')::bigint
    FROM regexp_split_to_array(unnest(string_to_array(ARRAY[(
        'placeholder'
    )], 'placeholder')), E'\\n') AS t(line)
    WHERE line LIKE 'INSERT INTO selemti.sesion_cajon VALUES%'
);

-- Importar todas las sesiones
\copy ./BD/Diciembre/08_12_2025/todas_sesiones_productivas.sql

-- IMPORTAR PRECORTES_OTROS (datos adicionales de formas de pago)
SELECT '';
SELECT '=== IMPORTANDO PRECORTES OTROS ===' as info;

-- Limpiar duplicados si existen
DELETE FROM selemti.precorte_otros;

-- Importar todos los precortes_otros
\copy ./BD/Diciembre/08_12_2025/todos_precortes_otros_productivos.sql

-- VERIFICACIÓN FINAL
SELECT '';
SELECT '=== VERIFICACIÓN FINAL ===' as info;

SELECT 'Precortes importados:' as tipo, COUNT(*) as cantidad FROM selemti.precorte
UNION ALL
SELECT 'Sesiones importadas:' as tipo, COUNT(*) as cantidad FROM selemti.sesion_cajon
UNION ALL
SELECT 'Precortes_otros importados:' as tipo, COUNT(*) as cantidad FROM selemti.precorte_otros
UNION ALL
SELECT 'Total cortes completos:' as tipo, COUNT(*) + COUNT(*) + COUNT(*) as cantidad FROM (
    SELECT COUNT(*) FROM selemti.precorte
    UNION ALL
    SELECT COUNT(*) FROM selemti.sesion_cajon
    UNION ALL
    SELECT COUNT(*) FROM selemti.precorte_otros
) as conteos;

-- MOSTRAR RESUMEN POR FECHA
SELECT '';
SELECT 'RESUMEN DE CORTES POR FECHA:' as info;
SELECT
    DATE_TRUNC('day', creado_en)::date as fecha,
    COUNT(*) as precortes_dia,
    ROUND(AVG(sistema_efectivo_esperado), 2) as promedio_efectivo,
    ROUND(AVG(declarado_efectivo), 2) as promedio_declarado,
    ROUND(AVG(sistema_tarjetas), 2) as promedio_tarjetas,
    ROUND(AVG(declarado_tarjetas), 2) as promedio_tarjetas_declarado
FROM selemti.precorte
WHERE creado_en IS NOT NULL
GROUP BY DATE_TRUNC('day', creado_en)::date
ORDER BY fecha DESC
LIMIT 10;

SELECT '';
SELECT 'IMPORTACIÓN COMPLETA DE CORTES PRODUCTIVOS FINALIZADA' as resultado;