# Validación: Modelos vs Base de Datos

## Validación: TransferHeader (app/Models/Inventory/TransferHeader.php)
**Tabla BD**: `selemti.traspaso_cab`

### ✅ Alineaciones Correctas
- `$table = 'selemti.traspaso_cab'` ✓
- `$fillable` incluye: from_bodega_id, to_bodega_id, estado, usuario_id, validada_por, posteada_por, meta ✓
- `$primaryKey = 'id'` ✓
- `$casts` incluye timestamps ✓

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Relación | origenAlmacen() -> BelongsTo(Almacen::class, 'from_bodega_id') | from_bodega_id → cat_almacenes.id | Alineación correcta |
| Relación | destinoAlmacen() -> BelongsTo(Almacen::class, 'to_bodega_id') | to_bodega_id → cat_almacenes.id | Alineación correcta |
| Relación | usuario() -> BelongsTo(User::class, 'usuario_id') | usuario_id → users.id | Alineación correcta |
| Relación | validadaPor() -> BelongsTo(User::class, 'validada_por') | validada_por → users.id | Alineación correcta |
| Relación | posteadaPor() -> BelongsTo(User::class, 'posteada_por') | posteada_por → users.id | Alineación correcta |

### 🔗 Validación de Relaciones
- `origenAlmacen()` correctly references `from_bodega_id` which maps to `selemti.cat_almacenes.id`
- `destinoAlmacen()` correctly references `to_bodega_id` which maps to `selemti.cat_almacenes.id`
- `usuario()` correctly references `usuario_id` which should map to `users.id`
- `validadaPor()` correctly references `validada_por` which should map to `users.id`
- `posteadaPor()` correctly references `posteada_por` which should map to `users.id`

---

## Validación: TransferLine (app/Models/Inventory/TransferLine.php)
**Tabla BD**: `selemti.traspaso_det`

### ✅ Alineaciones Correctas
- `$table = 'selemti.traspaso_det'` ✓
- `$fillable` incluye: traspaso_id, item_id, qty, um_id, batch_id ✓
- `$primaryKey = 'id'` ✓
- `$casts` incluye qty como decimal ✓

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Relación | header() -> BelongsTo(TransferHeader::class, 'traspaso_id') | traspaso_id → traspaso_cab.id | Alineación correcta |
| Relación | item() -> BelongsTo(Item::class, 'item_id') | item_id → items.id | Alineación correcta |

### 🔗 Validación de Relaciones
- `header()` correctly references `traspaso_id` which maps to `selemti.traspaso_cab.id`
- `item()` correctly references `item_id` which maps to `selemti.items.id`

---

## Validación: MovimientoInventario (app/Models/Inv/MovimientoInventario.php)
**Tabla BD**: `selemti.mov_inv`

### ✅ Alineaciones Correctas
- `$table = 'selemti.mov_inv'` ✓
- `$primaryKey = 'id'` ✓
- `$fillable` incluye todas las columnas insertables ✓
- `$casts` tiene tipos correctos ✓

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Notas | $timestamps = false, pero usa created_at | Columna created_at existe | Se usa created_at en lugar de updated_at |

### 🔗 Validación de Relaciones
- `item()` correctly references `item_id` which maps to `selemti.items.id`
- `lote()` correctly references `lote_id` which maps to `selemti.inventory_batch.id`

---

## Validación: Batch (app/Models/Inv/Batch.php)
**Tabla BD**: `selemti.inventory_batch`

### ✅ Alineaciones Correctas
- `$table = 'selemti.inventory_batch'` ✓
- `$primaryKey = 'id'` ✓
- `$fillable` cubre la mayoría de columnas insertables ✓
- `$casts` tiene tipos correctos ✓

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Columnas faltantes | 'unit_cost' ausente en $fillable | Columna unit_cost existe | Agregar a $fillable |
| Columnas faltantes | 'ubicacion_id' ausente en $fillable | Columna ubicacion_id existe | Agregar a $fillable |

### 🔗 Validación de Relaciones
- `item()` correctly references `item_id` which maps to `selemti.items.id`

---

## Validación: Item (app/Models/Inv/Item.php)
**Tabla BD**: `selemti.items`

### ✅ Alineaciones Correctas
- `$table = 'selemti.items'` ✓
- `$primaryKey = 'id'` ✓
- `$incrementing = false` y `$keyType = 'string'` alineados ✓
- `$fillable` cubre la mayoría de columnas ✓
- `$casts` tiene tipos correctos ✓

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Columnas faltantes | 'item_code' ausente en $fillable | Columna item_code existe | Agregar a $fillable |
| Columnas faltantes | 'es_producible', 'es_consumible_operativo', 'es_empaque_to_go' ausentes en $fillable | Columnas existen | Agregar a $fillable |
| Columnas faltantes | 'category_id' ausente en $fillable | Columna category_id existe | Agregar a $fillable |

### 🔗 Validación de Relaciones
- `uom()` correctly references `unidad_medida_id` which maps to `selemti.cat_unidades.id`
- `uomCompra()` correctly references `unidad_compra_id` which maps to `selemti.cat_unidades.id`
- `uomSalida()` correctly references `unidad_salida_id` which maps to `selemti.cat_unidades.id`
- `unidadCanonico()` correctly references `unidad_medida_id` which maps to `selemti.cat_unidades.id`

---

## Validación: Unidad (app/Models/Catalogs/Unidad.php)
**Tabla BD**: `selemti.cat_unidades`

### ✅ Alineaciones Correctas
- `$table = 'selemti.cat_unidades'` ✓
- `$primaryKey = 'id'` ✓
- `$fillable` cubre columnas insertables ✓
- `$casts` tiene tipos correctos ✓

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Columnas faltantes | 'categoria' ausente en $fillable | Columna categoria no existe en BD | Revisar modelo o BD |

### 🔗 Validación de Relaciones
- Todas las relaciones están correctamente implementadas

---

## Validación: Almacen (app/Models/Catalogs/Almacen.php)
**Tabla BD**: `selemti.cat_almacenes`

### ✅ Alineaciones Correctas
- `$table = 'selemti.cat_almacenes'` ✓
- `$fillable` incluye: clave, nombre, sucursal_id, activo ✓
- `$casts` tiene tipos correctos ✓

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Primary Key | No especificado | Columna id es BIGINT PRIMARY KEY | Alineación correcta, usa default |

### 🔗 Validación de Relaciones
- `sucursal()` correctly references `sucursal_id` which maps to `selemti.cat_sucursales.id`

---

## Validación: Sucursal (app/Models/Catalogs/Sucursal.php)
**Tabla BD**: `selemti.cat_sucursales`

### ✅ Alineaciones Correctas
- `$table = 'selemti.cat_sucursales'` ✓
- `$fillable` incluye columnas insertables ✓
- `$casts` tiene tipos correctos ✓

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Primary Key | No especificado | Columna id es BIGINT PRIMARY KEY | Alineación correcta, usa default |

### 🔗 Validación de Relaciones
- `almacenes()` correctly references `sucursal_id` which maps to `selemti.cat_almacenes.sucursal_id`

---

## Validación: Movimiento (app/Models/Inv/Movimiento.php)
**Tabla BD**: `selemti.mov_inv`

### ⚠️ Advertencia Importante
- `$table = 'mov_inv'` - Falta especificar el esquema 'selemti.'
- `$fillable` está vacío y se usa `$guarded = []`
- Este modelo no coincide completamente con selemti.mov_inv

### ❌ Desalineaciones Encontradas
| Aspecto | En Código | En BD Real | Acción Requerida |
|---------|-----------|------------|------------------|
| Esquema | No especifica 'selemti' | Tabla completa es 'selemti.mov_inv' | Agregar propiedad $connection = 'pgsql' y $table = 'selemti.mov_inv' |
| Columnas | $guarded = [] (todas permitidas) | Columnas específicas en BD | Definir $fillable con columnas específicas |

### 🔗 Validación de Relaciones
- Este modelo carece de relaciones definidas

---

## Notas Importantes

### Sobre recepcion_cab y recepcion_det
No existen modelos Eloquent dedicados para estas tablas. El sistema utiliza directamente el servicio `App\Services\Inventory\ReceptionService` que interactúa con la base de datos mediante consultas `DB::table('selemti.recepcion_cab')` y `DB::table('selemti.recepcion_det')`.

### Sugerencias de Alineación
1. Considerar la creación de modelos Eloquent para recepcion_cab y recepcion_det si se requiere más funcionalidad orientada a objetos
2. Actualizar el modelo Movimiento para que coincida con la estructura real de selemti.mov_inv
3. Añadir las columnas faltantes a los modelos existentes para completar la alineación
4. Verificar la discrepancia en la columna 'categoria' en el modelo Unidad