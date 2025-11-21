# ISSUE-002: ReceptionService - 12 Columnas Fantasma Críticas

**Tipo**: 🔴 BLOCKER
**Épica**: INV-002 (Recepciones State Machine)
**Detectado por**: CLAUDE (Auditoría INV-002-AUDIT)
**Fecha**: 2025-11-20
**Estado**: OPEN
**Asignado a**: CODEX
**Prioridad**: CRÍTICA
**Impacto**: ⚠️ BLOQUEADOR DE PRODUCCIÓN

---

## 1. Resumen

**12 columnas fantasma** detectadas en `ReceptionService.php` que NO EXISTEN en PostgreSQL:

- **5 columnas fantasma** en `inventory_batch`
- **5 columnas fantasma** en `mov_inv`
- **2 columnas con nombres incorrectos**
- **1 valor ENUM inválido**

**Riesgo**: PostgreSQL rechazará todos los posteos de recepciones.

---

## 2. Columnas Fantasma Detalladas

### 2.1 `inventory_batch` (5 errores)

| Columna | Estado | Acción |
|---------|--------|--------|
| `uom_base` | ❌ NO EXISTE | ELIMINAR |
| `caducidad` | ⚠️ Incorrecto | Renombrar a `fecha_caducidad` |
| `sucursal_id` | ❌ NO EXISTE | ELIMINAR |
| `almacen_id` | ❌ NO EXISTE | ELIMINAR |
| `meta` | ❌ NO EXISTE | ELIMINAR |

**Columnas FALTANTES (REQUERIDAS)**:
- `fecha_recepcion` (date NOT NULL)
- `fecha_caducidad` (date NOT NULL)
- `ubicacion_id` (varchar(10) NOT NULL, CHECK 'UBIC-%')

### 2.2 `mov_inv` (7 errores)

| Columna | Estado | Acción |
|---------|--------|--------|
| `tipo => 'RECEPCION'` | 🔴 INVÁLIDO | Cambiar a `'ENTRADA'` |
| `qty` | ❌ NO EXISTE | Renombrar a `cantidad` |
| `uom` | ❌ NO EXISTE | ELIMINAR |
| `almacen_id` | ❌ NO EXISTE | ELIMINAR |
| `user_id` | ⚠️ Incorrecto | Renombrar a `usuario_id` |
| `batch_id` | ⚠️ Incorrecto | Renombrar a `lote_id` |
| `meta` | ❌ NO EXISTE | ELIMINAR |

---

## 3. Código Correcto (Copy-Paste Ready)

### 3.1 Fix `inventory_batch` (líneas 203-218)

```php
// ❌ ANTES (INCORRECTO)
$batchId = DB::table('selemti.inventory_batch')->insertGetId([
    'item_id' => $line->item_id,
    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
    'cantidad_original' => $line->qty,
    'cantidad_actual' => $line->qty,
    'uom_base' => $meta['uom_base'] ?? 'UND',  // ❌
    'caducidad' => $meta['fecha_caducidad'] ?? null,  // ❌
    'estado' => 'ACTIVO',
    'temperatura_recepcion' => $line->temperatura,
    'documento_url' => $line->doc_url,
    'sucursal_id' => $reception->sucursal_id,  // ❌
    'almacen_id' => $reception->almacen_id,    // ❌
    'meta' => $line->meta,                      // ❌
    'created_at' => $now,
    'updated_at' => $now,
]);

// ✅ DESPUÉS (CORRECTO)
$batchId = DB::table('selemti.inventory_batch')->insertGetId([
    'item_id' => $line->item_id,
    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
    'fecha_recepcion' => $reception->fecha_recepcion,  // ✅ REQUERIDO
    'fecha_caducidad' => $meta['fecha_caducidad'] ?? now()->addYear(),  // ✅ REQUERIDO
    'temperatura_recepcion' => $line->temperatura,
    'documento_url' => $line->doc_url,
    'cantidad_original' => $line->qty,
    'cantidad_actual' => $line->qty,
    'estado' => 'ACTIVO',
    'ubicacion_id' => 'UBIC-' . str_pad($reception->almacen_id ?? 1, 5, '0', STR_PAD_LEFT),  // ✅ REQUERIDO
    'unit_cost' => $line->costo_unit ?? 0,
    'created_at' => $now,
    'updated_at' => $now,
]);
```

### 3.2 Fix `mov_inv` (líneas 226-242)

```php
// ❌ ANTES (INCORRECTO)
DB::table('selemti.mov_inv')->insert([
    'item_id' => $line->item_id,
    'tipo' => 'RECEPCION',  // ❌
    'qty' => $line->qty,     // ❌
    'uom' => $meta['uom_base'] ?? 'UND',  // ❌
    'sucursal_id' => $reception->sucursal_id,
    'almacen_id' => $reception->almacen_id,  // ❌
    'ref_tipo' => 'recepcion',
    'ref_id' => $receptionId,
    'user_id' => $userId,   // ❌
    'batch_id' => $batchId, // ❌
    'ts' => $now,
    'meta' => json_encode([...]),  // ❌
]);

// ✅ DESPUÉS (CORRECTO)
DB::table('selemti.mov_inv')->insert([
    'item_id' => $line->item_id,
    'tipo' => 'ENTRADA',  // ✅ VÁLIDO
    'cantidad' => $line->qty,  // ✅ CORRECTO
    'costo_unit' => $line->costo_unit ?? 0,
    'sucursal_id' => (string) $reception->sucursal_id,
    'ref_tipo' => 'recepcion',
    'ref_id' => $receptionId,
    'usuario_id' => $userId,  // ✅ CORRECTO
    'lote_id' => $batchId,    // ✅ CORRECTO
    'ts' => $now,
]);
```

---

## 4. Checklist para CODEX

**Archivo**: `app/Services/Inventory/ReceptionService.php`

- [ ] Corregir `postReception()` líneas 203-218 (inventory_batch)
- [ ] Corregir `postReception()` líneas 226-242 (mov_inv)
- [ ] Agregar manejo de `ubicacion_id` con formato 'UBIC-XXXXX'
- [ ] Validar `fecha_caducidad` siempre tenga valor (default 1 año)
- [ ] Cambiar tipo 'RECEPCION' → 'ENTRADA'
- [ ] Ejecutar tests: `php artisan test tests/Feature/ReceptionStateTest.php`
- [ ] Generar: `DEVLOG_SPRINT1_INV-002-CODEX-FIX.md`

---

## 5. Evidencia

**Estructura Real**:
```sql
-- inventory_batch
\d selemti.inventory_batch
-- Verificado: NO existen uom_base, caducidad, sucursal_id, almacen_id, meta
-- Existen: fecha_recepcion, fecha_caducidad, ubicacion_id (todos NOT NULL)

-- mov_inv
\d selemti.mov_inv
-- CHECK constraint: tipo IN ('ENTRADA','SALIDA','AJUSTE','MERMA','TRASPASO')
-- NO permite 'RECEPCION'
-- Columnas correctas: cantidad, lote_id, usuario_id
```

---

## 6. Impacto

**Sin corrección**:
```
ERROR: column "uom_base" of relation "inventory_batch" does not exist
ERROR: CHECK constraint "mov_inv_tipo_check" violated
ERROR: NOT NULL violation: column "fecha_recepcion"
```

**Módulos bloqueados**:
- ❌ INV-002-QWEN-BD (no puede testear)
- ❌ INV-002-COPILOT-UI (no puede usar servicio roto)
- ❌ Tests (fallarán todos)

---

## 7. Tiempo Estimado

| Tarea | Tiempo | IA |
|-------|--------|-----|
| Fix Backend | 30-45 min | CODEX |
| Migraciones BD | 15 min | QWEN |
| Tests | 30 min | CODEX |

---

## 8. Referencias

- **DEVLOG Auditoría**: `docs/V4.1/Code/Sprint1/DEVLOG_SPRINT1_INV-002-CLAUDE-AUDIT.md`
- **Dump BD**: `database/BD_SCHEMA_SELEMTI.sql`
- **Archivo**: `app/Services/Inventory/ReceptionService.php`

---

**Creado**: 2025-11-20 15:35
**Estado**: ⏳ OPEN (esperando CODEX)
