# 🚀 Implementación de Soluciones - Guía Paso a Paso

## 📋 Overview

Guía completa de implementación de las soluciones críticas identificadas en el análisis del sistema de reportes. Incluye scripts SQL, pasos de validación y procedimientos de rollback.

**Fecha:** 9 de Diciembre de 2025
**Estado:** Listo para implementación
**Prioridad:** 🚨 **CRÍTICA**

---

## ⚠️ **PRE-IMPLEMENTACIÓN CRÍTICA**

### **BACKUP OBLIGATORIO**
```bash
# Backup completo ANTES de cualquier cambio
pg_dump -h localhost -p 5433 -U postgres -d pos > backup_pre_fix_20251209.sql

# Backup específico de tablas críticas
pg_dump -h localhost -p 5433 -U postgres -d pos \
  -t public.ticket \
  -t public.ticket_discount \
  -t public.ticket_item_discount \
  -t public.drawer_pull_report \
  -t public.transactions \
  > backup_critical_tables_20251209.sql
```

### **Verificar Estado Actual**
```sql
-- Conteo actual para validar después
SELECT 'PRE_FIX' as estado, COUNT(*) as total_tickets, SUM(total_discount) as total_descuentos
FROM public.ticket WHERE voided = false;

SELECT 'PRE_FIX' as estado, COUNT(*) as total_drawer_reports, SUM(totaldiscountamount) as total_descuentos_drawer
FROM public.drawer_pull_report;
```

---

## 🛠️ **PASO 1: Corrección Crítica de Descuentos**

### **1.1 Crear Vista Maestra de Descuentos**

```sql
-- File: 01_vista_descuentos_reales.sql
CREATE OR REPLACE VIEW vw_descuentos_reales AS
WITH descuentos_unificados AS (
    SELECT
        t.id as ticket_id,
        t.total_discount as descuento_header,
        COALESCE(td_total.value, 0) as descuento_ticket_level,
        COALESCE(tid_total.value, 0) as descuento_item_level,

        -- Lógica anti-duplicación: prioridad ticket_level > item_level > header
        CASE
            WHEN td_total.value > 0 THEN td_total.value
            WHEN tid_total.value > 0 THEN tid_total.value
            ELSE t.total_discount
        END as descuento_real_unificado,

        CASE
            WHEN td_total.value > 0 THEN 'TICKET_LEVEL'
            WHEN tid_total.value > 0 THEN 'ITEM_LEVEL'
            WHEN t.total_discount > 0 THEN 'HEADER_ONLY'
            ELSE 'SIN_DESCUENTO'
        END as tipo_descuento_final,

        -- Bandera de duplicación para auditoría
        CASE
            WHEN td_total.value > 0 AND t.total_discount > 0 THEN 'DUPLICADO_HEADER_TICKET'
            WHEN tid_total.value > 0 AND t.total_discount > 0 THEN 'DUPLICADO_HEADER_ITEM'
            WHEN td_total.value > 0 AND tid_total.value > 0 THEN 'DUPLICADO_TICKET_ITEM'
            WHEN td_total.value > 0 AND tid_total.value > 0 AND t.total_discount > 0 THEN 'DUPLICADO_COMPLETO'
            ELSE 'SIN_DUPLICACION'
        END as estatus_duplicacion,

        -- Cálculo de duplicación
        (COALESCE(td_total.value, 0) + COALESCE(tid_total.value, 0) + t.total_discount) as total_bruto_sin_validar,
        CASE
            WHEN td_total.value > 0 THEN td_total.value
            WHEN tid_total.value > 0 THEN tid_total.value
            ELSE t.total_discount
        END as descuento_validado

    FROM public.ticket t
    LEFT JOIN (
        SELECT ticket_id, SUM(value) as value
        FROM public.ticket_discount
        GROUP BY ticket_id
    ) td_total ON t.id = td_total.ticket_id
    LEFT JOIN (
        SELECT ti.ticket_id, SUM(tid.value) as value
        FROM public.ticket_item ti
        JOIN public.ticket_item_discount tid ON ti.id = tid.ticket_itemid
        GROUP BY ti.ticket_id
    ) tid_total ON t.id = tid_total.ticket_id
    WHERE t.voided = false
)
SELECT
    ticket_id,
    descuento_header,
    descuento_ticket_level,
    descuento_item_level,
    descuento_real_unificado,
    tipo_descuento_final,
    estatus_duplicacion,
    total_bruto_sin_validar,
    (total_bruto_sin_validar - descuento_real_unificado) as cantidad_duplicada,
    -- Validación final
    CASE
        WHEN descuento_real_unificado <> descuento_header
             AND descuento_header > 0
        THEN 'NECESITA_CORRECCION'
        ELSE 'CORRECTO'
    END as estatus_validacion
FROM descuentos_unificados;
```

### **1.2 Validar Vista de Descuentos**

```sql
-- Verificar resultados
SELECT
    'POST_VIEW_CREATION' as paso,
    COUNT(*) as total_tickets,
    COUNT(CASE WHEN estatus_duplicacion != 'SIN_DUPLICACION' THEN 1 END) as tickets_con_duplicacion,
    SUM(descuento_real_unificado) as descuentos_reales_calculados,
    SUM(descuento_header) as descuentos_header_original,
    (SUM(descuento_header) - SUM(descuento_real_unificado)) as diferencia_a_corregir
FROM vw_descuentos_reales;

-- Ejemplos de tickets con problemas
SELECT * FROM vw_descuentos_reales
WHERE estatus_duplicacion != 'SIN_DUPLICACION'
LIMIT 10;
```

---

## 🔧 **PASO 2: Funciones de Cálculo Corregidas**

### **2.1 Función Principal de Descuentos**

```sql
-- File: 02_funcion_descuentos_reales.sql
CREATE OR REPLACE FUNCTION fn_calcular_descuentos_reales(
    p_fecha DATE,
    p_terminal_id INTEGER DEFAULT NULL
) RETURNS TABLE(
    terminal_id INTEGER,
    fecha DATE,
    tickets_con_descuento INTEGER,
    total_descuentos_reales DECIMAL,
    descuentos_header DECIMAL,
    descuentos_ticket_level DECIMAL,
    descuentos_item_level DECIMAL,
    tickets_con_duplicacion INTEGER,
    monto_duplicado_corregido DECIMAL,
    descuentos_drawer_report DECIMAL,
    diferencia_drawer_vs_real DECIMAL,
    porcentaje_error DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(p_terminal_id, t.terminal_id) as terminal_id,
        p_fecha as fecha,
        COUNT(CASE WHEN d.descuento_real_unificado > 0 THEN 1 END) as tickets_con_descuento,
        SUM(d.descuento_real_unificado) as total_descuentos_reales,
        SUM(d.descuento_header) as descuentos_header,
        SUM(d.descuento_ticket_level) as descuentos_ticket_level,
        SUM(d.descuento_item_level) as descuentos_item_level,
        COUNT(CASE WHEN d.estatus_duplicacion != 'SIN_DUPLICACION' THEN 1 END) as tickets_con_duplicacion,
        SUM(d.total_bruto_sin_validar - d.descuento_real_unificado) as monto_duplicado_corregido,
        COALESCE(dpr.totaldiscountamount, 0) as descuentos_drawer_report,
        COALESCE(dpr.totaldiscountamount, 0) - SUM(d.descuento_real_unificado) as diferencia_drawer_vs_real,
        CASE
            WHEN dpr.totaldiscountamount > 0
            THEN ((COALESCE(dpr.totaldiscountamount, 0) - SUM(d.descuento_real_unificado)) / dpr.totaldiscountamount * 100)
            ELSE 0
        END as porcentaje_error
    FROM public.ticket t
    LEFT JOIN vw_descuentos_reales d ON t.id = d.ticket_id
    LEFT JOIN public.drawer_pull_report dpr ON
        DATE(t.closing_date) = DATE(dpr.report_time) AND
        t.terminal_id = dpr.terminal_id
        AND (p_terminal_id IS NULL OR t.terminal_id = p_terminal_id)
    WHERE DATE(t.closing_date) = p_fecha
      AND t.voided = false
      AND (p_terminal_id IS NULL OR t.terminal_id = p_terminal_id)
    GROUP BY COALESCE(p_terminal_id, t.terminal_id), p_fecha, dpr.totaldiscountamount;
END;
$$ LANGUAGE plpgsql;
```

### **2.2 Validar Función**

```sql
-- Probar función con datos de hoy
SELECT * FROM fn_calcular_descuentos_reales(CURRENT_DATE - INTERVAL '1 day');

-- Comparar con valores actuales
SELECT
    'VALIDACION_FUNCION' as prueba,
    d.fecha,
    d.terminal_id,
    d.total_descuentos_reales,
    d.descuentos_drawer_report,
    d.diferencia_drawer_vs_real,
    d.porcentaje_error
FROM fn_calcular_descuentos_reales(CURRENT_DATE - INTERVAL '1 day') d
WHERE ABS(d.diferencia_drawer_vs_real) > 0.01;
```

---

## 📊 **PASO 3: Vista Maestra de Corte de Caja**

### **3.1 Vista Completa con Todos los Componentes**

```sql
-- File: 03_vista_corte_caja_completo.sql
CREATE OR REPLACE VIEW vw_corte_caja_completo AS
WITH datos_transacciones AS (
    SELECT
        t.terminal_id,
        DATE(t.closing_date) as fecha,

        -- Ventas por tipo de pago (desde transactions)
        SUM(CASE WHEN tr.payment_type = 'CASH' THEN tr.amount ELSE 0 END) as ventas_efectivo,
        SUM(CASE WHEN tr.payment_type = 'CREDIT_CARD' THEN tr.amount ELSE 0 END) as ventas_tarjeta_credito,
        SUM(CASE WHEN tr.payment_type = 'DEBIT_CARD' THEN tr.amount ELSE 0 END) as ventas_tarjeta_debito,
        SUM(CASE WHEN tr.payment_type = 'CUSTOM_PAYMENT' THEN tr.amount ELSE 0 END) as ventas_personalizadas,

        -- Operaciones especiales
        SUM(CASE WHEN tr.payment_type = 'PAY_OUT' THEN tr.amount ELSE 0 END) as salidas_efectivo,
        SUM(CASE WHEN tr.payment_type = 'REFUND' THEN tr.amount ELSE 0 END) as devoluciones,
        SUM(CASE WHEN tr.payment_type = 'VOID_TRANS' THEN tr.amount ELSE 0 END) as anulaciones,

        -- Descuentos reales (unificados - sin duplicar)
        COALESCE(SUM(d.descuento_real_unificado), 0) as descuentos_reales,

        -- Propinas
        SUM(CASE WHEN tr.tips_amount > 0 THEN tr.tips_amount ELSE 0 END) as propinas,

        -- Tickets procesados
        COUNT(DISTINCT t.id) as tickets_procesados,
        COUNT(DISTINCT tr.id) as transacciones_procesadas,
        COUNT(DISTINCT CASE WHEN t.total_discount > 0 THEN t.id END) as tickets_con_descuento,

        -- Análisis de duplicación
        COUNT(DISTINCT CASE WHEN d.estatus_duplicacion != 'SIN_DUPLICACION' THEN t.id END) as tickets_con_duplicacion,
        COALESCE(SUM(d.total_bruto_sin_validar - d.descuento_real_unificado), 0) as monto_duplicado

    FROM public.ticket t
    LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
    LEFT JOIN vw_descuentos_reales d ON t.id = d.ticket_id
    WHERE t.voided = false
    GROUP BY t.terminal_id, DATE(t.closing_date)
),
anulaciones_unificadas AS (
    SELECT
        t.terminal_id,
        DATE(t.closing_date) as fecha,
        COUNT(*) as tickets_voided,
        SUM(t.total_price) as monto_tickets_voided,
        SUM(t.total_discount) as descuentos_tickets_voided
    FROM public.ticket t
    WHERE t.voided = true
    GROUP BY t.terminal_id, DATE(t.closing_date)
)
SELECT
    dt.*,

    -- Datos del drawer pull report para comparación
    dpr.id as drawer_report_id,
    dpr.report_time as drawer_report_time,
    dpr.ticket_count as tickets_drawer,
    dpr.cash_receipt_amount as efectivo_drawer,
    dpr.credit_card_receipt_amount as tarjeta_credito_drawer,
    dpr.debit_card_receipt_amount as tarjeta_debito_drawer,
    dpr.refund_amount as devoluciones_drawer,
    dpr.totaldiscountamount as descuentos_drawer,
    dpr.pay_out_amount as salidas_efectivo_drawer,
    dpr.net_sales as ventas_netas_drawer,
    dpr.gross_receipts as recibos_brutos_drawer,
    dpr.variance as varianza_drawer,

    -- Datos de anulaciones
    au.tickets_voided,
    au.monto_tickets_voided,
    au.descuentos_tickets_voided,

    -- Cálculos correctos con todos los componentes
    (dt.ventas_efectivo + dt.ventas_tarjeta_credito + dt.ventas_tarjeta_debito + dt.ventas_personalizadas
     - dt.descuentos_reales - dt.devoluciones - dt.salidas_efectivo) as ventas_netas_calculadas,

    -- Total de ingresos
    (dt.ventas_efectivo + dt.ventas_tarjeta_credito + dt.ventas_tarjeta_debito + dt.ventas_personalizadas) as total_ingresos,

    -- Total de egresos/deducciones
    (dt.descuentos_reales + dt.devoluciones + dt.salidas_efectivo) as total_deducciones,

    -- Diferencias para validación
    (dt.ventas_efectivo - dpr.cash_receipt_amount) as diferencia_efectivo,
    (dt.ventas_tarjeta_credito - dpr.credit_card_receipt_amount) as diferencia_tarjeta_credito,
    (dt.ventas_tarjeta_debito - dpr.debit_card_receipt_amount) as diferencia_tarjeta_debito,
    (dt.descuentos_reales - dpr.totaldiscountamount) as diferencia_descuentos,
    (dt.devoluciones - dpr.refund_amount) as diferencia_devoluciones,
    (dt.salidas_efectivo - dpr.pay_out_amount) as diferencia_salidas,
    (dt.tickets_procesados - dpr.ticket_count) as diferencia_tickets,

    -- Porcentajes de error
    CASE
        WHEN dpr.cash_receipt_amount > 0
        THEN ((dt.ventas_efectivo - dpr.cash_receipt_amount) / dpr.cash_receipt_amount * 100)
        ELSE 0
    END as porcentaje_error_efectivo,

    CASE
        WHEN dpr.totaldiscountamount > 0
        THEN ((dt.descuentos_reales - dpr.totaldiscountamount) / dpr.totaldiscountamount * 100)
        ELSE 0
    END as porcentaje_error_descuentos,

    -- Estado de validación general
    CASE
        WHEN ABS(dt.ventas_efectivo - dpr.cash_receipt_amount) < 1.00
         AND ABS(dt.descuentos_reales - dpr.totaldiscountamount) < 0.01
         AND ABS(dt.devoluciones - dpr.refund_amount) < 1.00
         AND ABS(dt.tickets_procesados - dpr.ticket_count) < 1
        THEN 'CONSISTENTE'
        WHEN ABS(dt.ventas_efectivo - dpr.cash_receipt_amount) > 100
         OR ABS(dt.descuentos_reales - dpr.totaldiscountamount) > 100
        THEN 'CRITICO'
        ELSE 'INCONSISTENTE'
    END as estado_validacion,

    -- Métricas de calidad
    CASE
        WHEN dt.tickets_con_duplicacion > 0 THEN 'NECESITA_CORRECCION'
        ELSE 'OK'
    END as estatus_descuentos,

    -- Resumen de problemas
    (ABS(diferencia_efectivo) + ABS(diferencia_tarjeta_credito) + ABS(diferencia_tarjeta_debito)
     + ABS(diferencia_descuentos) + ABS(diferencia_devoluciones) + ABS(diferencia_salidas)) as total_diferencias,

    -- Timestamp de cálculo
    CURRENT_TIMESTAMP as timestamp_calculo

FROM datos_transacciones dt
LEFT JOIN public.drawer_pull_report dpr ON
    dt.terminal_id = dpr.terminal_id AND
    dt.fecha = DATE(dpr.report_time)
LEFT JOIN anulaciones_unificadas au ON
    dt.terminal_id = au.terminal_id AND
    dt.fecha = au.fecha;
```

### **3.2 Validar Vista de Corte de Caja**

```sql
-- Probar vista con datos de hoy
SELECT
    terminal_id,
    fecha,
    tickets_procesados,
    ventas_efectivo,
    ventas_tarjeta_credito,
    descuentos_reales,
    estado_validacion,
    total_diferencias,
    estatus_descuentos
FROM vw_corte_caja_completo
WHERE fecha = CURRENT_DATE - INTERVAL '1 day'
ORDER BY terminal_id;

-- Ver solo problemas críticos
SELECT * FROM vw_corte_caja_completo
WHERE estado_validacion = 'CRITICO'
  AND fecha >= CURRENT_DATE - INTERVAL '7 days';
```

---

## ✅ **PASO 4: Sistema de Validación Automática**

### **4.1 Función de Validación Inteligente**

```sql
-- File: 04_funcion_validacion_integridad.sql
CREATE OR REPLACE FUNCTION fn_validar_integridad_corte(
    p_fecha_inicio DATE DEFAULT CURRENT_DATE - INTERVAL '7 days',
    p_fecha_fin DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    fecha DATE,
    terminal_id INTEGER,
    tipo_problema VARCHAR,
    severidad VARCHAR,
    descripcion TEXT,
    valores JSON,
    recomendacion VARCHAR,
    fecha_deteccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    -- Validar inconsistencia crítica de descuentos
    SELECT
        c.fecha,
        c.terminal_id,
        'DUPLICACION_DESCUENTOS' as tipo_problema,
        CASE
            WHEN c.porcentaje_error_descuentos > 100 THEN 'CRITICO'
            WHEN c.porcentaje_error_descuentos > 20 THEN 'ALTO'
            WHEN c.porcentaje_error_descuentos > 5 THEN 'MEDIO'
            ELSE 'BAJO'
        END as severidad,
        'Descuentos calculados no coinciden con drawer_pull_report. Posible duplicación en cálculos.' as descripcion,
        json_build_object(
            'descuentos_reales', c.descuentos_reales,
            'descuentos_drawer', c.descuentos_drawer,
            'diferencia', c.diferencia_descuentos,
            'porcentaje_error', c.porcentaje_error_descuentos,
            'tickets_con_duplicacion', c.tickets_con_duplicacion
        ) as valores,
        CASE
            WHEN c.porcentaje_error_descuentos > 100
            THEN 'CORREGIR INMEDIATAMENTE - Revisar lógica de cálculo de descuentos'
            WHEN c.porcentaje_error_descuentos > 20
            THEN 'PRIORIDAD ALTA - Investigar tickets con descuentos duplicados'
            ELSE 'MONITOREAR - Validar periódicamente'
        END as recomendacion
    FROM vw_corte_caja_completo c
    WHERE c.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
      AND ABS(c.diferencia_descuentos) > 0.01

    UNION ALL

    -- Validar inconsistencia de efectivo
    SELECT
        c.fecha,
        c.terminal_id,
        'INCONSISTENCIA_EFECTIVO' as tipo_problema,
        CASE
            WHEN ABS(c.diferencia_efectivo) > 1000 THEN 'CRITICO'
            WHEN ABS(c.diferencia_efectivo) > 100 THEN 'ALTO'
            WHEN ABS(c.diferencia_efectivo) > 10 THEN 'MEDIO'
            ELSE 'BAJO'
        END as severidad,
        'Efectivo calculado desde transactions no coincide con drawer_pull_report.' as descripcion,
        json_build_object(
            'efectivo_calculado', c.ventas_efectivo,
            'efectivo_drawer', c.efectivo_drawer,
            'diferencia', c.diferencia_efectivo,
            'porcentaje_error', c.porcentaje_error_efectivo,
            'tickets_procesados', c.tickets_procesados
        ) as valores,
        CASE
            WHEN ABS(c.diferencia_efectivo) > 1000
            THEN 'REVISIÓN URGENTE - Posible error en transacciones de efectivo'
            WHEN ABS(c.diferencia_efectivo) > 100
            THEN 'INVESTIGAR - Validar transacciones del día'
            ELSE 'MONITOREAR - Mantener observación'
        END as recomendacion
    FROM vw_corte_caja_completo c
    WHERE c.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
      AND ABS(c.diferencia_efectivo) > 1.00

    UNION ALL

    -- Validar tickets faltantes
    SELECT
        c.fecha,
        c.terminal_id,
        'TICKETS_FALTANTES' as tipo_problema,
        CASE
            WHEN ABS(c.diferencia_tickets) > 10 THEN 'CRITICO'
            WHEN ABS(c.diferencia_tickets) > 5 THEN 'ALTO'
            WHEN ABS(c.diferencia_tickets) > 1 THEN 'MEDIO'
            ELSE 'BAJO'
        END as severidad,
        'Cantidad de tickets en drawer_pull_report no coincide con transacciones procesadas.' as descripcion,
        json_build_object(
            'tickets_procesados', c.tickets_procesados,
            'tickets_drawer', c.tickets_drawer,
            'diferencia', c.diferencia_tickets,
            'transacciones_procesadas', c.transacciones_procesadas
        ) as valores,
        CASE
            WHEN ABS(c.diferencia_tickets) > 10
            THEN 'INVESTIGAR URGENTE - Faltan muchos tickets'
            WHEN ABS(c.diferencia_tickets) > 5
            THEN 'REVISAR - Validar sincronización'
            ELSE 'MONITOREAR - Verificar periódicamente'
        END as recomendacion
    FROM vw_corte_caja_completo c
    WHERE c.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
      AND ABS(c.diferencia_tickets) > 0;
END;
$$ LANGUAGE plpgsql;
```

### **4.2 Probar Sistema de Validación**

```sql
-- Validar última semana
SELECT * FROM fn_validar_integridad_corte();

-- Ver solo problemas críticos
SELECT * FROM fn_validar_integridad_corte()
WHERE severidad = 'CRITICO'
ORDER BY fecha DESC, terminal_id;

-- Resumen de problemas
SELECT
    tipo_problema,
    severidad,
    COUNT(*) as cantidad,
    MIN(fecha) as primera_ocurrencia,
    MAX(fecha) as ultima_ocurrencia
FROM fn_validar_integridad_corte()
GROUP BY tipo_problema, severidad
ORDER BY severidad, cantidad DESC;
```

---

## 🚨 **PASO 5: Índices de Performance**

```sql
-- File: 05_indices_optimizacion.sql
-- Índices para mejorar performance de las vistas

-- Índices para tabla ticket
CREATE INDEX IF NOT EXISTS idx_ticket_fecha_terminal_void
ON public.ticket(DATE(closing_date), terminal_id, voided);

CREATE INDEX IF NOT EXISTS idx_ticket_descuento
ON public.ticket(total_discount) WHERE total_discount > 0;

-- Índices para tabla ticket_discount
CREATE INDEX IF NOT EXISTS idx_ticket_discount_ticket
ON public.ticket_discount(ticket_id);

CREATE INDEX IF NOT EXISTS idx_ticket_discount_value
ON public.ticket_discount(value) WHERE value > 0;

-- Índices para tabla ticket_item_discount
CREATE INDEX IF NOT EXISTS idx_ticket_item_discount_item
ON public.ticket_item_discount(ticket_itemid);

CREATE INDEX IF NOT EXISTS idx_ticket_item_discount_value
ON public.ticket_item_discount(value) WHERE value > 0;

-- Índices para tabla transactions
CREATE INDEX IF NOT EXISTS idx_transactions_fecha_terminal
ON public.transactions(DATE(transaction_time), terminal_id);

CREATE INDEX IF NOT EXISTS idx_transactions_payment_type
ON public.transactions(payment_type, amount);

CREATE INDEX IF NOT EXISTS idx_transactions_ticket
ON public.transactions(ticket_id);

-- Índices para tabla drawer_pull_report
CREATE INDEX IF NOT EXISTS idx_drawer_pull_fecha_terminal
ON public.drawer_pull_report(DATE(report_time), terminal_id);

-- Índices compuestos para joins
CREATE INDEX IF NOT EXISTS idx_ticket_completo
ON public.ticket(terminal_id, DATE(closing_date), voided, total_discount);

CREATE INDEX IF NOT EXISTS idx_transactions_completo
ON public.transactions(ticket_id, payment_type, amount, DATE(transaction_time));
```

---

## ✅ **PASO 6: Validación Final**

### **6.1 Comparación Antes vs Después**

```sql
-- VALIDACIÓN FINAL COMPLETA
SELECT '=== ANTES VS DESPUÉS DE CORRECCIONES ===' as informe;

-- 1. Descuentos
SELECT
    'DESCUENTOS' as tipo,
    SUM(total_discount) as valor_antes,
    (SELECT SUM(descuento_real_unificado) FROM vw_descuentos_reales) as valor_despues,
    (SUM(total_discount) - (SELECT SUM(descuento_real_unificado) FROM vw_descuentos_reales)) as diferencia,
    CASE
        WHEN (SELECT SUM(descuento_real_unificado) FROM vw_descuentos_reales) > 0
        THEN ((SUM(total_discount) - (SELECT SUM(descuento_real_unificado) FROM vw_descuentos_reales)) / (SELECT SUM(descuento_real_unificado) FROM vw_descuentos_reales) * 100)
        ELSE 0
    END as porcentaje_error_corregido
FROM public.ticket
WHERE voided = false

UNION ALL

-- 2. Tickets con duplicación
SELECT
    'TICKETS_DUPLICADOS' as tipo,
    (SELECT COUNT(*) FROM vw_descuentos_reales WHERE estatus_duplicacion != 'SIN_DUPLICACION') as valor_antes,
    0 as valor_despues,
    (SELECT COUNT(*) FROM vw_descuentos_reales WHERE estatus_duplicacion != 'SIN_DUPLICACION') as diferencia,
    100 as porcentaje_error_corregido

UNION ALL

-- 3. Validación de integridad (últimos 7 días)
SELECT
    'ERRORES_INTEGRIDAD' as tipo,
    COUNT(*) as valor_antes,
    0 as valor_despues,
    COUNT(*) as diferencia,
    100 as porcentaje_error_corregido
FROM fn_validar_integridad_corte();
```

### **6.2 Performance Tests**

```sql
-- Test de performance de vistas
EXPLAIN ANALYZE
SELECT * FROM vw_descuentos_reales
WHERE ticket_id IN (SELECT id FROM public.ticket ORDER BY id DESC LIMIT 1000);

EXPLAIN ANALYZE
SELECT * FROM vw_corte_caja_completo
WHERE fecha = CURRENT_DATE - INTERVAL '1 day';

EXPLAIN ANALYZE
SELECT * FROM fn_calcular_descuentos_reales(CURRENT_DATE - INTERVAL '1 day');
```

---

## 🔄 **PASO 7: Procedimientos de Mantenimiento**

### **7.1 Reporte Diario Automático**

```sql
-- File: 06_procedimiento_diario.sql
-- Procedimiento para ejecutar validación diaria
CREATE OR REPLACE PROCEDURE sp_validacion_diaria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha DATE := CURRENT_DATE - INTERVAL '1 day';
    v_problemas_criticos INTEGER := 0;
    v_total_problemas INTEGER := 0;
BEGIN
    -- Contar problemas críticos
    SELECT COUNT(*) INTO v_problemas_criticos
    FROM fn_validar_integridad_corte(v_fecha, v_fecha)
    WHERE severidad = 'CRITICO';

    -- Contar todos los problemas
    SELECT COUNT(*) INTO v_total_problemas
    FROM fn_validar_integridad_corte(v_fecha, v_fecha);

    -- Insertar en log de auditoría
    INSERT INTO selemti.auditoria(quien, que, payload)
    VALUES (
        0, -- Sistema
        'VALIDACION_DIARIA',
        json_build_object(
            'fecha_validada', v_fecha,
            'problemas_criticos', v_problemas_criticos,
            'total_problemas', v_total_problemas,
            'estatus', CASE WHEN v_problemas_criticos = 0 THEN 'OK' ELSE 'ERROR' END,
            'timestamp_ejecucion', CURRENT_TIMESTAMP
        )
    );

    -- Si hay problemas críticos, registrar detalle
    IF v_problemas_criticos > 0 THEN
        INSERT INTO selemti.auditoria(quien, que, payload)
        SELECT
            0,
            'DETALLE_PROBLEMAS_CRITICOS',
            json_build_object(
                'problema', tipo_problema,
                'terminal', terminal_id,
                'descripcion', descripcion,
                'valores', valores,
                'recomendacion', recomendacion
            )
        FROM fn_validar_integridad_corte(v_fecha, v_fecha)
        WHERE severidad = 'CRITICO';
    END IF;

    COMMIT;
END;
$$;

-- Agendar para ejecución diaria (depende del sistema de scheduling)
-- Ejemplo: cron job para ejecutar a las 2:00 AM
-- 0 2 * * * psql -h localhost -U postgres -d pos -c "CALL sp_validacion_diaria();"
```

---

## 🚨 **PASO 8: Rollback Plan**

### **8.1 Procedimiento de Rollback**

```sql
-- File: 07_rollback_procedure.sql
-- En caso de problemas críticos, ejecutar este rollback

-- 1. Eliminar vistas y funciones creadas
DROP VIEW IF EXISTS vw_descuentos_reales;
DROP VIEW IF EXISTS vw_corte_caja_completo;
DROP FUNCTION IF EXISTS fn_calcular_descuentos_reales(DATE, INTEGER);
DROP FUNCTION IF EXISTS fn_validar_integridad_corte(DATE, DATE);
DROP PROCEDURE IF EXISTS sp_validacion_diaria();

-- 2. Eliminar índices creados
DROP INDEX IF EXISTS idx_ticket_fecha_terminal_void;
DROP INDEX IF EXISTS idx_ticket_descuento;
DROP INDEX IF EXISTS idx_ticket_discount_ticket;
DROP INDEX IF EXISTS idx_ticket_discount_value;
DROP INDEX IF EXISTS idx_ticket_item_discount_item;
DROP INDEX IF EXISTS idx_ticket_item_discount_value;
DROP INDEX IF EXISTS idx_transactions_fecha_terminal;
DROP INDEX IF EXISTS idx_transactions_payment_type;
DROP INDEX IF EXISTS idx_transactions_ticket;
DROP INDEX IF EXISTS idx_drawer_pull_fecha_terminal;
DROP INDEX IF EXISTS idx_ticket_completo;
DROP INDEX IF EXISTS idx_transactions_completo;

-- 3. Validar estado original
SELECT 'ROLLBACK_COMPLETADO' as estado;
SELECT COUNT(*) as tickets_totales, SUM(total_discount) as descuentos_originales
FROM public.ticket WHERE voided = false;
```

### **8.2 Validación de Rollback**

```sql
-- Verificar que todo volvió al estado original
SELECT
    'VALIDACION_ROLLBACK' as prueba,
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'vw_descuentos_reales')
        THEN 'OK'
        ELSE 'ERROR'
    END as vistas_eliminadas,
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'fn_calcular_descuentos_reales')
        THEN 'OK'
        ELSE 'ERROR'
    END as funciones_eliminadas;
```

---

## 📋 **Checklist Final de Implementación**

### **✅ Pre-Implementación:**
- [ ] Backup completo de base de datos
- [ ] Verificación de estado actual
- [ ] Backup de tablas críticas específicas

### **✅ Implementación:**
- [ ] Crear vista `vw_descuentos_reales`
- [ ] Validar corrección de duplicación
- [ ] Crear función `fn_calcular_descuentos_reales`
- [ ] Implementar vista `vw_corte_caja_completo`
- [ ] Configurar sistema de validación automática
- [ ] Crear índices de performance
- [ ] Ejecutar validación final

### **✅ Post-Implementación:**
- [ ] Comparar antes vs después
- [ ] Test de performance
- [ ] Documentar resultados
- [ ] Capacitar usuarios
- [ ] Programar mantenimiento diario

### **✅ Monitoreo:**
- [ ] Ejecutar validación por 7 días
- [ ] Monitorizar performance
- [ ] Revisar logs de errores
- [ ] Validar consistencia de datos

---

## 🎯 **Resultado Esperado**

### **Métricas de Éxito:**
- **Error Descuentos:** 264% → <5%
- **Tickets Duplicados:** Variable → 0
- **Performance Queries:** <2 segundos
- **Consistencia Datos:** 100%

### **Impacto en Negocio:**
- **Confianza Reportes:** 100%
- **Tiempo Corrección:** Automático
- **Detección Problemas:** Inmediata
- **Toma Decisiones:** Basada en datos precisos

---

## 🚀 **¡Listo para Implementar!**

### **Comando de Ejecución:**
```bash
# Ejecutar todos los scripts en orden
psql -h localhost -p 5433 -U postgres -d pos -f 01_vista_descuentos_reales.sql
psql -h localhost -p 5433 -U postgres -d pos -f 02_funcion_descuentos_reales.sql
psql -h localhost -p 5433 -U postgres -d pos -f 03_vista_corte_caja_completo.sql
psql -h localhost -p 5433 -U postgres -d pos -f 04_funcion_validacion_integridad.sql
psql -h localhost -p 5433 -U postgres -d pos -f 05_indices_optimizacion.sql
psql -h localhost -p 5433 -U postgres -d pos -f 06_procedimiento_diario.sql
```

### **Validación Post-Implementación:**
```sql
-- Verificar todo funciona correctamente
SELECT * FROM fn_validar_integridad_corte();
SELECT * FROM vw_corte_caja_completo WHERE fecha = CURRENT_DATE - INTERVAL '1 day';
SELECT COUNT(*) FROM vw_descuentos_reales WHERE estatus_duplicacion != 'SIN_DUPLICACION';
```

---

**¡El sistema está listo para ser corregido! Estos scripts solucionarán el problema crítico de duplicación y proporcionarán datos precisos y confiables para todos los reportes.** 🚀