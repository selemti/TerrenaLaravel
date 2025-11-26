# Esquema de Tablas de Inventario - selemti

## Tabla: selemti.recepcion_cab

### Descripción
Esta tabla registra las cabeceras de las recepciones de inventario, registrando información general sobre cada recepción como la sucursal, proveedor, fecha, usuario responsable, etc.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('recepcion_cab_id_seq'::regclass) | Identificador único de la recepción |
| sucursal_id | bigint | NOT NULL | ID de la sucursal donde se realizó la recepción |
| proveedor_id | integer | NULL | ID del proveedor (puede ser nulo) |
| oc_ref | text | NULL | Referencia de la orden de compra |
| ts | timestamp without time zone | NOT NULL, DEFAULT now() | Timestamp de la recepción |
| usuario_id | bigint | NULL | ID del usuario que realizó la recepción |
| meta | jsonb | NULL | Campo adicional para metadatos |
| almacen_id | character varying | NULL | ID del almacén |
| numero_recepcion | character varying | NULL | Número de la recepción |
| fecha_recepcion | date | NULL | Fecha de la recepción |
| estado | character varying | NULL | Estado actual de la recepción |
| total_presentaciones | numeric | NULL | Total en presentaciones |
| total_canonico | numeric | NULL | Total en unidades canónicas |
| created_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de creación |
| updated_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de actualización |
| deleted_at | timestamp without time zone | NULL | Fecha de eliminación (soft delete) |
| validada_por | bigint | NULL | ID del usuario que validó |
| validada_at | timestamp without time zone | NULL | Fecha de validación |
| posteada_por | bigint | NULL | ID del usuario que posteó |
| posteada_at | timestamp without time zone | NULL | Fecha de posteo |

Foreign Keys

- sucursal_id → selemti.cat_sucursales.id
- usuario_id → selemti.users.id
- posteada_por → selemti.users.id
- validada_por → selemti.users.id

Índices

- idx_recepcion_cab_deleted_at: deleted_at
- recepcion_cab_pkey: id (unique)
- selemti_recepcion_cab_almacen_id_index: almacen_id

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.recepcion_cab LIMIT 3;
```

| id | sucursal_id | proveedor_id | oc_ref | ts | usuario_id | meta | almacen_id | numero_recepcion | fecha_recepcion | estado | total_presentaciones | total_canonico | created_at | updated_at | deleted_at | validada_por | validada_at | posteada_por | posteada_at | 
|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| 2 | 1 | 1 | NULL | 2025-11-25 16:20:09 | 1 | NULL | 1 | RC-20251125-0001 | 2025-11-25 | VALIDADA | 2.0000 | 24.0000 | 2025-11-25 16:20:09 | 2025-11-25 16:20:10.03902 | NULL | NULL | NULL | NULL | NULL | 
| 3 | 1 | 1 | NULL | 2025-11-25 16:20:55 | 1 | NULL | 1 | RC-20251125-0002 | 2025-11-25 | POSTEADA | 2.0000 | 24.0000 | 2025-11-25 16:20:55 | 2025-11-25 16:20:55.384749 | NULL | 1 | 2025-11-25 16:20:55 | 1 | 2025-11-25 16:20:55 | 
| 4 | 1 | 1 | NULL | 2025-11-25 18:16:45 | 1 | NULL | 1 | RC-20251125-0003 | 2025-11-25 | POSTEADA | 2.0000 | 24.0000 | 2025-11-25 18:16:45 | 2025-11-25 18:16:46.04403 | NULL | 1 | 2025-11-25 18:16:46 | 1 | 2025-11-25 18:16:46 | 

---

## Tabla: selemti.recepcion_det

### Descripción
Esta tabla registra los detalles de cada recepción de inventario, incluyendo los artículos recibidos, cantidades, costos y lotes.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('recepcion_det_id_seq'::regclass) | Identificador único del detalle de recepción |
| recepcion_id | bigint | NOT NULL | ID de la recepción a la que pertenece este detalle |
| item_id | character varying | NOT NULL | ID del artículo recibido |
| bodega_id | bigint | NOT NULL | ID del almacén donde se recibió el artículo |
| qty | numeric | NOT NULL | Cantidad recibida |
| um_id | integer | NOT NULL | ID de la unidad de medida |
| costo_unit | numeric | NOT NULL | Costo unitario del artículo |
| batch_id | bigint | NULL | ID del lote (si aplica) |
| temperatura | numeric | NULL | Temperatura de recepción (para artículos refrigerados) |
| doc_url | text | NULL | URL del documento relacionado |
| meta | jsonb | NULL | Campo adicional para metadatos |
| created_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de creación |
| updated_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de actualización |
| deleted_at | timestamp without time zone | NULL | Fecha de eliminación (soft delete) |

Foreign Keys

- batch_id → selemti.inventory_batch.id
- bodega_id → selemti.cat_almacenes.id
- item_id → selemti.items.id
- recepcion_id → selemti.recepcion_cab.id
- um_id → selemti.cat_unidades.id

Índices

- idx_recepcion_det_batch_id: batch_id
- idx_recepcion_det_bodega_id: bodega_id
- idx_recepcion_det_item_id: item_id
- recepcion_det_pkey: id (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.recepcion_det LIMIT 3;
```

| id | recepcion_id | item_id | bodega_id | qty | um_id | costo_unit | batch_id | temperatura | doc_url | meta | created_at | updated_at | deleted_at | 
|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| 2 | 2 | ACEITE-NUT-01 | 1 | 24.000000 | 1 | 0.000000 | NULL | 22.50 | NULL | {"qty_pack": 2, "uom_base": "L", "pack_size": 1... | 2025-11-25 16:20:09 | 2025-11-25 16:20:09 | NULL | 
| 3 | 3 | ACEITE-NUT-01 | 1 | 24.000000 | 1 | 0.000000 | 1 | 22.50 | NULL | {"qty_pack": 2, "uom_base": "L", "pack_size": 1... | 2025-11-25 16:20:55 | 2025-11-25 16:20:55.384749 | NULL | 
| 4 | 4 | ACEITE-NUT-01 | 1 | 24.000000 | 1 | 0.000000 | 2 | 22.50 | NULL | {"qty_pack": 2, "uom_base": "L", "pack_size": 1... | 2025-11-25 18:16:45 | 2025-11-25 18:16:46.04403 | NULL | 

---

## Tabla: selemti.traspaso_cab

### Descripción
Esta tabla registra las cabeceras de los traspasos de inventario entre almacenes, incluyendo información sobre el origen, destino y estado del traspaso.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('traspaso_cab_id_seq'::regclass) | Identificador único del traspaso |
| from_bodega_id | bigint | NOT NULL | ID del almacén de origen |
| to_bodega_id | bigint | NOT NULL | ID del almacén de destino |
| ts | timestamp without time zone | NOT NULL, DEFAULT now() | Timestamp del traspaso |
| usuario_id | bigint | NULL | ID del usuario que realizó el traspaso |
| meta | jsonb | NULL | Campo adicional para metadatos |
| created_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de creación |
| updated_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de actualización |
| deleted_at | timestamp without time zone | NULL | Fecha de eliminación (soft delete) |
| validada_por | bigint | NULL | ID del usuario que validó el traspaso |
| validada_at | timestamp without time zone | NULL | Fecha de validación |
| posteada_por | bigint | NULL | ID del usuario que posteó el traspaso |
| posteada_at | timestamp without time zone | NULL | Fecha de posteo |
| estado | character varying | NULL, DEFAULT 'SOLICITADA'::character varying | Estado actual del traspaso |

Foreign Keys

- posteada_por → selemti.users.id
- validada_por → selemti.users.id
- from_bodega_id → selemti.cat_almacenes.id
- to_bodega_id → selemti.cat_almacenes.id
- usuario_id → selemti.users.id

Índices

- idx_traspaso_cab_deleted_at: deleted_at
- traspaso_cab_pkey: id (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.traspaso_cab LIMIT 3;
```

| id | from_bodega_id | to_bodega_id | ts | usuario_id | meta | created_at | updated_at | deleted_at | validada_por | validada_at | posteada_por | posteada_at | estado | 
|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| 1 | 1 | 2 | 2025-11-25 18:15:43.151773 | 1 | NULL | 2025-11-25 18:15:43 | 2025-11-25 18:15:43 | NULL | NULL | NULL | NULL | NULL | SOLICITADA | 
| 2 | 1 | 2 | 2025-11-25 18:15:56.675002 | 1 | NULL | 2025-11-25 18:15:56 | 2025-11-25 18:15:57.026122 | NULL | 1 | NULL | 1 | NULL | POSTEADA | 
| 3 | 1 | 2 | 2025-11-25 18:16:46.052155 | 1 | NULL | 2025-11-25 18:16:46 | 2025-11-25 18:16:46.076039 | NULL | 1 | NULL | 1 | NULL | POSTEADA | 

---

## Tabla: selemti.traspaso_det

### Descripción
Esta tabla registra los detalles de los traspasos de inventario, incluyendo los artículos transferidos, cantidades y unidades de medida.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('traspaso_det_id_seq'::regclass) | Identificador único del detalle del traspaso |
| traspaso_id | bigint | NOT NULL | ID del traspaso al que pertenece este detalle |
| item_id | character varying | NOT NULL | ID del artículo transferido |
| batch_id | bigint | NULL | ID del lote (si aplica) |
| qty | numeric | NOT NULL | Cantidad transferida |
| um_id | integer | NOT NULL | ID de la unidad de medida |
| created_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de creación |
| updated_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de actualización |
| deleted_at | timestamp without time zone | NULL | Fecha de eliminación (soft delete) |

Foreign Keys

- batch_id → selemti.inventory_batch.id
- item_id → selemti.items.id
- traspaso_id → selemti.traspaso_cab.id
- um_id → selemti.cat_unidades.id

Índices

- idx_traspaso_det_batch_id: batch_id
- idx_traspaso_det_item_id: item_id
- traspaso_det_pkey: id (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.traspaso_det LIMIT 3;
```

| id | traspaso_id | item_id | batch_id | qty | um_id | created_at | updated_at | deleted_at | 
|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| 1 | 1 | ACEITE-NUT-01 | NULL | 5.000000 | 2 | 2025-11-25 18:15:43 | 2025-11-25 18:15:43 | NULL | 
| 2 | 2 | ACEITE-NUT-01 | NULL | 5.000000 | 2 | 2025-11-25 18:15:56 | 2025-11-25 18:15:56 | NULL | 
| 3 | 3 | ACEITE-NUT-01 | NULL | 5.000000 | 2 | 2025-11-25 18:16:46 | 2025-11-25 18:16:46 | NULL | 

---

## Tabla: selemti.mov_inv

### Descripción
Esta tabla registra los movimientos de inventario, incluyendo entradas, salidas y transferencias con todas las características específicas de cada movimiento.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('mov_inv_id_seq'::regclass) | Identificador único del movimiento |
| ts | timestamp without time zone | NOT NULL, DEFAULT now() | Timestamp del movimiento |
| item_id | character varying | NOT NULL | ID del artículo movido |
| lote_id | integer | NULL | ID del lote (si aplica) |
| cantidad | numeric | NOT NULL | Cantidad movida |
| qty_original | numeric | NULL | Cantidad original antes del movimiento |
| uom_original_id | integer | NULL | ID de la unidad de medida original |
| costo_unit | numeric | NULL | Costo unitario del artículo |
| tipo | character varying | NOT NULL | Tipo de movimiento (ENTRADA, SALIDA, TRASPASO, etc.) |
| ref_tipo | character varying | NULL | Tipo de referencia del movimiento |
| ref_id | bigint | NULL | ID de referencia del movimiento |
| sucursal_id | character varying | NULL | ID de la sucursal |
| usuario_id | integer | NULL | ID del usuario que realizó el movimiento |
| created_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de creación |

Foreign Keys

- item_id → selemti.items.id
- lote_id → selemti.inventory_batch.id

Índices

- idx_mov_inv_item_id: item_id
- idx_mov_inv_item_ts: ts
- idx_mov_inv_item_ts: item_id
- idx_mov_inv_tipo: tipo
- idx_mov_inv_tipo_fecha: ts
- idx_mov_inv_tipo_fecha: tipo
- idx_mov_inv_ts: ts
- idx_mov_inv_ts_tipo: tipo
- idx_mov_inv_ts_tipo: ts
- ix_mov_item_id: item_id
- ix_mov_item_ts: ts
- ix_mov_item_ts: item_id
- ix_mov_ref: ref_tipo
- ix_mov_ref: ref_id
- ix_mov_sucursal: sucursal_id
- ix_mov_tipo: tipo
- ix_mov_ts: ts
- mov_inv_pkey: id (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.mov_inv LIMIT 3;
```

| id | ts | item_id | lote_id | cantidad | qty_original | uom_original_id | costo_unit | tipo | ref_tipo | ref_id | sucursal_id | usuario_id | created_at | 
|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| 107 | 2025-11-25 16:20:55 | ACEITE-NUT-01 | 1 | 24.000000 | NULL | NULL | 0.000000 | ENTRADA | recepcion | 3 | 1 | 1 | 2025-11-25 16:20:55 | 
| 108 | 2025-11-25 18:15:57 | ACEITE-NUT-01 | NULL | -5.000000 | NULL | NULL | 0.000000 | TRASPASO | transfer | 2 | 1 | 1 | 2025-11-25 18:15:57.026122 | 
| 109 | 2025-11-25 18:15:57 | ACEITE-NUT-01 | NULL | 5.000000 | NULL | NULL | 0.000000 | TRASPASO | transfer | 2 | 2 | 1 | 2025-11-25 18:15:57.026122 | 

---

## Tabla: selemti.inventory_batch

### Descripción
Esta tabla registra los lotes de inventario, incluyendo información sobre proveedor, fechas de recepción y caducidad, temperaturas, cantidades y estado.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | integer | NOT NULL, DEFAULT nextval('inventory_batch_id_seq'::regclass) | Identificador único del lote |
| item_id | character varying | NOT NULL | ID del artículo al que pertenece el lote |
| lote_proveedor | character varying | NOT NULL | Número de lote del proveedor |
| fecha_recepcion | date | NOT NULL | Fecha de recepción del lote |
| fecha_caducidad | date | NOT NULL | Fecha de caducidad del lote |
| temperatura_recepcion | numeric | NULL | Temperatura de recepción |
| documento_url | character varying | NULL | URL del documento relacionado |
| cantidad_original | numeric | NOT NULL | Cantidad original del lote |
| cantidad_actual | numeric | NOT NULL | Cantidad actual disponible |
| estado | character varying | NULL, DEFAULT 'ACTIVO'::character varying | Estado del lote |
| ubicacion_id | character varying | NOT NULL | ID de la ubicación física del lote |
| created_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de creación |
| updated_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de actualización |
| unit_cost | numeric | NOT NULL, DEFAULT '0'::numeric | Costo unitario del artículo en este lote |

Foreign Keys

- item_id → selemti.items.id

Índices

- idx_inventory_batch_caducidad: fecha_caducidad
- idx_inventory_batch_item: item_id
- idx_inventory_batch_item_estado: item_id
- idx_inventory_batch_item_estado: estado
- inventory_batch_pkey: id (unique)
- ix_ib_item_caduc: fecha_caducidad
- ix_ib_item_caduc: item_id

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.inventory_batch LIMIT 3;
```

| id | item_id | lote_proveedor | fecha_recepcion | fecha_caducidad | temperatura_recepcion | documento_url | cantidad_original | cantidad_actual | estado | ubicacion_id | created_at | updated_at | unit_cost | 
|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| 1 | ACEITE-NUT-01 | LOTE-TEST-001 | 2025-11-25 | 2026-12-31 | 22.50 | NULL | 24.000 | 24.000 | ACTIVO | UBIC-00001 | 2025-11-25 16:20:55 | 2025-11-25 16:20:55 | 0.0000 | 
| 2 | ACEITE-NUT-01 | LOTE-TEST-001 | 2025-11-25 | 2026-12-31 | 22.50 | NULL | 24.000 | 24.000 | ACTIVO | UBIC-00001 | 2025-11-25 18:16:46 | 2025-11-25 18:16:46 | 0.0000 | 

---

## Tabla: selemti.cat_unidades

### Descripción
Esta tabla almacena los catálogos de unidades de medida utilizadas en el sistema de inventario.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('cat_unidades_id_seq'::regclass) | Identificador único de la unidad |
| clave | character varying | NOT NULL | Clave única de la unidad de medida |
| nombre | character varying | NOT NULL | Nombre descriptivo de la unidad |
| activo | boolean | NOT NULL, DEFAULT true | Indica si la unidad está activa |
| created_at | timestamp without time zone | NULL | Fecha de creación |
| updated_at | timestamp without time zone | NULL | Fecha de actualización |

Índices

- cat_unidades_clave_unique: clave (unique)
- cat_unidades_pkey: id (unique)
- idx_cat_unidades_activo: activo
- idx_cat_unidades_clave: clave
- selemti_cat_unidades_clave_unique: clave (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.cat_unidades LIMIT 3;
```

| id | clave | nombre | activo | created_at | updated_at | 
|---------|---------|---------|---------|---------|---------|
| 1 | KG | Kilogramo | 1 | 2025-11-25 16:20:04 | 2025-11-25 16:20:04 | 
| 2 | L | Litro | 1 | 2025-11-25 16:20:04 | 2025-11-25 16:20:04 | 
| 3 | PZA | Pieza | 1 | 2025-11-25 16:20:04 | 2025-11-25 16:20:04 | 

---

## Tabla: selemti.cat_almacenes

### Descripción
Esta tabla almacena los catálogos de almacenes (bodegas) disponibles en el sistema.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('cat_almacenes_id_seq'::regclass) | Identificador único del almacén |
| clave | character varying | NOT NULL | Clave única del almacén |
| nombre | character varying | NOT NULL | Nombre del almacén |
| sucursal_id | bigint | NULL | ID de la sucursal a la que pertenece el almacén |
| activo | boolean | NOT NULL, DEFAULT true | Indica si el almacén está activo |
| created_at | timestamp without time zone | NULL | Fecha de creación |
| updated_at | timestamp without time zone | NULL | Fecha de actualización |

Foreign Keys

- sucursal_id → selemti.cat_sucursales.id
- sucursal_id → selemti.cat_sucursales.id

Índices

- cat_almacenes_clave_unique: clave (unique)
- cat_almacenes_pkey: id (unique)
- selemti_cat_almacenes_clave_unique: clave (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.cat_almacenes LIMIT 3;
```

| id | clave | nombre | sucursal_id | activo | created_at | updated_at | 
|---------|---------|---------|---------|---------|---------|---------|
| 1 | ALM-SUR-01 | Almacen Principal Sur | 1 | 1 | 2025-11-25 14:24:03 | 2025-11-25 14:24:03 | 
| 2 | ALM-NTE-01 | Almacen Principal Norte | 2 | 1 | 2025-11-25 14:24:03 | 2025-11-25 14:24:03 | 

---

## Tabla: selemti.cat_sucursales

### Descripción
Esta tabla almacena los catálogos de sucursales disponibles en el sistema.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('cat_sucursales_id_seq'::regclass) | Identificador único de la sucursal |
| clave | character varying | NOT NULL | Clave única de la sucursal |
| nombre | character varying | NOT NULL | Nombre de la sucursal |
| ubicacion | character varying | NULL | Ubicación física de la sucursal |
| activo | boolean | NOT NULL, DEFAULT true | Indica si la sucursal está activa |
| created_at | timestamp without time zone | NULL | Fecha de creación |
| updated_at | timestamp without time zone | NULL | Fecha de actualización |

Índices

- cat_sucursales_clave_unique: clave (unique)
- cat_sucursales_pkey: id (unique)
- selemti_cat_sucursales_clave_unique: clave (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.cat_sucursales LIMIT 3;
```

| id | clave | nombre | ubicacion | activo | created_at | updated_at | 
|---------|---------|---------|---------|---------|---------|---------|
| 1 | SUR | Sucursal Sur | Av. Sur 123 | 1 | 2025-11-25 14:24:03 | 2025-11-25 14:24:03 | 
| 2 | NTE | Sucursal Norte | Av. Norte 456 | 1 | 2025-11-25 14:24:03 | 2025-11-25 14:24:03 | 

---

## Tabla: selemti.cat_proveedores

### Descripción
Esta tabla almacena los catálogos de proveedores disponibles en el sistema.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | bigint | NOT NULL, DEFAULT nextval('cat_proveedores_id_seq'::regclass) | Identificador único del proveedor |
| rfc | character varying | NOT NULL | RFC del proveedor |
| nombre | character varying | NOT NULL | Nombre del proveedor |
| telefono | character varying | NULL | Teléfono del proveedor |
| email | character varying | NULL | Correo electrónico del proveedor |
| activo | boolean | NOT NULL, DEFAULT true | Indica si el proveedor está activo |
| created_at | timestamp without time zone | NULL | Fecha de creación |
| updated_at | timestamp without time zone | NULL | Fecha de actualización |

Índices

- cat_proveedores_pkey: id (unique)
- cat_proveedores_rfc_unique: rfc (unique)
- idx_prov_rfc: rfc
- selemti_cat_proveedores_rfc_unique: rfc (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.cat_proveedores LIMIT 3;
```

| id | rfc | nombre | telefono | email | activo | created_at | updated_at | 
|---------|---------|---------|---------|---------|---------|---------|---------|
| 1 | PROVEEDORTEST | Proveedor Test | NULL | NULL | 1 | 2025-11-25 14:24:03 | 2025-11-25 14:24:03 | 

---

## Tabla: selemti.items

### Descripción
Esta tabla almacena los artículos/inventarios disponibles en el sistema, incluyendo sus propiedades como categoría, unidad de medida, temperatura, costos, etc.

### Estructura
```sql
-- Información de columnas obtenida mediante consulta SQL
```

Columnas Clave

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| id | character varying | NOT NULL | ID único del artículo (clave) |
| nombre | character varying | NOT NULL | Nombre del artículo |
| descripcion | text | NULL | Descripción del artículo |
| categoria_id | character varying | NOT NULL | ID de la categoría del artículo |
| unidad_medida | character varying | NOT NULL, DEFAULT 'PZ'::character varying | Unidad de medida predeterminada |
| perishable | boolean | NULL, DEFAULT false | Indica si el artículo es perecedero |
| temperatura_min | integer | NULL | Temperatura mínima recomendada |
| temperatura_max | integer | NULL | Temperatura máxima recomendada |
| costo_promedio | numeric | NULL, DEFAULT 0.00 | Costo promedio del artículo |
| activo | boolean | NULL, DEFAULT true | Indica si el artículo está activo |
| created_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de creación |
| updated_at | timestamp without time zone | NULL, DEFAULT now() | Fecha de actualización |
| unidad_medida_id | integer | NULL | ID de la unidad de medida |
| factor_conversion | numeric | NULL, DEFAULT 1.0 | Factor de conversión |
| unidad_compra_id | integer | NULL | ID de la unidad de compra |
| factor_compra | numeric | NULL, DEFAULT 1.0 | Factor de compra |
| tipo | USER-DEFINED | NULL | Tipo de artículo |
| unidad_salida_id | integer | NULL | ID de la unidad de salida |
| category_id | bigint | NULL | ID de la categoría (alternativo) |
| item_code | character varying | NULL | Código del artículo |
| es_producible | boolean | NOT NULL, DEFAULT false | Indica si el artículo es producible |
| es_consumible_operativo | boolean | NOT NULL, DEFAULT false | Indica si es un consumible operativo |
| es_empaque_to_go | boolean | NOT NULL, DEFAULT false | Indica si es empaque para llevar |

Foreign Keys

- category_id → selemti.item_categories.id
- unidad_salida_id → selemti.cat_unidades.id

Índices

- idx_items_activo: activo
- idx_items_activo_categoria: categoria_id
- idx_items_activo_categoria: activo
- idx_items_categoria_id: categoria_id
- idx_items_unidad_compra_id: unidad_compra_id
- idx_items_unidad_medida_id: unidad_medida_id
- idx_items_unidad_salida_id: unidad_salida_id
- items_pkey: id (unique)
- ux_items_item_code: item_code (unique)

### Datos de Ejemplo (3 registros)

```sql
SELECT * FROM selemti.items LIMIT 3;
```

| id | nombre | descripcion | categoria_id | unidad_medida | perishable | temperatura_min | temperatura_max | costo_promedio | activo | created_at | updated_at | unidad_medida_id | factor_conversion | unidad_compra_id | factor_compra | tipo | unidad_salida_id | category_id | item_code | es_producible | es_consumible_operativo | es_empaque_to_go | 
|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| ACEITE-NUTRIOLI-01 | Aceite de Soya Nutrioli | Aceite vegetal de soya 100% puro | CAT-ABARR | L |  | NULL | NULL | 150.00 | 1 | 2025-11-03 10:48:23.476701 | 2025-11-20 23:16:18 | 2 | 1.000000 | 16 | 2.838000 | MATERIA_PRIMA | NULL | 9 | C-00003 |  |  |  | 
| ACEITE-NUT-01 | Aceite de Soya Nutrioli | Aceite vegetal de soya 100% puro | CAT-ABARR | L |  | NULL | NULL | 150.00 | 1 | 2025-11-03 10:44:59.528047 | 2025-11-20 23:16:18 | 2 | 1.000000 | NULL | 1.000000 | MATERIA_PRIMA | NULL | 9 | C-00004 |  |  |  | 
| LECHE-MEMBERS-01 | Leche Deslactosada Member's Mark | Leche deslactosada reducida en lactosa | CAT-LACT | L | 1 | 2 | 8 | 220.00 | 1 | 2025-11-03 10:48:23.476701 | 2025-11-20 23:16:18 | 2 | 1.000000 | 12 | 12.000000 | MATERIA_PRIMA | NULL | 10 | C-00005 |  |  |  | 

---