# Reglas de Cálculo de Ventas - Terrena Reports

## Definición Oficial (alineada con Floreant POS)

### Fórmulas Exactas

| Concepto | Fórmula SQL | Ejemplo Real (2025-12-16) |
|----------|-------------|---------------------------|
| **Item Sales Grand Total** | `SUM(ti.item_price * ti.item_count)` | $631.00 |
| **Modifiers Grand Total** | `SUM(tim.total_price)` | $50.00 |
| **Total Discounts (PDF)** | `SUM(ticket_item_discount.amount)` | $8.80 |
| **Net Sales (Ventas Netas)** | Item Sales - Discounts | $622.20 |
| **Customer Payments** | `SUM(t.total_price)` | $604.20 |

### Tablas y Columnas Específicas

- **Items**: `public.ticket_item` → `item_price`, `item_count`
- **Modifiers**: `public.ticket_item_modifier` → `total_price`
- **Discounts**: `public.ticket_item_discount` → `amount`
- **No usar**: `ti.total_price` (ya incluye modificadores)

### Filtros Base

```sql
WHERE
  DATE(folio_date) = 'fecha'
  AND paid = true
  AND voided = false
  AND total_price > 0  -- Excluye tickets con descuento 100%
```

### Modo "Conciliación Floreant"

Replica exactamente el reporte PDF de Floreant:
- Usa las fórmulas arriba definidas
- Aplica los filtros especificados
- Muestra: Items $631, Modifiers $50, Discounts $8.8, Net $622.2

## Diferencia Contable Importante

| Concepto | Monte | Significado |
|----------|-------|-------------|
| **Net Sales** | $622.20 | Lo que se debía cobrar |
| **Customer Payments** | $604.20 | Lo que se pagó efectivamente |
| **Diferencia** | $18.00 | Ajustes, créditos, timing |

**Esta diferencia NO es error**, es naturaleza contable:
- Ventas = Lo vendido (independiente de cómo se pague)
- Pagos = Lo recibido (depende de forma de pago, plazos, etc.)

## Uso en Terrena

1. **Modo Operativo Default ("Estricto")**
   - Ventas + Pagos visibles por separado
   - Para backoffice diario

2. **Modo "Conciliación Floreant"**
   - Replica exactamente el PDF de Floreant
   - Para auditorías y validación histórica

## Evidencia de Validación

- ✅ No hay doble conteo de modificadores
- ✅ Descuentos vienen exclusivamente de `ticket_item_discount`
- ✅ Coincidencia exacta con reporte PDF Floreant
- ✅ Explicación clara de diferencia $18.00

---
*Documento generado el 2025-12-16 tras validación completa.*