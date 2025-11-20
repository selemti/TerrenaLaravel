# FUNCIONES SQL - Sistema Terrena

**MAESTRO (Consolidación CLAUDE + QWEN + CODEX + COPILOT)**
**Fecha**: 14 Noviembre 2025

---

## OVERVIEW

**Total de funciones en `selemti`**: 37 funciones SQL
**Total de funciones en `public`**: 100+ funciones (sistema POS Floreant + extensiones Terrena)

**Distribución**:
- Funciones críticas (sin doc): 12 (32%)
- Funciones documentadas: 12 (32%)
- Funciones auxiliares: 13 (36%)

**⚠️ NOTA IMPORTANTE**: Esta documentación describe **QUÉ** hace cada función y **PARA QUÉ** se usa, NO incluye el código fuente completo. Para ver el código fuente, usar:

```sql
SELECT pg_get_functiondef('selemti.nombre_funcion'::regproc);
```

---

## 1. FUNCIONES CRÍTICAS (12 funciones) - PRIORIDAD ALTA

Estas son las funciones más importantes del sistema que requieren documentación urgente por su impacto en el negocio.

### 🔴 1.1 fn_recipe_cost_at(recipe_id, fecha)

**Módulo**: Recetas / Costeo
**Propósito**: Calcula el costo total de una receta en una fecha específica
**Estado**: ❌ SIN DOCUMENTAR (CRÍTICO)

**Uso**:
- Backend: `RecipeService::calculateCost()`
- Reportes de costeo de recetas
- Análisis de variación de costos en el tiempo

**Parámetros**:
- `recipe_id` (integer) - ID de la receta
- `fecha` (date) - Fecha para el cálculo

**Retorno**: `numeric` - Costo total de la receta

**Lógica de negocio**:
1. Obtiene la versión activa de la receta en la fecha especificada
2. Para cada insumo en `receta_insumo`:
   - Llama a `fn_item_unit_cost_at(item_id, fecha)` para obtener costo del insumo
   - Multiplica costo unitario × cantidad
3. Suma todos los costos de insumos
4. Agrega costos de labor (si aplica)
5. Agrega overhead (si aplica)
6. Retorna costo total

**Consideraciones**:
- Función PURA (sin side effects)
- Utilizada en snapshots de costos
- Performance crítica (caching recomendado)

**Ejemplo de uso**:
```sql
-- Costo de receta #15 al 1 de octubre 2025
SELECT selemti.fn_recipe_cost_at(15, '2025-10-01');
```

---

### 🔴 1.2 fn_recipes_using_item(item_id)

**Módulo**: Recetas / BOM Implosion
**Propósito**: BOM Implosion - Encuentra todas las recetas que utilizan un item específico
**Estado**: ❌ SIN DOCUMENTAR (CRÍTICO - FEATURE SOLICITADA)

**Uso**:
- Análisis de impacto de cambios de precio
- Identificar recetas afectadas por falta de stock
- Reportes de "¿Dónde se usa este insumo?"

**Parámetros**:
- `item_id` (integer) - ID del item/insumo

**Retorno**: `TABLE(recipe_id, recipe_name, qty, uom)` - Lista de recetas que usan el item

**Lógica de negocio**:
1. Busca en `receta_insumo` todas las versiones activas que contienen `item_id`
2. Agrupa por `receta_cab.id`
3. Retorna lista de recetas con cantidad usada

**Consideraciones**:
- Búsqueda recursiva (puede incluir sub-recetas)
- Performance crítica para items usados en muchas recetas

**Ejemplo de uso**:
```sql
-- ¿Qué recetas usan el item #42 (harina)?
SELECT * FROM selemti.fn_recipes_using_item(42);
```

---

### 🔴 1.3 fn_item_unit_cost_at(item_id, fecha)

**Módulo**: Inventario / Costeo
**Propósito**: Calcula el costo unitario de un item en una fecha específica
**Estado**: ❌ SIN DOCUMENTAR (CRÍTICO)

**Uso**:
- Llamada desde `fn_recipe_cost_at()`
- Reportes de costos de inventario
- Análisis de variación de costos

**Parámetros**:
- `item_id` (integer) - ID del item
- `fecha` (date) - Fecha para el cálculo

**Retorno**: `numeric` - Costo unitario del item en UOM base

**Lógica de negocio**:
1. Busca en `cost_layer` las capas activas del item en la fecha
2. Aplica método FIFO/FEFO según política del item
3. Calcula costo promedio ponderado
4. Normaliza a UOM base
5. Retorna costo unitario

**Consideraciones**:
- Si no hay cost_layer, usa `items.costo_promedio`
- Performance crítica (función llamada miles de veces)

**Ejemplo de uso**:
```sql
-- Costo del item #42 al 15 de septiembre
SELECT selemti.fn_item_unit_cost_at(42, '2025-09-15');
```

---

### 🔴 1.4 fn_expandir_consumo_ticket(ticket_id)

**Módulo**: POS / Consumo de Inventario
**Propósito**: Expande el consumo de un ticket según las recetas mapeadas
**Estado**: ❌ SIN DOCUMENTAR (CRÍTICO)

**Uso**:
- Llamada automática después de `ingesta_ticket()`
- Registra consumo de inventario desde ventas POS

**Parámetros**:
- `ticket_id` (integer) - ID del ticket (de `public.ticket`)

**Retorno**: `void` (realiza INSERT en `mov_inv`)

**Lógica de negocio**:
1. Lee `public.ticket_item` para el ticket
2. Para cada item vendido:
   - Busca mapeo en `pos_map` (menu_item_id → receta_id)
   - Si existe receta:
     - Lee BOM desde `receta_insumo`
     - Para cada insumo: Calcula cantidad = porción × qty vendida
     - Registra SALIDA en `mov_inv` (tipo='CONSUMO_POS')
   - Si no existe receta:
     - Busca mapeo directo (menu_item → item)
     - Registra SALIDA directa

**Consideraciones**:
- Función con SIDE EFFECTS (inserta en `mov_inv`)
- Transaccional (TODO o NADA)
- Puede ser reversada con `fn_reversar_consumo_ticket()`

**Ejemplo de uso**:
```sql
-- Expandir consumo del ticket #12345
SELECT selemti.fn_expandir_consumo_ticket(12345);
```

---

### 🔴 1.5 recalcular_costos_periodo(fecha_inicio, fecha_fin)

**Módulo**: Recetas / Costeo Masivo
**Propósito**: Recalcula costos de recetas en un periodo completo
**Estado**: ❌ SIN DOCUMENTAR (CRÍTICO)

**Uso**:
- Reprocesamiento de costos históricos
- Corrección de errores de costeo
- Ajustes después de cambios en precios

**Parámetros**:
- `fecha_inicio` (date) - Fecha inicial del periodo
- `fecha_fin` (date) - Fecha final del periodo

**Retorno**: `integer` - Cantidad de recetas recalculadas

**Lógica de negocio**:
1. Obtiene lista de recetas activas en el periodo
2. Para cada receta:
   - Llama a `fn_recipe_cost_at(recipe_id, fecha)`
   - Compara con costo registrado en `recipe_cost_history`
   - Si difiere: actualiza `recipe_cost_history`
3. Registra operación en `recalc_log`
4. Retorna cantidad de recetas procesadas

**Consideraciones**:
- Operación COSTOSA (puede tardar minutos)
- Debe ejecutarse en horarios de baja carga
- Usa cola `job_recalc_queue` para paralelización

**Ejemplo de uso**:
```sql
-- Recalcular octubre 2025
SELECT selemti.recalcular_costos_periodo('2025-10-01', '2025-10-31');
```

---

### 🔴 1.6 fn_confirmar_consumo_ticket(ticket_id)

**Módulo**: POS / Consumo
**Propósito**: Confirma (finaliza) el consumo de un ticket
**Estado**: ❌ SIN DOCUMENTAR

**Uso**:
- Marca consumo como CONFIRMADO (no reversible)
- Actualiza stock final

**Parámetros**:
- `ticket_id` (integer)

**Retorno**: `boolean` - true si confirmó exitosamente

**Lógica**: Actualiza estado en `inv_consumo_pos`

---

### 🔴 1.7 fn_reversar_consumo_ticket(ticket_id)

**Módulo**: POS / Consumo
**Propósito**: Reversa el consumo de un ticket (ticket void)
**Estado**: ❌ SIN DOCUMENTAR

**Uso**:
- Cuando un ticket se anula en POS
- Revierte movimientos de inventario

**Parámetros**:
- `ticket_id` (integer)

**Retorno**: `void`

**Lógica**:
1. Busca movimientos en `mov_inv` con `ref_tipo='CONSUMO_POS'` y `ref_id=ticket_id`
2. Crea movimientos inversos (ENTRADA para compensar SALIDA)
3. Registra en `pos_reverse_log`

---

### 🔴 1.8 reprocesar_costos_historicos()

**Módulo**: Recetas / Costeo
**Propósito**: Reprocesa TODO el histórico de costos
**Estado**: ❌ SIN DOCUMENTAR

**Uso**:
- Migración de datos
- Corrección masiva de errores

**Parámetros**: Ninguno

**Retorno**: `integer` - Registros procesados

**Lógica**: Similar a `recalcular_costos_periodo()` pero SIN filtro de fechas

**⚠️ PELIGRO**: Operación MUY costosa (puede tardar horas)

---

### 🔴 1.9 sp_snapshot_recipe_cost()

**Módulo**: Recetas / Snapshots
**Propósito**: Genera snapshot de costos de recetas (proceso batch)
**Estado**: ❌ SIN DOCUMENTAR

**Uso**:
- Job nocturno (cron)
- Genera snapshots en `recipe_cost_snapshots`

**Parámetros**: Ninguno

**Retorno**: `integer` - Snapshots creados

**Lógica**:
1. Para cada receta activa:
   - Llama `fn_recipe_cost_at(recipe_id, CURRENT_DATE)`
   - Inserta en `recipe_cost_snapshots`

---

### 🔴 1.10 inferir_recetas_de_ventas()

**Módulo**: POS / Análisis
**Propósito**: Infiere recetas desde patrones de ventas
**Estado**: ❌ SIN DOCUMENTAR

**Uso**:
- Machine learning / análisis de patrones
- Sugerencias de mapeo automático

**Lógica**: Análisis estadístico de `ticket_item` para detectar patrones

---

### 🔴 1.11 registrar_consumo_porcionado()

**Módulo**: POS / Consumo
**Propósito**: Registra consumo con porciones fraccionadas
**Estado**: ❌ SIN DOCUMENTAR

**Uso**:
- Cuando se venden porciones (ej: 1.5 porciones de pizza)

**Lógica**: Calcula qty = porción_base × fracción

---

### 🔴 1.12 cerrar_lote_preparado()

**Módulo**: Inventario / Lotes
**Propósito**: Cierra un lote preparado (ya no disponible)
**Estado**: ❌ SIN DOCUMENTAR

**Uso**:
- Cuando un lote se agota completamente
- Cuando un lote vence

**Lógica**: Actualiza `inventory_batch.estado = 'CERRADO'`

---

## 2. FUNCIONES DE CAJA (5 funciones) - ⭐⭐⭐⭐⭐ DOCUMENTADAS

Estas funciones están bien documentadas en `/docs/V4.0/Caja/`.

### ✅ 2.1 fn_precorte_after_insert()

**Módulo**: Caja
**Propósito**: Trigger automático después de insertar precorte
**Estado**: ✅ DOCUMENTADO

**Uso**: Trigger `trg_precorte_after_insert` en tabla `precorte`

**Lógica**:
1. Genera snapshot del estado de caja
2. Actualiza `sesion_cajon.ultimo_precorte_id`
3. Calcula diferencias efectivo vs sistema

**Documentación**: `/docs/V4.0/Caja/README.md`

---

### ✅ 2.2 fn_postcorte_after_insert()

**Módulo**: Caja
**Propósito**: Trigger automático después de insertar postcorte
**Estado**: ✅ DOCUMENTADO

**Uso**: Trigger `trg_postcorte_after_insert` en tabla `postcorte`

**Lógica**:
1. Genera registro en `conciliacion`
2. Calcula variaciones (A_FAVOR, EN_CONTRA, CUADRA)
3. Cierra sesión de caja

**Documentación**: `/docs/V4.0/Caja/README.md`

---

### ✅ 2.3 fn_precorte_after_update_aprobado()

**Módulo**: Caja
**Propósito**: Trigger cuando se aprueba un precorte
**Estado**: ✅ DOCUMENTADO

**Uso**: Trigger `trg_precorte_after_update_aprobado` en tabla `precorte`

**Lógica**:
1. Si `precorte.aprobado = true`:
   - Cierra automáticamente `sesion_cajon`
   - Actualiza `sesion_cajon.estatus = 'CERRADA'`

**Documentación**: `/docs/V4.0/Caja/README.md`

---

### ✅ 2.4 fn_precorte_efectivo_bi()

**Módulo**: Caja
**Propósito**: Validación before insert en `precorte_efectivo`
**Estado**: ✅ DOCUMENTADO

**Uso**: Trigger `trg_precorte_efectivo_bi` en tabla `precorte_efectivo`

**Lógica**:
1. Valida que suma de billetes/monedas = total efectivo
2. Rechaza insert si no cuadra

**Documentación**: `/docs/V4.0/Caja/README.md`

---

### ✅ 2.5 fn_fondo_actual()

**Módulo**: Caja
**Propósito**: Calcula el fondo actual de caja
**Estado**: ⚠️ NO DOCUMENTADO (pero usado)

**Uso**:
- Backend: `SesionCajonService`
- Dashboard de caja

**Parámetros**:
- `sesion_id` (integer)

**Retorno**: `numeric` - Fondo actual

**Lógica**:
1. Suma movimientos de efectivo desde apertura
2. Resta pagos realizados
3. Suma reingresos

---

## 3. FUNCIONES DE INVENTARIO (8 funciones) - ⭐⭐⭐⭐ PARCIAL

### ⚠️ 3.1 fn_assign_item_code()

**Módulo**: Inventario
**Propósito**: Auto-asigna código a items nuevos
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger `trg_items_assign_code` en tabla `items`

**Lógica**:
1. Obtiene contador de categoría (`item_category_counters`)
2. Genera código: `{categoria_codigo}-{contador}`
3. Incrementa contador

**Ejemplo**: `INS-001`, `PROD-042`

---

### ⚠️ 3.2 fn_uom_factor(origen_id, destino_id)

**Módulo**: Catálogos / UOM
**Propósito**: Calcula factor de conversión entre dos unidades
**Estado**: ⚠️ BREVEMENTE DOCUMENTADO

**Uso**:
- `ReceptionService`
- `ProductionService`
- Normalización de cantidades

**Parámetros**:
- `origen_id` (integer) - UOM origen
- `destino_id` (integer) - UOM destino

**Retorno**: `numeric` - Factor de conversión

**Lógica**:
1. Busca en `cat_uom_conversion` la conversión directa
2. Si no existe, busca ruta indirecta (via UOM base)
3. Retorna factor

**Ejemplo**:
```sql
-- ¿Cuántos kg hay en 1 lt de agua?
SELECT selemti.fn_uom_factor(
    (SELECT id FROM cat_unidades WHERE codigo='LT'),
    (SELECT id FROM cat_unidades WHERE codigo='KG')
); -- Retorna 1.0
```

---

### ⚠️ 3.3 fn_after_price_insert_alert()

**Módulo**: Inventario / Precios
**Propósito**: Genera alerta cuando cambia precio de un item
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger `trg_ivp_after_insert` en tabla `item_vendor_prices`

**Lógica**:
1. Compara precio nuevo vs precio anterior
2. Si variación > 10%: Inserta en `alert_events`

---

### ⚠️ 3.4 fn_ivp_upsert_close_prev()

**Módulo**: Inventario / Precios
**Propósito**: Cierra precio previo al insertar nuevo precio
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger `trg_ivp_close_prev` en tabla `item_vendor_prices`

**Lógica**:
1. Busca precio abierto (`vigente_hasta IS NULL`)
2. Cierra precio: `UPDATE vigente_hasta = CURRENT_DATE`

---

### ⚠️ 3.5 tg_invshot_autofill()

**Módulo**: Inventario / Snapshots
**Propósito**: Auto-completa campos en snapshots de inventario
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger `trg_invshot_biur` en tabla `inventory_snapshot`

**Lógica**: Auto-calcula stock, costo, etc.

---

### ⚠️ 3.6 set_timestamp_ipp()

**Módulo**: Inventario (legacy)
**Propósito**: Auto-actualiza timestamp en `insumo_proveedor_presentacion`
**Estado**: ⚠️ NO DOCUMENTADO (LEGACY)

**Uso**: Trigger en tabla legacy

**Lógica**: `updated_at = CURRENT_TIMESTAMP`

---

## 4. FUNCIONES DE FORMAS DE PAGO (2 funciones) - ⭐⭐⭐⭐ PARCIAL

### ⚠️ 4.1 fn_normalizar_forma_pago()

**Módulo**: Caja / Formas de Pago
**Propósito**: Normaliza forma de pago desde POS
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Mapeo de formas de pago POS → selemti
- `fn_tx_after_insert_forma_pago()`

**Lógica**:
1. Lee forma de pago desde `public.transactions`
2. Mapea a forma estándar en `selemti.formas_pago`
3. Retorna ID normalizado

**Ejemplo**: "CASH" → "EFECTIVO", "CARD" → "TARJETA"

---

### ⚠️ 4.2 fn_tx_after_insert_forma_pago()

**Módulo**: Caja / Transacciones
**Propósito**: Trigger after insert en transacciones POS
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger `trg_selemti_tx_ai_forma_pago` en `public.transactions`

**Lógica**:
1. Normaliza forma de pago
2. Actualiza `sesion_cajon` con movimiento

---

## 5. FUNCIONES DE TERMINAL/SESIÓN (2 funciones) - ⭐⭐⭐⭐ PARCIAL

### ⚠️ 5.1 fn_terminal_bu_snapshot_cierre()

**Módulo**: Terminal
**Propósito**: Genera snapshot antes de cerrar terminal
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger `trg_selemti_terminal_bu_snapshot` en `public.terminal`

**Lógica**: Guarda estado del terminal antes de UPDATE

---

### ⚠️ 5.2 fn_reparar_sesion_apertura()

**Módulo**: Sesión Cajon
**Propósito**: Repara sesiones con apertura incorrecta
**Estado**: ❌ NO DOCUMENTADO

**Uso**:
- Mantenimiento correctivo
- Script de limpieza

**Lógica**: Corrige `sesion_cajon.apertura_ts` basado en primer movimiento

---

## 6. FUNCIONES DAH (Drawer Activity History) (2 funciones) - ⭐⭐⭐⭐ PARCIAL

### ⚠️ 6.1 fn_dah_after_insert()

**Módulo**: Caja / DAH
**Propósito**: Actualiza sesión después de movimiento de cajón
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger `trg_selemti_dah_ai` en `public.drawer_assigned_history`

**Lógica**: Actualiza `sesion_cajon` con movimientos de efectivo (refuerzos, retiros)

---

### ⚠️ 6.2 fn_dah_after_insert_refuerzo()

**Módulo**: Caja / DAH
**Propósito**: Específicamente para refuerzos de efectivo
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger auxiliar

**Lógica**: Similar a `fn_dah_after_insert()` pero solo refuerzos

---

## 7. FUNCIONES DE AUDITORÍA (1 función) - ⭐⭐⭐⭐⭐ BIEN

### ✅ 7.1 audit_trigger_func()

**Módulo**: Auditoría
**Propósito**: Función genérica de auditoría (trigger reutilizable)
**Estado**: ⚠️ NO DOCUMENTADO (pero estándar PostgreSQL)

**Uso**: Trigger en múltiples tablas críticas

**Lógica**:
1. Captura OLD y NEW record
2. Inserta en `audit_log` con:
   - `table_name`
   - `operation` (INSERT/UPDATE/DELETE)
   - `old_data` (JSON)
   - `new_data` (JSON)
   - `user_id`
   - `timestamp`

---

## 8. FUNCIONES DE SISTEMA (4 funciones) - ⭐⭐⭐⭐ BIEN

### ⚠️ 8.1 update_updated_at_column()

**Módulo**: Sistema
**Propósito**: Auto-actualiza campo `updated_at` en UPDATE
**Estado**: ⚠️ NO DOCUMENTADO (pero estándar)

**Uso**: Trigger en ~10 tablas

**Lógica**:
```sql
NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
```

---

### ⚠️ 8.2 fn_slug(texto)

**Módulo**: Sistema
**Propósito**: Genera slug desde texto (ej: "Hola Mundo" → "hola-mundo")
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**:
- Generación de códigos
- URLs amigables

**Lógica**:
1. Lower case
2. Reemplaza espacios por guiones
3. Elimina caracteres especiales

---

### ⚠️ 8.3 refresh_materialized_views()

**Módulo**: Sistema
**Propósito**: Refresca vistas materializadas
**Estado**: ⚠️ SIN USO (no hay vistas materializadas en selemti)

**Acción**: Deprecar

---

### ⚠️ 8.4 fn_generar_postcorte()

**Módulo**: Caja
**Propósito**: Genera postcorte automáticamente desde precorte
**Estado**: ❌ NO DOCUMENTADO (posible uso futuro)

**Uso**: Posible automatización futura

**Lógica**: Crea `postcorte` desde datos en `precorte`

---

## 9. FUNCIONES DE CATEGORÍAS (1 función) - ⭐⭐⭐ PARCIAL

### ⚠️ 9.1 fn_gen_cat_codigo()

**Módulo**: Inventario / Categorías
**Propósito**: Genera código automático para categorías
**Estado**: ⚠️ NO DOCUMENTADO

**Uso**: Trigger `trg_item_categories_autocode` en `item_categories`

**Lógica**: Genera código único para nueva categoría

---

## 10. FUNCIONES EN ESQUEMA PUBLIC RELACIONADAS CON TERRENA

Las siguientes funciones fueron creadas por Terrena para extender la funcionalidad del sistema POS Floreant y forman parte integral del sistema de integración POS ↔ Terrena:

### 10.1 Funciones de Asignación de Folios

| Función | Propósito | Uso principal | Estado |
|---------|-----------|---------------|--------|
| `assign_daily_folio` | Asigna folio diario único a tickets | Impresión de tickets | EN USO |
| `_last_assign_window` | Maneja ventana de asignación de folios | Control de concurrencia | EN USO |
| `get_ticket_folio_info` | Obtiene información de folio de ticket | Impresión y seguimiento | EN USO |
| `reset_daily_folio_smart` | Reinicia inteligentemente folio diario | Inicio de día | EN USO |

### 10.2 Funciones de Diagnóstico

| Función | Propósito | Uso principal | Estado |
|---------|-----------|---------------|--------|
| `f_daily_diagnostics_summary_on` | Diagnóstico diario de resumen | Reporte de inconsistencias | DIAGNÓSTICO |
| `f_diag_drawer_vs_cash_transactions_on` | Diagnóstico de cajón vs transacciones | Validación de integridad | DIAGNÓSTICO |
| `f_item_mods_on` | Procesamiento de modificadores de ítems | Análisis KDS | KDS |
| `f_sales_mix_payment_on` | Procesamiento de mezcla de pagos | Análisis de pagos | REPORTES |

### 10.3 Funciones de Reconciliación

| Función | Propósito | Uso principal | Estado |
|---------|-----------|---------------|--------|
| `fn_correct_drawer_report` | Corrige reporte de cajón | Validación de fondo / cambio | CAJA |
| `fn_daily_reconciliation` | Conciliación diaria | Cierre de día | CAJA |
| `fn_reconciliation_detail` | Detalle de conciliación | Reporte detallado | CAJA |
| `get_daily_stats` | Obtiene estadísticas diarias | Dashboard | REPORTES |

### 10.4 Funciones de KDS (Kitchen Display System)

| Función | Propósito | Uso principal | Estado |
|---------|-----------|---------------|--------|
| `kds_notify` | Notificación al sistema de cocina | Actualización KDS | KDS |

### 10.5 Funciones de Seguridad Criptográfica (Extensiones)

Estas funciones son extensiones PostgreSQL estándar y no forman parte del negocio Terrena:
- `armor`, `dearmor` - Encriptación/desencriptación de datos
- `crypt`, `decrypt`, `decrypt_iv`, `encrypt`, `encrypt_iv` - Funciones criptográficas
- `digest`, `hmac` - Hashing y HMAC
- `pgp_*` - Funciones PGP
- `uuid_*` - Generación de UUIDs
- `gen_random_*` - Generación de valores aleatorios

**NOTA IMPORTANTE**: Las funciones en `public` son extensiones del sistema Floreant POS desarrolladas por Terrena. No son parte del sistema original de POS, sino piezas de integración y análisis desarrolladas para la explotación de datos del POS.

---

## 11. FUNCIONES SIN USO (3 funciones) - DEPRECAR

### ❌ 11.1 refresh_materialized_views()

**Estado**: Sin uso (no hay vistas materializadas)
**Acción**: Deprecar y eliminar

---

### ⚠️ 11.2 fn_generar_postcorte()

**Estado**: Posible uso futuro
**Acción**: Validar si se necesita

---

## RESUMEN

### Por Estado

```
✅ Documentadas:        12 (32%)
❌ Críticas sin doc:    12 (32%)
⚠️ Parcial/sin doc:     13 (36%)
```

### Por Módulo

| Módulo | Funciones | Estado |
|--------|-----------|--------|
| Recetas/Costeo | 6 | ❌ CRÍTICO (sin doc) |
| POS/Consumo | 7 | ❌ CRÍTICO (sin doc) |
| Caja | 5 | ✅ EXCELENTE |
| Inventario | 8 | ⚠️ PARCIAL |
| Sistema | 4 | ⚠️ PARCIAL |
| Formas de Pago | 2 | ⚠️ PARCIAL |
| Terminal/Sesión | 2 | ⚠️ PARCIAL |
| DAH | 2 | ⚠️ PARCIAL |
| Auditoría | 1 | ✅ BIEN |

### Prioridades de Documentación

**🔴 URGENTE (Próxima semana - 20h)**:
1. `fn_recipe_cost_at()`
2. `fn_recipes_using_item()`
3. `fn_item_unit_cost_at()`
4. `fn_expandir_consumo_ticket()`
5. `recalcular_costos_periodo()`

**⚠️ IMPORTANTE (2 semanas - 16h)**:
6. `fn_confirmar_consumo_ticket()`
7. `fn_reversar_consumo_ticket()`
8. `reprocesar_costos_historicos()`
9. `sp_snapshot_recipe_cost()`
10. `inferir_recetas_de_ventas()`

**⚠️ NICE TO HAVE (1 mes - 12h)**:
11. Resto de funciones auxiliares

---

**Última actualización**: 14 Noviembre 2025
**Autor**: Claude Code (MAESTRO)