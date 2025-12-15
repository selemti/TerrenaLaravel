-- Agregar columnas para métricas de descuentos y ventas a postcorte
ALTER TABLE selemti.postcorte
ADD COLUMN total_ventas_brutas NUMERIC(12,2) NOT NULL DEFAULT 0,
ADD COLUMN total_ventas_netas NUMERIC(12,2) NOT NULL DEFAULT 0,
ADD COLUMN total_descuentos_drawer NUMERIC(12,2) NOT NULL DEFAULT 0,
ADD COLUMN total_descuentos_reales NUMERIC(12,2) NOT NULL DEFAULT 0,
ADD COLUMN diferencia_descuentos NUMERIC(12,2) NOT NULL DEFAULT 0,
ADD COLUMN porcentaje_error_descuentos NUMERIC(5,2) NOT NULL DEFAULT 0,
ADD COLUMN calidad_reporte_descuentos TEXT NOT NULL DEFAULT 'SIN_DATOS';

-- Agregar constraint para el campo de calidad
ALTER TABLE selemti.postcorte
ADD CONSTRAINT postcorte_calidad_reporte_descuentos_check
CHECK (calidad_reporte_descuentos IN ('SIN_DATOS', 'EXCELENTE', 'BUENO', 'ACEPTABLE', 'REVISAR', 'CRITICO'));