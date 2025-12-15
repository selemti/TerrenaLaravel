-- Vista para monitorear métricas de descuentos en postcortes
CREATE OR REPLACE VIEW selemti.vw_postcortes_con_descuentos AS
SELECT
    pc.id,
    pc.sesion_id,
    sc.terminal_id,
    sc.apertura_ts,
    sc.cierre_ts,

    -- Métricas tradicionales
    pc.sistema_efectivo_esperado,
    pc.declarado_efectivo,
    pc.diferencia_efectivo,
    pc.veredicto_efectivo,
    pc.sistema_tarjetas,
    pc.declarado_tarjetas,
    pc.diferencia_tarjetas,
    pc.veredicto_tarjetas,
    pc.sistema_transferencias,
    pc.declarado_transferencias,
    pc.diferencia_transferencias,
    pc.veredicto_transferencias,

    -- Nuevas métricas de descuentos y ventas
    pc.total_ventas_brutas,
    pc.total_ventas_netas,
    pc.total_descuentos_drawer,
    pc.total_descuentos_reales,
    pc.diferencia_descuentos,
    pc.porcentaje_error_descuentos,
    pc.calidad_reporte_descuentos,

    -- Métricas calculadas adicionales
    CASE
        WHEN pc.total_ventas_brutas > 0
        THEN ROUND((pc.total_descuentos_drawer / pc.total_ventas_brutas * 100), 2)
        ELSE 0
    END as porcentaje_descuentos_drawer_sobre_ventas,

    CASE
        WHEN pc.total_ventas_brutas > 0
        THEN ROUND((pc.total_descuentos_reales / pc.total_ventas_brutas * 100), 2)
        ELSE 0
    END as porcentaje_descuentos_reales_sobre_ventas,

    -- Clasificación de calidad
    CASE
        WHEN pc.calidad_reporte_descuentos IN ('EXCELENTE', 'BUENO') THEN 'VERDE'
        WHEN pc.calidad_reporte_descuentos = 'ACEPTABLE' THEN 'AMARILLO'
        ELSE 'ROJO'
    END as nivel_alerta_descuentos,

    -- Información de estado
    pc.validado,
    pc.validado_por,
    pc.validado_en,
    pc.creado_en,
    pc.creado_por,
    pc.notas

FROM selemti.postcorte pc
JOIN selemti.sesion_cajon sc ON pc.sesion_id = sc.id
ORDER BY pc.creado_en DESC;

-- Vista para reporte de calidad de reportes de descuentos por período
CREATE OR REPLACE VIEW selemti.vw_calidad_reportes_descuentos AS
SELECT
    DATE(pc.creado_en) as fecha,
    sc.terminal_id,
    COUNT(*) as total_postcortes,
    COUNT(CASE WHEN pc.calidad_reporte_descuentos = 'EXCELENTE' THEN 1 END) as excelentes,
    COUNT(CASE WHEN pc.calidad_reporte_descuentos = 'BUENO' THEN 1 END) as buenos,
    COUNT(CASE WHEN pc.calidad_reporte_descuentos = 'ACEPTABLE' THEN 1 END) as aceptables,
    COUNT(CASE WHEN pc.calidad_reporte_descuentos = 'REVISAR' THEN 1 END) as revisar,
    COUNT(CASE WHEN pc.calidad_reporte_descuentos = 'CRITICO' THEN 1 END) as criticos,

    -- Sumas de métricas
    SUM(pc.total_descuentos_drawer) as total_drawer_descuentos,
    SUM(pc.total_descuentos_reales) as total_reales_descuentos,
    SUM(pc.diferencia_descuentos) as total_diferencia,

    -- Promedios
    ROUND(AVG(pc.porcentaje_error_descuentos), 2) as promedio_error_porcentual,

    -- Calificación general del día
    CASE
        WHEN COUNT(CASE WHEN pc.calidad_reporte_descuentos IN ('REVISAR', 'CRITICO') THEN 1 END) = 0 THEN 'DIA EXCELENTE'
        WHEN COUNT(CASE WHEN pc.calidad_reporte_descuentos = 'CRITICO' THEN 1 END) > 0 THEN 'DIA CRITICO'
        ELSE 'DIA ACEPTABLE'
    END as calificacion_dia

FROM selemti.postcorte pc
JOIN selemti.sesion_cajon sc ON pc.sesion_id = sc.id
GROUP BY DATE(pc.creado_en), sc.terminal_id
ORDER BY fecha DESC, sc.terminal_id;