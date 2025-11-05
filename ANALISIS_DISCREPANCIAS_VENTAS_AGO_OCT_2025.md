# ANÁLISIS COMPLETO DE DISCREPANCIAS EN VENTAS
## Período: Agosto - Octubre 2025

**Fecha del Análisis:** 2025-11-05  
**Script Utilizado:** `scripts/analyze_sales_discrepancies.php`

---

## RESUMEN EJECUTIVO

Se identificaron **5 categorías principales de problemas** que están causando discrepancias significativas en los reportes de ventas y caja. El análisis abarcó 3 meses (agosto, septiembre y octubre 2025) y reveló patrones sistemáticos que afectan la integridad de los datos financieros.

### Cifras Clave

- **Total de tickets con problemas:** 251 tickets
- **Impacto financiero directo:** $34,534.20 en discrepancias
- **Reportes de caja afectados:** 155 de 156 (99.4%)
- **Discrepancia total en reportes:** $2,133,602.00

---

## PROBLEMAS IDENTIFICADOS

### 1. 🎫 TICKETS CON DESCUENTO DEL 100%

**Hallazgo Principal:** Los tickets con descuento del 100% NO se están registrando correctamente en el sistema de reportes.

**Datos:**
- **Total de tickets:** 79
- **Monto total descontado:** $7,855.00
- **Estado de pago:** 100% no pagados (79/79)
- **Estado de cierre:** 100% cerrados

**Distribución por Mes:**
- Agosto 2025: 22 tickets ($2,080.00)
- Septiembre 2025: 37 tickets ($3,794.00)
- Octubre 2025: 20 tickets ($1,981.00)

**Problema Detectado:**
El sistema está registrando el descuento como "$100" en lugar del monto real del ticket. Por ejemplo:
- Ticket ID 37: Descuento de $120 → se registra como $100
- Ticket ID 187: Descuento de $73 → se registra como $100

**Impacto:**
- Los reportes subestiman el monto real de descuentos otorgados
- Las ventas brutas no coinciden con las ventas netas
- Los tickets quedan marcados como "no pagados" afectando la integridad de los datos

**Recomendaciones:**
1. ✅ Corregir la lógica de registro de descuentos al 100% para que capture el monto real
2. ✅ Implementar validación que marque estos tickets como "pagados" si el descuento es 100%
3. ✅ Crear un reporte específico para tickets con descuento del 100% para auditoría

---

### 2. 💰 TICKETS NO PAGADOS PERO CERRADOS

**Hallazgo Principal:** Existen tickets que se cerraron sin registrar ningún pago, pero que tienen un total > $0.

**Datos:**
- **Total de tickets:** 22
- **Monto no cobrado:** $2,428.10
- **Todos tienen:** $0.00 en transacciones registradas

**Distribución por Mes:**
- Agosto 2025: 16 tickets ($1,931.10)
- Septiembre 2025: 5 tickets ($472.00)
- Octubre 2025: 1 ticket ($25.00)

**Casos Críticos:**
- Ticket ID 14: $802.00 no cobrado
- Ticket ID 550: $241.00 no cobrado
- Ticket ID 549: $228.00 no cobrado

**Posibles Causas:**
1. Error en el proceso de cierre de caja
2. Descuentos del 100% no correctamente etiquetados
3. Tickets de cortesía sin marcado apropiado
4. Fallos en la sincronización POS → BD

**Impacto:**
- Inflación artificial de las ventas (ventas registradas sin ingreso real)
- Descuadre en caja al final del día
- Imposibilidad de conciliar ventas vs efectivo recibido

**Recomendaciones:**
1. ✅ Implementar validación: NO permitir cerrar ticket con total > $0 y pagos = $0
2. ✅ Crear proceso de revisión manual para estos casos
3. ✅ Backfill: Analizar cada uno de estos 22 tickets y corregir/anotar

---

### 3. ❌ TICKETS ANULADOS CON TRANSACCIONES

**Hallazgo Principal:** Tickets marcados como "anulados" (voided=TRUE) que aún tienen transacciones de pago registradas.

**Datos:**
- **Total de tickets:** 108
- **Monto en transacciones:** $20,987.00
- **Patrón observado:** Cash + Refund + Void por el mismo monto (triple registro)

**Distribución por Mes:**
- Agosto 2025: 13 tickets ($3,450.00)
- Septiembre 2025: 31 tickets ($5,172.00)
- Octubre 2025: 64 tickets ($12,365.00) ← **Incremento significativo**

**Ejemplo del Problema (Ticket ID 101):**
```
Total del ticket: $137.00
- Transacción CASH: +$137.00
- Transacción REFUND: +$137.00  
- Transacción VOID_TRANS: +$137.00
= Total registrado: $411.00 para un ticket de $137.00
```

**Problema Detectado:**
El sistema está registrando TRES transacciones cuando se anula un ticket:
1. El pago original
2. El reembolso
3. La transacción de anulación

Esto causa que el mismo dinero se cuente 3 veces.

**Impacto:**
- Inflación masiva en los totales de efectivo ($20,987 × 3 = ~$62,961)
- Reportes de caja incorrectos
- Incremento en octubre sugiere un problema creciente

**Recomendaciones:**
1. ✅ **URGENTE:** Revisar la lógica de anulación de tickets
2. ✅ Implementar: Al anular, solo registrar VOID_TRANS (no duplicar pagos)
3. ✅ Crear script de corrección para los 108 tickets afectados
4. ✅ Auditar por qué hay incremento en octubre (¿cambio en el sistema?)

---

### 4. ⚖️ TICKETS CON DISCREPANCIA ENTRE TOTAL Y PAGOS

**Hallazgo Principal:** Tickets donde la suma de pagos NO coincide con el total del ticket.

**Datos:**
- **Total de tickets:** 42
- **Diferencia total:** $3,264.10

**Distribución por Mes:**
- Agosto 2025: 17 tickets ($1,918.10)
- Septiembre 2025: 5 tickets ($442.00)
- Octubre 2025: 20 tickets ($904.00)

**Casos Críticos:**
| Ticket ID | Fecha | Total | Pagado | Diferencia |
|-----------|-------|-------|--------|------------|
| 14 | 2025-08-15 | $802.00 | $0.00 | $802.00 |
| 22441 | 2025-10-20 | $100.00 | $2.00 | $98.00 |
| 6932 | 2025-09-06 | $106.00 | $10.00 | $96.00 |
| 24456 | 2025-10-27 | $138.00 | $52.00 | $86.00 |

**Patrones Observados:**
- Algunos tickets tienen pago PARCIAL (ej: $100 total, $2 pagado)
- Mayoría tienen pago CERO pero total > 0
- Posible problema con propinas no registradas

**Impacto:**
- Imposibilidad de cuadrar caja
- Reportes de ventas no confiables
- Posible pérdida de ingresos no rastreada

**Recomendaciones:**
1. ✅ Implementar alerta en tiempo real cuando pago ≠ total
2. ✅ Investigar tickets con pago parcial (propinas, adelantos?)
3. ✅ Crear proceso de reconciliación diaria

---

### 5. 📊 DISCREPANCIAS EN REPORTES DE CAJA (DRAWER PULL REPORTS)

**Hallazgo Principal:** Discrepancia MASIVA entre lo reportado y lo real en casi todos los reportes de caja.

**Datos:**
- **Reportes analizados:** 156
- **Reportes con problemas:** 155 (99.4%)
- **Diferencia en efectivo:** $1,155,204.01
- **Diferencia en tickets:** 36,196 tickets
- **Diferencia en ventas:** $2,133,602.00

**Patrón Observado:**
TODOS los reportes muestran valores NEGATIVOS, lo que significa que el sistema está reportando MENOS de lo que realmente existe en la base de datos.

**Ejemplo (2025-08-15):**
```
Reportado: $15,050.00
Real en BD: $30,100.00  
Diferencia: -$15,050.00 (el reporte muestra la mitad de lo real)
```

**Problema Crítico Detectado:**
El algoritmo que genera los Drawer Pull Reports NO está considerando:
1. Todos los tickets cerrados del día
2. Todas las transacciones de pago
3. Tickets anulados correctamente

Posiblemente está usando una **consulta diferente** a la que debería usar, o tiene filtros incorrectos (ej: solo cuenta un turno en lugar de todo el día).

**Impacto:**
- **CRÍTICO:** Los reportes de caja son completamente no confiables
- Imposibilidad de auditoría financiera
- Riesgo legal y contable

**Recomendaciones URGENTES:**
1. ✅ **PRIORIDAD MÁXIMA:** Revisar el código que genera `drawer_pull_report`
2. ✅ Comparar con las vistas `vw_sales_mix_payment` y `vw_report_journal_payments`
3. ✅ Implementar validación cruzada antes de guardar el reporte
4. ✅ Deshabilitar temporalmente la generación automática hasta corregir
5. ✅ Generar reportes correctos retroactivamente para agosto-octubre

---

## ANÁLISIS DE PATRONES TEMPORALES

### Tendencia de Problemas por Mes

| Categoría | Agosto | Septiembre | Octubre | Tendencia |
|-----------|--------|------------|---------|-----------|
| Descuento 100% | 22 | 37 | 20 | ↑↓ Variable |
| No pagados | 16 | 5 | 1 | ↓ Mejorando |
| Anulados c/trans | 13 | 31 | 64 | ↑↑ Empeorando |
| Disc. pago | 17 | 5 | 20 | ↑↓ Variable |

**Observación Crítica:**  
El problema de "Tickets anulados con transacciones" está **EMPEORANDO** significativamente (13 → 31 → 64). Esto sugiere:
- Posible cambio en el código en agosto/septiembre
- Capacitación inadecuada del personal
- Bug introducido que se está propagando

---

## IMPACTO FINANCIERO TOTAL

### Resumen de Discrepancias Directas
```
Descuentos mal registrados:        $7,855.00
Ventas no cobradas:                $2,428.10
Transacciones duplicadas:         $20,987.00
Discrepancias pago vs total:       $3,264.10
                                  ___________
SUBTOTAL (Problemas directos):    $34,534.20
```

### Impacto en Reportes de Caja
```
Diferencia total reportes:    $2,133,602.00
```

**TOTAL ESTIMADO DE EXPOSICIÓN FINANCIERA:** ~$2,168,136.20

---

## CAUSA RAÍZ IDENTIFICADA

Basándose en el análisis, las causas raíz son:

### 1. **Descuentos al 100%**
- **Causa:** Lógica de negocio incorrecta que registra "100" en lugar del monto real
- **Ubicación probable:** Controller o modelo de Descuentos/Cortesías
- **Severidad:** Media
- **Esfuerzo de corrección:** Bajo (1-2 días)

### 2. **Tickets sin pago**
- **Causa:** Falta de validación en el proceso de cierre
- **Ubicación probable:** POS → API de cierre de ticket
- **Severidad:** Media
- **Esfuerzo de corrección:** Medio (3-5 días)

### 3. **Anulaciones con triple registro**
- **Causa:** Lógica de anulación que no limpia transacciones anteriores
- **Ubicación probable:** Módulo de anulaciones / refunds
- **Severidad:** **ALTA** (problema creciente)
- **Esfuerzo de corrección:** Alto (5-7 días + testing)

### 4. **Drawer Pull Reports incorrectos**
- **Causa:** Consulta SQL incorrecta o filtros mal aplicados
- **Ubicación probable:** `drawer_pull_report` generator
- **Severidad:** **CRÍTICA** (99% de reportes afectados)
- **Esfuerzo de corrección:** Alto (7-10 días + validación)

---

## PLAN DE ACCIÓN RECOMENDADO

### FASE 1: URGENTE (Semana 1)
1. **Deshabilitar generación automática de Drawer Pull Reports**
2. **Crear script de validación** que alerte discrepancias en tiempo real
3. **Auditar los 108 tickets anulados** del período
4. **Corregir lógica de descuentos al 100%**

### FASE 2: CORRECCIÓN (Semanas 2-3)
1. **Reescribir módulo de anulaciones** para evitar triple registro
2. **Implementar validaciones de cierre** (no permitir total > 0 sin pagos)
3. **Corregir generador de Drawer Pull Reports**
4. **Crear tests automatizados** para cada escenario

### FASE 3: RECUPERACIÓN (Semanas 4-5)
1. **Regenerar reportes correctos** para agosto-octubre
2. **Reconciliar discrepancias** con datos bancarios
3. **Documentar ajustes contables** necesarios
4. **Capacitar personal** en nuevos procesos

### FASE 4: PREVENCIÓN (Semana 6+)
1. **Implementar dashboard de monitoreo** en tiempo real
2. **Alertas automáticas** para anomalías
3. **Auditoría semanal** de discrepancias
4. **Revisión mensual** de integridad de datos

---

## ARCHIVOS GENERADOS

- **Script de análisis:** `scripts/analyze_sales_discrepancies.php`
- **Resultados JSON:** `storage/logs/sales_discrepancies_2025-11-05_042608.json`
- **Log de salida:** `storage/logs/analysis_output.txt`

---

## CONSULTAS SQL ÚTILES

### Ver tickets con descuento 100% de un día específico
```sql
SELECT t.id, t.folio_date, t.total_price, t.total_discount, t.paid, t.voided
FROM public.ticket t
WHERE t.folio_date = '2025-10-01'
  AND t.total_discount > 0
  AND t.total_price = 0
ORDER BY t.id;
```

### Ver tickets anulados con transacciones
```sql
SELECT 
    t.id,
    t.voided,
    COUNT(tr.id) as trans_count,
    SUM(tr.amount) as total_trans
FROM public.ticket t
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
WHERE t.folio_date = '2025-10-01'
  AND t.voided = TRUE
GROUP BY t.id, t.voided
HAVING COUNT(tr.id) > 0;
```

### Comparar reporte vs realidad
```sql
SELECT 
    dpr.id as report_id,
    DATE(dpr.report_time) as report_date,
    dpr.cash_receipt_amount as reported_cash,
    dpr.ticket_count as reported_tickets,
    COUNT(DISTINCT t.id) as actual_tickets,
    COALESCE(SUM(CASE WHEN tr.payment_type = 'CASH' THEN tr.amount ELSE 0 END), 0) as actual_cash
FROM public.drawer_pull_report dpr
LEFT JOIN public.ticket t ON DATE(t.folio_date) = DATE(dpr.report_time)
LEFT JOIN public.transactions tr ON t.id = tr.ticket_id
WHERE DATE(dpr.report_time) = '2025-10-01'
GROUP BY dpr.id, dpr.report_time, dpr.cash_receipt_amount, dpr.ticket_count;
```

---

## CONCLUSIÓN

El sistema de reportes tiene **problemas críticos sistemáticos** que requieren atención inmediata. La buena noticia es que todos los datos están en la base de datos, solo necesitamos:

1. ✅ Corregir la lógica de negocio
2. ✅ Implementar validaciones
3. ✅ Regenerar reportes correctos

**Tiempo estimado de corrección completa:** 6-8 semanas  
**Riesgo si no se corrige:** Alto - Problemas legales, contables y de auditoría

---

**Elaborado por:** Script automatizado de análisis  
**Fecha:** 2025-11-05  
**Versión:** 1.0
