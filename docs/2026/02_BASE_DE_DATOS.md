# Base de Datos — TerrenaLaravel
> Actualizado: Abril 2026 | PostgreSQL 9.5

## Configuración de Conexión

| Ambiente | Host | Puerto | BD | Usuario |
|----------|------|--------|----|----|
| Local (dev) | localhost | 5433 | pos | postgres |
| Producción | 100.126.124.101 | 5432 | pos | floreant |

---

## Schemas

### schema: `public` (FloreantPOS — solo lectura desde Laravel)
Contiene todas las tablas del POS FloreantPOS v1.5. Laravel solo lee, nunca escribe.

Tablas clave que consume el ERP:

| Tabla | Descripción | Uso en ERP |
|-------|------------|-----------|
| `ticket` | Comandas/órdenes completadas | PosConsumptionService, reportes |
| `ticket_item` | Líneas de cada comanda | Consumo de insumos |
| `ticket_item_modifier` | Modificadores aplicados | Reportes de mods |
| `transactions` | Pagos por forma de pago | Precorte, conciliación |
| `drawer_assigned_history` | Asignación de cajones a terminales | Sesión de cajón |
| `coupon_and_discount` | Descuentos configurados (% o monto) | Reportes descuentos ⚠️ |
| `menu_item` | Catálogo de productos POS | Mapeo → insumos |
| `menu_category` | Categorías de menú | Reportes por familia |
| `restaurant_user` | Usuarios del POS | Cajeros, meseros |
| `terminal` | Terminales/cajas | Sesiones |

**Nota crítica:** `coupon_and_discount.value` almacena el **porcentaje** del descuento (ej. 100 para 100%), NO el monto real. El monto real está en `ticket.total_discount`.

### schema: `selemti` (ERP propio — lectura/escritura)
Todas las tablas del ERP Laravel. Prefijadas con `selemti.` en producción.

---

## Tablas Principales — schema `selemti`

### Módulo de Caja

| Tabla | Descripción | Columnas Clave |
|-------|------------|---------------|
| `sesion_cajon` | Sesión de caja activa | `terminal_id`, `apertura_en`, `cierre_en`, `fondo_apertura` |
| `precorte` | Resumen previo al corte | `sesion_id`, `total_sistema`, `total_declarado`, `status` |
| `postcorte` | Corte oficial con diferencias | `precorte_id`, `total_ventas_brutas`⚠️, `total_descuentos_drawer`⚠️, `aprobado_por` |
| `formas_pago` | Catálogo de formas de pago | `codigo`, `payment_type`, `custom_name` |

**⚠️ Bug activo:** `postcorte.total_ventas_brutas`, `total_descuentos_drawer`, `total_descuentos_reales` siempre NULL — trigger roto.

### Módulo de Inventario

| Tabla | Descripción | Columnas Clave |
|-------|------------|---------------|
| `items` | Maestro de insumos | `id (varchar)`, `nombre`, `categoria_id`, `unidad_medida_id`, `costo_promedio`, `tipo` |
| `inventory_batch` | Lotes de inventario | `item_id`, `lote_proveedor`, `fecha_caducidad`, `cantidad_actual`, `ubicacion_id` |
| `cost_layer` | Capas de costo FIFO/WAC | `item_id`, `batch_id`, `qty_in`, `qty_left`, `unit_cost` |
| `item_vendor` | Proveedor-ítem-presentación | `item_id`, `vendor_id`, `presentacion`, `factor_a_canonica`, `costo_ultimo` |
| `historial_costos_item` | Histórico de costos WAC/PEPS | `item_id`, `costo_wac`, `costo_peps`, `valid_from`, `valid_to` |

### Módulo de Compras

| Tabla | Descripción | Columnas Clave |
|-------|------------|---------------|
| `purchase_requests` | Solicitudes de compra | `status`, `solicitado_por`, `aprobado_por` |
| `purchase_request_lines` | Líneas de solicitud | `item_id`, `qty_solicitada`, `unidad_id` |
| `purchase_orders` | Órdenes de compra | `proveedor_id`, `status`, `total_mxn` |
| `purchase_order_lines` | Líneas de OC | `item_id`, `qty_pedida`, `precio_unit` |
| `purchase_suggestions` | Sugerencias automáticas | `item_id`, `qty_sugerida`, `motivo`, `status` |

### Módulo de Recetas

| Tabla | Descripción | Columnas Clave |
|-------|------------|---------------|
| `recetas` | Cabecera de receta | `id (varchar)`, `nombre`, `categoria_id`, `rendimiento` |
| `receta_detalle` | Ingredientes de receta | `receta_id`, `item_id`, `cantidad`, `unidad_id` |
| `receta_version` | Versiones de receta | `receta_id`, `version_num`, `activa`, `costo_calculado` |
| `historial_costos_receta` | Snapshots de costo | `receta_version_id`, `costo_total`, `costo_porcion` |

### Módulo de Producción

| Tabla | Descripción | Columnas Clave |
|-------|------------|---------------|
| `ordenes_produccion` | Órdenes de mise en place | `receta_id`, `cantidad`, `status`, `producido_en` |

### Módulo de Unidades

| Tabla | Descripción | Columnas Clave |
|-------|------------|---------------|
| `unidades_medida` | Catálogo de unidades | `codigo`, `nombre`, `tipo` (masa/volumen/unidad) |
| `conversiones_unidad` | Conversiones entre unidades | `unidad_origen_id`, `unidad_destino_id`, `factor_conversion` |

### Módulo de Catálogos

| Tabla | Descripción | Columnas Clave |
|-------|------------|---------------|
| `almacen` | Almacenes/ubicaciones | `id`, `sucursal_id`, `nombre`, `activo` |
| `sucursal` | Sucursales | `id`, `nombre`, `activo` |
| `stock_policy` | Políticas de stock | `item_id`, `almacen_id`, `min_stock`, `punto_reorden`, `max_stock` |

### Módulo de Caja Chica

| Tabla | Descripción |
|-------|------------|
| `cash_funds` | Fondos fijos activos |
| `cash_fund_movements` | Movimientos de caja chica |
| `cash_fund_arqueos` | Arqueos periódicos |
| `cash_fund_movement_audit_logs` | Auditoría de movimientos |

### Laravel / Sistema

| Tabla | Propósito |
|-------|----------|
| `users` | Usuarios ERP |
| `roles`, `permissions` | Spatie RBAC |
| `model_has_roles`, `model_has_permissions` | Asignación de roles |
| `audit_log` | Log de auditoría de operaciones |
| `jobs`, `failed_jobs`, `job_batches` | Queue de Laravel |
| `pos_item_mapping` | Mapeo producto POS → insumo ERP |

---

## ERD Simplificado (módulo central)

```
sucursal ──< almacen ──< inventory_batch ──< cost_layer
                              │
items ──────────────────────-─┤
  │                            │
  ├──< item_vendor             │
  │     └── proveedor          │
  │                            │
  └──< receta_detalle          │
        └── recetas            │
              └── receta_version
                    └── historial_costos_receta

ticket (public.*) ──> PosConsumptionService ──> inventory_batch (decrementa qty)

sesion_cajon ──> precorte ──> postcorte
```

---

## Notas de Migración y Compatibilidad

- Producción corre **PostgreSQL 9.5** — algunas funciones modernas no disponibles
- Se han aplicado hotfixes específicos para PG95 (ver `D:\Tavo\2025\UX\Inventarios\v3\selemti_hotfix_pg95_v2.sql`)
- Las migraciones de Laravel están en `database/migrations/`
- El SQL maestro de inventario está en `D:\Tavo\2025\UX\Inventarios\v3\selemti_deploy_inventarios_PG95_CONSOLIDADO_FINAL.sql`
- Las vistas de precorte/conciliación están en `D:\Tavo\2025\UX\Cortes\V5\`
