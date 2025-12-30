# Reporte de Optimización - Sales Exceptions Report

## Análisis de Rendimiento

### Contexto
- Reporte procesa ~215 tickets/día
- Para rangos de 10 días son ~2,631 tickets
- Esto causa timeouts por queries múltiples con grandes conjuntos de datos

### Queries Actuales Analizadas

#### 1. Query Principal - `fetchTickets()`
```sql
SELECT t.id AS ticket_id,
       COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
       UPPER(COALESCE(t.branch_key, 'SIN_SUCURSAL')) AS branch_key,
       t.terminal_id,
       -- ... otras columnas
FROM public.ticket as t
WHERE (COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) 
       BETWEEN ? AND ?)
```

**Observaciones:**
- Utiliza expresiones complejas en el WHERE
- Existen índices adecuados: `ix_ticket_folio_date`, `ix_ticket_branch_key`

#### 2. Query de Resumen de Pagos - `loadPaymentSummary()`
```sql
SELECT tx.ticket_id,
       SUM(CASE WHEN ...) AS payment_total,
       -- ... otras agregaciones
FROM public.transactions as tx
WHERE tx.ticket_id IN (?, ?, ?, ...) -- con 2,631+ IDs
GROUP BY tx.ticket_id
```

**Observaciones:**
- Falta índice en `ticket_id` en tabla `transactions`
- Gran cláusula `WHERE IN` con miles de IDs

#### 3. Query de Detalles de Transacciones - `loadTransactionDetails()`
```sql
SELECT tx.ticket_id, tx.payment_type, tx.transaction_type, tx.amount, tx.voided
FROM public.transactions as tx
WHERE tx.ticket_id IN (?, ?, ?, ...) -- con 2,631+ IDs
ORDER BY tx.id
```

**Observaciones:**
- Similar al anterior, sin índice en `ticket_id`
- Gran cláusula `WHERE IN` con miles de IDs

#### 4. Query de Descuentos - `loadDiscounts()`
```sql
-- Query 1: ticket_discount
SELECT td.ticket_id, COALESCE(..., 'SIN NOMBRE') AS discount_name, ...
FROM public.ticket_discount as td
LEFT JOIN public.coupon_and_discount as cad ...
WHERE td.ticket_id IN (?, ?, ?, ...) -- con 2,631+ IDs

-- Query 2: ticket_item_discount
SELECT ti.ticket_id, COALESCE(..., 'SIN NOMBRE') AS discount_name, ...
FROM public.ticket_item as ti
JOIN public.ticket_item_discount as tid ...
WHERE ti.ticket_id IN (?, ?, ?, ...) -- con 2,631+ IDs
```

**Observaciones:**
- Faltan índices en `ticket_id` (ticket_discount) y `ticket_itemid` (ticket_item_discount)
- Gran cláusula `WHERE IN` con miles de IDs

#### 5. Query de Ítems - `loadItems()`
```sql
SELECT ti.ticket_id, COALESCE(..., 'SIN NOMBRE') AS item_name, ...
FROM public.ticket_item as ti
WHERE ti.ticket_id IN (?, ?, ?, ...) -- con 2,631+ IDs
```

**Observaciones:**
- Existe un índice parcial: `ix_ticket_item_ticket_pg (ticket_id, pg_id)`
- Aún puede beneficiarse de un índice simple en `ticket_id`

## Índices Faltantes Identificados

| Tabla | Columna | Tipo de Índice | Recomendación |
|-------|---------|----------------|---------------|
| `public.transactions` | `ticket_id` | B-tree | `CREATE INDEX idx_transactions_ticket_id ON public.transactions (ticket_id);` |
| `public.ticket_discount` | `ticket_id` | B-tree | `CREATE INDEX idx_ticket_discount_ticket_id ON public.ticket_discount (ticket_id);` |
| `public.ticket_item_discount` | `ticket_itemid` | B-tree | `CREATE INDEX idx_ticket_item_discount_ticket_itemid ON public.ticket_item_discount (ticket_itemid);` |

## Queries Optimizadas Propuestas

### Solución 1: Optimización de Índices (Corta Plazo)
Los índices propuestos permitirán que las consultas `WHERE IN` con miles de IDs se ejecuten de manera significativamente más eficiente.

### Solución 2: Estrategia de Procesamiento por Lotes (Media Plazo)
Implementar un procesamiento por lotes para evitar cláusulas `WHERE IN` extremadamente grandes:

```php
// En lugar de procesar 2,631 tickets de una vez
$tickets = $this->fetchTickets($start, $end, $branchIds, $terminalIds);
$ticketIds = $tickets->pluck('ticket_id')->map(fn ($id) => (int) $id)->unique()->values();

// Procesar en lotes de 500-1000 tickets
$chunks = $ticketIds->chunk(500);
foreach ($chunks as $chunk) {
    $payments = $this->loadPaymentSummary($chunk);
    $transactions = $this->loadTransactionDetails($chunk);
    // etc.
}
```

### Solución 3: CTEs o Query Unificada (Largo Plazo)
Considerar una única query compleja que combine todos los datos usando CTEs o subqueries:

```sql
WITH ticket_data AS (
    -- Query principal de tickets
),
payment_summary AS (
    -- Resumen de pagos
),
transaction_details AS (
    -- Detalles de transacciones
),
discounts_data AS (
    -- Datos de descuentos
),
items_data AS (
    -- Datos de ítems
)
SELECT ...
FROM ticket_data t
LEFT JOIN payment_summary ps ON t.ticket_id = ps.ticket_id
LEFT JOIN transaction_details td ON t.ticket_id = td.ticket_id
LEFT JOIN discounts_data dd ON t.ticket_id = dd.ticket_id
LEFT JOIN items_data id ON t.ticket_id = id.ticket_id
```

## Estimación de Mejora de Rendimiento

1. **Con solo añadir índices** (Solución 1):
   - Mejora estimada: 70-80%
   - La query de transacciones que actualmente escanea la tabla completa se ejecutará en tiempo logarítmico

2. **Con procesamiento por lotes** (Solución 2):
   - Mejora estimada adicional: 15-25%
   - Reduce el tamaño de cada operación `WHERE IN`

3. **Con query unificada** (Solución 3):
   - Mejora estimada adicional: 20-30%
   - Reduce el número de round trips a la DB de 5 a 1

**Total estimado de mejora potencial**: 85-95% reducción de tiempo de ejecución

## Recomendaciones Priorizadas

1. **Inmediata (Índices)**: Añadir los índices faltantes
   - Riesgo: Mínimo
   - Esfuerzo: Bajo
   - Impacto: Alto (70-80% mejora)

2. **Corta Plazo (Lotes)**: Implementar procesamiento por lotes
   - Riesgo: Medio
   - Esfuerzo: Medio
   - Impacto: Medio (15-25% mejora adicional)

3. **Largo Plazo (Query Unificada)**: Reescribir la lógica con CTEs o joins
   - Riesgo: Alto
   - Esfuerzo: Alto
   - Impacto: Medio (20-30% mejora adicional)

## Consideraciones de PostgreSQL 9.5

Todas las soluciones propuestas son compatibles con PostgreSQL 9.5:
- Los índices B-tree son soportados
- Las CTEs están disponibles desde PostgreSQL 8.4+
- Las funciones window y vistas materializadas no se utilizan

## Notas de Implementación

- El schema `public` es de solo lectura, por lo que los índices deben ser creados por personal con permisos adecuados
- Se deben realizar pruebas exhaustivas antes de implementar cualquier cambio en producción
- Considerar el horario de menor impacto para implementar mejoras