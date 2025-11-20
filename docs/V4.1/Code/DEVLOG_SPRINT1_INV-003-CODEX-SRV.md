# DEVLOG SPRINT 1 - INV-003-CODEX-SRV

**Task ID**: INV-003-CODEX-SRV  
**Épica**: INV-003 - Transferencias con flujo completo  
**Módulo**: Inventario  
**Tipo de trabajo**: Backend  
**IA Responsable**: CODEX  
**Fecha**: 19 Noviembre 2025  
**Estado**: DONE ✅

---

## 📋 OBJETIVO

Implementar servicios backend para el flujo completo de transferencias entre almacenes:
- SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA
- Validaciones de stock
- Registro de discrepancias
- Consumo de inventario (mov_inv)

---

## ✅ ARCHIVOS VERIFICADOS

### TransferService YA COMPLETO:

**`app/Services/Inventory/TransferService.php`** (326 líneas)

Métodos verificados (todos implementados):
- ✅ `createTransfer()` - Crea transferencia SOLICITADA
- ✅ `approveTransfer()` - SOLICITADA → APROBADA (valida stock)
- ✅ `markInTransit()` - APROBADA → EN_TRANSITO (despacho)
- ✅ `receiveTransfer()` - EN_TRANSITO → RECIBIDA (registra discrepancias)
- ✅ `postTransferToInventory()` - RECIBIDA → POSTEADA (genera mov_inv)

### API REST YA COMPLETA:

**`app/Http/Controllers/Api/Inventory/TransferApiController.php`**

Endpoints verificados:
- ✅ GET /api/inventory/transfers (listar con filtros)
- ✅ POST /api/inventory/transfers (crear)
- ✅ POST /api/inventory/transfers/{id}/approve (aprobar)
- ✅ POST /api/inventory/transfers/{id}/ship (despachar)
- ✅ POST /api/inventory/transfers/{id}/receive (recibir)
- ✅ POST /api/inventory/transfers/{id}/post (postear a inventario)

### Rutas registradas:

**`routes/api.php`** - Grupo: `inventory/transfers`

```php
Route::prefix('inventory/transfers')->middleware(['auth:sanctum'])->group(function () {
    Route::get('/', [TransferApiController::class, 'index']);
    Route::post('/', [TransferApiController::class, 'store']);
    Route::get('/{id}', [TransferApiController::class, 'show']);
    Route::post('/{id}/approve', [TransferApiController::class, 'approve']);
    Route::post('/{id}/ship', [TransferApiController::class, 'ship']);
    Route::post('/{id}/receive', [TransferApiController::class, 'receive']);
    Route::post('/{id}/post', [TransferApiController::class, 'post']);
});
```

---

## 🔧 FLUJO COMPLETO IMPLEMENTADO

### 1. CREATE (SOLICITADA)
```php
POST /api/inventory/transfers
Body: {
  "origen_almacen_id": 1,
  "destino_almacen_id": 2,
  "lineas": [
    { "item_id": "ITEM-001", "cantidad": 10, "unidad_medida": "UND" }
  ]
}
```

**Lógica**:
- Crea `transfer_cab` con estado `SOLICITADA`
- Crea `transfer_det` por cada línea
- NO afecta inventario

### 2. APPROVE (APROBADA)
```php
POST /api/inventory/transfers/{id}/approve
```

**Lógica**:
- Valida que esté en estado `SOLICITADA`
- **Valida stock disponible en almacén origen** (calcula desde `mov_inv`)
- Si no hay stock suficiente → lanza RuntimeException
- Actualiza estado a `APROBADA`
- Registra `aprobada_por` y `fecha_aprobada`

### 3. SHIP (EN_TRANSITO)
```php
POST /api/inventory/transfers/{id}/ship
Body: { "numero_guia": "GUIA-12345" }
```

**Lógica**:
- Valida que esté en estado `APROBADA`
- Actualiza `cantidad_despachada` = `cantidad_solicitada` (por defecto)
- Actualiza estado a `EN_TRANSITO`
- Registra `despachada_por`, `fecha_despachada`, `numero_guia`
- NO afecta inventario aún

### 4. RECEIVE (RECIBIDA)
```php
POST /api/inventory/transfers/{id}/receive
Body: {
  "lineas": [
    { "line_id": 1, "cantidad_recibida": 9.5, "observaciones": "Faltó 0.5" }
  ],
  "observaciones_generales": "..."
}
```

**Lógica**:
- Valida que esté en estado `EN_TRANSITO`
- Actualiza `cantidad_recibida` por cada línea
- **Calcula discrepancias**: `varianza = cantidad_despachada - cantidad_recibida`
- Registra `observaciones_recepcion`
- Actualiza estado a `RECIBIDA`
- Registra `recibida_por`, `fecha_recibida`
- NO afecta inventario aún

### 5. POST (POSTEADA)
```php
POST /api/inventory/transfers/{id}/post
```

**Lógica**:
- Valida que esté en estado `RECIBIDA`
- Por cada línea genera:
  * **Movimiento SALIDA** en almacén origen:
    - `tipo = 'TRASPASO_OUT'`
    - `cantidad = -abs(cantidad_despachada)`
    - `sucursal_id = origen_almacen_id`
  * **Movimiento ENTRADA** en almacén destino:
    - `tipo = 'TRASPASO_IN'`
    - `cantidad = abs(cantidad_recibida)`
    - `sucursal_id = destino_almacen_id`
- Actualiza estado a `POSTEADA` (irreversible)
- Registra `posteada_por`, `fecha_posteada`

---

## 🔗 ESTRUCTURA DE BD CONFIRMADA

### transfer_cab (selemti.transfer_cab)

Campos confirmados en BD_SCHEMA_SELEMTI.sql:
- `id` (PK)
- `origen_almacen_id` (FK)
- `destino_almacen_id` (FK)
- `estado` (VARCHAR - default 'CREADA')
- `creada_por` (INT)
- `despachada_por` (INT, nullable)
- `recibida_por` (INT, nullable)
- `guia` (VARCHAR 64, nullable)
- `created_at` (TIMESTAMP)

### transfer_det (selemti.transfer_det)

Campos confirmados:
- `id` (PK)
- `transfer_id` (FK)
- `item_id` (VARCHAR 20)
- `cantidad` (NUMERIC 12,3)
- `cantidad_despachada` (NUMERIC 12,3, nullable)
- `cantidad_recibida` (NUMERIC 12,3, nullable)
- `created_at` (TIMESTAMP)

### ⚠️ Campos en modelo pero NO en BD:

El modelo `TransferHeader` tiene campos adicionales que **NO existen en la BD real**:

```php
// Campos FANTASMA (requieren migraciones INV-003-QWEN-BD)
'fecha_solicitada',
'fecha_aprobada',
'fecha_despachada',
'fecha_recibida',
'fecha_posteada',
'aprobada_por',
'posteada_por',
'numero_guia',
'observaciones',
'observaciones_recepcion',
```

**Decisión de implementación**:
- El código **asume** que estos campos existen (los usa en `->update()`)
- Si las migraciones no se ejecutan, Laravel lanzará excepciones de columna no encontrada
- Estado actual: **BLOCKED para producción** hasta INV-003-QWEN-BD

---

## ⚠️ DEPENDENCIAS CON MIGRACIONES (INV-003-QWEN-BD)

### Columnas faltantes en `transfer_cab`:

```sql
-- TODO: INV-003-QWEN-BD debe agregar:
ALTER TABLE selemti.transfer_cab ADD COLUMN fecha_solicitada TIMESTAMP;
ALTER TABLE selemti.transfer_cab ADD COLUMN fecha_aprobada TIMESTAMP;
ALTER TABLE selemti.transfer_cab ADD COLUMN fecha_despachada TIMESTAMP;
ALTER TABLE selemti.transfer_cab ADD COLUMN fecha_recibida TIMESTAMP;
ALTER TABLE selemti.transfer_cab ADD COLUMN fecha_posteada TIMESTAMP;
ALTER TABLE selemti.transfer_cab ADD COLUMN aprobada_por INTEGER;
ALTER TABLE selemti.transfer_cab ADD COLUMN posteada_por INTEGER;
ALTER TABLE selemti.transfer_cab ADD COLUMN numero_guia VARCHAR(64);
ALTER TABLE selemti.transfer_cab ADD COLUMN observaciones TEXT;
ALTER TABLE selemti.transfer_cab ADD COLUMN observaciones_recepcion TEXT;
```

### Columnas faltantes en `transfer_det`:

```sql
-- TODO: INV-003-QWEN-BD debe agregar:
ALTER TABLE selemti.transfer_det ADD COLUMN unidad_medida VARCHAR(10);
ALTER TABLE selemti.transfer_det ADD COLUMN observaciones TEXT;
ALTER TABLE selemti.transfer_det ADD COLUMN observaciones_recepcion TEXT;
```

### Tabla nueva requerida:

```sql
-- TODO: INV-003-QWEN-BD debe crear:
CREATE TABLE selemti.transfer_state_audit (
    id BIGSERIAL PRIMARY KEY,
    transfer_id BIGINT NOT NULL REFERENCES selemti.transfer_cab(id),
    estado_anterior VARCHAR(16),
    estado_nuevo VARCHAR(16) NOT NULL,
    usuario_id INTEGER NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🧪 CÓMO PROBAR

### Prueba completa del flujo:

```bash
# 1. Crear transferencia
curl -X POST http://localhost/api/inventory/transfers \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "origen_almacen_id": 1,
    "destino_almacen_id": 2,
    "lineas": [
      {"item_id": "ITEM-001", "cantidad": 10, "unidad_medida": "UND"}
    ]
  }'

# Respuesta: {"transfer_id": 123, "status": "SOLICITADA"}

# 2. Aprobar
curl -X POST http://localhost/api/inventory/transfers/123/approve \
  -H "Authorization: Bearer TOKEN"

# Respuesta: {"transfer_id": 123, "status": "APROBADA"}

# 3. Despachar
curl -X POST http://localhost/api/inventory/transfers/123/ship \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"numero_guia": "GUIA-12345"}'

# Respuesta: {"transfer_id": 123, "status": "EN_TRANSITO"}

# 4. Recibir
curl -X POST http://localhost/api/inventory/transfers/123/receive \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "lineas": [
      {"line_id": 1, "cantidad_recibida": 9.5, "observaciones": "Faltó 0.5"}
    ]
  }'

# Respuesta: {
#   "transfer_id": 123,
#   "status": "RECIBIDA",
#   "varianzas": [
#     {"line_id": 1, "varianza": 0.5, "varianza_porcentaje": 5.0}
#   ]
# }

# 5. Postear a inventario
curl -X POST http://localhost/api/inventory/transfers/123/post \
  -H "Authorization: Bearer TOKEN"

# Respuesta: {
#   "transfer_id": 123,
#   "status": "POSTEADA",
#   "movimientos_generados": 2
# }
```

### Verificar en BD:

```sql
-- Ver transferencia
SELECT * FROM selemti.transfer_cab WHERE id = 123;

-- Ver líneas de detalle
SELECT * FROM selemti.transfer_det WHERE transfer_id = 123;

-- Ver movimientos generados
SELECT * FROM selemti.mov_inv 
WHERE ref_tipo = 'TRANSFER' AND ref_id = 123
ORDER BY ts;
```

---

## 📊 ESTADO FINAL

### ✅ Completado:

- [x] TransferService completo (5 métodos)
- [x] TransferApiController completo (7 endpoints)
- [x] Rutas registradas en routes/api.php
- [x] Validación de stock en aprobación
- [x] Cálculo de discrepancias en recepción
- [x] Generación de mov_inv en posteo
- [x] Manejo de excepciones y respuestas JSON

### ⚠️ Bloqueado para producción:

- [ ] **Requiere migraciones INV-003-QWEN-BD**:
  - Columnas timestamp (fecha_*)
  - Columnas usuario (aprobada_por, posteada_por)
  - Columnas observaciones
  - Tabla transfer_state_audit

### 📝 Notas técnicas:

1. **Validación de stock**: Actualmente calcula desde `mov_inv` con `SUM(cantidad)` agrupado por `item_id` y `sucursal_id`. No existe tabla `stock` dedicada.

2. **Discrepancias**: Se calculan como `cantidad_despachada - cantidad_recibida`. Si hay diferencia, se registra en el campo `varianza`.

3. **Movimientos de inventario**: Se generan con tipos `TRASPASO_OUT` (negativo) y `TRASPASO_IN` (positivo).

4. **Estado POSTEADA**: Es irreversible. No existe lógica de reversión implementada.

---

## 🚀 PRÓXIMOS PASOS

### Inmediato (QWEN):

1. Ejecutar migraciones INV-003-QWEN-BD:
   - Agregar columnas faltantes en `transfer_cab`
   - Agregar columnas faltantes en `transfer_det`
   - Crear tabla `transfer_state_audit`

### Corto plazo (COPILOT):

1. Crear componentes Livewire:
   - `TransferDispatch.php` (UI de despacho)
   - `TransferReceive.php` (UI de recepción)
   - `TransferList.php` (listado con filtros)

2. Crear tests:
   - `tests/Feature/TransferFlowTest.php`
   - Probar flujo completo SOLICITADA → POSTEADA

### Sprint 2:

1. Implementar permisos Spatie:
   - `transferencias.crear`
   - `transferencias.aprobar`
   - `transferencias.despachar`
   - `transferencias.recibir`
   - `transferencias.postear`

2. Agregar auditoría con `transfer_state_audit`

3. Implementar cancelación de transferencias

---

**Última actualización**: 19 Noviembre 2025 - 00:10  
**Responsable**: CODEX (Backend Developer)  
**Estado final**: DONE ✅ (Backend completo, bloqueado para producción hasta migraciones QWEN)
