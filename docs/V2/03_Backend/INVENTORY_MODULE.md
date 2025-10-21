# Módulo de Inventario - Documentación Técnica

## Resumen

El módulo de inventario proporciona un CRUD completo para la gestión de items, stock, movimientos y kardex. Integra con la base de datos PostgreSQL (legacy POS) para mantener sincronización con el sistema existente.

## Estructura de Archivos

### Backend (API)

**Controladores:**
- `app/Http/Controllers/Api/Inventory/ItemController.php` - CRUD de items
- `app/Http/Controllers/Api/Inventory/StockController.php` - Stock, KPIs, Kardex, Movimientos
- `app/Http/Controllers/Api/CatalogsController.php` - Catálogos auxiliares

**Modelos:**
- `app/Models/Inv/Item.php` - Items del inventario
- `app/Models/Inv/Batch.php` - Lotes/batches
- `app/Models/Inv/MovimientoInventario.php` - Movimientos (Kardex)
- `app/Models/Catalogs/Almacen.php` - Almacenes
- `app/Models/Catalogs/Sucursal.php` - Sucursales

### Frontend

**Vistas:**
- `resources/views/inventario.blade.php` - Vista principal de inventario
- `public/assets/js/inventario.js` - Lógica del frontend

## Endpoints Disponibles

### 1. KPIs y Dashboard

#### GET `/api/inventory/kpis`

Retorna métricas principales del inventario.

**Respuesta:**
```json
{
  "ok": true,
  "data": {
    "total_items": 120,
    "inventory_value": 45678.50,
    "low_stock_count": 5,
    "expiring_items": 3
  },
  "timestamp": "2025-10-21T00:00:00-06:00"
}
```

**Descripción de métricas:**
- `total_items`: Total de items activos en el catálogo
- `inventory_value`: Valor total del inventario (usando WAC de `vw_stock_valorizado`)
- `low_stock_count`: Items con stock por debajo del mínimo definido en políticas
- `expiring_items`: Items con lotes que caducan en los próximos 30 días

### 2. Listado de Stock

#### GET `/api/inventory/stock/list`

Lista completa de stock con filtros y paginación.

**Parámetros:**
- `q` (string): Búsqueda por SKU, nombre o descripción
- `sucursal_id` (string): Filtrar por sucursal
- `categoria_id` (string): Filtrar por categoría
- `status` (enum): `all`, `active`, `inactive`, `low_stock`, `expiring`
- `page` (int): Número de página
- `per_page` (int): Items por página (default: 25)
- `order_by` (string): Campo para ordenar (default: `nombre`)
- `order_dir` (string): `asc` o `desc` (default: `asc`)

**Respuesta:**
```json
{
  "ok": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "sku": "ITEM-001",
        "nombre": "Leche Entera 1L",
        "descripcion": "Leche entera pasteurizada",
        "categoria": "Lácteos",
        "categoria_id": "CAT-10",
        "stock": 45.00,
        "uom": "Litro",
        "costo": 18.50,
        "valor_total": 832.50,
        "activo": true,
        "ubicacion_id": "SUC-01"
      }
    ],
    "per_page": 25,
    "total": 120,
    "last_page": 5
  },
  "timestamp": "2025-10-21T00:00:00-06:00"
}
```

### 3. CRUD de Items

#### GET `/api/inventory/items`

Lista de items con filtros.

**Parámetros:**
- `q` (string): Búsqueda por ID, nombre o descripción
- `activo` (boolean): Filtrar por estado activo/inactivo
- `categoria_id` (string): Filtrar por categoría
- `per_page` (int): Items por página (default: 25)

#### GET `/api/inventory/items/{id}`

Detalle de un item específico (incluye relaciones con unidades de medida).

#### POST `/api/inventory/items`

Crear nuevo item.

**Body:**
```json
{
  "id": "ITEM-NEW",
  "nombre": "Nuevo Producto",
  "descripcion": "Descripción del producto",
  "categoria_id": "CAT-10",
  "unidad_medida_id": 1,
  "unidad_compra_id": 2,
  "unidad_salida_id": 3,
  "activo": true
}
```

#### PUT `/api/inventory/items/{id}`

Actualizar item existente.

**Body:** Mismos campos que POST (excepto `id`)

#### DELETE `/api/inventory/items/{id}`

Desactivar item (soft delete).

### 4. Kardex

#### GET `/api/inventory/items/{id}/kardex`

Historial de movimientos de un item (últimos 100 registros).

**Parámetros:**
- `lote_id` (int): Filtrar por lote específico
- `from` (date): Fecha desde
- `to` (date): Fecha hasta

**Respuesta:**
```json
{
  "ok": true,
  "data": [
    {
      "id": 1234,
      "ts": "2025-10-20 15:30:00",
      "item_id": "ITEM-001",
      "lote_id": 56,
      "cantidad": 10.500,
      "tipo": "ENTRADA",
      "ref_tipo": "RECEPCION",
      "ref_id": "REC-123",
      "sucursal_id": "SUC-01",
      "usuario_id": 5
    }
  ],
  "timestamp": "2025-10-21T00:00:00-06:00"
}
```

### 5. Lotes/Batches

#### GET `/api/inventory/items/{id}/batches`

Lista de lotes de un item.

**Parámetros:**
- `estado` (string): Filtrar por estado (`ACTIVO`, `AGOTADO`, etc.)
- `per_page` (int): Batches por página (default: 25)

### 6. Movimientos Rápidos

#### POST `/api/inventory/movements`

Crear movimiento de inventario (entrada, salida, ajuste, merma).

**Body:**
```json
{
  "item_id": "ITEM-001",
  "tipo": "ENTRADA",
  "cantidad": 10.5,
  "costo_unit": 18.50,
  "sucursal_id": "SUC-01",
  "razon": "Ajuste por inventario físico",
  "lote_id": 56
}
```

**Validaciones:**
- `item_id`: Requerido, string, max 20 caracteres
- `tipo`: Requerido, enum: `ENTRADA`, `SALIDA`, `AJUSTE`, `MERMA`
- `cantidad`: Requerido, numérico, mínimo 0.001
- `costo_unit`: Opcional, numérico, mínimo 0
- `sucursal_id`: Requerido, string
- `razon`: Opcional, string, max 255 caracteres
- `lote_id`: Opcional, integer

### 7. Catálogos Auxiliares

#### GET `/api/catalogs/categories`

Lista de categorías de productos (de POS).

**Parámetros:**
- `show_all` (boolean): Mostrar categorías ocultas (default: false)

#### GET `/api/catalogs/sucursales`

Lista de sucursales.

**Parámetros:**
- `show_all` (boolean): Mostrar sucursales inactivas (default: false)

#### GET `/api/catalogs/almacenes`

Lista de almacenes.

**Parámetros:**
- `show_all` (boolean): Mostrar almacenes inactivos (default: false)
- `sucursal_id` (string): Filtrar por sucursal

#### GET `/api/catalogs/movement-types`

Lista de tipos de movimiento (constantes del sistema).

**Respuesta:**
```json
{
  "ok": true,
  "data": [
    {
      "value": "ENTRADA",
      "label": "Entrada",
      "description": "Entrada de inventario",
      "affects_stock": true,
      "sign": "+"
    },
    {
      "value": "SALIDA",
      "label": "Salida",
      "description": "Salida de inventario",
      "affects_stock": true,
      "sign": "-"
    }
  ]
}
```

## Base de Datos

### Conexión

El módulo utiliza la conexión **PostgreSQL** (`pgsql`) para acceder a la base de datos legacy del sistema POS.

### Tablas Principales

#### `selemti.items`

Catálogo maestro de items.

**Columnas principales:**
- `id` (string, PK): SKU único del item
- `nombre` (string): Nombre del item
- `descripcion` (text): Descripción detallada
- `categoria_id` (string): FK a categoría
- `unidad_medida_id` (int): FK a unidad base
- `unidad_compra_id` (int): FK a unidad de compra
- `unidad_salida_id` (int): FK a unidad de salida
- `costo_promedio` (decimal): WAC del item
- `activo` (boolean): Estado del item

#### `selemti.inventory_batch`

Lotes/batches de inventario.

**Columnas principales:**
- `id` (serial, PK)
- `item_id` (string): FK a items
- `ubicacion_id` (string): Almacén o sucursal
- `cantidad_actual` (decimal): Stock actual del lote
- `costo_unit` (decimal): Costo unitario del lote
- `fecha_caducidad` (date): Fecha de caducidad
- `estado` (string): Estado del lote

#### `selemti.mov_inv`

Kardex de movimientos.

**Columnas principales:**
- `id` (serial, PK)
- `ts` (timestamp): Fecha y hora del movimiento
- `item_id` (string): FK a items
- `lote_id` (int): FK a batch (opcional)
- `cantidad` (decimal): Cantidad movida (en UOM base)
- `qty_original` (decimal): Cantidad original (antes de conversión)
- `costo_unit` (decimal): Costo unitario
- `tipo` (string): Tipo de movimiento
- `ref_tipo` (string): Tipo de referencia
- `ref_id` (string): ID de documento de referencia
- `sucursal_id` (string): Sucursal
- `usuario_id` (int): Usuario que realizó el movimiento

### Vistas Importantes

#### `selemti.vw_stock_actual`

Vista que calcula el stock actual por item y ubicación.

#### `selemti.vw_stock_valorizado`

Vista que calcula el valor del inventario usando WAC (Weighted Average Cost).

**Columnas:**
- `item_key`: ID del item
- `sucursal_id`: ID de sucursal
- `stock`: Cantidad en stock
- `costo_wac`: Costo promedio ponderado
- `valor`: Valor total (stock × costo_wac)

#### `selemti.vw_stock_brechas`

Vista que identifica items con stock fuera de política (min/max).

**Columnas:**
- `sucursal_id`: ID de sucursal
- `item_id`: ID del item
- `min_qty`: Cantidad mínima definida
- `max_qty`: Cantidad máxima definida
- `stock_actual`: Stock actual
- `faltante`: Cantidad faltante para llegar al mínimo
- `excedente`: Cantidad excedente sobre el máximo

## Frontend - inventario.blade.php

### Características

1. **Filtros:**
   - Búsqueda por texto (SKU, nombre, descripción)
   - Filtro por sucursal
   - Filtro por categoría
   - Filtro por estado (activos, inactivos, bajo stock, por caducar)

2. **KPIs Dashboard:**
   - Total de items distintos
   - Valor total del inventario
   - Items con bajo stock
   - Items con caducidad próxima

3. **Tabla de Stock:**
   - Listado paginado de items
   - Visualización de existencias por UOM
   - Costos y valor total
   - Estado del item
   - Acciones: Ver Kardex, Movimiento Rápido

4. **Modal de Kardex:**
   - Historial completo de movimientos
   - Columnas: Fecha, Hora, Tipo, Entrada, Salida, Saldo, Referencia
   - Cálculo de saldo acumulado

5. **Offcanvas de Movimiento Rápido:**
   - Crear movimientos sin salir de la pantalla
   - Selección de tipo de movimiento
   - Ingreso de cantidad y costo
   - Asignación de sucursal
   - Notas/razón del movimiento

### JavaScript (inventario.js)

**Funciones principales:**
- `loadKPIs()`: Carga métricas del dashboard
- `loadStockList()`: Carga tabla de stock con filtros
- `loadCatalogs()`: Carga catálogos auxiliares
- `verKardex(itemId)`: Muestra modal con kardex del item
- `movimientoRapido(itemId)`: Abre offcanvas para crear movimiento
- `guardarMovimiento()`: Guarda movimiento rápido

**Utilidades:**
- `apiGet(endpoint)`: Wrapper para fetch GET
- `apiPost(endpoint, data)`: Wrapper para fetch POST
- `toast(msg, type)`: Notificaciones toast
- `fmt.currency(val)`: Formato moneda
- `fmt.number(val, decimals)`: Formato número

## Pendientes / Mejoras Futuras

1. **CRUD de Items en UI:**
   - Formulario de creación de items
   - Edición inline de items
   - Modal de edición completa

2. **Gestión de Lotes:**
   - Visualización de lotes por item
   - Asignación de lotes en movimientos
   - Alertas de caducidad

3. **Reportes:**
   - Reporte de rotación de inventario
   - Análisis ABC
   - Comparativo de períodos

4. **Integraciones:**
   - Sincronización con POS en tiempo real
   - Integración con módulo de compras
   - Trazabilidad de lotes en recetas

5. **Validaciones:**
   - Validación de stock disponible antes de salidas
   - Alertas de stock crítico
   - Prevención de movimientos negativos

## Errores Corregidos

### 2025-10-21

**Error:** SQLSTATE[42703]: Undefined column: 7 ERROR: no existe la columna «stock»

**Causa:** El código estaba usando columnas incorrectas (`stock`, `minimo`) en la vista `vw_stock_brechas`, cuando las columnas correctas son `stock_actual`, `min_qty`, `max_qty`.

**Archivos afectados:**
- `app/Http/Controllers/Api/Inventory/StockController.php:29` - Query de KPIs
- `app/Http/Controllers/Api/Inventory/StockController.php:108` - Filtro de low_stock

**Solución:** Actualización de queries para usar nombres correctos de columnas.

**Commit:** [hash del commit si se hace]

---

*Última actualización: 2025-10-21*
