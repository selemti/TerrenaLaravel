# Análisis de Migraciones Pendientes
**Fecha:** 2025-11-05  
**Total:** 12 migraciones pendientes

---

## 📊 Resumen Ejecutivo

| Categoría | Cantidad | Acción Requerida |
|-----------|----------|------------------|
| ✅ **Marcar como ejecutadas** | 4 | Tablas ya existen, solo registrar |
| ⚙️ **Hacer idempotentes** | 2 | Agregar checks antes de crear |
| ✅ **Ejecutar directamente** | 3 | No hay conflictos |
| 🔧 **Corregir SQL** | 2 | Arreglar referencias de columnas |
| ✅ **Ya idempotente** | 1 | Lista para ejecutar |

**Total sincronizado hasta ahora:** 65 de 77 migraciones (84%)

---

## 📋 Detalle por Migración

### Grupo 1: Marcar como Ejecutadas (4)
**Tablas YA EXISTEN - Solo registrar en tabla `migrations`**

#### 1. `2025_11_15_030000_create_pos_consumption_tables` ✓
- **Tablas:** `inv_consumo_pos`, `inv_consumo_pos_det`, `inv_consumo_pos_log`
- **Estado:** TODAS existen en schema selemti
- **Acción:** Registrar sin ejecutar

#### 2. `2025_11_15_070000_create_pos_sync_tables` ✓
- **Tablas:** `pos_sync_batches`, `pos_sync_logs`, `menu_items`, `menu_item_sync_map`
- **Estado:** TODAS existen en schema selemti
- **Acción:** Registrar sin ejecutar

#### 3. `2025_11_15_080000_create_menu_engineering_tables` ✓
- **Tablas:** `menu_engineering_snapshots`
- **Estado:** Existe en schema selemti
- **Acción:** Registrar sin ejecutar

#### 4. `2025_11_15_100000_create_reporting_tables` ✓
- **Tablas:** `report_definitions`, `report_runs`
- **Estado:** TODAS existen en schema selemti
- **Acción:** Registrar sin ejecutar

---

### Grupo 2: Hacer Idempotentes (2)
**ALGUNAS tablas existen - Agregar checks**

#### 5. `2025_11_15_000000_create_inventory_receiving_tables` ⚙️
- **Tablas creadas:**
  - ✓ `selemti.recepcion_cab` (YA EXISTE)
  - ✗ `inventory_batch` (FALTA)
  - ✗ `recepcion_det` (FALTA)
  - ✗ `mov_inv` (FALTA)
  - ✗ `recepcion_adjuntos` (FALTA)

**Problema:** Ya tiene `if (!$schema->hasTable())` para recepcion_cab, pero falta para inventory_batch

**Solución:** Verificar que todos los `if (!$schema->hasTable())` estén presentes

#### 6. `2025_11_15_060000_create_costing_extension_tables` ⚙️
- **Tablas:**
  - ✗ `labor_roles` (FALTA)
  - ✓ `recipe_labor_steps` (YA EXISTE en selemti)
  - ✗ `overhead_definitions` (FALTA)
  - ✓ `recipe_overhead_allocations` (YA EXISTE en selemti)
  - ✓ `recipe_extended_cost_history` (YA EXISTE en selemti)

**Problema:** 3 tablas ya existen, necesita checks adicionales

**Solución:** Verificar que todos los `if (!$schema->hasTable())` estén presentes

---

### Grupo 3: Ejecutar Directamente (3)
**NINGUNA tabla existe - Seguras para ejecutar**

#### 7. `2025_11_15_010000_create_inventory_counts_tables` ✅
- **Tablas:** `inventory_counts`, `inventory_count_lines`
- **Estado:** No existen
- **Acción:** Ejecutar directamente con `php artisan migrate --step`

#### 8. `2025_11_15_020000_create_production_tables` ✅
- **Tablas:** `production_orders`, `production_order_inputs`, `production_order_outputs`, `inventory_wastes`
- **Estado:** No existen
- **Acción:** Ejecutar directamente

#### 9. `2025_11_15_050000_create_purchasing_tables` ✅
- **Tablas:** `purchase_requests`, `purchase_request_lines`, `purchase_vendor_quotes`, etc.
- **Estado:** No existen (7 tablas)
- **Acción:** Ejecutar directamente

---

### Grupo 4: Corregir SQL (2)
**Problema con archivo SQL - Referencias incorrectas**

#### 10. `2025_11_04_000900_create_additional_sales_report_views` 🔧
**Archivo:** `docs/docs/BD/NoviembreDocsDocs/VentasReport/v9/script_sql_reportes_adicionales.sql`

**Problema:** Usa `ti.discount_amount` pero la columna se llama `ti.discount`

**Código actual:**
```sql
SELECT SUM(COALESCE(ti.discount_amount, COALESCE(ti.discount, 0)))
```

**Solución:** Cambiar `discount_amount` por `discount` en TODO el archivo SQL

**Líneas afectadas:**
- Línea 45: En vista `vw_ticket_base`
- Posiblemente en otras vistas

#### 11. `2025_11_06_120000_refresh_sales_report_views`
- **Depende de:** Migración anterior
- **Acción:** Ejecutar DESPUÉS de corregir la anterior

---

### Grupo 5: Ya Idempotente (1)

#### 12. `2025_11_15_090000_extend_alert_tables` ✅
- **Columnas agregadas:**
  - `alert_rules`: `scope`, `threshold_numeric`, `threshold_percent`, `notification_channels`
  - `alert_events`: `assigned_to`, `acknowledged_at`, `resolution_notes`, `severity`
- **Estado:** TODAS las columnas YA EXISTEN
- **Diseño:** YA usa `addColumnIfMissing()` - es idempotente
- **Acción:** Ejecutar directamente (no hará nada pero se registrará)

---

## 🎯 Plan de Acción Paso a Paso

### FASE 1: Registrar Migraciones Seguras (Batch 13)
**Objetivo:** Marcar como ejecutadas las que ya tienen sus tablas

```php
php scripts/register_safe_migrations_part2.php
```

**Migraciones a registrar:**
1. `2025_11_15_030000_create_pos_consumption_tables`
2. `2025_11_15_070000_create_pos_sync_tables`
3. `2025_11_15_080000_create_menu_engineering_tables`
4. `2025_11_15_100000_create_reporting_tables`

---

### FASE 2: Corregir Archivo SQL de Reportes
**Objetivo:** Arreglar referencias de columnas

1. Abrir: `docs/docs/BD/NoviembreDocsDocs/VentasReport/v9/script_sql_reportes_adicionales.sql`
2. Buscar y reemplazar: `discount_amount` → `discount`
3. Verificar cambios en línea 45 y siguientes
4. Copiar archivo corregido a: `database/sql/reportes/` (si no existe el directorio, crearlo)

---

### FASE 3: Verificar Migraciones Idempotentes
**Objetivo:** Confirmar que tienen checks de existencia

**Revisar:**
1. `2025_11_15_000000_create_inventory_receiving_tables.php`
   - ✓ Ya tiene checks para todas las tablas
   
2. `2025_11_15_060000_create_costing_extension_tables.php`
   - ✓ Ya tiene checks para todas las tablas

---

### FASE 4: Ejecutar Migraciones Restantes (Batch 14-16)
**Objetivo:** Aplicar cambios faltantes

```bash
# 1. Ejecutar migraciones idempotentes
php artisan migrate --step  # Inventory receiving
php artisan migrate --step  # Inventory counts  
php artisan migrate --step  # Production
php artisan migrate --step  # Pos consumption (no hará cambios)
php artisan migrate --step  # Purchasing
php artisan migrate --step  # Costing extension
php artisan migrate --step  # Pos sync (no hará cambios)
php artisan migrate --step  # Menu engineering (no hará cambios)
php artisan migrate --step  # Extend alerts (no hará cambios)
php artisan migrate --step  # Reporting (no hará cambios)

# 2. Ejecutar reportes (después de corregir SQL)
php artisan migrate --step  # Create sales report views
php artisan migrate --step  # Refresh sales report views
```

---

## 📦 Tablas que se Crearán

### Nuevas (13 tablas)
1. `inventory_batch` - Lotes de inventario
2. `recepcion_det` - Detalle de recepciones
3. `mov_inv` - Movimientos de inventario
4. `recepcion_adjuntos` - Documentos de recepción
5. `inventory_counts` - Conteos de inventario
6. `inventory_count_lines` - Líneas de conteo
7. `production_orders` - Órdenes de producción
8. `production_order_inputs` - Insumos de producción
9. `production_order_outputs` - Productos terminados
10. `inventory_wastes` - Mermas
11. `purchase_requests`, `purchase_request_lines` - Solicitudes de compra
12. `purchase_vendor_quotes`, `purchase_vendor_quote_lines` - Cotizaciones
13. `purchase_orders`, `purchase_order_lines`, `purchase_documents` - Órdenes de compra
14. `labor_roles` - Roles de mano de obra
15. `overhead_definitions` - Definiciones de gastos indirectos

### Vistas (8)
1. `vw_ticket_base` - Base de tickets válidos
2. `vw_report_sales_detail` - Detalle de ventas
3. `vw_report_sales_summary` - Resumen de ventas
4. `vw_report_balance_detail` - Detalle de balance
5. `vw_report_sales_exceptions` - Excepciones
6. `vw_report_menu_usage` - Uso de menú
7. `vw_report_journal_lines` - Líneas de journal
8. `vw_report_journal_payments` - Pagos de journal

### Funciones PL/pgSQL (3)
1. `fn_expandir_consumo_ticket()` - Expandir recetas de ticket
2. `fn_confirmar_consumo_ticket()` - Confirmar consumo
3. `fn_reversar_consumo_ticket()` - Reversar consumo

### Triggers (1)
1. `trg_ticket_inventory_consumption` - Trigger automático en tickets

---

## ⚠️ Advertencias

### 1. Migraciones de Consumo POS
- **Ya existen tablas y funciones**
- La migración intenta crearlas de nuevo
- **Solución:** Si la ejecutamos, fallará en CREATE TABLE pero pasará en DROP/CREATE de funciones
- **Riesgo:** Podría sobrescribir funciones personalizadas
- **Recomendación:** Solo registrar, NO ejecutar

### 2. Archivo SQL de Reportes
- **DEBE corregirse antes de ejecutar**
- Fallar en producción podría dejar vistas a medias
- **Verificar:** Hacer backup antes de aplicar

### 3. Tablas de Inventario
- `inventory_batch` es crítica para lotes/caducidad
- `mov_inv` es crítica para trazabilidad
- **Validar:** Que no existan datos huérfanos después de crear

---

## 🔍 Validaciones Post-Migración

Después de completar, verificar:

```sql
-- 1. Contar registros en tablas principales
SELECT 'recepcion_cab'::text, COUNT(*) FROM selemti.recepcion_cab
UNION ALL SELECT 'inv_consumo_pos', COUNT(*) FROM selemti.inv_consumo_pos
UNION ALL SELECT 'pos_sync_batches', COUNT(*) FROM selemti.pos_sync_batches;

-- 2. Verificar vistas
SELECT table_name FROM information_schema.views 
WHERE table_schema = 'public' AND table_name LIKE 'vw_report%';

-- 3. Verificar funciones
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'selemti' AND routine_type = 'FUNCTION';

-- 4. Verificar triggers
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

---

## 📝 Estado Final Esperado

Después de completar todo:
- **Migraciones registradas:** 77 de 77 (100%)
- **Nuevas tablas:** 15
- **Nuevas vistas:** 8
- **Nuevas funciones:** 3
- **Nuevos triggers:** 1

---

**Siguiente paso:** ¿Proceder con FASE 1 (registrar migraciones seguras)?
