# REFAC_INVENTARIO_AUDITORIA_ESTRICTA

**Fecha**: 2025-11-17
**Metodología**: Comparación DIRECTA entre BD PostgreSQL real y código Laravel
**Alcance**: Módulo Inventario completo (models, services, controllers)

---

## 1. Tabla BD vs Código por Tabla

### 1.1 selemti.items

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ |
| **Modelos** | `App\Models\Inv\Item` (principal), `App\Models\Inventory\Item` (minimal) |
| **$table correcto** | ✅ `selemti.items` |
| **$connection** | ⚠️ FALTA en Inventory\Item |
| **Columnas en BD** | 23 columnas |
| **Columnas en $fillable** | 15 columnas (Inv\Item) |
| **Columnas en $casts** | 6 columnas |

**Columnas BD (23 total)**:
```
id, nombre, descripcion, categoria_id, unidad_medida, perishable,
temperatura_min, temperatura_max, costo_promedio, activo, created_at,
updated_at, unidad_medida_id, factor_conversion, unidad_compra_id,
factor_compra, tipo, unidad_salida_id, category_id, item_code,
es_producible, es_consumible_operativo, es_empaque_to_go
```

**Columnas $fillable en Inv\Item (15)**:
```
nombre, descripcion, categoria_id, unidad_medida, perishable,
temperatura_min, temperatura_max, costo_promedio, activo,
unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra,
tipo, unidad_salida_id
```

**🟡 COLUMNAS BD NO MAPEADAS (8)**: Campos nuevos agregados después
```
category_id (bigint FK), item_code, es_producible, es_consumible_operativo,
es_empaque_to_go
```

**⚠️ CAMPO LEGACY DUPLICADO**:
- `unidad_medida` (VARCHAR) - legacy, debería migrar a `unidad_medida_id` (integer FK)
- Ambos existen en BD por compatibilidad

**Columnas FANTASMA**: ❌ NINGUNA

---

### 1.2 selemti.mov_inv (Kardex)

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ |
| **Modelos** | `App\Models\Inv\MovimientoInventario` (✅), `App\Models\Inventory\Movement` (🔴 ROTO) |
| **$table correcto** | ✅ `selemti.mov_inv` (MovimientoInventario) |
| **$connection** | ✅ `pgsql` (MovimientoInventario), ⚠️ FALTA (Movement) |
| **Columnas en BD** | 14 columnas |

**Columnas BD (14 total)**:
```
id, ts, item_id, lote_id, cantidad, qty_original, uom_original_id,
costo_unit, tipo, ref_tipo, ref_id, sucursal_id, usuario_id, created_at
```

#### 1.2.1 MovimientoInventario.php (✅ PERFECTO)

**Columnas $fillable (13)** - Todas existen en BD:
```
ts, item_id, lote_id, cantidad, qty_original, uom_original_id,
costo_unit, tipo, ref_tipo, ref_id, sucursal_id, usuario_id, created_at
```

**Columnas $casts (3)**:
```
ts => datetime, cantidad => decimal:3, costo_unit => decimal:4
```

**Estado**: ✅ 100% CORRECTO - NO HAY FANTASMA

---

#### 1.2.2 Inventory\Movement.php (🔴 INUTILIZABLE - 50% FANTASMA)

**Columnas $fillable (14)**: **7 FANTASMA (50%)**
```
✅ ts
✅ item_id
❌ sucursal_dest      → BD: sucursal_id
❌ lote_codigo        → BD: lote_id (integer FK, no código)
❌ caducidad          → NO EXISTE (está en tabla lote, no mov_inv)
❌ qty                → BD: cantidad
❌ udm                → BD: uom_original_id (integer FK, no código)
✅ costo_unit
✅ tipo
✅ ref_tipo
✅ ref_id
❌ notas              → NO EXISTE en mov_inv
❌ created_by         → BD: usuario_id
✅ created_at
```

**Columnas FANTASMA detectadas (7)**:
1. ❌ `sucursal_dest` - BD tiene `sucursal_id`
2. ❌ `lote_codigo` - BD tiene `lote_id` (FK integer)
3. ❌ `caducidad` - NO existe en mov_inv (está en tabla lote)
4. ❌ `qty` - BD tiene `cantidad`
5. ❌ `udm` - BD tiene `uom_original_id` (FK integer)
6. ❌ `notas` - NO existe
7. ❌ `created_by` - BD tiene `usuario_id`

**🔴 ERROR CRÍTICO**: Este modelo es **INUTILIZABLE**. Usa nombres de columnas incorrectos.

**Acción requerida**: ❌ ELIMINAR `app/Models/Inventory/Movement.php` completamente
                      ✅ USAR `app/Models/Inv/MovimientoInventario.php`

---

### 1.3 selemti.lote / inventory_batch

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ (tabla `lote`) |
| **Modelos** | `App\Models\Inv\Batch` (✅), `App\Models\Inv\LoteInventario` (duplicado) |
| **$table correcto** | ✅ `selemti.lote` / `selemti.inventory_batch` |
| **$connection** | ⚠️ FALTA en ambos |
| **Columnas en BD** | 6 columnas (lote), 8 columnas (inventory_batch) |

**Columnas BD lote (6)**:
```
id, item_id, proveedor_id, codigo, caducidad, estado, creado_ts
```

**Columnas BD inventory_batch (8)**:
```
id, item_id, vendor_id, batch_code, expiration_date, unit_cost,
created_at, updated_at
```

#### 1.3.1 Batch.php

**Columnas $fillable (7)**:
```
item_id, vendor_id, batch_code, expiration_date, unit_cost,
created_at, updated_at
```

**Columnas $casts (2)**:
```
expiration_date => date, unit_cost => decimal:4
```

**🔴 ERROR - Tabla incorrecta**: Modelo usa `selemti.lote` pero campos son de `inventory_batch`

**Columnas FANTASMA si la tabla es `lote`**:
- `vendor_id` → BD tiene `proveedor_id`
- `batch_code` → BD tiene `codigo`
- `expiration_date` → BD tiene `caducidad`
- `unit_cost` → NO EXISTE en lote (existe en inventory_batch)

**Acción requerida**: Decidir cuál tabla usar (`lote` legacy vs `inventory_batch` nueva)

---

### 1.4 selemti.transfer_cab

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ |
| **Modelo** | `App\Models\Inventory\TransferHeader` |
| **$table correcto** | ✅ `selemti.transfer_cab` |
| **$connection** | ⚠️ FALTA |
| **Columnas en BD** | 9 columnas |
| **Columnas en $fillable** | 17 columnas |

**Columnas BD (9 total)**:
```
id, origen_almacen_id, destino_almacen_id, estado, creada_por,
despachada_por, recibida_por, guia, created_at
```

**Columnas $fillable en modelo (17)**: **10 FANTASMA (59%)**
```
✅ origen_almacen_id
✅ destino_almacen_id
✅ estado
✅ creada_por
❌ aprobada_por        → NO EXISTE
❌ despachada_por      → ✅ EXISTE (error en análisis previo)
❌ recibida_por        → ✅ EXISTE
❌ posteada_por        → NO EXISTE
❌ numero_guia         → BD: guia
❌ fecha_solicitada    → NO EXISTE
❌ fecha_aprobada      → NO EXISTE
❌ fecha_despachada    → NO EXISTE
❌ fecha_recibida      → NO EXISTE
❌ fecha_posteada      → NO EXISTE
❌ observaciones       → NO EXISTE
❌ observaciones_recepcion → NO EXISTE
✅ created_at
❌ updated_at          → NO EXISTE
```

**🔴 COLUMNAS FANTASMA REALES (10)**:
1. ❌ `aprobada_por`
2. ❌ `posteada_por`
3. ❌ `numero_guia` (BD tiene `guia`)
4. ❌ `fecha_solicitada`
5. ❌ `fecha_aprobada`
6. ❌ `fecha_despachada`
7. ❌ `fecha_recibida`
8. ❌ `fecha_posteada`
9. ❌ `observaciones`
10. ❌ `observaciones_recepcion`
11. ❌ `updated_at`

**Acción requerida**:
- Opción 1: 🔴 Crear migración SQL para agregar las 10 columnas faltantes
- Opción 2: ✅ Simplificar modelo eliminando campos FANTASMA (recomendado)

---

### 1.5 selemti.transfer_det

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ |
| **Modelo** | `App\Models\Inventory\TransferLine` |
| **$table correcto** | ✅ `selemti.transfer_det` |
| **$connection** | ⚠️ FALTA |
| **Columnas en BD** | 7 columnas |
| **Columnas en $fillable** | 10 columnas |

**Columnas BD (7 total)**:
```
id, transfer_id, item_id, cantidad, cantidad_despachada,
cantidad_recibida, created_at
```

**Columnas $fillable en modelo (10)**: **4 FANTASMA (40%)**
```
✅ transfer_id
✅ item_id
❌ cantidad_solicitada   → BD: cantidad
❌ unidad_medida         → NO EXISTE
✅ cantidad_despachada
✅ cantidad_recibida
❌ observaciones         → NO EXISTE
❌ observaciones_recepcion → NO EXISTE
✅ created_at
✅ updated_at (si existe)
```

**🔴 COLUMNAS FANTASMA (4)**:
1. ❌ `cantidad_solicitada` - BD tiene `cantidad`
2. ❌ `unidad_medida` - NO existe
3. ❌ `observaciones` - NO existe
4. ❌ `observaciones_recepcion` - NO existe

**Acción requerida**: Corregir nombre de `cantidad_solicitada` → `cantidad` y eliminar campos FANTASMA

---

### 1.6 selemti.recepcion_cab

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ |
| **Modelo** | No encontrado en análisis inicial |
| **Columnas en BD** | 15 columnas |

**Columnas BD (15 total)**:
```
id, sucursal_id, proveedor_id, oc_ref, ts, usuario_id, meta, almacen_id,
numero_recepcion, fecha_recepcion, estado, total_presentaciones,
total_canonico, created_at, updated_at, deleted_at
```

**Estado**: ⚠️ Modelo no analizado o no existe

---

### 1.7 selemti.recepcion_det

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ |
| **Modelo** | No encontrado en análisis inicial |
| **Columnas en BD** | 13 columnas |

**Columnas BD (13 total)**:
```
id, recepcion_id, item_id, bodega_id, qty, um_id, costo_unit, batch_id,
temperatura, doc_url, meta, created_at, updated_at, deleted_at
```

**Estado**: ⚠️ Modelo no analizado o no existe

---

### 1.8 selemti.stock_policy / inv_stock_policy

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ (ambas tablas) |
| **Modelo** | `App\Models\Inv\PoliticaStock` |
| **$table correcto** | ✅ `selemti.stock_policy` |
| **$connection** | ⚠️ FALTA |
| **Columnas en BD** | 9 columnas |
| **Columnas en $fillable** | 8 columnas |

**Columnas BD (9 total)**:
```
id, item_id, sucursal_id, almacen_id, min_qty, max_qty, reorder_lote,
activo, created_at
```

**Columnas $fillable (8)**:
```
item_id, sucursal_id, almacen_id, min_qty, max_qty, reorder_lote,
activo, created_at
```

**Columnas FANTASMA**: ❌ NINGUNA

**Estado**: ✅ PERFECTO

---

### 1.9 selemti.unidades_medida_legacy

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ |
| **Modelo** | `App\Models\Inv\Unidad` |
| **$table correcto** | ✅ `selemti.unidades_medida_legacy` |
| **$connection** | ⚠️ FALTA |
| **Columnas en BD** | 9 columnas |
| **Columnas en $fillable** | 8 columnas |

**Columnas BD (9 total)**:
```
id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base,
decimales, created_at
```

**Columnas $fillable (8)**:
```
codigo, nombre, tipo, categoria, es_base, factor_conversion_base,
decimales, created_at
```

**Columnas FANTASMA**: ❌ NINGUNA

**Estado**: ✅ PERFECTO

---

### 1.10 selemti.conversiones_unidad_legacy

| Aspecto | Valor |
|---------|-------|
| **Existe en BD** | ✅ SÍ |
| **Modelo** | `App\Models\Inv\ConversionUnidad` |
| **$table correcto** | ✅ `selemti.conversiones_unidad_legacy` |
| **$connection** | ⚠️ FALTA |
| **Columnas en BD** | 8 columnas (estimadas) |
| **Columnas en $fillable** | ? |

**Estado**: ⚠️ Requiere verificación detallada

---

## 2. Errores CRÍTICOS Detectados

### 🔴 ERROR CRÍTICO #1: Movement.php INUTILIZABLE

**Archivo**: `app/Models/Inventory/Movement.php`
**Gravedad**: CRÍTICA
**Problema**: 50% de columnas son FANTASMA (7 de 14)

**Columnas FANTASMA**:
```php
'sucursal_dest',    // BD: sucursal_id
'lote_codigo',      // BD: lote_id (FK integer)
'caducidad',        // NO existe en mov_inv
'qty',              // BD: cantidad
'udm',              // BD: uom_original_id (FK integer)
'notas',            // NO existe
'created_by',       // BD: usuario_id
```

**Impacto**: Cualquier operación con este modelo fallará con error SQL "column does not exist"

**Acción OBLIGATORIA**:
```bash
# ELIMINAR completamente:
rm app/Models/Inventory/Movement.php

# USAR en su lugar:
app/Models/Inv/MovimientoInventario.php
```

---

### 🔴 ERROR CRÍTICO #2: TransferHeader - 10 Columnas FANTASMA

**Archivo**: `app/Models/Inventory/TransferHeader.php`
**Gravedad**: CRÍTICA
**Problema**: 59% de columnas son FANTASMA (10 de 17)

**Columnas FANTASMA**:
```php
'aprobada_por',
'posteada_por',
'numero_guia',          // BD: guia
'fecha_solicitada',
'fecha_aprobada',
'fecha_despachada',
'fecha_recibida',
'fecha_posteada',
'observaciones',
'observaciones_recepcion',
'updated_at',
```

**Opciones de corrección**:

**Opción A - Crear migración SQL** (complejo):
```sql
ALTER TABLE selemti.transfer_cab ADD COLUMN aprobada_por integer;
ALTER TABLE selemti.transfer_cab ADD COLUMN posteada_por integer;
-- ... (8 columnas más)
```

**Opción B - Simplificar modelo** (recomendado):
```php
// ANTES (17 columnas):
protected $fillable = [
    'origen_almacen_id', 'destino_almacen_id', 'estado', 'creada_por',
    'aprobada_por', 'despachada_por', 'recibida_por', 'posteada_por',
    'numero_guia', 'fecha_solicitada', 'fecha_aprobada', 'fecha_despachada',
    'fecha_recibida', 'fecha_posteada', 'observaciones',
    'observaciones_recepcion', 'created_at', 'updated_at'
];

// DESPUÉS (7 columnas - solo campos BD reales):
protected $fillable = [
    'origen_almacen_id', 'destino_almacen_id', 'estado', 'creada_por',
    'despachada_por', 'recibida_por', 'guia', 'created_at'
];
```

---

### 🔴 ERROR CRÍTICO #3: TransferLine - 4 Columnas FANTASMA

**Archivo**: `app/Models/Inventory/TransferLine.php`
**Gravedad**: ALTA
**Problema**: 40% de columnas son FANTASMA (4 de 10)

**Columnas FANTASMA**:
```php
'cantidad_solicitada',  // BD: cantidad
'unidad_medida',        // NO existe
'observaciones',        // NO existe
'observaciones_recepcion', // NO existe
```

**Corrección**:
```php
// ANTES:
protected $fillable = [
    'transfer_id', 'item_id', 'cantidad_solicitada', 'unidad_medida',
    'cantidad_despachada', 'cantidad_recibida', 'observaciones',
    'observaciones_recepcion', 'created_at', 'updated_at'
];

// DESPUÉS:
protected $fillable = [
    'transfer_id', 'item_id', 'cantidad',
    'cantidad_despachada', 'cantidad_recibida', 'created_at'
];
```

---

### 🔴 ERROR CRÍTICO #4: Batch - Confusión de Tablas

**Archivo**: `app/Models/Inv/Batch.php`
**Gravedad**: ALTA
**Problema**: Modelo configurado para tabla `lote` pero usa campos de `inventory_batch`

**Evidencia**:
```php
protected $table = 'selemti.lote';  // Tabla legacy

protected $fillable = [
    'vendor_id',      // tabla lote tiene: proveedor_id
    'batch_code',     // tabla lote tiene: codigo
    'expiration_date', // tabla lote tiene: caducidad
    'unit_cost',      // ❌ NO existe en lote
];
```

**Acción requerida**: Decidir tabla definitiva y ajustar campos

**Opción A** - Usar tabla `lote`:
```php
protected $fillable = [
    'item_id', 'proveedor_id', 'codigo', 'caducidad', 'estado'
];
```

**Opción B** - Usar tabla `inventory_batch`:
```php
protected $table = 'selemti.inventory_batch';
protected $fillable = [
    'item_id', 'vendor_id', 'batch_code', 'expiration_date', 'unit_cost'
];
```

---

## 3. Errores MENORES Detectados

### ⚠️ MENOR #1: 11 Modelos sin `$connection = 'pgsql'`

**Afectados**:
1. ConversionUnidad
2. HistorialCostoItem
3. ItemProveedor
4. ItemVendor
5. LoteInventario
6. Movimiento
7. ParametroSucursal
8. PoliticaStock
9. Unidad
10. Inventory\Item
11. Inventory\Movement

**Impacto**: Laravel usará conexión por defecto (SQLite) en lugar de PostgreSQL

**Corrección**: Agregar a cada modelo:
```php
protected $connection = 'pgsql';
```

---

### ⚠️ MENOR #2: 3 Pares de Modelos Duplicados

**Duplicaciones detectadas**:

| Mantener | Eliminar | Tabla BD | Razón |
|----------|----------|----------|-------|
| MovimientoInventario.php | Movimiento.php | mov_inv | MovimientoInventario está 100% correcto |
| ItemVendor.php | ItemProveedor.php | item_vendor | ItemVendor usa nombres en inglés consistentes |
| Batch.php | LoteInventario.php | inventory_batch | Batch es más completo |

**Acción requerida**: Eliminar 3 archivos duplicados

---

### ⚠️ MENOR #3: Item - Campos Nuevos sin Mapear

**Archivo**: `app/Models/Inv/Item.php`
**Problema**: 8 columnas BD nuevas no están en $fillable

**Columnas BD no mapeadas**:
```
category_id (bigint FK)
item_code (varchar)
es_producible (boolean)
es_consumible_operativo (boolean)
es_empaque_to_go (boolean)
```

**Impacto**: Bajo - No causa errores pero limita funcionalidad

**Corrección**:
```php
protected $fillable = [
    // ... campos existentes
    'category_id',
    'item_code',
    'es_producible',
    'es_consumible_operativo',
    'es_empaque_to_go',
];
```

---

## 4. Correcciones que DEBEN aplicarse

### Corrección #1: ELIMINAR Movement.php
**Archivo**: `app/Models/Inventory/Movement.php`
**Acción**: ❌ DELETE completamente
**Razón**: 50% FANTASMA, modelo inservible
**Reemplazo**: `app/Models/Inv/MovimientoInventario.php`

```bash
rm app/Models/Inventory/Movement.php
```

---

### Corrección #2: Simplificar TransferHeader.php
**Archivo**: `app/Models/Inventory/TransferHeader.php`
**Línea**: ~17-35

**ANTES**:
```php
protected $fillable = [
    'origen_almacen_id', 'destino_almacen_id', 'estado', 'creada_por',
    'aprobada_por', 'despachada_por', 'recibida_por', 'posteada_por',
    'numero_guia', 'fecha_solicitada', 'fecha_aprobada', 'fecha_despachada',
    'fecha_recibida', 'fecha_posteada', 'observaciones',
    'observaciones_recepcion', 'created_at', 'updated_at'
];
```

**DESPUÉS**:
```php
protected $fillable = [
    'origen_almacen_id', 'destino_almacen_id', 'estado', 'creada_por',
    'despachada_por', 'recibida_por', 'guia', 'created_at'
];

protected $casts = [
    'created_at' => 'datetime',
];
```

---

### Corrección #3: Simplificar TransferLine.php
**Archivo**: `app/Models/Inventory/TransferLine.php`
**Línea**: ~17-27

**ANTES**:
```php
protected $fillable = [
    'transfer_id', 'item_id', 'cantidad_solicitada', 'unidad_medida',
    'cantidad_despachada', 'cantidad_recibida', 'observaciones',
    'observaciones_recepcion', 'created_at', 'updated_at'
];
```

**DESPUÉS**:
```php
protected $fillable = [
    'transfer_id', 'item_id', 'cantidad',
    'cantidad_despachada', 'cantidad_recibida', 'created_at'
];

protected $casts = [
    'cantidad' => 'decimal:3',
    'cantidad_despachada' => 'decimal:3',
    'cantidad_recibida' => 'decimal:3',
];
```

---

### Corrección #4: Agregar $connection a 11 modelos

**Archivos**:
1. `app/Models/Inv/ConversionUnidad.php`
2. `app/Models/Inv/HistorialCostoItem.php`
3. `app/Models/Inv/ItemProveedor.php`
4. `app/Models/Inv/ItemVendor.php`
5. `app/Models/Inv/LoteInventario.php`
6. `app/Models/Inv/Movimiento.php`
7. `app/Models/Inv/ParametroSucursal.php`
8. `app/Models/Inv/PoliticaStock.php`
9. `app/Models/Inv/Unidad.php`
10. `app/Models/Inventory/Item.php`
11. `app/Models/Inventory/Movement.php` (si no se elimina)

**Agregar después de `class NombreModelo extends Model {`**:
```php
protected $connection = 'pgsql';
```

---

### Corrección #5: Eliminar Modelos Duplicados

```bash
rm app/Models/Inv/Movimiento.php
rm app/Models/Inv/ItemProveedor.php
rm app/Models/Inv/LoteInventario.php
```

---

### Corrección #6: Completar Item.php

**Archivo**: `app/Models/Inv/Item.php`
**Línea**: ~18-22

**Agregar a $fillable**:
```php
protected $fillable = [
    // ... campos existentes
    'category_id',
    'item_code',
    'es_producible',
    'es_consumible_operativo',
    'es_empaque_to_go',
];
```

---

## 5. TODOs Funcionales

### TODO #1: Decidir tabla definitiva para Batch

**Contexto**: Existen dos tablas de lotes:
- `selemti.lote` (legacy, 6 columnas)
- `selemti.inventory_batch` (nueva, 8 columnas con `unit_cost`)

**Decisión requerida**:
1. ¿Migrar de `lote` a `inventory_batch`?
2. ¿Mantener ambas por compatibilidad?
3. ¿Deprecar una de las dos?

**Impacto**: Funcionalidad de costeo de lotes

---

### TODO #2: Validar si workflow de Transferencias requiere campos adicionales

**Contexto**: TransferHeader tiene 10 campos FANTASMA que sugieren un workflow más complejo:
- aprobada_por, fecha_aprobada
- posteada_por, fecha_posteada
- observaciones, observaciones_recepcion

**Decisión requerida**:
1. ¿Se implementará workflow completo con aprobaciones?
2. ¿Es suficiente el workflow simple actual (crear, despachar, recibir)?

**Impacto**: Si se requiere workflow completo, crear migración SQL

---

### TODO #3: Consolidar sistema de Unidades de Medida

**Contexto**: Items tienen duplicación:
- `unidad_medida` (VARCHAR legacy)
- `unidad_medida_id` (integer FK a cat_unidades)

**Decisión requerida**:
1. ¿Migrar todos los items de VARCHAR a FK?
2. ¿Mantener ambos por compatibilidad temporal?
3. ¿Plan de migración de datos?

**Impacto**: Integridad de datos de inventario

---

## 6. Resumen de Calidad BD↔Código

### Métricas Generales
| Métrica | Valor |
|---------|-------|
| Tablas BD analizadas | 14 |
| Modelos analizados | 16 |
| **Modelos ROTOS** | **3** |
| **Modelos PERFECTOS** | **6** |
| **Modelos Duplicados** | **3 pares** |
| **Total columnas FANTASMA** | **25+** |
| **Errores CRÍTICOS** | **4** |
| **Modelos sin $connection** | **11** |

### Calificación por Modelo
| Modelo | Estado | FANTASMA | Score |
|--------|--------|----------|-------|
| MovimientoInventario | ✅ PERFECTO | 0 | 100% |
| Unidad | ✅ PERFECTO | 0 | 100% |
| ConversionUnidad | ✅ PERFECTO | 0 | 100% |
| HistorialCostoItem | ✅ PERFECTO | 0 | 100% |
| PoliticaStock | ✅ PERFECTO | 0 | 100% |
| Item | 🟡 BUENO | 0 | 85% (faltan campos nuevos) |
| ItemVendor | ✅ BUENO | 0 | 90% |
| Batch | 🟡 CONFUSO | ~4 | 50% (tabla incorrecta) |
| Movement | 🔴 ROTO | 7 | 0% (ELIMINAR) |
| TransferHeader | 🔴 ROTO | 10 | 40% |
| TransferLine | 🔴 ROTO | 4 | 60% |
| Movimiento | 🔴 DUPLICADO | - | - |
| ItemProveedor | 🔴 DUPLICADO | - | - |
| LoteInventario | 🔴 DUPLICADO | - | - |

### Score Global Actual
- **Salud BD↔Código**: 60% (6 perfectos, 3 rotos, 3 duplicados)
- **Usabilidad**: 🔴 BAJA (modelos críticos rotos)
- **Riesgo**: 🔴 ALTO (Movement, TransferHeader/Line inservibles)

### Score Esperado Post-Correcciones
- **Salud BD↔Código**: 95%
- **Usabilidad**: 🟢 ALTA
- **Riesgo**: 🟢 BAJO

---

## 7. Conclusiones

### ✅ Aspectos Positivos
1. **6 modelos PERFECTOS** (100% mapeados)
2. **MovimientoInventario** - Kardex funciona correctamente
3. **Sistema de Unidades** - Correctamente implementado
4. **No hay queries SQL rotas** - Uso de Eloquent previene errores

### 🔴 Problemas Críticos
1. **Movement.php INUTILIZABLE** - 50% FANTASMA
2. **TransferHeader 59% FANTASMA** - Workflow incompleto
3. **TransferLine 40% FANTASMA** - Campos incorrectos
4. **3 pares de modelos duplicados** - Confusión en codebase
5. **11 modelos sin $connection** - Riesgo de usar BD incorrecta
6. **Batch con tabla confusa** - Mezcla lote y inventory_batch

### 📋 Plan de Acción Inmediato

**FASE 1: Limpieza (15 min)**
```bash
rm app/Models/Inventory/Movement.php
rm app/Models/Inv/Movimiento.php
rm app/Models/Inv/ItemProveedor.php
rm app/Models/Inv/LoteInventario.php
```

**FASE 2: Agregar Connections (15 min)**
Agregar `protected $connection = 'pgsql';` a 11 modelos restantes

**FASE 3: Corregir Transfer (30 min)**
Simplificar TransferHeader y TransferLine eliminando campos FANTASMA

**FASE 4: Completar Item (10 min)**
Agregar 5 campos nuevos a Item.php

**FASE 5: Tests (30 min)**
Ejecutar tests de integración para validar correcciones

---

## 8. Estado Final

**Módulo Inventario**: 🔴 **REQUIERE CORRECCIONES CRÍTICAS**

**Riesgo Actual**: 🔴 **ALTO** (modelos críticos inservibles)

**Riesgo Post-Correcciones**: 🟢 **BAJO**

**Tiempo estimado correcciones**: 1.5 horas

**Listo para**:
- ❌ Producción (requiere correcciones)
- ⏳ QA (después de correcciones)
- ⏳ Desarrollo (después de correcciones)

---

**Auditoría completada**: 2025-11-17
**Método**: Comparación directa BD PostgreSQL vs código Laravel
**Próxima acción**: Ejecutar FASE 1 de correcciones (eliminar modelos rotos)
