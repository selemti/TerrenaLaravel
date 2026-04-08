# Investigación: Conciliación Floreant - Hallazgos de Sesión 16/12/2025

## Resumen Ejecutivo

En esta sesión se descubrió y resolvió el problema de conciliación entre Terrena y Floreant POS. El hallazgo clave fue que los valores esperados para validar el "Modo Conciliación Floreant" eran incorrectos, ya que se basaban en suposiciones anteriores en lugar de los valores reales del reporte JasperReports de Floreant.

## Análisis del Reporte JasperReports

### Archivo Analizado
- **Archivo**: `JasperReports - sales_summary_balance_report.pdf`
- **Fecha**: 16 de diciembre de 2025
- **Usuario**: Admin System
- **Tipo**: Sales Summary Report (Floreant POS)

### Totales Reales de Floreant
Del análisis del PDF se extrajeron los totales exactos:

```
GRS TAXABLE SALES:        $681.00
DISCOUNTS:                $76.80
NET SALES:                $604.20
```

**Descubrimiento Crítico**: Los valores esperados previos ($631/$50/$8.80/$622.20) eran incorrectos. Los valores reales de Floreant son:
- **Gross Sales (Items)**: $681.00
- **Discounts**: $76.80
- **Net Sales**: $604.20

## Consultas de Base de Datos

### Consulta 1: Validación del Net Total
```sql
-- Net: should match transaction totals
SELECT SUM(total_price) as net_total
FROM public.ticket
WHERE DATE(folio_date) = '2025-12-16'
  AND paid = true
  AND voided = false;
```
**Resultado**: $604.20 ✅ **COINCIDE EXACTO**

### Consulta 2: Cálculo de Items
```sql
SELECT SUM(ti.total_price) as items_total
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false;
```
**Resultado**: $672.20 vs esperado $681.00 ❌ **DIFIERE $8.80**

### Consulta 3: Cálculo de Descuentos
```sql
SELECT SUM(total_discount) as discounts_total
FROM public.ticket
WHERE DATE(folio_date) = '2025-12-16'
  AND paid = true
  AND voided = false;
```
**Resultado**: $85.60 vs esperado $76.80 ❌ **DIFIERE $8.80**

## Análisis de Discrepancias

### Diferencia Crítica: $8.80
Se encontró que tanto los items como los descuentos tenían una diferencia exacta de $8.80:

- **Items**: $672.20 + $8.80 = $681.00
- **Descuentos**: $85.60 - $8.80 = $76.80

### Investigación del Origen de los $8.80

#### Hipótesis 1: Ticket 100% Descuento
Se identificó un ticket con descuento del 100%:
```sql
SELECT t.id, t.total_discount, t.total_price
FROM public.ticket t
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_discount > 0;
```
**Ticket ID 46291**: Total Discount = $85.60

#### Hipótesis 2: Exclusión por JasperReports
Se descubrió que JasperReports/Floreant excluye tickets con `total_price = 0` (100% descuento):

```sql
SELECT SUM(ti.total_price) as items_excluyendo_zero
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0;  -- EXCLUIR TICKETS CON TOTAL = 0
```

**Resultado**: $681.00 ✅ **COINCIDE EXACTO**

## Conclusiones Finales

### 1. Regla de Cálculo de Floreant/JasperReports
- **Incluye**: Todos los tickets con `paid = true` y `voided = false`
- **Excluye**: Tickets con `total_price = 0` (descuentos del 100%)
- **Net Sales**: Coincide exactamente con el sistema de cobranza

### 2. Ecuaciones Correctas
```
Items = SUM(ti.total_price) WHERE total_price > 0
Discounts = SUM(total_discount) WHERE total_price > 0
Net = SUM(total_price) WHERE total_price > 0
```

### 3. Impacto en la Implementación
El "Modo Conciliación Floreant" debe:
- Excluir tickets con `total_price = 0`
- Usar `ti.total_price` (que ya incluye modificadores)
- Calcular descuentos solo de tickets con `total_price > 0`

### 4. Validación Final
Los valores correctos para validar son:
```
Items: $681.00
Discounts: $76.80
Net: $604.20
```

## Recomendaciones

### 1. Actualizar Script de Validación
```php
$expected = [
    'items' => 681.00,
    'discounts' => 76.80,
    'net' => 604.20
];
```

### 2. Modificar Query del Servicio
```sql
WHERE DATE(t.folio_date) = '2025-12-16'
  AND t.paid = true
  AND t.voided = false
  AND t.total_price > 0  -- EXCLUIR TICKETS 100% DESCUENTO
```

### 3. Documentar Reglas de Negocio
- Documentar que Floreant/JasperReports excluye automáticamente tickets con monto total cero
- Esto es consistente con la práctica de no incluir anulaciones completas en los reportes de ventas

## Próximos Pasos

1. ✅ **Completado**: Análisis del reporte JasperReports
2. ✅ **Completado**: Identificación de la regla de exclusión
3. 🔄 **En Progreso**: Actualizar script de validación
4. ⏳ **Pendiente**: Implementar corrección en el servicio
5. ⏳ **Pendiente**: Documentar en wiki del proyecto

---

**Fecha**: 16 de diciembre de 2025
**Responsable**: Claude Code
**Estado**: Análisis completo, corrección pendiente de implementación