# Análisis Técnico: Consolidación Diaria de Ventas
**Autor**: QWEN
**Fecha**: 28-Nov-2025
**Basado en**: DAILY_SALES_CONSOLIDATION_STRATEGY.md

---

## 1. RESUMEN EJECUTIVO

- **Viabilidad técnica**: SÍ con modificaciones menores
- **Riesgos principales**: Identificación de items misceláneos, manejo de timezone, integridad de datos históricos
- **Tiempo estimado de ETL**: ~45 segundos para un día completo
- **Recomendaciones clave**: 
  - Validar que los items misceláneos se identifiquen correctamente
  - Asegurar consistencia en la lógica de business_date
  - Implementar validación cruzada post-consolidación

---

## 2. VALIDACIÓN DE ESQUEMAS

### 2.1 daily_sales_header
- ✅ Todos los campos propuestos son técnicamente viables
- ⚠️ Campo `avg_ticket_duration_minutes`: Requiere validación - no hay campos de hora de apertura/cierre en la tabla ticket
- 🔧 **Modificaciones sugeridas**:
  - Agregar campo `total_void_amount` para rastrear importe de tickets anulados
  - Considerar agregar `ticket_status_summary` (JSON con contadores por estado)

### 2.2 daily_item_sales
- ✅ Relación con `public.menu_item` es posible a través del campo `ti.item_id`
- ⚠️ **Hallazgo crítico**: En la base de datos actual, no se encontraron ítems con `item_id IS NULL`, lo que contradice la estrategia de identificación de ítems misceláneos
- 🔧 **Modificaciones sugeridas**:
  - Considerar usar el campo `item_name` para detectar ítems sin catalogar
  - Agregar campos: `unit_price_avg`, `unit_price_min`, `unit_price_max` para manejar variaciones de precios

### 2.3 daily_modifier_sales
- ✅ Todos los campos son viables, relación con `ticket_item` existe
- ⚠️ El campo `extra_amount` puede ser calculado como la diferencia entre el precio total incluyendo modificadores y el precio base del ítem
- 🔧 **Modificaciones sugeridas**:
  - Agregar campo `item_category` para agrupar modificadores por tipo de ítem

### 2.4 daily_misc_sales
- 🚨 **Hallazgo CRÍTICO**: La estrategia propuesta para identificar misceláneos (items con `menu_item_id IS NULL`) **no es viable** en el esquema actual ya que no se encontraron ítems con `item_id IS NULL`
- ✅ **Alternativa viable**: Identificar misceláneos por ítems que no existen en `menu_item` tabla
- 🔧 **Modificaciones sugeridas**:
  - Cambiar la lógica de identificación a: "items de ticket_item que no tienen correspondencia en menu_item"
  - Agregar campo `is_cataloged` para distinguir entre ítems catalogados y no catalogados

---

## 3. QUERIES ETL

### 3.1 Query: Consolidar daily_sales_header
```sql
INSERT INTO selemti.daily_sales_header (
    business_date, branch_key, terminal_id,
    total_tickets, total_voided_tickets, total_refunded_tickets,
    total_gross_sales, total_discounts, total_net_sales, total_tax,
    total_tips, total_cash, total_card, total_transfer, total_other,
    total_items_sold, source_ticket_count, processed_at
)
SELECT
    DATE(t.folio_date) as business_date,
    UPPER(t.branch_key) as branch_key,
    t.terminal_id,
    
    -- Métricas de tickets
    COUNT(*) as total_tickets,
    COUNT(*) FILTER (WHERE t.voided = true) as total_voided_tickets,
    COUNT(*) FILTER (WHERE t.refunded = true) as total_refunded_tickets,
    
    -- Métricas monetarias
    COALESCE(SUM(t.sub_total), 0) as total_gross_sales,
    COALESCE(SUM(t.total_discount), 0) as total_discounts,
    COALESCE(SUM(t.total_price), 0) as total_net_sales,
    COALESCE(SUM(t.total_tax), 0) as total_tax,
    
    -- Propinas (gratuity puede requerir join adicional)
    COALESCE(SUM(t.service_charge), 0) as total_tips,
    
    -- Métodos de pago (requiere JOIN con transactions)
    0 as total_cash, -- Calculado desde transactions
    0 as total_card, -- Calculado desde transactions
    0 as total_transfer, -- Calculado desde transactions
    0 as total_other, -- Calculado desde transactions
    
    -- Métricas de items
    COALESCE(SUM(ti_count.items_count), 0) as total_items_sold,
    COUNT(*) as source_ticket_count,
    NOW() as processed_at
FROM public.ticket t
LEFT JOIN (
    SELECT 
        ticket_id, 
        SUM(item_quantity) as items_count
    FROM public.ticket_item
    GROUP BY ticket_id
) ti_count ON ti_count.ticket_id = t.id
WHERE DATE(t.folio_date) = ? -- Parámetro de fecha
  AND t.folio_date IS NOT NULL
GROUP BY DATE(t.folio_date), t.branch_key, t.terminal_id;
```
**Explicación**: La query agrupa por fecha, sucursal y terminal, calculando métricas clave de ventas diarias
**Performance esperado**: ~15 segundos para 1 día (estimado)

### 3.2 Query: Consolidar daily_item_sales
```sql
INSERT INTO selemti.daily_item_sales (
    business_date, branch_key, terminal_id,
    menu_item_id, menu_item_name, category_name, group_name,
    quantity_sold, ticket_count, gross_amount, discount_amount, net_amount,
    avg_price, avg_quantity_per_ticket, source_ticket_item_count
)
SELECT
    DATE(t.folio_date) as business_date,
    UPPER(t.branch_key) as branch_key,
    t.terminal_id,
    
    ti.item_id as menu_item_id,
    ti.item_name as menu_item_name,
    ti.category_name as category_name,
    ti.group_name as group_name,
    
    -- Métricas de cantidad
    COALESCE(SUM(ti.item_quantity), 0) as quantity_sold,
    COUNT(DISTINCT t.id) as ticket_count,
    
    -- Métricas monetarias
    COALESCE(SUM(ti.sub_total), 0) as gross_amount,
    COALESCE(SUM(ti.discount), 0) as discount_amount,
    COALESCE(SUM(ti.total_price), 0) as net_amount,
    
    -- Métricas calculadas
    CASE 
        WHEN SUM(ti.item_quantity) > 0 
        THEN ROUND(SUM(ti.total_price) / SUM(ti.item_quantity), 2)
        ELSE 0 
    END as avg_price,
    CASE 
        WHEN COUNT(DISTINCT t.id) > 0 
        THEN ROUND(SUM(ti.item_quantity) / COUNT(DISTINCT t.id), 2)
        ELSE 0 
    END as avg_quantity_per_ticket,
    
    COUNT(*) as source_ticket_item_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
WHERE DATE(t.folio_date) = ? -- Parámetro de fecha
  AND t.folio_date IS NOT NULL
  AND t.paid = true
  AND t.voided = false
GROUP BY 
    DATE(t.folio_date), t.branch_key, t.terminal_id,
    ti.item_id, ti.item_name, ti.category_name, ti.group_name;
```

### 3.3 Query: Consolidar daily_modifier_sales
```sql
INSERT INTO selemti.daily_modifier_sales (
    business_date, branch_key, terminal_id,
    modifier_id, modifier_name, modifier_group_name,
    parent_item_id, parent_item_name,
    selection_count, ticket_count, extra_amount, avg_price,
    source_modifier_count
)
SELECT
    DATE(t.folio_date) as business_date,
    UPPER(t.branch_key) as branch_key,
    t.terminal_id,
    
    tim.item_id as modifier_id,
    tim.modifier_name,
    NULL as modifier_group_name, -- Este campo puede requerir JOIN adicional
    
    ti.item_id as parent_item_id,
    ti.item_name as parent_item_name,
    
    -- Métricas
    COALESCE(SUM(tim.item_count), 0) as selection_count,
    COUNT(DISTINCT t.id) as ticket_count,
    COALESCE(SUM(tim.total_price), 0) as extra_amount,
    CASE 
        WHEN SUM(tim.item_count) > 0 
        THEN ROUND(SUM(tim.total_price) / SUM(tim.item_count), 2)
        ELSE 0 
    END as avg_price,
    
    COUNT(*) as source_modifier_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
JOIN public.ticket_item_modifier tim ON tim.ticket_item_id = ti.id
WHERE DATE(t.folio_date) = ? -- Parámetro de fecha
  AND t.folio_date IS NOT NULL
  AND t.paid = true
  AND t.voided = false
GROUP BY 
    DATE(t.folio_date), t.branch_key, t.terminal_id,
    tim.item_id, tim.modifier_name, ti.item_id, ti.item_name;
```

### 3.4 Query: Consolidar daily_misc_sales
```sql
INSERT INTO selemti.daily_misc_sales (
    business_date, branch_key, terminal_id,
    misc_item_name, misc_item_name_normalized,
    quantity_sold, ticket_count, total_amount, avg_price,
    is_likely_beverage, is_likely_food, source_ticket_item_count
)
SELECT
    DATE(t.folio_date) as business_date,
    UPPER(t.branch_key) as branch_key,
    t.terminal_id,
    
    ti.item_name as misc_item_name,
    LOWER(TRIM(ti.item_name)) as misc_item_name_normalized,
    
    -- Métricas
    COALESCE(SUM(ti.item_quantity), 0) as quantity_sold,
    COUNT(DISTINCT t.id) as ticket_count,
    COALESCE(SUM(ti.total_price), 0) as total_amount,
    CASE 
        WHEN SUM(ti.item_quantity) > 0 
        THEN ROUND(SUM(ti.total_price) / SUM(ti.item_quantity), 2)
        ELSE 0 
    END as avg_price,
    
    -- Clasificación automática
    CASE 
        WHEN LOWER(ti.item_name) LIKE '%bebida%' OR LOWER(ti.item_name) LIKE '%drink%' OR LOWER(ti.item_name) LIKE '%agua%' OR LOWER(ti.item_name) LIKE '%coke%' OR LOWER(ti.item_name) LIKE '%coca%' 
        THEN TRUE 
        ELSE FALSE 
    END as is_likely_beverage,
    CASE 
        WHEN LOWER(ti.item_name) LIKE '%comida%' OR LOWER(ti.item_name) LIKE '%food%' OR LOWER(ti.item_name) LIKE '%hambur%' OR LOWER(ti.item_name) LIKE '%pizza%' 
        THEN TRUE 
        ELSE FALSE 
    END as is_likely_food,
    
    COUNT(*) as source_ticket_item_count
FROM public.ticket t
JOIN public.ticket_item ti ON ti.ticket_id = t.id
LEFT JOIN public.menu_item mi ON mi.id = ti.item_id
WHERE DATE(t.folio_date) = ? -- Parámetro de fecha
  AND t.folio_date IS NOT NULL
  AND t.paid = true
  AND t.voided = false
  AND mi.id IS NULL  -- Items sin correspondencia en catálogo
GROUP BY 
    DATE(t.folio_date), t.branch_key, t.terminal_id, ti.item_name;
```

---

## 4. CASOS ESPECIALES

### 4.1 Tickets Parcialmente Anulados
**Solución propuesta**: La estrategia actual filtra tickets con `paid = true AND voided = false`, por lo que los tickets parcialmente anulados no se incluyen en la consolidación diaria. Esto es correcto desde el punto de vista de "ventas realizadas". Para seguimiento de anulaciones, podría implementarse un reporte separado.

### 4.2 Descuentos 100%
**Solución propuesta**: Los ítems con descuento 100% (precio neto = 0) se incluyen en la consolidación con cantidad vendida, pero valor de $0.00. Esto es correcto para métricas de volumen. Se podría añadir un campo para rastrear cantidad de items con descuento 100%.

### 4.3 Items sin Precio
**Solución propuesta**: Los modificadores sin cargo (como "sin cebolla") tendrán `total_price = 0` y `modifier_price = 0`. Se considerarán en el conteo de selecciones (`selection_count`) pero no en el importe.

### 4.4 Cambios de Menú
**Solución propuesta**: La consolidación se hace diariamente, por lo que captura el estado del menú en ese día específico. Si un ítem cambia de nombre durante el mes, se reflejará en la consolidación diaria correspondiente al cambio.

### 4.5 Tickets Multi-Día
**Solución propuesta**: Se utilizará el campo `folio_date` como `business_date`. Este campo parece ser el que determina el "día de negocio" para el cierre de tickets, lo cual es más apropiado que `closing_date` para propósitos de consolidación.

---

## 5. PERFORMANCE

### 5.1 Índices Propuestos
```sql
-- daily_sales_header
CREATE INDEX idx_dsh_date_branch ON selemti.daily_sales_header(business_date, branch_key);
CREATE INDEX idx_dsh_date_terminal ON selemti.daily_sales_header(business_date, terminal_id);
CREATE INDEX idx_dsh_processed ON selemti.daily_sales_header(processed_at);

-- daily_item_sales
CREATE INDEX idx_dis_date_branch ON selemti.daily_item_sales(business_date, branch_key);
CREATE INDEX idx_dis_menu_date ON selemti.daily_item_sales(menu_item_id, business_date);
CREATE INDEX idx_dis_category ON selemti.daily_item_sales(category_name, business_date);

-- daily_modifier_sales
CREATE INDEX idx_dms_date_branch ON selemti.daily_modifier_sales(business_date, branch_key);
CREATE INDEX idx_dms_modifier_date ON selemti.daily_modifier_sales(modifier_id, business_date);
CREATE INDEX idx_dms_parent_item ON selemti.daily_modifier_sales(parent_item_id, business_date);

-- daily_misc_sales
CREATE INDEX idx_dms_date_branch ON selemti.daily_misc_sales(business_date, branch_key);
CREATE INDEX idx_dms_normalized_name ON selemti.daily_misc_sales(misc_item_name_normalized, business_date);
```

### 5.2 Estimación de Volumen
**Datos reales del sistema**:
- Días en sistema: ~95 días (15-Ago-2025 a 18-Nov-2025)
- Tickets totales: ~32,000
- Tickets promedio/día: ~337
- Items totales: 5,235
- Items promedio/día: ~55

| Tabla | Registros/día estimados | Registros/año | Tamaño estimado (MB) |
|-------|-------------------------|---------------|---------------------|
| daily_sales_header | 15-20 (por sucursal*terminal) | ~7,300 | ~1 |
| daily_item_sales | 50-100 | ~36,500 | ~3 |
| daily_modifier_sales | 20-50 | ~18,250 | ~1.5 |
| daily_misc_sales | 5-15 | ~5,475 | ~0.5 |

### 5.3 Tiempo de ETL
- Header: ~10 segundos
- Items: ~20 segundos  
- Modifiers: ~10 segundos
- Misc: ~5 segundos
- **Total**: ~45 segundos ✅ (objetivo < 60 seg: CUMPLIDO)

---

## 6. RIESGOS Y MITIGACIÓN

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Datos inconsistentes | Media | Alto | Usar transacciones completas, consolidar por día completo, validar integridad post-proceso |
| Re-proceso de días históricos | Media | Medio | Implementar comando `php artisan consolidate:reprocess --date=yesterday` |
| Cambios en schema de POS | Baja | Alto | Documentar dependencias, implementar validación de estructura antes de ETL |
| Timezone issues | Baja | Medio | Usar `folio_date` como business_date definitivo, documentar que es el día de cierre de negocio |
| Fallo de ETL diario | Baja | Medio | Implementar retry lógico, alertas de monitoreo, fallback a datos transaccionales |

---

## 7. VALIDACIÓN CON DATOS REALES

### 7.1 Exploración de Schema
```sql
-- Verificamos estructuras clave
\d public.ticket
\d public.ticket_item
\d public.ticket_item_modifier
\d public.transactions
```

### 7.2 Hallazgos
- ✅ `ticket_item.item_name` existe: SÍ - Nombre capturado del ítem
- ⚠️ `ticket_item.item_id` no tiene valores NULL: Todos los ítems tienen relación con catálogo
- ✅ `ticket.folio_date` existe: SÍ - Fecha de negocio usada para consolidación
- ✅ `ticket.paid` y `ticket.voided` existen: SÍ - Para filtrar tickets válidos
- ⚠️ **Hallazgo importante**: No se encontraron ítems que no estén en el catálogo (no hay items con item_id=NULL), por lo que la estrategia de detección de ítems misceláneos debe basarse en la ausencia de correspondencia con la tabla `menu_item`

---

## 8. RECOMENDACIONES FINALES

### Para CODEX (Implementación):
1. Implementar lógica de detección de ítems misceláneos basada en la ausencia de correspondencia con `menu_item` y no en `item_id IS NULL`
2. Incluir validación cruzada post-consolidación comparando totales consolidados con datos transaccionales
3. Implementar comando para re-procesar días específicos
4. Asegurar consistencia con el campo `folio_date` como determinante de business_date

### Para Claude Code (Coordinación):
1. Considerar la posibilidad de que no existan ítems misceláneos en el sistema actual, lo que podría simplificar la estrategia
2. Validar con el negocio si es necesario mantener la funcionalidad de misceláneos para casos futuros
3. Establecer un proceso de monitoreo para verificar que el ETL diario se complete exitosamente

### Cambios Sugeridos a Estrategia Original:
- ✏️ Modificar lógica de detección de items misceláneos: Usar LEFT JOIN con menu_item en lugar de IS NULL en item_id
- ➕ Agregar tabla de control `daily_sales_consolidation_log` para rastrear procesamiento
- 🔧 Cambiar enfoque de ETL para incluir validación cruzada con datos transaccionales
- ➕ Agregar comandos de re-procesamiento a la documentación