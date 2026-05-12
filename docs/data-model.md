# Data Model — TerrenaLaravel ERP
> PostgreSQL 9.5 | Schema `selemti` (ERP) + Schema `public` (FloreantPOS, read-only)

## Arquitectura de Datos

El sistema tiene dos schemas completamente independientes:

| Schema | Owner | Acceso desde Laravel | Propósito |
|--------|-------|---------------------|-----------|
| `public` | FloreantPOS (Java) | **Solo lectura** | POS de punto de venta |
| `selemti` | TerrenaLaravel | Lectura/escritura | ERP completo |

**Regla de oro:** nunca hacer `INSERT`, `UPDATE`, `DELETE` en `public.*` desde Laravel.

---

## Modelo Canónico de Ítem

El ítem es la entidad central del ERP. Clase: `App\Models\Inv\Item`.

```
selemti.items
─────────────────────────────────────────────────────
id               varchar   PK — UUID o código semántico (ej. "CAFE-001")
item_code        varchar   Código de referencia adicional
nombre           varchar   Nombre del insumo/producto
descripcion      text      Descripción larga
categoria_id     varchar   FK → selemti.item_categories
tipo             varchar   INSUMO | PRODUCTO | EMPAQUE
activo           boolean   Soft delete

-- UOM (unidades de medida)
unidad_medida_id  int  FK → selemti.unidades_medida  — UOM BASE (KG, L, PZ)
unidad_compra_id  int  FK → selemti.unidades_medida  — UOM compra (CAJA, BOLSA)
unidad_salida_id  int  FK → selemti.unidades_medida  — UOM salida a producción
factor_compra    numeric   1 unidad_compra = factor_compra unidades base
factor_conversion numeric  Conversión auxiliar (usar factor_compra para compras)

-- Costos
costo_promedio   numeric(12,2)   Costo WAC actualizado tras cada recepción

-- Flags de negocio
perishable              boolean
temperatura_min/max     numeric
es_producible           boolean   Puede generarse en producción (mise en place)
es_consumible_operativo boolean   Se consume directo sin receta
es_empaque_to_go        boolean
```

### Relaciones del Ítem

```
Item ──< ItemProveedor (selemti.insumo_proveedor_presentacion)
     │      └── Proveedor (selemti.proveedores)
     │
     ├──< InventoryBatch (selemti.inventory_batch)
     │      └── CostLayer (selemti.cost_layer)
     │
     ├──< StockPolicy (selemti.stock_policy)
     │      └── Almacen, Sucursal
     │
     ├──< RecetaDetalle (selemti.receta_detalle)
     │      └── Receta (selemti.recetas)
     │           └── RecetaVersion
     │
     └──< ReplenishmentSuggestion
```

---

## Módulo Caja

### Flujo de Corte de Caja

```
sesion_cajon (public.drawer_assigned_history)
    │ 1
    │ N
    ▼
precorte  ───────────────────────────────────────────────
id            serial PK
sesion_id     int    FK → public.drawer_assigned_history
status        varchar  BORRADOR | ENVIADO | APROBADO
efectivo_declarado  numeric
created_at, updated_at

    │ 1
    │ 1
    ▼
postcorte  ──────────────────────────────────────────────
id            serial PK
precorte_id   int    FK → selemti.precorte  UNIQUE
sistema_efectivo_esperado  numeric   — calculado desde public.transactions
diferencia    numeric   = efectivo_declarado - sistema_efectivo_esperado
veredicto     varchar   CUADRA | A_FAVOR | EN_CONTRA
aprobado_por  int    FK → selemti.users
aprobado_en   timestamp
```

**Tablas POS que alimentan el postcorte (solo lectura):**

| Tabla (public) | Dato leído |
|----------------|-----------|
| `transactions` | Total por forma de pago en la sesión |
| `ticket` | `total_discount` — descuento real en dinero |
| `coupon_and_discount` | Solo para nombre/tipo, NO para monto (usar `ticket.total_discount`) |

---

## Módulo Inventario — Kardex

### `selemti.mov_inv` — Tabla central de movimientos

```
mov_inv
─────────────────────────────────────────────────
id            bigserial PK
item_id       varchar   FK → selemti.items
lote_id       int       FK → selemti.inventory_batch (nullable)
tipo          varchar   ENTRADA | SALIDA | AJUSTE | TRANSFERENCIA | PRODUCCION | CONSUMO_POS
cantidad      numeric   Positivo o negativo — siempre en UOM base
qty_original  numeric   Cantidad en la UOM de origen antes de conversión
uom_original_id int     FK → selemti.unidades_medida
costo_unit    numeric   Costo unitario en el momento del movimiento
sucursal_id   varchar
ref_tipo      varchar   Tipo de entidad origen: reception | transfer | inventory_count | batch | pos_ticket
ref_id        int       ID de la entidad origen
usuario_id    int       FK → selemti.users
ts            timestamp Marca de tiempo del movimiento (distinta a created_at)
created_at    timestamp
```

**Invariante:** `cantidad` siempre en UOM base. Usar `UomConversionService::resolveToBase()` antes de insertar.

### `selemti.inventory_batch` — Lotes

```
inventory_batch
─────────────────────────────────────────────────
id                serial PK
item_id           varchar   FK → selemti.items
lote_proveedor    varchar   Código de lote del proveedor
fecha_caducidad   date
cantidad_actual   numeric   Stock actual en este lote (UOM base)
ubicacion_id      int       FK → selemti.almacen
costo_unit        numeric   Costo WAC/PEPS del lote
ref_tipo          varchar   reception | production | adjustment
ref_id            int
created_at, updated_at
```

### `selemti.cost_layer` — Capas de costo FIFO/WAC

```
cost_layer
─────────────────────────────────────────────────
id         bigserial PK
item_id    varchar
batch_id   int       FK → inventory_batch
qty_in     numeric   Cantidad original al entrar la capa
qty_left   numeric   Cantidad aún disponible (decrementada en salidas)
unit_cost  numeric   Costo unitario de esta capa
created_at timestamp
```

---

## Módulo Inventario — Recepción

### State Machine: `BORRADOR → VALIDADA → POSTEADA`

Solo el estado `POSTEADA` genera movimientos en `mov_inv` e `inventory_batch`.

```
selemti.recepciones
─────────────────────────────────────────────────
id               serial PK
folio            varchar   UNIQUE
proveedor_id     int       FK → selemti.proveedores
purchase_order_id int      FK → selemti.purchase_orders (nullable)
estado           varchar   BORRADOR | VALIDADA | POSTEADA
almacen_id       int       FK → selemti.almacen
recibido_por     int       FK → selemti.users
fecha_recepcion  date
posteado_en      timestamp (populated on POSTEADA)
posteado_por     int

selemti.recepcion_lineas
─────────────────────────────────────────────────
id               serial PK
recepcion_id     int       FK → selemti.recepciones
item_id          varchar   FK → selemti.items
qty_pedida       numeric   En UOM compra
qty_recibida     numeric   En UOM compra
uom_id           int       FK → selemti.unidades_medida
precio_unit      numeric
lote_proveedor   varchar
fecha_caducidad  date
```

---

## Módulo Inventario — Transferencias

### State Machine: `SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA`

Solo `postTransferToInventory()` (estado POSTEADA) modifica `inventory_batch` y `mov_inv`.

```
selemti.transfer_headers
─────────────────────────────────────────────────
id          serial PK
folio       varchar   UNIQUE
origen_id   varchar   FK → selemti.almacen
destino_id  varchar   FK → selemti.almacen
estado      varchar   SOLICITADA | APROBADA | EN_TRANSITO | RECIBIDA | POSTEADA
solicitado_por  int
aprobado_por    int
enviado_por     int
recibido_por    int
created_at, updated_at

selemti.transfer_lines
─────────────────────────────────────────────────
id              serial PK
transfer_id     int       FK → transfer_headers
item_id         varchar   FK → selemti.items
lote_id         int       FK → selemti.inventory_batch (nullable)
qty_solicitada  numeric   En UOM base
qty_enviada     numeric   En UOM base
qty_recibida    numeric   En UOM base
uom             varchar   Clave de UOM base
```

---

## Módulo Inventario — Conteo Físico

```
selemti.inventory_counts
─────────────────────────────────────────────────
id              serial PK
folio           varchar   UNIQUE (generado: SUCURSAL-YYYYMMDD-NNNN)
sucursal_id     varchar
almacen_id      varchar
estado          varchar   EN_PROCESO | AJUSTADO
programado_para date
iniciado_en     timestamp
cerrado_en      timestamp
cerrado_por     int
total_items     numeric
total_variacion numeric   Suma de variaciones absolutas
notas           text

selemti.inventory_count_lines
─────────────────────────────────────────────────
id                  serial PK
inventory_count_id  int     FK → inventory_counts
item_id             varchar FK → selemti.items
inventory_batch_id  int     FK → inventory_batch (nullable — cuenta por lote)
qty_teorica         numeric Esperado según sistema
qty_contada         numeric Contado físicamente
qty_variacion       numeric = qty_contada - qty_teorica
uom                 varchar Clave UOM base
motivo              text    Razón de diferencia
```

Al finalizar un conteo, se crean movimientos tipo `AJUSTE` en `mov_inv` para cada línea con variación ≠ 0.

---

## Módulo Compras

### Flujo Completo de Compras

```
PurchaseRequest (solicitud)
    │ aprobada
    ▼
VendorQuote (cotización de proveedor)
    │ seleccionada
    ▼
PurchaseOrder (orden de compra) ─── PurchaseOrderLine
    │
    ├── Recepción → postea a inventario (mov_inv ENTRADA)
    └── Devolución → postea a inventario (mov_inv SALIDA)
```

```
selemti.purchase_requests
─────────────────────────────────────────────────
id            serial PK
status        varchar   DRAFT | PENDING | APPROVED | REJECTED | ORDERED
solicitado_por int
aprobado_por  int
created_at, updated_at

selemti.purchase_orders
─────────────────────────────────────────────────
id             serial PK
proveedor_id   int
status         varchar   DRAFT | SENT | PARTIAL | RECEIVED | CANCELLED
total_mxn      numeric
fecha_entrega_esperada date
created_at, updated_at
```

---

## Módulo Recetas

```
selemti.recetas
─────────────────────────────────────────────────
id         varchar PK
nombre     varchar
categoria_id varchar
rendimiento numeric   Porciones que produce una unidad de la receta
activa     boolean

selemti.receta_version
─────────────────────────────────────────────────
id               serial PK
receta_id        varchar FK → recetas
version_num      int
activa           boolean   Solo una versión activa por receta
costo_calculado  numeric   Calculado por RecalcularCostosRecetasService
created_at       timestamp

selemti.receta_detalle
─────────────────────────────────────────────────
id               serial PK
receta_id        varchar FK → recetas
item_id          varchar FK → items
cantidad         numeric   En UOM especificada
unidad_id        int     FK → unidades_medida
```

---

## Módulo Caja Chica (Cash Fund)

```
selemti.cash_funds
─────────────────────────────────────────────────
id           serial PK
sucursal_id  varchar
monto_asignado numeric
monto_actual   numeric
estado       varchar   ACTIVO | CERRADO
responsable_id int

selemti.cash_fund_movements
─────────────────────────────────────────────────
id           serial PK
fund_id      int       FK → cash_funds
tipo         varchar   EGRESO | REPOSICION | AJUSTE
monto        numeric
concepto     text
comprobante  varchar   URL o referencia
creado_por   int
aprobado_por int
```

---

## Sistema UOM — Conversión de Unidades

### Tres UOMs base canónicas

| Base | Tipo | Ejemplos de UOM compra |
|------|------|------------------------|
| `KG` | masa | CAJA (12 KG), BOLSA (5 KG), LATA (800 G) |
| `L`  | volumen | GALON (3.785 L), BOTELLA (750 ML) |
| `PZ` | unidad | DOZEN (12 PZ), PAQUETE (24 PZ) |

### Resolución de conversión (`UomConversionService::resolveToBase`)

```
1. Si fromClave == uom_base → retornar qty sin cambio
2. Si fromClave == uom_compra → qty × factor_compra
3. Buscar en selemti.cat_uom_conversion (L↔ML, KG↔G)
4. Fallback: retornar qty sin cambio (conservador)
```

**Siempre eager-load antes de convertir:**
```php
Item::with(['uom', 'uomCompra'])->find($id)
```

---

## Integración FloreantPOS → ERP

### Tablas POS clave (solo lectura)

| Tabla (public) | Uso en ERP |
|----------------|-----------|
| `ticket` | Base de reportes de ventas. `total_discount` = monto real de descuento |
| `ticket_item` | Consumo de insumos por producto vendido |
| `ticket_item_modifier` | Modificadores aplicados (reportes de mods) |
| `transactions` | Formas de pago por sesión — base del precorte |
| `drawer_assigned_history` | Sesiones de cajón |
| `menu_item` | Catálogo POS → mapeo a `selemti.items` vía `pos_item_mapping` |

### Mapeo POS → ERP

```
public.menu_item.id
    │
    ▼
selemti.pos_item_mapping
    ├── pos_item_id     → public.menu_item.id
    └── erp_item_id     → selemti.items.id
```

El motor `fn_expandir_consumo_ticket` (PostgreSQL function en `public`) es la función que expande un ticket POS en sus insumos base. **No tocar desde Laravel.**

---

## Usuarios y Permisos

```
selemti.users (Laravel User model)
─────────────────────────────────
id, name, email, password
email_verified_at, remember_token

selemti.roles, selemti.permissions (Spatie Laravel Permission)
selemti.model_has_roles, selemti.model_has_permissions

selemti.personal_access_tokens (Sanctum)
─────────────────────────────────
tokenable_type, tokenable_id, name, token (hashed), abilities
last_used_at, expires_at
```

### Permisos relevantes

| Permiso | Módulo |
|---------|--------|
| `can_manage_purchasing` | Compras (recepciones, devoluciones) |
| `can_edit_production_order` | Producción (batches) |
| `reports.view` | Reportes de ventas (mix, drawer, etc.) |
| `audit.view` | Log de auditoría |
| `people.users.manage` | Gestión de usuarios y permisos |
