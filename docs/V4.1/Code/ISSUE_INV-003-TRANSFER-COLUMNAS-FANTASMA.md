# ISSUE-003: TransferService - 22+ Columnas Fantasma Críticas

**Tipo**: 🔴 BLOCKER
**Épica**: INV-003 (Transferencias)
**Detectado por**: CLAUDE (Auditoría INV-003-AUDIT)
**Fecha Detección**: 2025-11-23
**Estado**: OPEN
**Asignado a**: CODEX
**Prioridad**: CRÍTICA
**Impacto**: ⚠️ BLOQUEADOR DE PRODUCCIÓN - PostgreSQL rechazará todos los inserts/updates

---

## 1. Resumen Ejecutivo

Durante la auditoría preventiva `INV-003-AUDIT`, se detectaron **22+ columnas fantasma** en `TransferService.php` y modelos relacionados que NO EXISTEN en la base de datos real PostgreSQL:

- **10 columnas fantasma** en `transfer_cab` (TransferHeader.php)
- **4 columnas fantasma** en `transfer_det` (TransferLine.php)
- **8+ columnas fantasma** en `mov_inv` (Movement.php + TransferService.php)
- **2 valores ENUM inválidos** en mov_inv (CHECK constraint violation)

**Riesgo**: Si se despliega el código actual, **TODOS los flujos de transferencias fallarán** con error SQL.

**Patrón Sistémico Detectado**: El modelo `Movement.php` tiene errores que afectan **MÚLTIPLES ÉPICAS** (INV-002 + INV-003). Es crítico corregirlo una sola vez.

---

## 2. Columnas Fantasma por Tabla

### 2.1 `selemti.transfer_cab` (TransferHeader.php)

**Estructura Real en BD** (verificado con `\d selemti.transfer_cab`):
```
Columnas: 9
- id, origen_almacen_id, destino_almacen_id, estado, creada_por, despachada_por, recibida_por, guia, created_at
```

**Columnas Fantasma en Código** (TransferHeader.php fillable array líneas 34-51):

| Columna Código | Estado | Columna BD Real | Acción Requerida |
|----------------|--------|-----------------|------------------|
| `aprobada_por` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `posteada_por` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `numero_guia` | ⚠️ Nombre incorrecto | `guia` | RENOMBRAR en código |
| `fecha_solicitada` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `fecha_aprobada` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `fecha_despachada` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `fecha_recibida` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `fecha_posteada` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `observaciones` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `observaciones_recepcion` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |

**Total**: 10 columnas fantasma

---

### 2.2 `selemti.transfer_det` (TransferLine.php)

**Estructura Real en BD** (verificado con `\d selemti.transfer_det`):
```
Columnas: 7
- id, transfer_id, item_id, cantidad, cantidad_despachada, cantidad_recibida, created_at
```

**Columnas Fantasma en Código** (TransferLine.php fillable array líneas 22-32):

| Columna Código | Estado | Columna BD Real | Acción Requerida |
|----------------|--------|-----------------|------------------|
| `cantidad_solicitada` | ⚠️ Nombre incorrecto | `cantidad` | RENOMBRAR en código |
| `unidad_medida` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `observaciones` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |
| `observaciones_recepcion` | ❌ NO EXISTE | - | AGREGAR migración o ELIMINAR |

**Total**: 4 columnas (1 rename + 3 inexistentes)

---

### 2.3 `selemti.mov_inv` (Movement.php + TransferService.php)

**Estructura Real en BD** (verificado con `\d selemti.mov_inv`):
```
Columnas: 15
- id, ts, item_id, lote_id, cantidad, qty_original, uom_original_id, costo_unit, tipo, ref_tipo, ref_id, sucursal_id, usuario_id, created_at
- CHECK constraint: tipo IN ('ENTRADA','SALIDA','AJUSTE','MERMA','TRASPASO')
```

**Columnas Fantasma en Movement.php** (fillable array líneas 13-16):

| Columna Código | Estado | Columna BD Real | Acción Requerida |
|----------------|--------|-----------------|------------------|
| `qty` | ❌ NO EXISTE | `cantidad` | RENOMBRAR |
| `udm` | ❌ NO EXISTE | - | ELIMINAR |
| `notas` | ❌ NO EXISTE | - | ELIMINAR |
| `created_by` | ❌ NO EXISTE | `usuario_id` | RENOMBRAR |
| `sucursal_dest` | ❌ NO EXISTE | - | ELIMINAR |
| `lote_codigo` | ❌ NO EXISTE | `lote_id` | RENOMBRAR |
| `caducidad` | ❌ NO EXISTE | - | ELIMINAR |

**Columnas Fantasma en TransferService.php** (método `postTransferToInventory()` líneas 267-292):

| Columna/Valor Código | Estado | Columna/Valor BD Real | Acción Requerida |
|----------------------|--------|----------------------|------------------|
| `unidad_medida` | ❌ NO EXISTE | - | ELIMINAR de líneas 272, 286 |
| `observaciones` | ❌ NO EXISTE | - | ELIMINAR de líneas 277, 291 |
| `tipo => 'TRASPASO_OUT'` | 🔴 VALOR INVÁLIDO | `'TRASPASO'` | Cambiar a `'TRASPASO'` |
| `tipo => 'TRASPASO_IN'` | 🔴 VALOR INVÁLIDO | `'TRASPASO'` | Cambiar a `'TRASPASO'` |

**Total**: 11 errores (7 en Movement.php + 2 columnas + 2 valores ENUM inválidos en TransferService)

---

## 3. Errores CRÍTICOS por Método

### 3.1 `createTransfer()` (líneas 26-66)

**Errores**:
- Línea 46: `fecha_solicitada` ❌
- Línea 47: `observaciones` ❌
- Línea 54: `cantidad_solicitada` ❌ (debe ser `cantidad`)
- Línea 55: `unidad_medida` ❌
- Línea 56: `observaciones` ❌

**Error SQL esperado**:
```sql
ERROR: column "fecha_solicitada" of relation "transfer_cab" does not exist
ERROR: column "cantidad_solicitada" of relation "transfer_det" does not exist
```

---

### 3.2 `postTransferToInventory()` (líneas 251-313) - BLOQUEADOR TOTAL

**Errores CRÍTICOS**:
- Línea 270: `tipo => 'TRASPASO_OUT'` 🔴 CHECK constraint violation
- Línea 272: `unidad_medida` ❌
- Línea 277: `observaciones` ❌
- Línea 284: `tipo => 'TRASPASO_IN'` 🔴 CHECK constraint violation
- Línea 286: `unidad_medida` ❌
- Línea 291: `observaciones` ❌
- Línea 302: `posteada_por` ❌
- Línea 303: `fecha_posteada` ❌

**Error SQL esperado**:
```sql
ERROR: new row for relation "mov_inv" violates check constraint "mov_inv_tipo_check"
DETAIL: Failing row contains (..., TRASPASO_OUT, ...).
```

---

## 4. Código Correcto (Fix Completo)

### 4.1 Corrección `Movement.php`

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

### 4.2 Corrección TransferService.php método `postTransferToInventory()`

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

// ✅ MOVIMIENTO DE ENTRADA (corrección similar)
$movIn = Movement::create([
    'sucursal_id' => (string) $transfer->destino_almacen_id,
    'item_id' => $line->item_id,
    'tipo' => 'TRASPASO',  // ✅ VALOR VÁLIDO
    'cantidad' => abs($line->cantidad_recibida),
    'ts' => now(),
    'usuario_id' => $userId,
    'ref_tipo' => 'TRANSFER_IN',  // ✅ Diferenciar ENTRADA de SALIDA
    'ref_id' => $transfer->id,
]);
```

---

### 4.3 Opciones para transfer_cab/transfer_det

**Opción A** (rápida): Eliminar columnas fantasma del código y trabajar solo con las existentes.

**Opción B** (recomendada): Agregar migraciones para columnas de auditoría:

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

ALTER TABLE selemti.transfer_cab RENAME COLUMN guia TO numero_guia;

-- Migration: 2025_11_23_000002_add_audit_columns_to_transfer_det.php
ALTER TABLE selemti.transfer_det
ADD COLUMN unidad_medida varchar(10),
ADD COLUMN observaciones text,
ADD COLUMN observaciones_recepcion text;

ALTER TABLE selemti.transfer_det RENAME COLUMN cantidad TO cantidad_solicitada;
```

---

## 5. Plan de Corrección

### Tareas Generadas:

#### 5.1 CODEX (Backend Fix) - NUEVA TAREA

**Task_ID**: `INV-003-CODEX-FIX`
**Descripción**: Corregir 22+ columnas fantasma en TransferService + modelos
**Bloqueador**: Este ISSUE
**Prioridad**: CRÍTICA
**Archivos**:
1. `app/Models/Inventory/Movement.php` (CRÍTICO - afecta también INV-002)
2. `app/Models/Inventory/TransferHeader.php`
3. `app/Models/Inventory/TransferLine.php`
4. `app/Services/Inventory/TransferService.php`

**Checklist**:
- [ ] Corregir Movement.php fillable array (CRÍTICO - afecta INV-002 + INV-003)
- [ ] Decidir Opción A (eliminar columnas) o B (agregar migraciones)
- [ ] Corregir TransferService método `createTransfer()` (líneas 41-58)
- [ ] Corregir TransferService método `approveTransfer()` (líneas 115-119)
- [ ] Corregir TransferService método `markInTransit()` (líneas 157-162)
- [ ] Corregir TransferService método `receiveTransfer()` (líneas 206-217)
- [ ] Corregir TransferService método `postTransferToInventory()` (líneas 267-304)
- [ ] Cambiar tipo='TRASPASO_OUT/IN' a tipo='TRASPASO'
- [ ] Ejecutar tests: `php artisan test tests/Feature/TransferWorkflowTest.php`
- [ ] Generar DEVLOG: `DEVLOG_SPRINT1_INV-003-CODEX-FIX.md`

---

#### 5.2 QWEN (Migraciones) - Si se elige Opción B

**Task_ID**: `INV-003-QWEN-BD` (ya existe)
**Descripción**: Agregar columnas de auditoría state machine
**Scripts**:
- `2025_11_23_000001_add_audit_columns_to_transfer_cab.sql`
- `2025_11_23_000002_add_audit_columns_to_transfer_det.sql`

---

## 6. Impacto y Riesgo

### 6.1 Si se Deploy sin Corrección

**Todos los flujos de transferencias fallarán**:
- Crear transferencia → ERROR (fecha_solicitada no existe)
- Aprobar transferencia → ERROR (aprobada_por no existe)
- Despachar transferencia → ERROR (fecha_despachada no existe)
- Recibir transferencia → ERROR (observaciones_recepcion no existe)
- Postear transferencia → ERROR CRÍTICO (CHECK constraint violation tipo='TRASPASO_OUT')

### 6.2 Módulos Bloqueados

❌ **INV-003-CODEX-SRV**: No puede implementarse sin corrección previa
❌ **INV-003-QWEN-BD**: No puede testear migraciones sin backend funcional
❌ **INV-003-COPILOT-UI**: No puede construir UI sobre servicio roto
❌ **Tests**: TransferWorkflowTest fallará en TODOS los casos

---

## 7. Comparación con Otras Auditorías

| Épica | Servicio | Columnas Fantasma | Estado | Issue |
|-------|----------|-------------------|--------|-------|
| INV-002 | ReceptionService | 12 (inventory_batch: 5, mov_inv: 7) | BLOCKED | ISSUE-002 |
| **INV-003** | **TransferService** | **22+ (transfer_cab: 10, transfer_det: 4, mov_inv: 8+)** | **BLOCKED** | **ISSUE-003** |

**Conclusión**: El modelo `Movement.php` tiene errores **transversales** que afectan múltiples épicas. Debe corregirse una sola vez y validar alineación con TODAS las auditorías.

---

## 8. Tiempo Estimado de Corrección

| Tarea | Tiempo | Responsable |
|-------|--------|-------------|
| Fix Movement.php (afecta INV-002+003) | 20 min | CODEX |
| Fix TransferService (5 métodos) | 45 min | CODEX |
| Fix TransferHeader/Line (decidir Opción A/B) | 30 min | CODEX + QWEN |
| Migraciones BD (si Opción B) | 20 min | QWEN |
| Tests (TransferWorkflowTest) | 30 min | CODEX |
| **TOTAL** | **2-2.5 horas** | - |

---

## 9. Referencias

- **DEVLOG Auditoría**: `docs/V4.1/Code/DEVLOG_SPRINT1_INV-003-CLAUDE-AUDIT.md`
- **Estructura BD Real**:
  - `\d selemti.transfer_cab` (9 columnas)
  - `\d selemti.transfer_det` (7 columnas)
  - `\d selemti.mov_inv` (15 columnas, CHECK constraint)
- **Archivos a Corregir**:
  - `app/Models/Inventory/Movement.php`
  - `app/Models/Inventory/TransferHeader.php`
  - `app/Models/Inventory/TransferLine.php`
  - `app/Services/Inventory/TransferService.php`
- **Auditorías Relacionadas**:
  - `DEVLOG_SPRINT1_INV-002-CLAUDE-AUDIT.md`
  - `ISSUE_INV-002-RECEPTION-COLUMNAS-FANTASMA.md`

---

## 10. Criterios de Aceptación (DONE)

Este ISSUE se marca como DONE cuando:

- [x] Auditoría completada (CLAUDE)
- [ ] Movement.php corregido (CODEX)
- [ ] TransferService corregido (CODEX)
- [ ] TransferHeader/Line corregidos (CODEX)
- [ ] Tests pasan exitosamente
- [ ] DEVLOG de corrección generado
- [ ] Migraciones BD ejecutadas (QWEN, si Opción B)
- [ ] UI puede consumir servicio sin errores (COPILOT)

---

**Creado por**: CLAUDE-ORQUESTADOR-V4.1
**Fecha**: 2025-11-23
**Última Actualización**: 2025-11-23 14:50
**Estado**: ⏳ OPEN (esperando corrección CODEX)
