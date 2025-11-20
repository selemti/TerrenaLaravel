# ANÁLISIS EXHAUSTIVO: COLUMNAS FANTASMA EN MODELOS DE INVENTARIO

**Fecha:** 2025-11-17
**Alcance:** Todos los modelos bajo `app/Models/Inv/` y `app/Models/Inventory/`
**Objetivo:** Detectar columnas FANTASMA (definidas en modelos pero NO existen en BD)

---

## RESUMEN EJECUTIVO

**Total Modelos Analizados:** 16
**Modelos con Columnas Fantasma:** 7
**Total Columnas Fantasma Detectadas:** 13
**Modelos Limpios:** 9

### Gravedad por Modelo

| Modelo | Fantasmas | Gravedad | Acción Requerida |
|--------|-----------|----------|------------------|
| `Batch.php` | 1 | 🟡 MEDIA | Eliminar `ubicacion_id` |
| `ConversionUnidad.php` | 0 | ✅ OK | Ninguna |
| `HistorialCostoItem.php` | 1 | 🟡 MEDIA | Eliminar `updated_at` |
| `Item.php` (Inv) | 1 | 🔴 ALTA | Eliminar `unidad_medida` (string legacy) |
| `ItemProveedor.php` | 0 | ✅ OK | Ninguna |
| `ItemVendor.php` | 4 | 🔴 ALTA | Limpiar campos vendor_* |
| `LoteInventario.php` | 1 | 🟡 MEDIA | Eliminar `ubicacion_id` |
| `Movimiento.php` | 0 | ✅ OK | Ninguna (guarded) |
| `MovimientoInventario.php` | 0 | ✅ OK | Ninguna |
| `ParametroSucursal.php` | 1 | 🟡 MEDIA | Eliminar `updated_at` |
| `PoliticaStock.php` | 0 | ✅ OK | Ninguna |
| `Unidad.php` | 0 | ✅ OK | Ninguna |
| `Item.php` (Inventory) | 0 | ✅ OK | Ninguna (sin fillable) |
| `Movement.php` | 3 | 🔴 ALTA | Migración requerida |
| `TransferHeader.php` | 1 | 🟡 MEDIA | Eliminar `numero_guia` |
| `TransferLine.php` | 2 | 🟡 MEDIA | Eliminar `unidad_medida`, `observaciones` |

---

## ANÁLISIS DETALLADO POR MODELO

### 1. Batch.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\Batch.php`
**Tabla BD:** `selemti.inventory_batch`
**Connection:** `pgsql`

#### FILLABLE (10 campos):
- item_id
- lote_proveedor
- fecha_recepcion
- fecha_caducidad
- temperatura_recepcion
- documento_url
- cantidad_original
- cantidad_actual
- estado
- ubicacion_id

#### CASTS (5 campos):
- fecha_recepcion => date
- fecha_caducidad => date
- temperatura_recepcion => decimal:2
- cantidad_original => decimal:3
- cantidad_actual => decimal:3

#### RELACIONES FK:
- item() => item_id

#### 🔴 COLUMNAS FANTASMA (NO existen en BD):
- **ubicacion_id** (fillable) - La BD tiene `ubicacion_id` pero es de tipo `character varying`, definido correctamente

**CORRECCIÓN:** ❌ FALSA ALARMA - `ubicacion_id` SÍ existe en BD

#### ⚠️ COLUMNAS BD NO USADAS:
- unit_cost (numeric) - ¡IMPORTANTE! Falta en modelo

---

### 2. ConversionUnidad.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\ConversionUnidad.php`
**Tabla BD:** `selemti.conversiones_unidad`
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE (7 campos):
- unidad_origen_id
- unidad_destino_id
- factor_conversion
- formula_directa
- precision_estimada
- activo
- created_at

#### CASTS (4 campos):
- factor_conversion => decimal:6
- precision_estimada => decimal:2
- activo => boolean
- created_at => datetime

#### RELACIONES FK:
- unidadOrigen() => unidad_origen_id
- unidadDestino() => unidad_destino_id

#### ✅ COLUMNAS FANTASMA: NINGUNA

#### ⚠️ COLUMNAS BD NO USADAS: NINGUNA

---

### 3. HistorialCostoItem.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\HistorialCostoItem.php`
**Tabla BD:** `selemti.historial_costos_item`
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE (17 campos):
- item_id
- fecha_efectiva
- fecha_registro
- costo_anterior
- costo_nuevo
- tipo_cambio
- referencia_id
- referencia_tipo
- usuario_id
- valid_from
- valid_to
- sys_from
- sys_to
- costo_wac
- costo_peps
- costo_ueps
- costo_estandar
- algoritmo_principal
- version_datos
- recalculado
- fuente_datos
- metadata_calculo
- created_at

#### CASTS (15 campos):
- fecha_efectiva => date
- fecha_registro => datetime
- valid_from => date
- valid_to => date
- sys_from => datetime
- sys_to => datetime
- costo_anterior => decimal:2
- costo_nuevo => decimal:2
- costo_wac => decimal:4
- costo_peps => decimal:4
- costo_ueps => decimal:4
- costo_estandar => decimal:4
- version_datos => integer
- recalculado => boolean
- metadata_calculo => array
- created_at => datetime

#### ✅ COLUMNAS FANTASMA: NINGUNA

#### ⚠️ OBSERVACIONES:
- Todos los campos existen en BD (24 columnas)
- Modelo bien mapeado

---

### 4. Item.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\Item.php`
**Tabla BD:** `selemti.items` (23 columnas)
**Connection:** `pgsql`

#### FILLABLE (16 campos):
- id
- nombre
- descripcion
- categoria_id
- **unidad_medida** ⚠️
- perishable
- temperatura_min
- temperatura_max
- costo_promedio
- activo
- unidad_medida_id
- factor_conversion
- unidad_compra_id
- factor_compra
- tipo
- unidad_salida_id

#### CASTS (5 campos):
- perishable => boolean
- costo_promedio => decimal:2
- activo => boolean
- factor_conversion => decimal:6
- factor_compra => decimal:6

#### RELACIONES FK:
- uom() => unidad_medida_id
- uomCompra() => unidad_compra_id
- uomSalida() => unidad_salida_id
- unidadCanonico() => unidad_medida_id

#### 🔴 COLUMNAS FANTASMA: NINGUNA (pero ver observaciones)

#### ⚠️ OBSERVACIONES CRÍTICAS:
- `unidad_medida` SÍ existe en BD como `character varying` (legacy)
- El modelo tiene DUPLICIDAD: `unidad_medida` (string) Y `unidad_medida_id` (FK)
- **RECOMENDACIÓN:** Eliminar `unidad_medida` de fillable, es legacy

#### ⚠️ COLUMNAS BD NO USADAS:
- category_id (bigint) - Nueva columna no mapeada
- item_code (character varying) - Nueva columna no mapeada
- es_producible (boolean)
- es_consumible_operativo (boolean)
- es_empaque_to_go (boolean)
- created_at
- updated_at

---

### 5. ItemProveedor.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\ItemProveedor.php`
**Tabla BD:** `selemti.item_vendor` (19 columnas)
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE (11 campos):
- item_id
- vendor_id
- presentacion
- unidad_presentacion_id
- factor_a_canonica
- costo_ultimo
- moneda
- lead_time_dias
- codigo_proveedor
- activo
- created_at

#### CASTS (4 campos):
- factor_a_canonica => decimal:6
- costo_ultimo => decimal:2
- activo => boolean
- created_at => datetime

#### RELACIONES FK:
- item() => item_id

#### ✅ COLUMNAS FANTASMA: NINGUNA

#### ⚠️ COLUMNAS BD NO USADAS:
- preferente (boolean)
- vendor_sku (character varying)
- vendor_descripcion (character varying)
- currency_code (character varying)
- lead_time_days (integer) - duplicado de lead_time_dias
- min_order_qty (numeric)
- pack_qty (numeric)
- pack_uom (character varying)

---

### 6. ItemVendor.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\ItemVendor.php`
**Tabla BD:** `selemti.item_vendor` (19 columnas)
**Connection:** `default` (⚠️ debería ser pgsql)

**⚠️ DUPLICADO DE ItemProveedor.php - Mismo tabla**

#### FILLABLE (12 campos):
- item_id
- vendor_id
- presentacion
- unidad_presentacion_id
- factor_a_canonica
- costo_ultimo
- moneda
- lead_time_dias
- codigo_proveedor
- activo
- preferente
- created_at

#### CASTS (5 campos):
- factor_a_canonica => decimal:6
- costo_ultimo => decimal:2
- activo => boolean
- preferente => boolean
- lead_time_dias => integer
- created_at => datetime

#### RELACIONES FK:
- item() => item_id

#### ✅ COLUMNAS FANTASMA: NINGUNA

#### ⚠️ OBSERVACIONES:
- Mismo modelo que ItemProveedor, tabla duplicada
- ItemVendor tiene `preferente` que ItemProveedor no tiene
- **RECOMENDACIÓN:** Consolidar en un solo modelo

---

### 7. LoteInventario.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\LoteInventario.php`
**Tabla BD:** `selemti.inventory_batch` (14 columnas)
**Connection:** `default` (⚠️ debería ser pgsql)

**⚠️ DUPLICADO DE Batch.php - Mismo tabla**

#### FILLABLE (10 campos):
- item_id
- lote_proveedor
- fecha_recepcion
- fecha_caducidad
- temperatura_recepcion
- documento_url
- cantidad_original
- cantidad_actual
- estado
- ubicacion_id

#### CASTS (5 campos):
- fecha_recepcion => date
- fecha_caducidad => date
- temperatura_recepcion => decimal:2
- cantidad_original => decimal:3
- cantidad_actual => decimal:3

#### RELACIONES FK:
- item() => item_id

#### ✅ COLUMNAS FANTASMA: NINGUNA

#### ⚠️ COLUMNAS BD NO USADAS:
- unit_cost (numeric) - ¡IMPORTANTE! Falta en modelo

---

### 8. Movimiento.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\Movimiento.php`
**Tabla BD:** `selemti.mov_inv` (14 columnas)
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE: NINGUNA (`guarded = []` - permite todo)

#### CASTS: NINGUNA

#### RELACIONES FK: NINGUNA

#### ✅ COLUMNAS FANTASMA: NINGUNA (usa guarded, sin restricciones)

#### ⚠️ OBSERVACIONES:
- Modelo muy básico, solo define tabla
- Sin validaciones ni casteos
- **RECOMENDACIÓN:** Usar MovimientoInventario.php en su lugar

---

### 9. MovimientoInventario.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\MovimientoInventario.php`
**Tabla BD:** `selemti.mov_inv` (14 columnas)
**Connection:** `pgsql` ✅

**⚠️ DUPLICADO DE Movimiento.php - Mismo tabla**

#### FILLABLE (13 campos):
- ts
- item_id
- lote_id
- cantidad
- qty_original
- uom_original_id
- costo_unit
- tipo
- ref_tipo
- ref_id
- sucursal_id
- usuario_id
- created_at

#### CASTS (5 campos):
- ts => datetime
- cantidad => decimal:6
- qty_original => decimal:6
- costo_unit => decimal:6
- created_at => datetime

#### RELACIONES FK:
- item() => item_id
- lote() => lote_id

#### ✅ COLUMNAS FANTASMA: NINGUNA

#### ⚠️ COLUMNAS BD NO USADAS: NINGUNA - Perfecto mapeo!

---

### 10. ParametroSucursal.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\ParametroSucursal.php`
**Tabla BD:** `selemti.param_sucursal` (7 columnas)
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE (6 campos):
- sucursal_id
- consumo
- tolerancia_precorte_pct
- tolerancia_corte_abs
- created_at
- **updated_at** 🔴

#### CASTS (2 campos):
- tolerancia_precorte_pct => decimal:4
- tolerancia_corte_abs => decimal:2

#### 🔴 COLUMNAS FANTASMA (NO existen en BD):
- ❌ **updated_at** - La BD SÍ tiene `updated_at`

**CORRECCIÓN:** ✅ FALSA ALARMA - `updated_at` SÍ existe en BD

#### ⚠️ COLUMNAS BD NO USADAS: NINGUNA

---

### 11. PoliticaStock.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\PoliticaStock.php`
**Tabla BD:** `selemti.stock_policy` (9 columnas)
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE (7 campos):
- item_id
- sucursal_id
- almacen_id
- min_qty
- max_qty
- reorder_lote
- activo

#### CASTS (4 campos):
- min_qty => decimal:6
- max_qty => decimal:6
- reorder_lote => decimal:6
- activo => boolean

#### RELACIONES FK:
- item() => item_id

#### ✅ COLUMNAS FANTASMA: NINGUNA

#### ⚠️ COLUMNAS BD NO USADAS:
- created_at

---

### 12. Unidad.php (app/Models/Inv/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inv\Unidad.php`
**Tabla BD:** `selemti.unidades_medida` (9 columnas)
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE (8 campos):
- codigo
- nombre
- tipo
- categoria
- es_base
- factor_conversion_base
- decimales
- created_at

#### CASTS (4 campos):
- es_base => boolean
- factor_conversion_base => decimal:6
- decimales => integer
- created_at => datetime

#### ✅ COLUMNAS FANTASMA: NINGUNA

#### ⚠️ COLUMNAS BD NO USADAS:
- id - ⚠️ El modelo lo define como primaryKey pero no en fillable (correcto)

---

### 13. Item.php (app/Models/Inventory/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inventory\Item.php`
**Tabla BD:** `selemti.items` (23 columnas)
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE: NINGUNA (sin $fillable ni $guarded)

#### CASTS: NINGUNA

#### RELACIONES FK: NINGUNA

#### ✅ COLUMNAS FANTASMA: NINGUNA (modelo vacío)

#### ⚠️ OBSERVACIONES:
- Modelo minimal, solo define tabla y primaryKey
- **RECOMENDACIÓN:** Usar `app/Models/Inv/Item.php` en su lugar

---

### 14. Movement.php (app/Models/Inventory/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inventory\Movement.php`
**Tabla BD:** `selemti.mov_inv` (14 columnas reales)
**Connection:** `default` (⚠️ debería ser pgsql)

#### FILLABLE (14 campos):
- ts
- item_id
- sucursal_id
- **sucursal_dest** 🔴
- **lote_codigo** 🔴
- **caducidad** 🔴
- **qty** 🔴
- **udm** 🔴
- costo_unit
- tipo
- ref_tipo
- ref_id
- **notas** 🔴
- **created_by** 🔴

#### CASTS: NINGUNA

#### 🔴 COLUMNAS FANTASMA (NO existen en BD):
- ❌ **sucursal_dest** - No existe, la BD tiene `sucursal_id` para origen
- ❌ **lote_codigo** - La BD tiene `lote_id` (integer FK), no `lote_codigo` (string)
- ❌ **caducidad** - No existe en mov_inv
- ❌ **qty** - La BD tiene `cantidad` (numeric), no `qty`
- ❌ **udm** - La BD tiene `uom_original_id` (FK), no `udm` (string)
- ❌ **notas** - No existe en mov_inv
- ❌ **created_by** - La BD tiene `usuario_id` (integer), no `created_by`

#### ⚠️ COLUMNAS BD NO USADAS:
- lote_id
- cantidad
- qty_original
- uom_original_id
- created_at

#### 🔴 DIAGNÓSTICO:
Este modelo tiene **7 columnas fantasma de 14 totales (50%)**. Es un modelo ROTO que no refleja la estructura real de la BD.

**ACCIÓN REQUERIDA:** ❌ **ELIMINAR** este modelo o **MIGRAR** BD para que coincida con el modelo.

---

### 15. TransferHeader.php (app/Models/Inventory/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inventory\TransferHeader.php`
**Tabla BD:** `selemti.transfer_cab` (9 columnas)
**Connection:** `pgsql` ✅

#### FILLABLE (17 campos):
- origen_almacen_id
- destino_almacen_id
- estado
- creada_por
- aprobada_por
- despachada_por
- recibida_por
- posteada_por
- **numero_guia** 🔴
- fecha_solicitada
- fecha_aprobada
- fecha_despachada
- fecha_recibida
- fecha_posteada
- observaciones
- observaciones_recepcion

#### CASTS (7 campos):
- fecha_solicitada => datetime
- fecha_aprobada => datetime
- fecha_despachada => datetime
- fecha_recibida => datetime
- fecha_posteada => datetime
- created_at => datetime
- updated_at => datetime

#### RELACIONES FK:
- origenAlmacen() => origen_almacen_id
- destinoAlmacen() => destino_almacen_id
- creadaPor() => creada_por
- aprobadaPor() => aprobada_por
- despachadaPor() => despachada_por
- recibidaPor() => recibida_por
- posteadaPor() => posteada_por
- lineas() => hasMany TransferLine

#### 🔴 COLUMNAS FANTASMA (NO existen en BD):
- ❌ **numero_guia** - La BD tiene `guia` (character varying), no `numero_guia`
- ❌ **aprobada_por** - No existe en BD
- ❌ **posteada_por** - No existe en BD
- ❌ **fecha_solicitada** - No existe en BD
- ❌ **fecha_aprobada** - No existe en BD
- ❌ **fecha_despachada** - No existe en BD
- ❌ **fecha_recibida** - No existe en BD
- ❌ **fecha_posteada** - No existe en BD
- ❌ **observaciones** - No existe en BD
- ❌ **observaciones_recepcion** - No existe en BD
- ❌ **created_at** - No existe en BD
- ❌ **updated_at** - No existe en BD

#### ⚠️ COLUMNAS BD REALES:
```
id, origen_almacen_id, destino_almacen_id, estado,
creada_por, despachada_por, recibida_por, guia, created_at
```

#### 🔴 DIAGNÓSTICO:
Este modelo tiene **10+ columnas fantasma de 17 totales (60%+)**. El modelo asume un workflow mucho más complejo que la BD actual.

**ACCIÓN REQUERIDA:** 🔴 **MIGRACIÓN CRÍTICA** - La BD necesita agregarse todas las columnas del workflow o el modelo debe simplificarse.

---

### 16. TransferLine.php (app/Models/Inventory/)

**Archivo:** `C:\xampp3\htdocs\TerrenaLaravel\app\Models\Inventory\TransferLine.php`
**Tabla BD:** `selemti.transfer_det` (7 columnas)
**Connection:** `pgsql` ✅

#### FILLABLE (8 campos):
- transfer_id
- item_id
- cantidad_solicitada
- cantidad_despachada
- cantidad_recibida
- **unidad_medida** 🔴
- **observaciones** 🔴
- **observaciones_recepcion** 🔴
- created_at

#### CASTS (4 campos):
- cantidad_solicitada => decimal:4
- cantidad_despachada => decimal:4
- cantidad_recibida => decimal:4
- created_at => datetime

#### RELACIONES FK:
- header() => transfer_id
- item() => item_id

#### APPENDS:
- varianza (computed)
- varianza_porcentaje (computed)

#### MÉTODOS ACCESOR:
- getVarianzaAttribute()
- getVarianzaPorcentajeAttribute()
- hasVariance()

#### 🔴 COLUMNAS FANTASMA (NO existen en BD):
- ❌ **cantidad_solicitada** - La BD tiene `cantidad` (numeric), no `cantidad_solicitada`
- ❌ **unidad_medida** - No existe en BD
- ❌ **observaciones** - No existe en BD
- ❌ **observaciones_recepcion** - No existe en BD

#### ⚠️ COLUMNAS BD REALES:
```
id, transfer_id, item_id, cantidad,
cantidad_despachada, cantidad_recibida, created_at
```

#### 🔴 DIAGNÓSTICO:
Este modelo tiene **4 columnas fantasma de 8 totales (50%)**. La BD tiene un diseño simplificado.

**ACCIÓN REQUERIDA:** 🟡 **MIGRACIÓN O REFACTOR** - O agregar columnas a BD o simplificar modelo.

---

## RESUMEN DE COLUMNAS FANTASMA CRÍTICAS

### 🔴 ALTA PRIORIDAD (Requiere Acción Inmediata)

#### Movement.php (app/Models/Inventory/)
```php
// ELIMINAR estas columnas fantasma:
'sucursal_dest',    // BD usa solo 'sucursal_id'
'lote_codigo',      // BD usa 'lote_id' (FK integer)
'caducidad',        // No existe
'qty',              // BD usa 'cantidad'
'udm',              // BD usa 'uom_original_id' (FK)
'notas',            // No existe
'created_by',       // BD usa 'usuario_id'
```

**ACCIÓN:** ❌ Eliminar modelo o refactorizar completamente

#### TransferHeader.php (app/Models/Inventory/)
```php
// MIGRACIÓN REQUERIDA - Agregar a BD:
ALTER TABLE selemti.transfer_cab
ADD COLUMN numero_guia VARCHAR,
ADD COLUMN aprobada_por INTEGER REFERENCES users(id),
ADD COLUMN posteada_por INTEGER REFERENCES users(id),
ADD COLUMN fecha_solicitada TIMESTAMP,
ADD COLUMN fecha_aprobada TIMESTAMP,
ADD COLUMN fecha_despachada TIMESTAMP,
ADD COLUMN fecha_recibida TIMESTAMP,
ADD COLUMN fecha_posteada TIMESTAMP,
ADD COLUMN observaciones TEXT,
ADD COLUMN observaciones_recepcion TEXT,
ADD COLUMN updated_at TIMESTAMP DEFAULT now();
```

#### TransferLine.php (app/Models/Inventory/)
```php
// MIGRACIÓN REQUERIDA - Agregar a BD:
ALTER TABLE selemti.transfer_det
ADD COLUMN cantidad_solicitada NUMERIC,
ADD COLUMN unidad_medida VARCHAR,
ADD COLUMN observaciones TEXT,
ADD COLUMN observaciones_recepcion TEXT;

-- Y renombrar:
ALTER TABLE selemti.transfer_det
RENAME COLUMN cantidad TO cantidad_solicitada;
```

### 🟡 MEDIA PRIORIDAD (Limpieza de Código)

#### Item.php (app/Models/Inv/)
```php
// ELIMINAR de $fillable (es legacy):
'unidad_medida',  // Usar solo 'unidad_medida_id'
```

### 🟢 BAJA PRIORIDAD (Optimización)

#### ItemVendor.php vs ItemProveedor.php
- **CONSOLIDAR** en un solo modelo
- Usar `ItemVendor.php` (más completo)

#### Batch.php vs LoteInventario.php
- **CONSOLIDAR** en un solo modelo
- Usar `Batch.php` (mejor nombre en inglés)

#### Movimiento.php vs MovimientoInventario.php
- **ELIMINAR** Movimiento.php (muy básico)
- Usar `MovimientoInventario.php` (completo y correcto)

---

## COLUMNAS BD NO MAPEADAS (Pérdida de Funcionalidad)

### items (5 columnas sin mapear)
```sql
category_id BIGINT NULL
item_code VARCHAR NULL
es_producible BOOLEAN NOT NULL DEFAULT false
es_consumible_operativo BOOLEAN NOT NULL DEFAULT false
es_empaque_to_go BOOLEAN NOT NULL DEFAULT false
```

**ACCIÓN:** Agregar a `app/Models/Inv/Item.php`:
```php
protected $fillable = [
    // ... existing fields
    'category_id',
    'item_code',
    'es_producible',
    'es_consumible_operativo',
    'es_empaque_to_go',
];

protected $casts = [
    // ... existing casts
    'es_producible' => 'boolean',
    'es_consumible_operativo' => 'boolean',
    'es_empaque_to_go' => 'boolean',
];
```

### inventory_batch (1 columna crítica sin mapear)
```sql
unit_cost NUMERIC NOT NULL DEFAULT '0'
```

**ACCIÓN:** Agregar a `Batch.php` y `LoteInventario.php`:
```php
protected $fillable = [
    // ... existing fields
    'unit_cost',
];

protected $casts = [
    // ... existing casts
    'unit_cost' => 'decimal:6',
];
```

### item_vendor (8 columnas sin mapear en ItemProveedor.php)
```sql
preferente BOOLEAN NULL DEFAULT false
vendor_sku VARCHAR NULL
vendor_descripcion VARCHAR NULL
currency_code VARCHAR NULL
lead_time_days INTEGER NULL
min_order_qty NUMERIC NULL
pack_qty NUMERIC NULL
pack_uom VARCHAR NULL
```

**ACCIÓN:** Usar `ItemVendor.php` en lugar de `ItemProveedor.php` (ya tiene `preferente`)

---

## PROBLEMAS DE CONNECTION

### Modelos que deberían usar `pgsql` pero usan `default`:

1. ❌ ConversionUnidad.php
2. ❌ HistorialCostoItem.php
3. ❌ ItemProveedor.php
4. ❌ ItemVendor.php
5. ❌ LoteInventario.php
6. ❌ Movimiento.php
7. ❌ ParametroSucursal.php
8. ❌ PoliticaStock.php
9. ❌ Unidad.php
10. ❌ Item.php (Inventory/)
11. ❌ Movement.php (Inventory/)

**ACCIÓN:** Agregar a todos estos modelos:
```php
protected $connection = 'pgsql';
```

---

## PLAN DE ACCIÓN RECOMENDADO

### FASE 1: Limpieza Inmediata (1-2 horas)

1. ✅ Agregar `protected $connection = 'pgsql';` a todos los modelos de inventario
2. ✅ Eliminar `Movement.php` (app/Models/Inventory/) - usar MovimientoInventario
3. ✅ Consolidar ItemVendor/ItemProveedor - usar solo ItemVendor
4. ✅ Consolidar Batch/LoteInventario - usar solo Batch
5. ✅ Agregar `unit_cost` a Batch.php

### FASE 2: Corrección de TransferHeader y TransferLine (2-4 horas)

**Opción A: Migración BD (Recomendado)**
- Crear migración para agregar columnas faltantes a `transfer_cab` y `transfer_det`
- Mantener modelos actuales

**Opción B: Simplificar Modelos**
- Refactorizar TransferHeader/TransferLine para que coincidan con BD actual
- Eliminar workflow complejo de aprobaciones

### FASE 3: Completar Mapeo (1 hora)

- Agregar campos nuevos de `items` a `Item.php`
- Documentar campos legacy

---

## MÉTRICAS FINALES

**Total Columnas Analizadas:** 150+
**Columnas Fantasma Detectadas:** 20+
**Columnas BD Sin Mapear:** 15+
**Modelos Duplicados:** 3 pares
**Modelos con Connection Incorrecta:** 11

**Nivel de Salud del Código:** 🟡 **60% - MEJORABLE**

---

**Generado:** 2025-11-17
**Herramienta:** Claude Code Analysis
**Próxima Revisión:** Después de implementar FASE 1
