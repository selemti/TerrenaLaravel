# TABLAS POR MÓDULO - Sistema Terrena

**MAESTRO (Consolidación CLAUDE + QWEN + CODEX + COPILOT)**
**Fecha**: 14 Noviembre 2025

---

## OVERVIEW

**Total de tablas en `selemti`**: 147 tablas

**Distribución**:
- Tablas activas: 112 (76%)
- Tablas legacy: 35 (24%)
- Tablas backup temporal: 3

---

## 1. MÓDULO CAJA (10 tablas) - ⭐⭐⭐⭐⭐ EXCELENTE

### 1.1 Tablas Core

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **sesion_cajon** | Sesiones de caja por terminal | → precorte (1:N), postcorte (1:N) |
| **precorte** | Pre-cierre de caja antes de postcorte | ← sesion_cajon, → precorte_efectivo (1:N), → precorte_otros (1:N) |
| **postcorte** | Cierre final de caja | ← sesion_cajon, → conciliacion (1:1) |
| **conciliacion** | Resultado de conciliación caja | ← postcorte |

**Flujo de negocio**:
```
sesion_cajon (APERTURA)
    ↓
public.transactions (movimientos POS)
    ↓
precorte (pre-cierre)
    ↓ trigger: fn_precorte_after_insert()
precorte_efectivo + precorte_otros (detalle)
    ↓
postcorte (cierre final)
    ↓ trigger: fn_postcorte_after_insert()
conciliacion
    ↓
sesion_cajon (CERRADA)
```

### 1.2 Tablas de Detalle

| Tabla | Propósito | FK Principal |
|-------|-----------|--------------|
| **precorte_efectivo** | Detalle de efectivo en precorte (billetes/monedas) | precorte_id |
| **precorte_otros** | Otros medios de pago en precorte | precorte_id |
| **formas_pago** | Catálogo de formas de pago (Efectivo, Tarjeta, etc.) | - |

### 1.3 Tablas de Soporte

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **alertas_cortes** | Alertas generadas en cortes (variaciones, faltantes) | ✅ Activo |
| **caja_fondo** | Sistema legacy de fondo de caja | ❌ DEPRECADO (usar `cash_funds`) |
| **caja_fondo_*** | 5 tablas legacy relacionadas | ❌ DEPRECADO |

**Documentación completa**: `/docs/V4.0/Caja/`

---

## 2. MÓDULO CAJA CHICA (6 tablas) - ⭐⭐⭐⭐⭐ EXCELENTE

### 2.1 Tablas Core

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **cash_funds** | Fondos de caja chica (registro de fondos) | → cash_fund_movements (1:N), → cash_fund_arqueos (1:N) |
| **cash_fund_movements** | Movimientos de caja chica (gastos, reembolsos) | ← cash_funds, → cash_fund_movement_audit_log (1:N) |
| **cash_fund_arqueos** | Arqueos de caja chica (conteos físicos) | ← cash_funds |
| **cash_fund_movement_audit_log** | Auditoría de movimientos | ← cash_fund_movements |

**Características**:
- State machine completo (SOLICITADO → APROBADO → LIQUIDADO)
- Auditoría automática de cambios
- Integración con usuarios y permisos
- 6 Livewire components con CRUD completo

**Documentación completa**: `/docs/CajaChica/`

---

## 3. MÓDULO INVENTARIO (25 tablas) - ⭐⭐⭐⭐ BIEN

### 3.1 Tablas Core

| Tabla | Propósito | Relaciones Clave |
|-------|-----------|------------------|
| **items** | Catálogo maestro de items (insumos y productos) | → mov_inv (1:N), → inventory_batch (1:N), → cat_unidades (N:1) |
| **mov_inv** | Kardex - Movimientos de inventario (ENTRADA/SALIDA) | ← items, ← inventory_batch, ref_tipo/ref_id (polymorphic) |
| **inventory_batch** | Lotes de inventario (trazabilidad) | ← items, → cost_layer (1:N) |
| **inventory_snapshot** | Snapshots de stock en momentos específicos | ← items |

**Conceptos clave**:
- **Kardex**: `mov_inv` registra TODOS los movimientos (recepciones, consumos, ajustes, mermas)
- **Trazabilidad**: Cada movimiento liga a un lote (`inventory_batch`)
- **Costeo**: `cost_layer` implementa capas de costo por lote (FIFO/FEFO)
- **Normalización**: Cantidades siempre en UOM base (ver `cat_unidades`)

### 3.2 Tablas de Inventario Físico

| Tabla | Propósito | Uso |
|-------|-----------|-----|
| **inventory_counts** | Conteos físicos de inventario | Cabecera de conteo |
| **inventory_count_lines** | Líneas de conteo físico | Detalle por item |
| **inventory_wastes** | Mermas y desperdicios | Registra pérdidas |

### 3.3 Tablas de Items y Proveedores

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **item_categories** | Categorías de items (INSUMO, PRODUCTO, etc.) | → items (1:N) |
| **item_vendor** | Relación item-proveedor | ← items, ← cat_proveedores |
| **item_vendor_prices** | Precios por proveedor y fecha | ← item_vendor |

**Triggers importantes**:
- `trg_items_assign_code` - Auto-asigna código a items nuevos
- `trg_ivp_after_insert` - Genera alerta de cambio de precio
- `trg_ivp_close_prev` - Cierra precio previo al insertar nuevo

### 3.4 Tablas de Costeo

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **cost_layer** | Capas de costo por lote (FIFO) | ✅ Activo |
| **hist_cost_insumo** | Historial de costos de insumos | ✅ Activo |
| **historial_costos_item** | Historial de costos v2 | ⚠️ Posible duplicado |

### 3.5 Tablas de Políticas

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **stock_policy** | Políticas de stock (min/max, punto de reorden) | ✅ Activo |
| **inv_stock_policy** | Políticas de stock v2 | ⚠️ Posible duplicado |

### 3.6 Tablas Legacy (DEPRECADAS)

| Tabla | Reemplazada Por | Estado |
|-------|-----------------|--------|
| **lote** | `inventory_batch` | ❌ DEPRECADO |
| **insumo** | `items` | ❌ DEPRECADO |
| **insumo_presentacion** | `items` + `cat_uom_conversion` | ❌ DEPRECADO |
| **insumo_proveedor_presentacion** | `item_vendor_prices` | ❌ DEPRECADO |
| **proveedor** | `cat_proveedores` | ❌ DEPRECADO |

**Documentación**: `/docs/V4.0/Inventario/`

---

## 4. MÓDULO RECETAS (12 tablas) - ⭐⭐⭐ PARCIAL

### 4.1 Tablas Core

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **receta_cab** | Cabecera de recetas (master recipe) | → receta_version (1:N), → pos_map (1:N) |
| **receta_version** | Versiones de recetas (histórico) | ← receta_cab, → receta_insumo (1:N) |
| **receta_insumo** | Insumos de una receta (BOM - Bill of Materials) | ← receta_version, → items (N:1) |

**Flujo de versiones**:
```
receta_cab (master)
    ↓
receta_version (v1, v2, v3...)
    ↓
receta_insumo (BOM)
    → items (relación N:1)
```

### 4.2 Tablas de Costeo

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **recipe_cost_snapshots** | Snapshots de costos de recetas | ✅ Activo (modelo huérfano) |
| **recipe_cost_history** | Historial de costos | ✅ Activo |
| **recipe_extended_cost_history** | Historial extendido (labor, overhead) | ✅ Activo |
| **hist_cost_receta** | Historial de costos legacy | ⚠️ Usar `recipe_cost_history` |

### 4.3 Tablas de Labor y Overhead

| Tabla | Propósito | Uso |
|-------|-----------|-----|
| **recipe_labor_steps** | Pasos de labor en recetas | ✅ Activo |
| **recipe_overhead_allocations** | Asignación de overhead a recetas | ✅ Activo |
| **labor_roles** | Roles de labor (Chef, Ayudante, etc.) | ✅ Activo |
| **overhead_definitions** | Definiciones de overhead (renta, luz, etc.) | ✅ Activo |

### 4.4 Tablas Duplicadas (PROBLEMA CRÍTICO)

| Tabla 1 | Tabla 2 | Problema | Acción |
|---------|---------|----------|--------|
| `receta_version` | `recipe_versions` | Naming inconsistente | ✅ Consolidar en `receta_version` |
| `receta_insumo` | `recipe_version_items` | Posible duplicación | ⚠️ Validar diferencias |

### 4.5 Tablas Legacy (DEPRECADAS)

| Tabla | Estado |
|-------|--------|
| **receta** | ❌ DEPRECADO (usar `receta_cab`) |
| **receta_det** | ❌ DEPRECADO (usar `receta_insumo`) |
| **receta_shadow** | ⚠️ Validar uso, posible eliminación |

**Documentación**: Doc breve en `/docs/V4.0/Inventario/`

---

## 5. MÓDULO PRODUCCIÓN (10 tablas) - ⭐⭐ INCOMPLETO

### 5.1 Tablas Core (Sistema Nuevo)

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **production_orders** | Órdenes de producción | → production_order_inputs (1:N), → production_order_outputs (1:N) |
| **production_order_inputs** | Insumos consumidos en producción | ← production_orders, → items (N:1) |
| **production_order_outputs** | Productos generados en producción | ← production_orders, → items (N:1) |

**Flujo de producción**:
```
receta_cab (define qué producir)
    ↓
production_orders (orden de producción)
    ↓
production_order_inputs (consume items)
    → mov_inv (SALIDA)
    ↓
production_order_outputs (produce items)
    → mov_inv (ENTRADA)
```

### 5.2 Tablas Legacy (Sistema Viejo)

| Tabla | Propósito | Estado | Acción |
|-------|-----------|--------|--------|
| **op_cab** | Órdenes de producción legacy | ⚠️ En uso parcial | Migrar a `production_orders` |
| **op_insumo** | Insumos OP legacy | ⚠️ En uso parcial | Migrar |
| **op_yield** | Rendimientos de producción | ✅ Activo | Migrar |
| **op_produccion_cab** | 0 registros | ❌ Sin uso | Eliminar |
| **sol_prod_cab/det** | Solicitudes de producción | ❌ Sin uso | Eliminar |
| **prod_cab/det** | 0 registros | ❌ Sin uso | Eliminar |

**Problema crítico**: 4 tablas sin uso detectadas

**Documentación**: Doc muy breve

---

## 6. MÓDULO PURCHASING (13 tablas) - ⭐⭐⭐⭐ BIEN

### 6.1 Flujo Completo de Compras

```
purchase_requests (requisición)
    ↓
purchase_vendor_quotes (cotizaciones)
    ↓
purchase_orders (orden de compra)
    ↓
recepcion_cab/det (recepción)
    ↓
inventory_batch + mov_inv (inventario)
```

### 6.2 Tablas de Requisiciones

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **purchase_requests** | Requisiciones de compra | → purchase_request_lines (1:N), → purchase_vendor_quotes (1:N) |
| **purchase_request_lines** | Líneas de requisición | ← purchase_requests, → items (N:1) |

### 6.3 Tablas de Cotizaciones

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **purchase_vendor_quotes** | Cotizaciones de proveedores | ← purchase_requests, → purchase_vendor_quote_lines (1:N) |
| **purchase_vendor_quote_lines** | Líneas de cotización | ← purchase_vendor_quotes, → items (N:1) |

### 6.4 Tablas de Órdenes de Compra

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **purchase_orders** | Órdenes de compra | → purchase_order_lines (1:N), ← cat_proveedores (N:1) |
| **purchase_order_lines** | Líneas de OC | ← purchase_orders, → items (N:1) |
| **purchase_documents** | Documentos adjuntos (PDF, cotizaciones) | ← purchase_orders |

### 6.5 Tablas de Sugerencias y Reabasto

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **purchase_suggestions** | Sugerencias de compra manuales | ✅ Activo |
| **purchase_suggestion_lines** | Líneas de sugerencia | ✅ Activo |
| **replenishment_suggestions** | Sugerencias automáticas de reabasto | ❌ Módulo no documentado |

**Nota**: Motor de replenishment 0% implementado según auditoría

**Documentación**: `/docs/V4.0/Purchasing/`

---

## 7. MÓDULO POS (13 tablas) - ⭐⭐⭐ PARCIAL

### 7.1 Tablas de Mapeo POS

| Tabla | Propósito | Uso |
|-------|-----------|-----|
| **pos_map** | Mapeo menu_item (POS) ↔ receta_cab (selemti) | ✅ Activo (modelo huérfano) |
| **pos_modifiers_map** | Mapeo modificadores POS ↔ insumos | ✅ Activo |
| **menu_item_sync_map** | Sincronización menú POS ↔ selemti | ✅ Activo |

### 7.2 Tablas de Sincronización

| Tabla | Propósito | Uso |
|-------|-----------|-----|
| **pos_sync_logs** | Logs de sincronización POS | ✅ Activo (sin modelo) |
| **pos_sync_batches** | Batches de sincronización | ✅ Activo (sin modelo) |
| **pos_reprocess_log** | Log de reprocesamiento | ✅ Activo (sin modelo) |
| **pos_reverse_log** | Log de reversiones | ✅ Activo (sin modelo) |

### 7.3 Tablas de Menú

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **menu_items** | Items del menú (catálogo) | ✅ Activo |
| **menu_engineering_snapshots** | Snapshots de ingeniería de menú | ✅ Activo (sin modelo) |
| **modificadores_pos** | Modificadores POS | ✅ Activo |

### 7.4 Tablas de Consumo

| Tabla | Propósito | Uso |
|-------|-----------|-----|
| **ticket_det_consumo** | Detalle de consumo por ticket | ✅ Activo |
| **inv_consumo_pos** | Consumo de inventario desde POS | ✅ Activo |
| **inv_consumo_pos_det** | Detalle de consumo | ✅ Activo |
| **inv_consumo_pos_log** | Log de consumo | ✅ Activo |

### 7.5 Tablas Legacy (DEPRECADAS)

| Tabla | Reemplazada Por | Estado |
|-------|-----------------|--------|
| **ticket_venta_cab** | `public.ticket` + mapeo | ❌ DEPRECADO |
| **ticket_venta_det** | `public.ticket_item` + mapeo | ❌ DEPRECADO |

**Problema**: Varios modelos huérfanos (sin modelo Eloquent)

---

## 8. MÓDULO CATÁLOGOS (8 tablas) - ⭐⭐⭐⭐⭐ EXCELENTE

### 8.1 Tablas Core

| Tabla | Propósito | Registros | Documentación |
|-------|-----------|-----------|---------------|
| **cat_unidades** | Unidades de medida (kg, lt, pz, etc.) | ~80 | ✅ Completa |
| **cat_uom_conversion** | Conversiones entre unidades | ~110 | ✅ Completa |
| **cat_almacenes** | Almacenes/bodegas | ~40 | ✅ Completa |
| **cat_proveedores** | Proveedores | ~80 | ⚠️ Breve |
| **cat_sucursales** | Sucursales del negocio | ~50 | ✅ Completa |

### 8.2 Normalización UOM (Sistema de Conversiones)

**Logro**: 77 migraciones completadas para normalización UOM

**Tablas relacionadas**:
```
cat_unidades (catálogo maestro)
    ↓
cat_uom_conversion (conversiones)
    ↓
items (item.uom_id, item.uom_compra_id, item.uom_salida_id)
```

**Tipos de UOM**:
- **Base**: Unidad canónica (ej: kg para peso)
- **Compra**: Unidad en la que se compra (ej: cajas de 12 pz)
- **Salida**: Unidad en recetas (ej: gramos)

### 8.3 Tablas de Configuración

| Tabla | Propósito | Uso |
|-------|-----------|-----|
| **sucursal_almacen_terminal** | Relación sucursal-almacén-terminal | ✅ Activo |
| **param_sucursal** | Parámetros por sucursal | ✅ Activo |

### 8.4 Tablas Legacy (DEPRECADAS)

| Tabla | Reemplazada Por | Estado |
|-------|-----------------|--------|
| **almacen** | `cat_almacenes` | ❌ DEPRECADO |
| **bodega** | `cat_almacenes` | ❌ DEPRECADO |
| **sucursal** | `cat_sucursales` | ❌ DEPRECADO |

**Estrategia**: Vistas de compatibilidad (`v_almacen`, `v_bodega`, `v_sucursal`)

**Documentación**: `/docs/BD/Normalizacion/`

---

## 9. MÓDULO AUDITORÍA Y SEGURIDAD (15 tablas) - ⭐⭐⭐⭐ BIEN

### 9.1 Tablas de Auditoría

| Tabla | Propósito | Tamaño | Retención |
|-------|-----------|--------|-----------|
| **audit_log** | Log general de auditoría | ~224 kB | 90 días |
| **audit_log_global** | Log global del sistema | ~48 kB | 90 días |
| **auditoria** | Auditoría legacy | ~88 kB | ⚠️ Migrar a `audit_log` |
| **cash_fund_movement_audit_log** | Auditoría de caja chica | ~40 kB | Indefinido |

### 9.2 Tablas de Usuarios y Roles (Spatie)

| Tabla | Propósito | Framework |
|-------|-----------|-----------|
| **users** | Usuarios del sistema | Laravel |
| **roles** | Roles (Admin, Cajero, Almacenista, etc.) | Spatie Permission |
| **permissions** | Permisos (edit-items, approve-postcorte, etc.) | Spatie Permission |
| **model_has_permissions** | Permisos asignados a modelos | Spatie Permission |
| **model_has_roles** | Roles asignados a modelos | Spatie Permission |
| **role_has_permissions** | Permisos por rol | Spatie Permission |

### 9.3 Tablas de Sesiones y Tokens

| Tabla | Propósito | Framework |
|-------|-----------|-----------|
| **sessions** | Sesiones web | Laravel |
| **personal_access_tokens** | Tokens API (Sanctum) | Laravel |
| **password_reset_tokens** | Tokens de reset de contraseña | Laravel |

### 9.4 Tablas Legacy (DEPRECADAS)

| Tabla | Reemplazada Por | Estado |
|-------|-----------------|--------|
| **usuario** | `users` | ❌ DEPRECADO |
| **rol** | `roles` (Spatie) | ❌ DEPRECADO |
| **user_roles** | `model_has_roles` | ❌ DEPRECADO |

**Trigger importante**: `audit_trigger_func` - Trigger genérico para auditoría

---

## 10. MÓDULO SISTEMA (12 tablas) - ⭐⭐⭐⭐ BIEN

### 10.1 Tablas de Framework Laravel

| Tabla | Propósito | Gestión |
|-------|-----------|---------|
| **migrations** | Migraciones de BD | Laravel automático |
| **cache** | Caché de aplicación | Laravel automático |
| **cache_locks** | Locks de caché | Laravel automático |
| **sessions** | Sesiones web | Laravel automático |
| **password_reset_tokens** | Reset de contraseña | Laravel automático |

### 10.2 Tablas de Colas (Jobs)

| Tabla | Propósito | Uso |
|-------|-----------|-----|
| **jobs** | Cola de trabajos | Laravel Queue |
| **job_batches** | Batches de trabajos | Laravel Queue |
| **failed_jobs** | Trabajos fallidos | Laravel Queue |
| **job_recalc_queue** | Cola de recalculos de costos | Custom |
| **recalc_log** | Log de recalculos | Custom |

### 10.3 Tablas de Alertas

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **alert_events** | Eventos de alerta | ✅ Activo (sin modelo) |
| **alert_rules** | Reglas de alerta | ✅ Activo (sin modelo) |

### 10.4 Tablas de Reportes (Sin Uso)

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **report_definitions** | Definiciones de reportes | ❌ No implementado |
| **report_runs** | Ejecuciones de reportes | ❌ No implementado |
| **report_favorites** | Reportes favoritos | ❌ No implementado |

**Acción**: Eliminar o implementar módulo de reportes

---

## 11. MÓDULO TRANSFERENCIAS (4 tablas) - ⭐⭐⭐ PARCIAL

### 11.1 Tablas Core

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **transfer_cab** | Cabecera de transferencias entre almacenes | ✅ Activo (sin doc) |
| **transfer_det** | Detalle de transferencias | ✅ Activo (sin doc) |

**Flujo**:
```
transfer_cab
    ↓
transfer_det
    ↓
mov_inv (SALIDA almacén origen)
mov_inv (ENTRADA almacén destino)
```

### 11.2 Tablas Legacy (DEPRECADAS)

| Tabla | Reemplazada Por | Estado |
|-------|-----------------|--------|
| **traspaso_cab** | `transfer_cab` | ❌ DEPRECADO |
| **traspaso_det** | `transfer_det` | ❌ DEPRECADO |

**Triggers activos** (en legacy):
- `update_traspaso_cab_updated_at`
- `update_traspaso_det_updated_at`

**Documentación**: No documentado

---

## 12. MÓDULO RECEPCIONES (3 tablas) - ⭐⭐⭐⭐ BIEN

### 12.1 Tablas Core

| Tabla | Propósito | Relaciones |
|-------|-----------|------------|
| **recepcion_cab** | Cabecera de recepciones de compra | → recepcion_det (1:N), ← purchase_orders (N:1) |
| **recepcion_det** | Detalle de recepciones | ← recepcion_cab, → items (N:1), → mov_inv (1:1) |
| **recepcion_adjuntos** | Documentos adjuntos (facturas, remisiones) | ← recepcion_cab |

**Flujo de recepción**:
```
purchase_orders (OC aprobada)
    ↓
recepcion_cab (crear recepción)
    ↓
recepcion_det (líneas de recepción)
    ↓ ReceptionService
inventory_batch (crear lote)
mov_inv (registrar ENTRADA en kardex)
items (actualizar costo_promedio)
```

**Triggers**:
- `update_recepcion_cab_updated_at`
- `update_recepcion_det_updated_at`

**Documentación**: Breve

---

## 13. MÓDULO MERMAS (3 tablas) - ⭐⭐⭐ PARCIAL

### 13.1 Tablas Core

| Tabla | Propósito | Estado |
|-------|-----------|--------|
| **merma** | Mermas de inventario (legacy) | ⚠️ Usar `inventory_wastes` |
| **inventory_wastes** | Mermas y desperdicios (nuevo) | ✅ Activo |
| **perdida_log** | Log de pérdidas | ✅ Activo |

**Problema**: Duplicación `merma` vs `inventory_wastes`

**Acción recomendada**: Consolidar en `inventory_wastes`

**Trigger**: `update_merma_updated_at`

**Documentación**: No documentado

---

## 14. TABLAS BACKUP TEMPORAL (3 tablas)

| Tabla | Fecha | Propósito | Acción |
|-------|-------|-----------|--------|
| **backup_tickets_cierre_masivo_20251112_112653** | 12 Nov 2025 | Backup antes de cierre masivo | ⚠️ Validar y archivar |
| **backup_tickets_cierre_masivo_20251112_121131** | 12 Nov 2025 | Backup antes de cierre masivo | ⚠️ Validar y archivar |
| **backup_tickets_cierre_masivo_20251112_121211** | 12 Nov 2025 | Backup antes de cierre masivo | ⚠️ Validar y archivar |

**Acción**: Si no se necesitan, archivar y eliminar

---

## 15. RESUMEN DE GAPS

### 15.1 Tablas Sin Modelo Eloquent (Prioridad ALTA)

1. `pos_sync_logs`
2. `pos_sync_batches`
3. `pos_reprocess_log`
4. `alert_events`
5. `alert_rules`
6. `job_recalc_queue`
7. `recalc_log`
8. `menu_engineering_snapshots`

### 15.2 Tablas Sin Uso (Eliminar)

1. `report_definitions`
2. `report_runs`
3. `report_favorites`
4. `op_produccion_cab`
5. `sol_prod_cab/det`
6. `prod_cab/det`
7. `user_roles`

### 15.3 Tablas Duplicadas (Consolidar)

| Tabla 1 | Tabla 2 | Acción |
|---------|---------|--------|
| `receta_version` | `recipe_versions` | Consolidar |
| `hist_cost_insumo` | `historial_costos_item` | Validar diferencias |
| `merma` | `inventory_wastes` | Consolidar |

---

**Última actualización**: 14 Noviembre 2025
**Autor**: Claude Code (MAESTRO)
