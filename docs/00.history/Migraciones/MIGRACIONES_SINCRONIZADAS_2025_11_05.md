# Resumen de Sincronización de Migraciones
**Fecha:** 2025-11-05  
**Proyecto:** TerrenaLaravel

---

## Situación Inicial

Se detectaron **35 migraciones pendientes** que no podían ejecutarse porque:
1. Muchas tablas ya existían en la base de datos
2. Las migraciones intentaban crear tablas/columnas duplicadas
3. Las migraciones no eran idempotentes (no verificaban existencia antes de crear)

### Problema Principal
Error típico al ejecutar `php artisan migrate`:
```
SQLSTATE[42P07]: Duplicate table: 7 ERROR: la relación «cash_funds» ya existe
```

---

## Acciones Realizadas

### 1. Análisis y Categorización
Se analizaron las 35 migraciones pendientes y se categorizaron en:

- **Categoría 1 - Seguras para registrar (16 migraciones):**
  - Tablas/columnas ya existen en la BD
  - Solo necesitan ser registradas en tabla `migrations`
  
- **Categoría 2 - Necesitan ejecutarse (5 migraciones):**
  - Tienen cambios pendientes por aplicar
  - Columnas faltantes identificadas
  
- **Categoría 3 - Requieren revisión (14 migraciones):**
  - Migraciones grandes y complejas del 15 de noviembre
  - Requieren análisis detallado antes de ejecutar

### 2. Registro de Migraciones Seguras (Batch 10)
Se registraron **16 migraciones** cuyas tablas/columnas ya existían:

```
✓ 2025_10_24_015559_add_fecha_recepcion_to_recepcion_cab_table
✓ 2025_10_24_100000_create_replenishment_suggestions_table
✓ 2025_10_24_120000_create_purchase_suggestions_table
✓ 2025_10_24_120101_create_purchase_suggestion_lines_table
✓ 2025_10_26_000004_add_unit_cost_to_inventory_batch
✓ 2025_10_26_000005_create_pos_map_table
✓ 2025_10_26_000006_create_ticket_item_modifiers_table
✓ 2025_10_27_100239_create_pos_reverse_log_table
✓ 2025_10_27_100252_create_pos_reprocess_log_table
✓ 2025_10_27_153528_create_personal_access_tokens_table
✓ 2025_10_28_000001_update_inv_consumo_flags
✓ 2025_10_28_000002_drop_public_ticket_trigger
✓ 2025_10_28_000010_create_audit_log_table
✓ 2025_10_28_200000_add_indexes_to_audit_log_table
✓ 2025_10_28_200001_add_foreign_key_to_audit_log_table
✓ 2025_10_30_000000_add_remember_token_to_selemti_users
```

### 3. Corrección de Migraciones No Idempotentes
Se modificaron **3 migraciones** para que verifiquen existencia antes de crear:

#### a) `2025_10_27_110252_add_flags_to_inv_consumo_pos_and_det.php`
- **Cambio:** Agregado checks con `Schema::hasColumn()` antes de crear columnas
- **Columna nueva:** `revertido` (faltaba en versión original)
- **Columnas verificadas:** `requiere_reproceso`, `procesado`, `fecha_proceso`, `revertido`

#### b) `2025_10_28_000003_add_display_fields_to_roles_table.php`
- **Cambio:** Agregado checks con `Schema::hasColumn()`
- **Columna nueva:** `color` (faltaba en versión original)
- **Columnas verificadas:** `display_name`, `description`, `color`

#### c) `2025_10_30_120000_add_code_columns_to_insumo.php`
- **Cambio:** Agregado checks con `Schema::hasColumn()`
- **Columna nueva:** `codigo_alterno` (agregada para compatibilidad)
- **Columnas verificadas:** `codigo`, `categoria_codigo`, `subcategoria_codigo`, `consecutivo`, `codigo_alterno`
- **Índices:** Manejo seguro de constraints e índices existentes

### 4. Ejecución de Migraciones Necesarias (Batch 11 y 12)
Se ejecutaron exitosamente **7 migraciones:**

```
✓ 2025_10_24_020818_add_missing_inventory_fields_to_recepcion_cab_table
✓ 2025_10_24_120102_alter_purchase_requests_add_fields
✓ 2025_10_26_000002_add_operational_flags_to_items
✓ 2025_10_27_110252_add_flags_to_inv_consumo_pos_and_det
✓ 2025_10_28_000003_add_display_fields_to_roles_table
✓ 2025_10_30_120000_add_code_columns_to_insumo
✓ 2025_11_03_194300_fix_item_id_data_types
```

#### Columnas Agregadas:

**Tabla `recepcion_cab`:**
- `almacen_origen_id` ✓
- `estado` ✓
- `total_presentaciones` ✓
- `total_canonico` ✓

**Tabla `items`:**
- `es_producible` ✓
- `es_consumible_operativo` ✓
- `es_empaque_to_go` ✓

**Tabla `inv_consumo_pos`:**
- `revertido` ✓ (NUEVA)
- Índice: `inv_consumo_pos_revertido_idx` ✓

**Tabla `inv_consumo_pos_det`:**
- `revertido` ✓ (NUEVA)
- Índice: `inv_consumo_pos_det_revertido_idx` ✓

**Tabla `roles` (selemti.roles):**
- `color` ✓ (NUEVA - varchar(7) para códigos hex)

**Tabla `insumo` (selemti.insumo):**
- `codigo_alterno` ✓ (NUEVA - varchar(50) para compatibilidad)

---

## Estado Final

### Migraciones Ejecutadas
- **Total de migraciones registradas:** 65 de 77
- **Migraciones pendientes:** 12

### Migraciones Pendientes que Requieren Revisión

Las siguientes migraciones están pendientes y requieren análisis adicional:

1. `2025_11_04_000900_create_additional_sales_report_views` ⚠️
   - **Problema:** Falta columna `ticket_item.discount_amount`
   - **Acción requerida:** Revisar estructura de tabla `ticket_item` o actualizar SQL de vistas

2. `2025_11_06_120000_refresh_sales_report_views`
   - Depende de migración anterior

3. **Migraciones del 15 de noviembre (9 archivos):**
   - `2025_11_15_000000_create_inventory_receiving_tables`
   - `2025_11_15_010000_create_inventory_counts_tables`
   - `2025_11_15_020000_create_production_tables`
   - `2025_11_15_030000_create_pos_consumption_tables`
   - `2025_11_15_050000_create_purchasing_tables`
   - `2025_11_15_060000_create_costing_extension_tables`
   - `2025_11_15_070000_create_pos_sync_tables`
   - `2025_11_15_080000_create_menu_engineering_tables`
   - `2025_11_15_090000_extend_alert_tables`
   - `2025_11_15_100000_create_reporting_tables`
   
   **Nota:** Estas son migraciones grandes que crean múltiples tablas y vistas. Se recomienda:
   - Verificar si son necesarias para la funcionalidad actual
   - Revisar una por una antes de ejecutar
   - Evaluar si algunas tablas ya existen

---

## Scripts Creados

Se generaron los siguientes scripts auxiliares en `scripts/`:

1. **`register_safe_migrations.php`**
   - Registra migraciones cuyas tablas ya existen
   - Incluye confirmación interactiva
   - ✓ Ejecutado exitosamente

2. **`sync_migrations_part1.sql`**
   - Versión SQL del script anterior
   - No utilizado (se prefirió versión PHP)

3. **`verify_missing_columns.sql`**
   - Script de verificación para identificar columnas faltantes
   - Útil para diagnóstico futuro

---

## Recomendaciones

### Inmediatas
1. ✅ **Completado:** Sincronización de migraciones básicas
2. ⚠️ **Pendiente:** Revisar migración de vistas de reportes
   - Verificar esquema de `ticket_item`
   - Actualizar SQL de vistas si es necesario

### A Futuro
1. **Hacer todas las migraciones idempotentes:**
   - Agregar checks `Schema::hasColumn()` antes de crear columnas
   - Agregar checks `Schema::hasTable()` antes de crear tablas
   - Manejar índices y constraints de forma segura

2. **Documentar cambios en BD:**
   - Mantener un changelog de alteraciones manuales
   - Registrar migraciones ejecutadas fuera de Laravel

3. **Revisar migraciones del 15 de noviembre:**
   - Analizar dependencias
   - Verificar compatibilidad con datos existentes
   - Ejecutar en ambiente de prueba primero

---

## Comandos Útiles

```bash
# Ver estado de migraciones
php artisan migrate:status

# Ver solo pendientes
php artisan migrate:status --pending

# Ejecutar una migración a la vez
php artisan migrate --step

# Revertir último batch
php artisan migrate:rollback --step=1

# Verificar estructura de BD
php artisan db:show
```

---

## Archivos Modificados

### Migraciones Actualizadas
1. `database/migrations/2025_10_27_110252_add_flags_to_inv_consumo_pos_and_det.php`
2. `database/migrations/2025_10_28_000003_add_display_fields_to_roles_table.php`
3. `database/migrations/2025_10_30_120000_add_code_columns_to_insumo.php`

### Scripts Nuevos
1. `scripts/register_safe_migrations.php`
2. `scripts/sync_migrations_part1.sql`
3. `scripts/verify_missing_columns.sql`

---

**Conclusión:** Se sincronizaron exitosamente 23 migraciones (16 registradas + 7 ejecutadas), corrigiendo problemas de duplicación y agregando columnas faltantes. Quedan 12 migraciones pendientes que requieren análisis individual antes de su ejecución.
