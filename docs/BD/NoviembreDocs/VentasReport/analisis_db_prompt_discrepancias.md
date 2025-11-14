# Análisis de Discrepancias: Prompt vs Base de Datos Real

## Resumen Ejecutivo
Tras analizar el dump de tu base de datos PostgreSQL 9.5, he identificado varias discrepancias importantes entre las expectativas del prompt y la estructura real de tu BD. El prompt parece estar basado en suposiciones sobre nombres de columnas y tablas que no coinciden completamente con tu implementación actual.

## ✅ Elementos que SÍ coinciden

### 1. Estructura General
- **PostgreSQL 9.5**: ✓ Confirmado
- **Schemas `public` y `selemti`**: ✓ Ambos existen
- **Tablas principales**: 
  - `ticket`: ✓ Existe
  - `transactions`: ✓ Existe
  - `terminal`: ✓ Existe
  - `ticket_item`: ✓ Existe

### 2. Funciones Críticas
Todas las funciones mencionadas en el prompt EXISTEN:
- `get_daily_stats()` ✓
- `fn_daily_reconciliation()` ✓
- `fn_reconciliation_detail()` ✓
- `fn_correct_drawer_report()` ✓
- `fn_normalizar_forma_pago()` ✓

### 3. Campos de Negocio en `ticket`
- `paid`: ✓ Existe
- `voided`: ✓ Existe
- `total_price`: ✓ Existe
- `total_discount`: ✓ Existe
- `service_charge`: ✓ Existe (como `service_charge`)
- `terminal_id`: ✓ Existe
- `folio_date`: ✓ Existe
- `branch_key`: ✓ Existe

## ❌ Discrepancias Críticas

### 1. Nombres de Columnas en `ticket`

| Prompt Asume | BD Real | Impacto |
|--------------|---------|---------|
| `created_at` | `create_date` | ALTO - Todas las vistas usan el nombre incorrecto |
| `updated_at` | NO EXISTE | MEDIO - No hay tracking de actualizaciones |
| `paid_at` | NO EXISTE | ALTO - El cálculo de folio_date depende de esto |
| `voided_at` | NO EXISTE | MEDIO - No hay timestamp del void |
| `closed_at` | `closing_date` | ALTO - Nombre diferente |
| `settled_at` | NO EXISTE (pero hay `settled` boolean) | ALTO - Crítico para folio_date |
| `tip_amount` | NO EXISTE | MEDIO - Para diagnóstico de propinas |
| `discount_reason` | NO EXISTE | MEDIO - Para auditoría de descuentos |

### 2. Nombres de Columnas en `ticket_item`

| Prompt Asume | BD Real | Impacto |
|--------------|---------|---------|
| `quantity` | `item_quantity` | ALTO - Usado en todos los cálculos |
| `item_total` | `total_price` | ALTO - Cálculos de netos |
| `discount_amount` | `discount` | ALTO - Cálculos de descuentos |
| `voided` | NO EXISTE | ALTO - No hay manera de marcar items void |
| `discount_name` | NO EXISTE | MEDIO - Para reportes de descuentos |
| `product_id` | `item_id` | MEDIO - Referencias diferentes |

### 3. Tabla de Productos
- El prompt asume una tabla `products`
- En la BD real parece ser `menu_item` o `items` (en schema selemti)
- Esto afecta la vista `vw_diag_orphan_ticket_items`

### 4. Columnas de Auditoría Faltantes
NO existen en la tabla `ticket`:
- `authorized_by`
- `discount_reason`
- `approved_by`

Esto impacta directamente los diagnósticos de descuentos (D3).

## ⚠️ Ajustes Necesarios en el Prompt

### 1. Corrección de Nombres de Columnas (PRIORIDAD ALTA)

```sql
-- ANTES (Prompt actual):
EXTRACT(HOUR FROM (t.created_at AT TIME ZONE 'America/Mexico_City'))

-- DESPUÉS (Corregido):
EXTRACT(HOUR FROM (t.create_date AT TIME ZONE 'America/Mexico_City'))
```

### 2. Cálculo de folio_date (CRÍTICO)

El prompt dice:
```sql
folio_date = COALESCE(settled_at, paid_at, closed_at)::date
```

Pero debe ser:
```sql
-- Opción 1: Usar solo closing_date
folio_date = COALESCE(closing_date, create_date)::date

-- Opción 2: Si necesitas más control, crear columnas faltantes primero
```

### 3. Ajuste en ticket_item

```sql
-- ANTES:
ROUND(SUM(COALESCE(ti.quantity,0)),2) AS qty,
ROUND(SUM(COALESCE(ti.item_total,0)-COALESCE(ti.discount_amount,0)),2) AS neto

-- DESPUÉS:
ROUND(SUM(COALESCE(ti.item_quantity,0)),2) AS qty,
ROUND(SUM(COALESCE(ti.total_price,0)-COALESCE(ti.discount,0)),2) AS neto
```

## 🔧 Recomendaciones de Implementación

### Opción A: Adaptar el Prompt a tu BD (Recomendado)
1. **Actualizar todas las referencias de columnas** en las vistas para usar los nombres reales
2. **Eliminar diagnósticos** que dependan de columnas inexistentes
3. **Simplificar el cálculo de folio_date** usando solo `closing_date`

### Opción B: Modificar tu BD
1. **Agregar columnas faltantes** con ALTER TABLE:
   ```sql
   ALTER TABLE ticket ADD COLUMN paid_at timestamp;
   ALTER TABLE ticket ADD COLUMN settled_at timestamp;
   ALTER TABLE ticket ADD COLUMN tip_amount numeric;
   ALTER TABLE ticket ADD COLUMN discount_reason text;
   ```

2. **Migrar datos** de columnas existentes:
   ```sql
   UPDATE ticket SET paid_at = create_date WHERE paid = true;
   UPDATE ticket SET settled_at = closing_date WHERE settled = true;
   ```

### Opción C: Crear Vistas de Compatibilidad
```sql
CREATE VIEW ticket_compatible AS
SELECT 
    *,
    create_date AS created_at,
    closing_date AS closed_at,
    NULL::timestamp AS paid_at,
    NULL::timestamp AS settled_at,
    NULL::numeric AS tip_amount
FROM ticket;
```

## 📋 Checklist de Validación Actualizado

Antes de implementar, verifica:

1. [ ] ¿Tienes permisos para crear vistas/funciones?
2. [ ] ¿Puedes modificar la estructura de tablas si es necesario?
3. [ ] ¿El campo `settled` (boolean) en ticket está siendo usado actualmente?
4. [ ] ¿La tabla `menu_item` es tu catálogo de productos principal?
5. [ ] ¿Existe algún sistema de auditoría en el schema `selemti`?
6. [ ] ¿Los descuentos se manejan solo en `ticket_discount` o también en ticket_item?

## 🚀 Próximos Pasos

1. **Decisión estratégica**: Elegir entre Opción A, B o C
2. **Generar script SQL corregido** con los nombres de columnas reales
3. **Probar en ambiente de desarrollo** antes de producción
4. **Documentar las diferencias** para el equipo

## Funciones que Necesitan Revisión

Estas funciones mencionadas en el prompt ya existen, pero deberías verificar que sus parámetros y resultados coincidan con lo esperado:

1. `get_daily_stats(p_date)` - Verificar columnas de salida
2. `fn_normalizar_forma_pago()` - Verificar lógica de normalización
3. `fn_correct_drawer_report()` - Verificar cálculos de cajón

## Conclusión

El prompt está bien estructurado pero asume una estructura de BD ligeramente diferente a la real. Los principales problemas son:
- **Nombres de columnas diferentes** (created_at vs create_date)
- **Columnas faltantes** para timestamps de auditoría
- **Referencias a tablas con nombres diferentes** (products vs menu_item)

Con los ajustes sugeridos, el sistema de reportes debería funcionar correctamente.
