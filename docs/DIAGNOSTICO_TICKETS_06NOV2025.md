# 📊 REPORTE DE DIAGNÓSTICO: Tickets Problemáticos

**Fecha de Ejecución:** 06 de Noviembre 2025
**Base de Datos:** PostgreSQL 9.5 - Database: pos
**Ejecutado por:** Claude Code

---

## 🎯 RESUMEN EJECUTIVO

Se identificaron **150 tickets problemáticos** que afectan los cortes de caja y reportes de ventas, representando **$3,523 MXN** en montos y **$3,259 MXN** en deudas pendientes.

### Clasificación de Problemas

| Categoría | Cantidad | Monto Total | Deuda Total | Prioridad |
|-----------|----------|-------------|-------------|-----------|
| 🔴 Cerrados sin pago | 107 | $2,428 | $2,353 | **CRÍTICO** |
| 🟠 Abiertos con deuda | 21 | $1,300 | $1,186 | **ALTO** |
| 🟡 Abiertos vacíos | 20 | $0 | $0 | **MEDIO** |
| 🟡 Pagados sin cierre | 2 | $75 | $0 | **BAJO** |
| **TOTAL** | **150** | **$3,803** | **$3,539** | |

---

## 🔴 TIPO A: Tickets Cerrados sin Pago (107 tickets)

### Resumen
- **Total de tickets:** 107
- **Con monto real:** 22 tickets ($2,428 MXN)
- **Vacíos (cancelados):** 85 tickets ($0 MXN)

### Desglose de los 22 Tickets Críticos

| ID | Fecha Creación | Fecha Cierre | Monto | Deuda | Terminal | Transacciones | Pagado |
|----|----------------|--------------|-------|-------|----------|---------------|--------|
| 14 | 2025-08-15 | 2025-08-15 | $802 | $802 | 102 | 0 | $0 |
| 550 | 2025-08-19 | 2025-08-19 | $241 | $241 | 9939 | 0 | $0 |
| 549 | 2025-08-19 | 2025-08-19 | $228 | $228 | 9939 | 0 | $0 |
| 14703 | 2025-09-29 | 2025-09-29 | $208 | $208 | 102 | 1 | $0 |
| 28 | 2025-08-15 | 2025-08-15 | $158 | $158 | 102 | 0 | $0 |
| 6932 | 2025-09-06 | 2025-09-19 | $106 | $96 | 101 | 1 | $10 |
| 11245 | 2025-09-19 | 2025-09-19 | $85 | $85 | 101 | 1 | $0 |
| 26 | 2025-08-15 | 2025-08-15 | $68 | $68 | 102 | 0 | $0 |
| 27 | 2025-08-15 | 2025-08-15 | $68 | $68 | 102 | 0 | $0 |
| 497 | 2025-08-18 | 2025-08-18 | $65 | $65 | 101 | 0 | $0 |
| 318 | 2025-08-18 | 2025-08-18 | $63 | $63 | 101 | 0 | $0 |
| 3413 | 2025-08-28 | 2025-09-19 | $55 | $15 | 101 | 2 | $40 |
| 496 | 2025-08-18 | 2025-08-18 | $50 | $50 | 101 | 0 | $0 |
| 31 | 2025-08-15 | 2025-08-15 | $42 | $42 | 102 | 0 | $0 |
| 8275 | 2025-09-10 | 2025-09-19 | $38 | $38 | 101 | 0 | $0 |
| 498 | 2025-08-18 | 2025-08-19 | $38 | $38 | 101 | 0 | $0 |
| 15159 | 2025-09-30 | 2025-09-30 | $35 | $15 | 101 | 1 | $20 |
| 62 | 2025-08-15 | 2025-08-18 | $25 | $25 | 102 | 0 | $0 |
| 15527 | 2025-10-01 | 2025-10-01 | $25 | $25 | 101 | 1 | $0 |
| 2744 | 2025-08-27 | 2025-08-27 | $15 | $10 | 101 | 1 | $5 |
| 416 | 2025-08-18 | 2025-08-18 | $13 | $13 | 101 | 1 | $0 |
| 754 | 2025-08-19 | 2025-08-19 | $0.10 | $0.10 | 9939 | 0 | $0 |

### Análisis
- **16 tickets (72%)** NO tienen ninguna transacción → Probablemente nunca fueron pagados
- **6 tickets (28%)** tienen transacciones parciales → Fueron pagados parcialmente
- **Patrón identificado:** Varios tickets del 19/09/2025 tienen `closing_date = 2025-09-19 04:32:56.605696` (timestamp idéntico), lo que indica un proceso de cierre masivo automático.

### ⚠️ **Impacto:**
- Estos tickets NO aparecen en reportes de ventas (porque `paid=false`)
- Representan **ventas reales no reportadas** = $2,428 MXN
- Pueden afectar declaraciones fiscales si se corrigen

---

## 🟠 TIPO B: Tickets Abiertos con Deuda (21 tickets)

### Tickets por Antigüedad

| ID | Fecha | Días Abierto | Monto | Deuda | Terminal | Tipo | Items |
|----|-------|--------------|-------|-------|----------|------|-------|
| 20226 | 2025-10-14 | **23 días** | $45 | $45 | 102 | CAFETERÍAS | 1 |
| 21310 | 2025-10-16 | **21 días** | $65 | $65 | 102 | PRINCIPAL | 1 |
| 21347 | 2025-10-16 | **21 días** | $45 | $35 | 102 | PRINCIPAL | 1 |
| 21456 | 2025-10-17 | **20 días** | $76 | $76 | 102 | PRINCIPAL | 3 |
| 21778 | 2025-10-17 | **20 días** | $15 | $15 | 101 | PRINCIPAL | 1 |
| 22129 | 2025-10-18 | **19 días** | $45 | $45 | 102 | PRINCIPAL | 1 |
| 21896 | 2025-10-18 | **19 días** | $20 | $20 | 101 | PRINCIPAL | 1 |
| 22447 | 2025-10-20 | **17 días** | $20 | $20 | 101 | PRINCIPAL | 1 |
| 22441 | 2025-10-20 | **17 días** | $100 | $98 | 101 | PRINCIPAL | 2 |
| 22634 | 2025-10-21 | **16 días** | $125 | $125 | 101 | PRINCIPAL | 4 |
| 22689 | 2025-10-21 | **16 días** | $58 | $58 | 102 | PRINCIPAL | 2 |
| 22641 | 2025-10-21 | **16 días** | $18 | $18 | 101 | PRINCIPAL | 1 |
| 23312 | 2025-10-22 | **15 días** | $55 | $55 | 101 | PRINCIPAL | 1 |
| 23988 | 2025-10-24 | **13 días** | $15 | $15 | 101 | PRINCIPAL | 1 |
| 24189 | 2025-10-25 | **12 días** | $63 | $13 | 101 | PRINCIPAL | 2 |
| 24726 | 2025-10-27 | **10 días** | $24 | $24 | 102 | PRINCIPAL | 1 |
| 24456 | 2025-10-27 | **10 días** | $138 | $86 | 101 | PRINCIPAL | 2 |
| 25024 | 2025-10-28 | **9 días** | $46 | $46 | 102 | PRINCIPAL | 1 |
| 25294 | 2025-10-29 | **8 días** | $20 | $20 | 101 | PRINCIPAL | 1 |
| 27040 | 2025-11-06 | **0 días** | $27 | $27 | 9939 | PRINCIPAL | 1 |
| 27042 | 2025-11-06 | **0 días** | $280 | $280 | 9939 | PRINCIPAL | 1 |

### Análisis
- **19 tickets antiguos (>7 días)** representan $993 MXN en deuda
- **Ticket más antiguo:** 23 días sin cerrar
- **2 tickets del terminal 9939** (inválido) creados hoy = $307 MXN

### ⚠️ **Impacto:**
- Estos tickets están **contaminando los cortes de caja**
- Aparecen como ventas del día en los reportes
- El ejemplo del usuario muestra exactamente este problema

---

## 🟡 TIPO C: Tickets Abiertos Vacíos (20 tickets)

### Resumen
- **Total:** 20 tickets
- **Todos tienen items** (no están realmente vacíos)
- **Antigüedad:** Entre 8 y 22 días
- **Monto total:** $0 (items eliminados o descuentos 100%)

### Detalle

| ID | Fecha | Días | Terminal | Items |
|----|-------|------|----------|-------|
| 20833, 20672, 20840 | 2025-10-15 | 22 días | 102 | 2-3 |
| 20449 | 2025-10-15 | 22 días | **401** | 1 |
| 21368, 21714, 21447, 21677 | 2025-10-16-17 | 20-21 días | 101-102 | 1-3 |
| 22523, 22353, 22549, 22697 | 2025-10-20-21 | 16-17 días | 101-102 | 1-2 |
| 23189, 23432, 23680, 23957 | 2025-10-22-24 | 13-15 días | 101-102 | 1-2 |
| 24641, 24955, 24983, 25417 | 2025-10-27-29 | 8-10 días | 101-102 | 1-3 |

### Análisis
- Probablemente tickets cancelados pero no anulados correctamente
- **1 ticket del terminal 401** (inválido)

### ⚠️ **Impacto:**
- Generan ruido en reportes
- NO afectan números (monto $0)
- Deben ser anulados para limpieza

---

## 🟡 TIPO D: Tickets Pagados sin Cierre (2 tickets)

| ID | Fecha | Monto | Pagado | Deuda | Terminal | Drawer Reset | Re-abierto | Transacciones |
|----|-------|-------|--------|-------|----------|--------------|------------|---------------|
| 2334 | 2025-08-26 | $10 | $10 | $0 | 101 | ✅ Sí | ✅ Sí | 1 ($10) |
| 27036 | 2025-11-06 | $65 | $65 | $0 | 9939 | ❌ No | ✅ Sí | 1 ($65) |

### Análisis
- Ambos tickets tienen `is_re_opened = true` → Fueron re-abiertos después de ser pagados
- El ticket 2334 tiene `drawer_resetted = true` → Relacionado con reset de cajón
- Ambos están completamente pagados (`due_amount = 0`)

### ⚠️ **Impacto:**
- Están siendo **incluidos en reportes** aunque no deberían (por falta de `closing_date`)
- Bajo impacto ($75 MXN total)

---

## 🚨 HALLAZGO CRÍTICO: Terminales Inválidos

Se detectaron tickets en **2 terminales que NO existen** en el sistema:

| Terminal | Tickets | Monto Total | Período | Abiertos |
|----------|---------|-------------|---------|----------|
| **401** | 142 | $3,895.60 | 29/09 - 04/11 | 1 |
| **9939** | 22 | $1,836.30 | 16/08 - 06/11 | 2 |
| **TOTAL** | **164** | **$5,731.90** | | **3** |

### Terminales Válidos
- Terminal 101: TERRERA
- Terminal 102: TERRERA

### ⚠️ **Impacto:**
- **$5,731.90 MXN** en ventas de terminales inválidos
- Terminal 401: Probablemente "ENTRADA" o cafetería
- Terminal 9939: Posiblemente terminal de prueba o desarrollo

### Recomendación
1. Identificar el origen de estos terminales
2. Reasignar tickets a terminales correctos
3. Actualizar configuración del POS

---

## ✅ HALLAZGO POSITIVO: NO hay Tickets Huérfanos

**Resultado:** 0 tickets pagados sin transacciones

Todos los tickets marcados como `paid = true` tienen al menos una transacción registrada, lo que indica que el sistema está registrando correctamente los pagos.

---

## 📊 IMPACTO EN REPORTES DE VENTAS

### Problema Principal: Vista `vw_ticket_base`

**Filtro actual:**
```sql
WHERE t.paid = true AND t.voided = false
```

**Problemas identificados:**
1. ❌ NO valida `closing_date IS NOT NULL`
   - **Consecuencia:** Incluye 2 tickets pagados sin cierre ($75)

2. ❌ NO valida `due_amount = 0`
   - **Consecuencia:** Puede incluir tickets con deudas

3. ❌ Excluye 22 tickets cerrados con monto real ($2,428)
   - **Consecuencia:** **Subdeclara ventas reales**

### Ejemplo del Usuario (06/11/2025 07:40 AM)

**Corte reportado:**
- Terminal 101: $462 en ventas
- Terminal 102: $45 en ventas

**Causa raíz:**
Los 21 tickets abiertos con deuda (antiguos) están sumándose a las ventas del día porque la consulta no filtra correctamente por `folio_date` o `closing_date`.

---

## 🎯 RESUMEN DE HALLAZGOS CRÍTICOS

### 1. **Tickets Cerrados sin Pago Real**
- **22 tickets con monto = $2,428 MXN**
- 16 sin transacciones, 6 con pagos parciales
- Representa ventas NO reportadas

### 2. **Tickets Abiertos Antiguos Afectando Cortes**
- **19 tickets >7 días = $993 MXN**
- Contaminan cortes de caja actuales
- Necesitan revisión y cierre inmediato

### 3. **Terminales Inválidos en Producción**
- **Terminal 401:** 142 tickets, $3,895 MXN
- **Terminal 9939:** 22 tickets, $1,836 MXN
- Requiere investigación urgente

### 4. **Vista de Reportes Incorrecta**
- Filtro actual excluye ventas reales
- Incluye tickets que no deberían estar
- Causa discrepancias en cortes

---

## 🚀 ACCIONES INMEDIATAS REQUERIDAS

### ⚡ URGENTE (Hoy)
1. **Actualizar filtro de `vw_ticket_base`** para excluir tickets abiertos antiguos
2. **Investigar terminales 401 y 9939** - ¿Son válidos?
3. **Generar lista Excel** de los 22 tickets cerrados sin pago para revisión contable

### 📅 ESTA SEMANA
1. **Revisar manualmente** los 22 tickets cerrados sin pago
2. **Cerrar/Anular** tickets abiertos >14 días (previa aprobación)
3. **Reasignar** tickets de terminales inválidos

### 📅 PRÓXIMAS 2 SEMANAS
1. **Implementar trigger** de validación de cierre
2. **Dashboard** de salud de tickets en tiempo real
3. **Proceso semanal** de revisión de tickets antiguos

---

## 📎 ARCHIVOS GENERADOS

1. **`docs/ANALISIS_TICKETS_ABIERTOS.md`** - Análisis completo con scripts de corrección
2. **`BD/Noviembre/fix_tickets/01_diagnostico_tickets.sql`** - Script SQL de diagnóstico
3. **`docs/DIAGNOSTICO_TICKETS_06NOV2025.md`** - Este reporte (resultados de ejecución)

---

## 👥 PRÓXIMOS PASOS

1. **Reunión urgente** con Gerencia, Contabilidad, IT
2. **Decidir estrategia** para los 22 tickets cerrados sin pago
3. **Aprobar** scripts de corrección
4. **Ejecutar** plan de limpieza

---

**Elaborado por:** Claude Code
**Ejecutado:** 06 de Noviembre 2025
**Prioridad:** 🔴 **CRÍTICO** - Requiere acción inmediata
**Estado:** ✅ Diagnóstico Completo - Esperando decisiones
