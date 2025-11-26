# DEVLOG - Sprint 1 - INV-003-AUDIT

**Épica**: INV-003 (Transferencias)
**Task_ID**: INV-003-AUDIT
**Tipo**: Auditoría Preventiva BD ↔ Código
**IA**: CLAUDE
**Fecha**: 2025-11-23
**Estado**: 🔴 BLOCKER CRÍTICO DETECTADO
**Prioridad**: CRÍTICA

---

## 1. Resumen Ejecutivo

Auditoría preventiva de `TransferService.php` y modelos relacionados (`TransferHeader`, `TransferLine`, `Movement`) detectó **22+ columnas fantasma críticas** distribuidas en 3 tablas:

- **transfer_cab**: 10 columnas fantasma
- **transfer_det**: 4 columnas fantasma
- **mov_inv**: 8+ columnas fantasma + 2 valores ENUM inválidos

**Riesgo**: Si se despliega el código actual, **TODOS los flujos de transferencias fallarán** con errores SQL (column does not exist, CHECK constraint violation).

**Impacto**: 🔴 **BLOQUEADOR TOTAL** - La épica INV-003 NO puede avanzar a implementación hasta corregir este código.

---

## 2. Alcance de la Auditoría

### 2.1 Archivos Auditados

| Archivo | Líneas | Propósito |
|---------|--------|-----------|
| `app/Services/Inventory/TransferService.php` | 327 | Lógica de negocio transferencias |
| `app/Models/Inventory/TransferHeader.php` | 140 | Modelo transfer_cab |
| `app/Models/Inventory/TransferLine.php` | 76 | Modelo transfer_det |
| `app/Models/Inventory/Movement.php` | 18 | Modelo mov_inv |

### 2.2 Tablas Validadas en BD Real

```bash
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.transfer_cab"
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.transfer_det"
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.mov_inv"
```

**Timestamp Validación**: 2025-11-23 14:15

---

## 3. Columnas Fantasma Detectadas

### 3.1 `selemti.transfer_cab` (TransferHeader.php)

#### Estructura Real en BD

```sql
-- Verificado con \d selemti.transfer_cab
Columnas:
- id                  bigint         PK, AUTO (nextval('transfer_cab_id_seq'))
- origen_almacen_id   integer        NOT NULL
- destino_almacen_id  integer        NOT NULL
- estado              varchar(16)    NOT NULL DEFAULT 'CREADA'
- creada_por          integer        NOT NULL
- despachada_por      integer
- recibida_por        integer
- guia                varchar(64)
- created_at          timestamp      DEFAULT now()
```

**Total columnas reales**: 9

#### Columnas en Código (fillable array líneas 34-51)

```php
protected $fillable = [
    'origen_almacen_id',        // ✅ EXISTE
    'destino_almacen_id',       // ✅ EXISTE
    'estado',                   // ✅ EXISTE
    'creada_por',               // ✅ EXISTE
    'aprobada_por',             // ❌ NO EXISTE
    'despachada_por',           // ✅ EXISTE
    'recibida_por',             // ✅ EXISTE
    'posteada_por',             // ❌ NO EXISTE
    'numero_guia',              // ❌ NO EXISTE (BD tiene 'guia')
    'fecha_solicitada',         // ❌ NO EXISTE
    'fecha_aprobada',           // ❌ NO EXISTE
    'fecha_despachada',         // ❌ NO EXISTE
    'fecha_recibida',           // ❌ NO EXISTE
    'fecha_posteada',           // ❌ NO EXISTE
    'observaciones',            // ❌ NO EXISTE
    'observaciones_recepcion',  // ❌ NO EXISTE
];
```

#### Resumen de Errores

| Columna Código | Estado | Columna BD Real | Acción Requerida |
|----------------|--------|-----------------|------------------|
| `aprobada_por` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `posteada_por` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `numero_guia` | ⚠️ Nombre incorrecto | `guia` | RENOMBRAR en código |
| `fecha_solicitada` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `fecha_aprobada` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `fecha_despachada` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `fecha_recibida` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `fecha_posteada` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `observaciones` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `observaciones_recepcion` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |

**Total Errores**: 10 columnas fantasma

---

### 3.2 `selemti.transfer_det` (TransferLine.php)

#### Estructura Real en BD

```sql
-- Verificado con \d selemti.transfer_det
Columnas:
- id                  bigint         PK, AUTO
- transfer_id         bigint         FK → transfer_cab(id)
- item_id             varchar(20)    NOT NULL
- cantidad            numeric(12,3)  NOT NULL
- cantidad_despachada numeric(12,3)
- cantidad_recibida   numeric(12,3)
- created_at          timestamp      DEFAULT now()
```

**Total columnas reales**: 7

#### Columnas en Código (fillable array líneas 22-32)

```php
protected $fillable = [
    'transfer_id',           // ✅ EXISTE
    'item_id',               // ✅ EXISTE
    'cantidad_solicitada',   // ❌ NO EXISTE (BD tiene 'cantidad')
    'cantidad_despachada',   // ✅ EXISTE
    'cantidad_recibida',     // ✅ EXISTE
    'unidad_medida',         // ❌ NO EXISTE
    'observaciones',         // ❌ NO EXISTE
    'observaciones_recepcion', // ❌ NO EXISTE
    'created_at',            // ✅ EXISTE
];
```

#### Resumen de Errores

| Columna Código | Estado | Columna BD Real | Acción Requerida |
|----------------|--------|-----------------|------------------|
| `cantidad_solicitada` | ⚠️ Nombre incorrecto | `cantidad` | RENOMBRAR en código |
| `unidad_medida` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `observaciones` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |
| `observaciones_recepcion` | ❌ NO EXISTE | - | ELIMINAR de código o agregar migración |

**Total Errores**: 4 columnas (1 rename + 3 inexistentes)

---

### 3.3 `selemti.mov_inv` (Movement.php + TransferService.php)

#### Estructura Real en BD

```sql
-- Verificado con \d selemti.mov_inv
Columnas:
- id              bigint         PK, AUTO
- ts              timestamp      NOT NULL DEFAULT now()
- item_id         varchar(20)    NOT NULL, FK → items(id)
- lote_id         integer        FK → inventory_batch(id)
- cantidad        numeric(14,6)  NOT NULL
- qty_original    numeric(14,6)
- uom_original_id integer
- costo_unit      numeric(14,6)  DEFAULT 0
- tipo            varchar(20)    NOT NULL
                  CHECK (tipo IN ('ENTRADA','SALIDA','AJUSTE','MERMA','TRASPASO'))
- ref_tipo        varchar(50)
- ref_id          bigint
- sucursal_id     varchar(30)
- usuario_id      integer
- created_at      timestamp      DEFAULT now()
```

**Total columnas reales**: 15

#### Columnas en Código (Movement.php fillable líneas 13-16)

```php
protected $fillable = [
    'ts',            // ✅ EXISTE
    'item_id',       // ✅ EXISTE
    'sucursal_id',   // ✅ EXISTE
    'sucursal_dest', // ❌ NO EXISTE
    'lote_codigo',   // ❌ NO EXISTE (debe ser lote_id)
    'caducidad',     // ❌ NO EXISTE
    'qty',           // ❌ NO EXISTE (debe ser cantidad)
    'udm',           // ❌ NO EXISTE
    'costo_unit',    // ✅ EXISTE
    'tipo',          // ✅ EXISTE
    'ref_tipo',      // ✅ EXISTE
    'ref_id',        // ✅ EXISTE
    'notas',         // ❌ NO EXISTE
    'created_by',    // ❌ NO EXISTE (debe ser usuario_id)
];
```

#### Uso en TransferService.php (líneas 267-292)

**Problema CRÍTICO**: El servicio usa el modelo `Movement` con columnas incorrectas:

```php
// TransferService.php líneas 267-278 (SALIDA en origen)
$movOut = Movement::create([
    'sucursal_id' => $transfer->origen_almacen_id,  // ✅ OK
    'item_id' => $line->item_id,                    // ✅ OK
    'tipo' => 'TRASPASO_OUT',                       // 🔴 VALOR INVÁLIDO (CHECK constraint)
    'cantidad' => -abs($line->cantidad_despachada), // ✅ OK
    'unidad_medida' => $line->unidad_medida,        // ❌ COLUMNA NO EXISTE
    'ts' => now(),                                   // ✅ OK
    'usuario_id' => $userId,                         // ✅ OK
    'ref_tipo' => 'TRANSFER',                        // ✅ OK
    'ref_id' => $transfer->id,                       // ✅ OK
    'observaciones' => "...",                        // ❌ COLUMNA NO EXISTE
]);

// TransferService.php líneas 281-292 (ENTRADA en destino)
$movIn = Movement::create([
    'sucursal_id' => $transfer->destino_almacen_id, // ✅ OK
    'item_id' => $line->item_id,                    // ✅ OK
    'tipo' => 'TRASPASO_IN',                        // 🔴 VALOR INVÁLIDO (CHECK constraint)
    'cantidad' => abs($line->cantidad_recibida),    // ✅ OK
    'unidad_medida' => $line->unidad_medida,        // ❌ COLUMNA NO EXISTE
    'ts' => now(),                                   // ✅ OK
    'usuario_id' => $userId,                         // ✅ OK
    'ref_tipo' => 'TRANSFER',                        // ✅ OK
    'ref_id' => $transfer->id,                       // ✅ OK
    'observaciones' => "...",                        // ❌ COLUMNA NO EXISTE
]);
```

#### Resumen de Errores en mov_inv

| Columna/Valor Código | Estado | Columna/Valor BD Real | Acción Requerida |
|----------------------|--------|----------------------|------------------|
| `qty` | ❌ NO EXISTE | `cantidad` | RENOMBRAR en Movement.php |
| `udm` | ❌ NO EXISTE | - | ELIMINAR (UOM ya está en item) |
| `notas` | ❌ NO EXISTE | - | ELIMINAR |
| `created_by` | ❌ NO EXISTE | `usuario_id` | RENOMBRAR en Movement.php |
| `sucursal_dest` | ❌ NO EXISTE | - | ELIMINAR |
| `lote_codigo` | ❌ NO EXISTE | `lote_id` | RENOMBRAR en Movement.php |
| `caducidad` | ❌ NO EXISTE | - | ELIMINAR |
| `unidad_medida` (en TransferService) | ❌ NO EXISTE | - | ELIMINAR de TransferService líneas 272, 286 |
| `observaciones` (en TransferService) | ❌ NO EXISTE | - | ELIMINAR de TransferService líneas 277, 291 |
| `tipo => 'TRASPASO_OUT'` | 🔴 VALOR INVÁLIDO | `'TRASPASO'` | Cambiar a `'TRASPASO'` (CHECK permite solo: ENTRADA, SALIDA, AJUSTE, MERMA, TRASPASO) |
| `tipo => 'TRASPASO_IN'` | 🔴 VALOR INVÁLIDO | `'TRASPASO'` | Cambiar a `'TRASPASO'` |

**Total Errores**: 11 (7 columnas fantasma en Movement.php + 2 columnas en TransferService + 2 valores ENUM inválidos)

---

## 4. Impacto por Método

### 4.1 `createTransfer()` (líneas 26-66)

**Estado**: ⚠️ BLOQUEADO PARCIAL

**Errores detectados**:
- Línea 41-48: Inserta en `transfer_cab` con 3 columnas fantasma:
  - `fecha_solicitada` ❌
  - `observaciones` ❌
  - (usa `estado` y `creada_por` que SÍ existen ✅)

- Línea 51-58: Inserta en `transfer_det` con 2 columnas fantasma:
  - `cantidad_solicitada` ❌ (debe ser `cantidad`)
  - `unidad_medida` ❌
  - `observaciones` ❌

**Error esperado al ejecutar**:
```sql
ERROR: column "fecha_solicitada" of relation "transfer_cab" does not exist
ERROR: column "cantidad_solicitada" of relation "transfer_det" does not exist
ERROR: column "unidad_medida" of relation "transfer_det" does not exist
```

---

### 4.2 `approveTransfer()` (líneas 78-126)

**Estado**: ⚠️ BLOQUEADO PARCIAL

**Errores detectados**:
- Línea 115-119: Actualiza con 2 columnas fantasma:
  - `aprobada_por` ❌
  - `fecha_aprobada` ❌

**Error esperado**:
```sql
ERROR: column "aprobada_por" of relation "transfer_cab" does not exist
ERROR: column "fecha_aprobada" of relation "transfer_cab" does not exist
```

---

### 4.3 `markInTransit()` (líneas 138-170)

**Estado**: ⚠️ BLOQUEADO PARCIAL

**Errores detectados**:
- Línea 157-162: Actualiza con 3 columnas fantasma:
  - `fecha_despachada` ❌
  - `numero_guia` ❌ (debe ser `guia`)

**Error esperado**:
```sql
ERROR: column "fecha_despachada" of relation "transfer_cab" does not exist
ERROR: column "numero_guia" of relation "transfer_cab" does not exist
```

---

### 4.4 `receiveTransfer()` (líneas 182-239)

**Estado**: ⚠️ BLOQUEADO PARCIAL

**Errores detectados**:
- Línea 206-209: Actualiza línea con columna fantasma:
  - `observaciones_recepcion` ❌

- Línea 212-217: Actualiza cabecera con 2 columnas fantasma:
  - `fecha_recibida` ❌
  - `observaciones_recepcion` ❌

**Error esperado**:
```sql
ERROR: column "observaciones_recepcion" of relation "transfer_det" does not exist
ERROR: column "fecha_recibida" of relation "transfer_cab" does not exist
```

---

### 4.5 `postTransferToInventory()` (líneas 251-313)

**Estado**: 🔴 BLOQUEADO TOTAL

**Errores CRÍTICOS detectados**:
- Línea 267-278: Crea movimiento SALIDA con 3 errores:
  - `tipo => 'TRASPASO_OUT'` 🔴 Valor inválido (CHECK constraint violation)
  - `unidad_medida` ❌ Columna no existe
  - `observaciones` ❌ Columna no existe

- Línea 281-292: Crea movimiento ENTRADA con 3 errores:
  - `tipo => 'TRASPASO_IN'` 🔴 Valor inválido (CHECK constraint violation)
  - `unidad_medida` ❌ Columna no existe
  - `observaciones` ❌ Columna no existe

- Línea 300-304: Actualiza cabecera con 2 columnas fantasma:
  - `posteada_por` ❌
  - `fecha_posteada` ❌

**Errores esperados**:
```sql
ERROR: new row for relation "mov_inv" violates check constraint "mov_inv_tipo_check"
DETAIL: Failing row contains (..., TRASPASO_OUT, ...).

ERROR: column "unidad_medida" of relation "mov_inv" does not exist
ERROR: column "observaciones" of relation "mov_inv" does not exist
ERROR: column "posteada_por" of relation "transfer_cab" does not exist
ERROR: column "fecha_posteada" of relation "transfer_cab" does not exist
```

---

## 5. Código Correcto (Fix Completo)

### 5.1 Corrección `Movement.php`

```php
// ❌ ANTES (INCORRECTO)
protected $fillable = [
    'ts', 'item_id', 'sucursal_id', 'sucursal_dest', 'lote_codigo', 'caducidad',
    'qty', 'udm', 'costo_unit', 'tipo', 'ref_tipo', 'ref_id', 'notas', 'created_by',
];

// ✅ DESPUÉS (CORRECTO - alineado con BD real)
protected $connection = 'pgsql';

protected $fillable = [
    'ts',
    'item_id',
    'lote_id',          // ✅ NO lote_codigo
    'cantidad',         // ✅ NO qty
    'qty_original',
    'uom_original_id',
    'costo_unit',
    'tipo',
    'ref_tipo',
    'ref_id',
    'sucursal_id',
    'usuario_id',       // ✅ NO created_by
    'created_at',
];
```

---

### 5.2 Corrección `TransferHeader.php`

**Opción A**: Eliminar columnas fantasma y usar solo las que existen en BD

```php
// ✅ OPCIÓN A: Usar solo columnas existentes
protected $fillable = [
    'origen_almacen_id',
    'destino_almacen_id',
    'estado',
    'creada_por',
    'despachada_por',
    'recibida_por',
    'guia',  // ✅ NO numero_guia
];
```

**Opción B**: Agregar migraciones para columnas de auditoría (RECOMENDADO)

```sql
-- Migration: 2025_11_23_000001_add_audit_columns_to_transfer_cab.php
ALTER TABLE selemti.transfer_cab
ADD COLUMN aprobada_por integer REFERENCES selemti.users(id),
ADD COLUMN posteada_por integer REFERENCES selemti.users(id),
ADD COLUMN fecha_solicitada timestamp,
ADD COLUMN fecha_aprobada timestamp,
ADD COLUMN fecha_despachada timestamp,
ADD COLUMN fecha_recibida timestamp,
ADD COLUMN fecha_posteada timestamp,
ADD COLUMN observaciones text,
ADD COLUMN observaciones_recepcion text;

-- Renombrar 'guia' a 'numero_guia' para consistencia
ALTER TABLE selemti.transfer_cab RENAME COLUMN guia TO numero_guia;
```

---

### 5.3 Corrección `TransferLine.php`

**Opción A**: Eliminar columnas fantasma

```php
// ✅ OPCIÓN A: Usar solo columnas existentes
protected $fillable = [
    'transfer_id',
    'item_id',
    'cantidad',  // ✅ NO cantidad_solicitada
    'cantidad_despachada',
    'cantidad_recibida',
    'created_at',
];
```

**Opción B**: Agregar migraciones (RECOMENDADO)

```sql
-- Migration: 2025_11_23_000002_add_audit_columns_to_transfer_det.php
ALTER TABLE selemti.transfer_det
ADD COLUMN unidad_medida varchar(10),
ADD COLUMN observaciones text,
ADD COLUMN observaciones_recepcion text;

-- Renombrar 'cantidad' a 'cantidad_solicitada'
ALTER TABLE selemti.transfer_det RENAME COLUMN cantidad TO cantidad_solicitada;
```

---

### 5.4 Corrección `TransferService.php` método `postTransferToInventory()`

```php
// ❌ ANTES (INCORRECTO - líneas 267-278)
$movOut = Movement::create([
    'sucursal_id' => $transfer->origen_almacen_id,
    'item_id' => $line->item_id,
    'tipo' => 'TRASPASO_OUT',  // ❌ VALOR INVÁLIDO
    'cantidad' => -abs($line->cantidad_despachada),
    'unidad_medida' => $line->unidad_medida,  // ❌ COLUMNA NO EXISTE
    'ts' => now(),
    'usuario_id' => $userId,
    'ref_tipo' => 'TRANSFER',
    'ref_id' => $transfer->id,
    'observaciones' => "Transferencia #{$transfer->id} a {$transfer->destinoAlmacen->nombre}",  // ❌ COLUMNA NO EXISTE
]);

// ✅ DESPUÉS (CORRECTO)
$movOut = Movement::create([
    'sucursal_id' => (string) $transfer->origen_almacen_id,  // ✅ Cast a varchar(30)
    'item_id' => $line->item_id,
    'tipo' => 'TRASPASO',  // ✅ VALOR VÁLIDO (CHECK constraint OK)
    'cantidad' => -abs($line->cantidad_despachada),
    'ts' => now(),
    'usuario_id' => $userId,
    'ref_tipo' => 'TRANSFER_OUT',  // ✅ Diferenciar SALIDA/ENTRADA en ref_tipo
    'ref_id' => $transfer->id,
    // ✅ NO hay columna observaciones - eliminar
    // ✅ NO hay columna unidad_medida - eliminar
]);

// ❌ ANTES (INCORRECTO - líneas 281-292)
$movIn = Movement::create([
    'sucursal_id' => $transfer->destino_almacen_id,
    'item_id' => $line->item_id,
    'tipo' => 'TRASPASO_IN',  // ❌ VALOR INVÁLIDO
    'cantidad' => abs($line->cantidad_recibida),
    'unidad_medida' => $line->unidad_medida,  // ❌ COLUMNA NO EXISTE
    'ts' => now(),
    'usuario_id' => $userId,
    'ref_tipo' => 'TRANSFER',
    'ref_id' => $transfer->id,
    'observaciones' => "Transferencia #{$transfer->id} desde {$transfer->origenAlmacen->nombre}",  // ❌ COLUMNA NO EXISTE
]);

// ✅ DESPUÉS (CORRECTO)
$movIn = Movement::create([
    'sucursal_id' => (string) $transfer->destino_almacen_id,  // ✅ Cast a varchar(30)
    'item_id' => $line->item_id,
    'tipo' => 'TRASPASO',  // ✅ VALOR VÁLIDO
    'cantidad' => abs($line->cantidad_recibida),
    'ts' => now(),
    'usuario_id' => $userId,
    'ref_tipo' => 'TRANSFER_IN',  // ✅ Diferenciar ENTRADA de SALIDA
    'ref_id' => $transfer->id,
    // ✅ NO hay columna observaciones - eliminar
    // ✅ NO hay columna unidad_medida - eliminar
]);
```

---

## 6. Comparación con Auditoría INV-002 (ReceptionService)

Esta auditoría revela un **patrón sistémico** de columnas fantasma en el proyecto:

| Épica | Servicio | Columnas Fantasma | Estado | Issue |
|-------|----------|-------------------|--------|-------|
| INV-002 | ReceptionService | 12 (inventory_batch: 5, mov_inv: 7) | BLOCKED | ISSUE-002 |
| **INV-003** | **TransferService** | **22+ (transfer_cab: 10, transfer_det: 4, mov_inv: 8+)** | **BLOCKED** | **Este DEVLOG** |

**Conclusión**: El modelo `Movement.php` tiene errores **transversales** que afectan múltiples épicas. Es crítico corregirlo **una sola vez** y validar que todas las auditorías se alineen.

---

## 7. Recomendaciones

### 7.1 Prioridad 1 - CRÍTICO

1. **Corregir Movement.php** (afecta INV-002 + INV-003):
   - Renombrar `qty` → `cantidad`
   - Renombrar `created_by` → `usuario_id`
   - Renombrar `lote_codigo` → `lote_id`
   - Eliminar: `udm`, `notas`, `sucursal_dest`, `caducidad`
   - Agregar `$connection = 'pgsql'`

2. **Decidir estrategia para transfer_cab/transfer_det**:
   - **Opción A** (rápida): Eliminar columnas fantasma del código
   - **Opción B** (completa): Agregar migraciones para columnas de auditoría

### 7.2 Prioridad 2 - ALTA

3. **Corregir valores ENUM en TransferService**:
   - Cambiar `TRASPASO_OUT` → `TRASPASO`
   - Cambiar `TRASPASO_IN` → `TRASPASO`
   - Usar `ref_tipo` para diferenciar: `TRANSFER_OUT` vs `TRANSFER_IN`

4. **Eliminar columnas inexistentes de TransferService**:
   - Quitar `unidad_medida` de líneas 272, 286
   - Quitar `observaciones` de líneas 277, 291

### 7.3 Prioridad 3 - MEDIA

5. **Agregar tests preventivos**:
   - Test que inserte un transfer completo (SOLICITADA → POSTEADA)
   - Validar que NO fallan con errores SQL
   - Test que verifique mov_inv se crea con tipo='TRASPASO'

6. **Documentar cambios en QWEN**:
   - Si se elige Opción B (migraciones), crear:
     - `INV-003-QWEN-BD-MIGRACIONES.md`
     - Scripts SQL validados contra BD real

---

## 8. Bloqueadores Generados

Esta auditoría genera 3 bloqueadores:

### 8.1 BLOQUEADOR para CODEX

**Task_ID**: `INV-003-CODEX-FIX` (CREAR NUEVA TAREA)

**Descripción**: Corregir 22+ columnas fantasma en TransferService + modelos

**Archivos a modificar**:
1. `app/Models/Inventory/Movement.php` (CRÍTICO - afecta también INV-002)
2. `app/Models/Inventory/TransferHeader.php`
3. `app/Models/Inventory/TransferLine.php`
4. `app/Services/Inventory/TransferService.php`

**Checklist**:
- [ ] Corregir Movement.php (fillable array)
- [ ] Decidir Opción A o B para transfer_cab/transfer_det
- [ ] Corregir TransferService método `createTransfer()` (líneas 41-58)
- [ ] Corregir TransferService método `approveTransfer()` (líneas 115-119)
- [ ] Corregir TransferService método `markInTransit()` (líneas 157-162)
- [ ] Corregir TransferService método `receiveTransfer()` (líneas 206-217)
- [ ] Corregir TransferService método `postTransferToInventory()` (líneas 267-304)
- [ ] Cambiar tipo='TRASPASO_OUT/IN' a tipo='TRASPASO'
- [ ] Ejecutar tests: `php artisan test tests/Feature/TransferWorkflowTest.php`
- [ ] Generar DEVLOG: `DEVLOG_SPRINT1_INV-003-CODEX-FIX.md`

---

### 8.2 BLOQUEADOR para QWEN (si se elige Opción B)

**Task_ID**: `INV-003-QWEN-BD` (ACTUALIZAR TAREA EXISTENTE)

**Descripción**: Migraciones para columnas de auditoría en transfer_cab/transfer_det

**Scripts SQL**:
1. `2025_11_23_000001_add_audit_columns_to_transfer_cab.sql`
2. `2025_11_23_000002_add_audit_columns_to_transfer_det.sql`

**Columnas a agregar**:
- Ver sección 5.2 y 5.3 de este DEVLOG

---

### 8.3 BLOQUEADOR para COPILOT

**Task_ID**: `INV-003-COPILOT-UI` (ACTUALIZAR TAREA EXISTENTE)

**Estado**: BLOCKED hasta que CODEX termine `INV-003-CODEX-FIX`

**Nota**: No puede construir UI sobre servicio roto.

---

## 9. Criterios de Aceptación (DONE)

Esta auditoría se marca como DONE cuando:

- [x] Código fuente completo leído
- [x] Estructura BD real verificada (psql)
- [x] Columnas fantasma identificadas (22+)
- [x] Comparación BD ↔ Código documentada
- [x] Código correcto propuesto (sección 5)
- [x] ISSUE generado para CODEX
- [x] Bloqueadores documentados
- [x] DEVLOG creado
- [ ] MASTER_SPRINT1_STATUS_V2.md actualizado (siguiente paso)

---

## 10. Evidencia de Validación

### 10.1 Queries Ejecutadas

```bash
# Verificar estructura transfer_cab
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.transfer_cab"

# Resultado:
# - 9 columnas reales
# - 10 columnas del código NO EXISTEN

# Verificar estructura transfer_det
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.transfer_det"

# Resultado:
# - 7 columnas reales
# - 4 columnas del código NO EXISTEN o tienen nombre incorrecto

# Verificar estructura mov_inv
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.mov_inv"

# Resultado:
# - 15 columnas reales
# - CHECK constraint: tipo IN ('ENTRADA','SALIDA','AJUSTE','MERMA','TRASPASO')
# - 'TRASPASO_OUT' y 'TRASPASO_IN' NO son válidos
```

---

## 11. Referencias

- **Código Auditado**:
  - `app/Services/Inventory/TransferService.php`
  - `app/Models/Inventory/TransferHeader.php`
  - `app/Models/Inventory/TransferLine.php`
  - `app/Models/Inventory/Movement.php`

- **BD Real**:
  - `selemti.transfer_cab` (9 columnas)
  - `selemti.transfer_det` (7 columnas)
  - `selemti.mov_inv` (15 columnas)

- **Orquestador**:
  - `MASTER_SPRINT1_STATUS_V2.md` (línea 67: INV-003-CODEX-SRV PENDING)
  - `PLAN_SPRINT1_IMPLEMENTACION.md` (Épica 4: INV-003)

- **Auditorías Relacionadas**:
  - `DEVLOG_SPRINT1_INV-002-CLAUDE-AUDIT.md` (12 columnas fantasma en ReceptionService)
  - `ISSUE_INV-002-RECEPTION-COLUMNAS-FANTASMA.md`

---

**Creado por**: CLAUDE-WORKER-V4.1
**Fecha**: 2025-11-23
**Última Actualización**: 2025-11-23 14:45
**Estado**: ✅ AUDIT DONE - BLOQUEADOR CRÍTICO DETECTADO
