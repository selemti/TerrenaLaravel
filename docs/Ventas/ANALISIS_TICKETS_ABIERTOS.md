# Análisis de Tickets Abiertos y Propuesta de Solución

**Fecha:** 06 de Noviembre 2025
**Analista:** Claude Code
**Estado:** CRÍTICO - Requiere acción inmediata

---

## 📊 Resumen Ejecutivo

Se han identificado **149 tickets problemáticos** en la base de datos que están afectando los cortes de caja y reportes de ventas. El problema más grave son **107 tickets cerrados sin pago** que representan **$2,428 MXN** con una deuda pendiente de **$2,353 MXN**.

---

## 🔍 Hallazgos del Análisis

### 1. Clasificación de Tickets Problemáticos

| Categoría | Cantidad | Monto Total | Deuda Total | Severidad |
|-----------|----------|-------------|-------------|-----------|
| **Cerrado sin pago** | 107 | $2,428 | $2,353 | 🔴 CRÍTICO |
| **Abierto con deuda** | 20 | $1,020 | $906 | 🟠 ALTO |
| **Abierto vacío** | 20 | $0 | $0 | 🟡 MEDIO |
| **Pagado sin cierre** | 2 | $75 | $0 | 🟡 MEDIO |
| **Total problemáticos** | **149** | **$3,523** | **$3,259** | |

### 2. Análisis por Tipo de Problema

#### 🔴 **Tipo A: Tickets Cerrados sin Pago** (107 tickets)
- **Estado:** `paid = false`, `closing_date IS NOT NULL`, `due_amount > 0`
- **Ejemplo:** Tickets 3413, 6932, 8275, 10814
- **Características:**
  - Tienen fecha de cierre con timestamp extraño: `2025-09-19 04:32:56.605696`
  - Status = 'CLOSED'
  - NO están marcados como pagados
  - Tienen deuda pendiente
- **Causa probable:** Proceso de cierre masivo o automático que cerró tickets sin validar el pago
- **Impacto:** Están siendo **excluidos** de reportes de ventas (porque `paid=false`), causando subdeclaración de ventas

#### 🟠 **Tipo B: Tickets Abiertos con Deuda** (20 tickets)
- **Estado:** `paid = false`, `closing_date IS NULL`, `due_amount > 0`
- **Ejemplo:** Tickets 20226, 21456, 22641, 23312, 24456
- **Características:**
  - Creados entre 14 de octubre y 6 de noviembre
  - Tienen monto por cobrar real
  - Algunos llevan más de 20 días abiertos
- **Causa probable:** Operación normal interrumpida (clientes que no pagaron, tickets olvidados)
- **Impacto:** Afectan cortes de caja al aparecer como ventas pendientes

#### 🟡 **Tipo C: Tickets Abiertos Vacíos** (20 tickets)
- **Estado:** `paid = false`, `closing_date IS NULL`, `total_price = 0`
- **Características:**
  - Sin items o con items eliminados
  - Probablemente tickets de prueba o cancelados incorrectamente
- **Impacto:** Ruido en reportes, no afectan números

#### 🟡 **Tipo D: Tickets Pagados sin Cierre** (2 tickets)
- **Estado:** `paid = true`, `closing_date IS NULL`
- **Ejemplo:** Tickets 2334, 27036
- **Características:**
  - Marcados como pagados pero sin fecha de cierre
  - `drawer_resetted = true` o `is_re_opened = true`
  - `due_amount = 0`
- **Causa probable:** Proceso de pago completado pero closing_date no se actualizó
- **Impacto:** **Están siendo incluidos en reportes** aunque no deberían (por no tener closing_date)

### 3. Problema con Terminal ID 9939

Se detectaron tickets (27036, 27040) con `terminal_id = 9939`, que no corresponde a ningún terminal real:
- Terminal 101: TERRERA
- Terminal 102: TERRERA

**Causa probable:** Terminal de prueba o error en configuración.

---

## 🎯 Impacto en Reportes Actuales

### Vista `vw_ticket_base` (Base de Reportes de Ventas)

**Filtro actual:**
```sql
WHERE t.paid = true AND t.voided = false
```

**Problemas:**
1. ❌ **NO verifica** `closing_date IS NOT NULL` → Incluye tickets pagados sin cierre (Tipo D)
2. ❌ **NO verifica** `due_amount = 0` → Puede incluir tickets con deudas
3. ❌ **Excluye** los 107 tickets cerrados sin pago (Tipo A) → Subdeclara ventas reales

### Ejemplo Real del Usuario

**Corte de caja del 06/11/2025 07:40 AM:**
- Terminal 101: Reporta $462 en ventas
- Terminal 102: Reporta $45 en ventas

**Causa:** Los tickets abiertos históricos están sumándose a las ventas del día porque la consulta no filtra adecuadamente por fecha de cierre.

---

## 🛠️ Propuesta de Solución

### FASE 1: Limpieza de Datos Históricos (Urgente)

#### 1.1 Script de Diagnóstico Completo
```sql
-- Identificar todos los tickets problemáticos con detalle
SELECT
    t.id,
    t.create_date,
    t.closing_date,
    t.paid,
    t.voided,
    t.total_price,
    t.due_amount,
    t.terminal_id,
    t.branch_key,
    CASE
        WHEN paid = true AND closing_date IS NULL THEN 'PAGADO_SIN_CIERRE'
        WHEN paid = false AND closing_date IS NOT NULL THEN 'CERRADO_SIN_PAGO'
        WHEN paid = false AND closing_date IS NULL AND due_amount > 0 THEN 'ABIERTO_CON_DEUDA'
        WHEN paid = false AND closing_date IS NULL AND total_price = 0 THEN 'ABIERTO_VACIO'
    END as problema
FROM public.ticket t
WHERE voided = false
    AND (
        (paid = true AND closing_date IS NULL)
        OR (paid = false AND closing_date IS NOT NULL)
        OR (paid = false AND closing_date IS NULL AND (due_amount > 0 OR total_price = 0))
    )
ORDER BY problema, create_date;
```

#### 1.2 Scripts de Corrección (Ejecutar en orden)

**A. Tickets Pagados sin Cierre (Tipo D) - 2 tickets**
```sql
-- Asignar closing_date = create_date para tickets pagados antiguos
UPDATE public.ticket
SET closing_date = create_date
WHERE paid = true
    AND closing_date IS NULL
    AND voided = false
    AND due_amount = 0
    AND create_date < CURRENT_DATE - INTERVAL '7 days';

-- Verificar
SELECT id, create_date, closing_date, paid FROM public.ticket
WHERE paid = true AND closing_date IS NOT NULL AND create_date::date = closing_date::date
LIMIT 5;
```

**B. Tickets Abiertos Vacíos (Tipo C) - 20 tickets**
```sql
-- Anular tickets vacíos antiguos (>30 días)
UPDATE public.ticket
SET
    voided = true,
    void_reason = 'Auto-anulado: ticket vacio historico'
WHERE paid = false
    AND closing_date IS NULL
    AND total_price = 0
    AND voided = false
    AND create_date < CURRENT_DATE - INTERVAL '30 days';
```

**C. Tickets Cerrados sin Pago (Tipo A) - 107 tickets - REQUIERE REVISIÓN MANUAL**
```sql
-- PASO 1: Verificar si tienen transacciones
SELECT
    t.id,
    t.total_price,
    t.due_amount,
    COUNT(tx.id) as num_transacciones,
    SUM(tx.amount) as monto_pagado
FROM public.ticket t
LEFT JOIN public.transactions tx ON tx.ticket_id = t.id AND tx.voided = false
WHERE t.paid = false
    AND t.closing_date IS NOT NULL
    AND t.voided = false
GROUP BY t.id, t.total_price, t.due_amount
ORDER BY t.id;

-- PASO 2A: Si tienen transacciones completas, marcar como pagados
UPDATE public.ticket t
SET
    paid = true,
    paid_amount = (
        SELECT COALESCE(SUM(tx.amount), 0)
        FROM public.transactions tx
        WHERE tx.ticket_id = t.id AND tx.voided = false
    )
WHERE t.paid = false
    AND t.closing_date IS NOT NULL
    AND t.voided = false
    AND EXISTS (
        SELECT 1
        FROM public.transactions tx
        WHERE tx.ticket_id = t.id
            AND tx.voided = false
        HAVING SUM(tx.amount) >= t.total_price - 0.50  -- Tolerancia de 50 centavos
    );

-- PASO 2B: Si NO tienen transacciones o están incompletas, reabrir
UPDATE public.ticket
SET
    closing_date = NULL,
    status = NULL
WHERE paid = false
    AND closing_date IS NOT NULL
    AND voided = false
    AND NOT EXISTS (
        SELECT 1
        FROM public.transactions tx
        WHERE tx.ticket_id = ticket.id AND tx.voided = false
    );
```

**D. Tickets Abiertos con Deuda Antigua (Tipo B) - Solo >60 días**
```sql
-- Anular tickets abiertos con deuda muy antiguos (>60 días)
-- NOTA: Revisar manualmente antes de ejecutar
UPDATE public.ticket
SET
    voided = true,
    void_reason = 'Auto-anulado: cuenta abierta >60 dias sin actividad'
WHERE paid = false
    AND closing_date IS NULL
    AND voided = false
    AND due_amount > 0
    AND create_date < CURRENT_DATE - INTERVAL '60 days';
```

### FASE 2: Corrección de Vistas y Reportes

#### 2.1 Recrear `vw_ticket_base` con Filtro Correcto
```sql
CREATE OR REPLACE VIEW public.vw_ticket_base AS
SELECT
    t.id AS ticket_id,
    t.terminal_id,
    t.branch_key,
    COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
    COALESCE(t.total_price, 0)::numeric(12,2) AS total_price,
    GREATEST(0, LEAST(
        COALESCE(t.total_discount,
            (SELECT SUM(COALESCE(ti.discount, 0))
             FROM ticket_item ti
             WHERE ti.ticket_id = t.id),
        0),
        COALESCE(t.total_price, 0)
    ))::numeric(12,2) AS total_discount,
    COALESCE((
        SELECT SUM(g.amount)
        FROM gratuity g
        WHERE g.ticket_id = t.id
            AND COALESCE(g.refunded, false) = false
            AND COALESCE(g.paid, true) = true
    ), 0)::numeric(12,2) AS tip_amount,
    COALESCE(t.service_charge, 0)::numeric(12,2) AS service_charges
FROM ticket t
WHERE t.paid = true
    AND t.voided = false
    AND t.closing_date IS NOT NULL  -- ✅ NUEVO: Asegurar que esté cerrado
    AND COALESCE(t.due_amount, 0) = 0;  -- ✅ NUEVO: Verificar que no haya deuda
```

#### 2.2 Crear Vista para Tickets Pendientes de Revisión
```sql
CREATE OR REPLACE VIEW public.vw_tickets_pendientes_revision AS
SELECT
    t.id AS ticket_id,
    t.create_date,
    t.closing_date,
    t.paid,
    t.voided,
    t.total_price,
    t.due_amount,
    t.terminal_id,
    t.branch_key,
    CASE
        WHEN paid = true AND closing_date IS NULL THEN 'PAGADO_SIN_CIERRE'
        WHEN paid = false AND closing_date IS NOT NULL THEN 'CERRADO_SIN_PAGO'
        WHEN paid = false AND closing_date IS NULL AND due_amount > 0 AND CURRENT_DATE - create_date::date > 7 THEN 'ABIERTO_ANTIGUA'
        WHEN paid = false AND closing_date IS NULL AND total_price = 0 THEN 'ABIERTO_VACIO'
    END as problema,
    CURRENT_DATE - create_date::date AS dias_desde_creacion,
    (SELECT COUNT(*) FROM transactions tx WHERE tx.ticket_id = t.id AND tx.voided = false) as num_transacciones
FROM public.ticket t
WHERE voided = false
    AND (
        (paid = true AND closing_date IS NULL)
        OR (paid = false AND closing_date IS NOT NULL)
        OR (paid = false AND closing_date IS NULL AND due_amount > 0 AND CURRENT_DATE - create_date::date > 7)
        OR (paid = false AND closing_date IS NULL AND total_price = 0)
    )
ORDER BY
    CASE problema
        WHEN 'CERRADO_SIN_PAGO' THEN 1
        WHEN 'ABIERTO_ANTIGUA' THEN 2
        WHEN 'PAGADO_SIN_CIERRE' THEN 3
        WHEN 'ABIERTO_VACIO' THEN 4
    END,
    create_date;
```

### FASE 3: Mejoras al Reporte de Cuentas Abiertas

#### 3.1 Actualizar Controlador para Categorizar Tickets
- Agregar columna "Tipo de Problema" en el reporte
- Agregar filtros por tipo de problema
- Agregar sección de "Tickets que Requieren Revisión Manual"

#### 3.2 Dashboard de Salud de Tickets
- Widget que muestre tickets problemáticos en tiempo real
- Alertas automáticas cuando un ticket lleva >7 días abierto
- Botón de acción rápida para anular/cerrar tickets

### FASE 4: Prevención (Reglas de Negocio)

#### 4.1 Trigger para Validar Cierre de Tickets
```sql
CREATE OR REPLACE FUNCTION validate_ticket_closure()
RETURNS TRIGGER AS $$
BEGIN
    -- Si se marca como paid=true, debe tener closing_date
    IF NEW.paid = true AND NEW.closing_date IS NULL THEN
        NEW.closing_date = CURRENT_TIMESTAMP;
    END IF;

    -- Si tiene closing_date, debe estar paid=true o voided=true
    IF NEW.closing_date IS NOT NULL AND NEW.paid = false AND NEW.voided = false THEN
        RAISE EXCEPTION 'Cannot close ticket without payment. Ticket ID: %', NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_ticket_closure
BEFORE UPDATE ON public.ticket
FOR EACH ROW
EXECUTE FUNCTION validate_ticket_closure();
```

#### 4.2 Job Programado de Limpieza Automática
```sql
-- Ejecutar diariamente a las 3 AM
-- Anular tickets vacíos >30 días
-- Alertar tickets con deuda >14 días
```

---

## 📋 Plan de Ejecución Recomendado

### Semana 1: Diagnóstico y Backup
- [ ] Ejecutar script de diagnóstico completo
- [ ] Crear backup de tabla `ticket` y `transactions`
- [ ] Documentar los 107 tickets cerrados sin pago (Excel)
- [ ] Validar manualmente una muestra de 10 tickets de cada tipo

### Semana 2: Limpieza Controlada
- [ ] Ejecutar correcciones Tipo D (pagados sin cierre)
- [ ] Ejecutar correcciones Tipo C (vacíos)
- [ ] Revisar manualmente Tipo A (cerrados sin pago) - CRÍTICO
- [ ] Ejecutar correcciones Tipo A por lotes de 10

### Semana 3: Implementación de Mejoras
- [ ] Actualizar `vw_ticket_base`
- [ ] Crear `vw_tickets_pendientes_revision`
- [ ] Actualizar reporte de Cuentas Abiertas
- [ ] Implementar trigger de validación

### Semana 4: Monitoreo y Prevención
- [ ] Dashboard de salud de tickets
- [ ] Configurar alertas automáticas
- [ ] Job de limpieza programado
- [ ] Capacitación al equipo

---

## 🚨 Riesgos y Consideraciones

1. **Los 107 tickets "cerrados sin pago" pueden representar ventas reales no reportadas**
   - Requieren revisión manual caso por caso
   - Pueden afectar declaraciones fiscales si se corrigen retroactivamente

2. **Modificar datos históricos puede afectar auditorías**
   - Documentar cada cambio
   - Mantener backup previo a correcciones
   - Generar log de cambios

3. **El trigger de validación puede romper integraciones existentes**
   - Probar en ambiente de staging
   - Coordinar con equipo de POS (Floreant)

---

## 📞 Siguientes Pasos

1. **Revisar este análisis con el equipo de contabilidad/finanzas**
2. **Decidir estrategia para los 107 tickets cerrados sin pago**
3. **Aprobar plan de ejecución**
4. **Asignar responsables y fechas**

---

**Elaborado por:** Claude Code
**Revisión requerida por:** Gerencia, Contabilidad, IT
**Prioridad:** 🔴 CRÍTICO - Los cortes de caja actuales no son confiables
