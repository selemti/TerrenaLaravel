-- PRECORTES DE HOY (2025-12-08) DESDE PRODUCCIÓN
-- Importar solo los 5 precortes del día actual

-- Primero verificar que no existan conflictos
DELETE FROM selemti.precorte WHERE creado_en::date = '2025-12-08';

INSERT INTO selemti.precorte VALUES
(177, 300, 6764.00, 3361.80, 'ENVIADO', 0.00, 0.00, 'CUADRA', '2025-12-08 17:34:49.82028-06', 8, '192.168.1.198', NULL, 0.00, 0.00, 0.00, 'CUADRA', false, NULL, NULL, false, NULL, NULL, NULL, false, NULL, 0.00, 0.00, 0.00, 0.00),
(178, 301, 6665.00, 7982.30, 'ENVIADO', 0.00, 0.00, 'CUADRA', '2025-12-08 17:59:03.812766-06', 6, '192.168.1.198', NULL, 0.00, 0.00, 0.00, 'CUADRA', false, NULL, NULL, false, NULL, NULL, NULL, false, NULL, 0.00, 0.00, 0.00, 0.00),
(179, 302, 9305.00, 3828.00, 'ENVIADO', 0.00, 0.00, 'CUADRA', '2025-12-08 18:43:45.029541-06', 11, '192.168.1.196', NULL, 0.00, 0.00, 0.00, 'CUADRA', false, NULL, NULL, false, NULL, NULL, NULL, false, NULL, 0.00, 0.00, 0.00, 0.00),
(175, 299, 1348.00, 40.00, 'ENVIADO', 0.00, 0.00, 'CUADRA', '2025-12-08 11:10:56.140902-06', 14, '192.168.1.210', NULL, 0.00, 0.00, 0.00, 'CUADRA', false, NULL, NULL, false, NULL, NULL, NULL, false, NULL, 0.00, 0.00, 0.00, 0.00),
(176, 303, 6979.00, 3406.00, 'ENVIADO', 0.00, 0.00, 'CUADRA', '2025-12-08 15:45:13.818912-06', 9, '192.168.1.112', NULL, 0.00, 0.00, 0.00, 'CUADRA', false, NULL, NULL, false, NULL, NULL, NULL, false, NULL, 0.00, 0.00, 0.00, 0.00);

-- Verificar importación
SELECT 'PRECORTES DE HOY IMPORTADOS:' as info;
SELECT COUNT(*) as total_importados, creado_en::date as fecha FROM selemti.precorte WHERE creado_en::date = '2025-12-08' GROUP BY creado_en::date;

SELECT '';
SELECT 'DETALLE DE PRECORTES IMPORTADOS:' as info;
SELECT
    id,
    sesion_id,
    ROUND(declarado_efectivo, 2) as efectivo,
    ROUND(declarado_tarjetas, 2) as tarjetas,
    ROUND(declarado_efectivo + declarado_tarjetas, 2) as total_declarado,
    veredicto_efectivo,
    veredicto_tarjetas,
    creado_en::time(0) as hora
FROM selemti.precorte
WHERE creado_en::date = '2025-12-08'
ORDER BY creado_en;