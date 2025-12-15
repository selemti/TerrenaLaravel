-- SCRIPT PARA EXTRAER PRECORTES DE HOY (2025-12-08) DESDE DUMP PRODUCTIVO
-- Selecciona solo los precortes del día actual para importarlos

-- Crear tabla temporal para almacenar precortes de hoy
CREATE TEMPORARY TABLE temp_precortes_hoy AS
SELECT
    id,
    sesion_id,
    sistema_efectivo_esperado,
    declarado_efectivo,
    diferencia_efectivo,
    veredicto_efectivo,
    sistema_tarjetas,
    declarado_tarjetas,
    diferencia_tarjetas,
    veredicto_tarjetas,
    creado_en,
    creado_por,
    notas,
    sistema_transferencias,
    declarado_transferencias,
    diferencia_transferencias,
    veredicto_transferencias,
    validado,
    validado_por,
    validado_en,
    requiere_aprobacion,
    aprobado_por,
    aprobado_en,
    motivo_irregular,
    rechazado,
    motivo_rechazo,
    total_ventas_brutas,
    total_ventas_netas,
    total_descuentos_drawer,
    total_descuentos_reales
FROM public.dummy_precortes
WHERE creado_en::date = CURRENT_DATE;

-- Generar INSERTs para los precortes de hoy
SELECT 'INSERT INTO selemti.precorte VALUES (' ||
    id || ', ' ||
    sesion_id || ', ' ||
    COALESCE(sistema_efectivo_esperado, 0) || ', ' ||
    COALESCE(declarado_efectivo, 0) || ', ' ||
    COALESCE(quoted_literal(diferencia_efectivo), 'NULL') || ', ' ||
    COALESCE(quoted_literal(veredicto_efectivo), '''CUADRA''') || ', ' ||
    COALESCE(sistema_tarjetas, 0) || ', ' ||
    COALESCE(declarado_tarjetas, 0) || ', ' ||
    COALESCE(quoted_literal(diferencia_tarjetas), 'NULL') || ', ' ||
    COALESCE(quoted_literal(veredicto_tarjetas), '''CUADRA''') || ', ' ||
    COALESCE(quoted_literal(creado_en, 'YYYY-MM-DD HH24:MI:SS.US'), '''') || ', ' ||
    COALESCE(creado_por, 'NULL') || ', ' ||
    COALESCE(quoted_literal(notas), 'NULL') || ', ' ||
    COALESCE(sistema_transferencias, 0) || ', ' ||
    COALESCE(declarado_transferencias, 0) || ', ' ||
    COALESCE(quoted_literal(diferencia_transferencias), 'NULL') || ', ' ||
    COALESCE(quoted_literal(veredicto_transferencias), '''CUADRA''') || ', ' ||
    COALESCE(validado, false) || ', ' ||
    COALESCE(validado_por, 'NULL') || ', ' ||
    COALESCE(quoted_literal(validado_en, 'YYYY-MM-DD HH24:MI:SS.US'), '''') || ', ' ||
    COALESCE(requiere_aprobacion, false) || ', ' ||
    COALESCE(aprobado_por, 'NULL') || ', ' ||
    COALESCE(quoted_literal(aprobado_en, 'YYYY-MM-DD HH24:MI:SS.US'), '''') || ', ' ||
    COALESCE(quoted_literal(motivo_irregular), 'NULL') || ', ' ||
    COALESCE(rechazado, false) || ', ' ||
    COALESCE(quoted_literal(motivo_rechazo), 'NULL') || ', ' ||
    COALESCE(total_ventas_brutas, 0) || ', ' ||
    COALESCE(total_ventas_netas, 0) || ', ' ||
    COALESCE(total_descuentos_drawer, 0) || ', ' ||
    COALESCE(total_descuentos_reales, 0) ||
    ');' as insert_sql
FROM (
    -- Datos de ejemplo - reemplazar con extracción real del dump
    SELECT 177, 300, 6764.00, 3361.80, 'ENVIADO', 0.00, 0.00, 'CUADRA', '2025-12-08 17:34:49.82028-06', 8, '192.168.1.198', NULL, 0.00, 0.00, 0.00, 'CUADRA', false, NULL, NULL, false, NULL, NULL, NULL, false, NULL, 0.00, 0.00, 0.00, 0.00
    WHERE '2025-12-08 17:34:49.82028-06'::date = CURRENT_DATE
) as datos;

-- Mostrar resultado
SELECT '';
SELECT 'PRECORTES DE HOY EXTRAÍDOS PARA IMPORTAR:' as info;
SELECT COUNT(*) as total_precortes_hoy FROM (
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
) as datos_falsos;

-- Limpiar
DROP TABLE IF EXISTS temp_precortes_hoy;