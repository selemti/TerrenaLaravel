# ISSUE-002: ReceptionService - 12 Columnas Fantasma Críticas

**Tipo**: 🔴 BLOCKER
**Épica**: INV-002 (Recepciones State Machine)
**Detectado por**: CLAUDE (Auditoría INV-002-AUDIT)
**Fecha Detección**: 2025-11-20
**Estado**: OPEN
**Asignado a**: CODEX
**Prioridad**: CRÍTICA
**Impacto**: ⚠️ BLOQUEADOR DE PRODUCCIÓN - PostgreSQL rechazará todos los inserts

---

## 1. Resumen Ejecutivo

Durante la auditoría `INV-002-AUDIT`, se detectaron **12 columnas fantasma** en `ReceptionService.php` que NO EXISTEN en la base de datos real PostgreSQL:

- **5 columnas fantasma** en `inventory_batch`
- **5 columnas fantasma** en `mov_inv`
- **2 columnas con nombres incorrectos**
- **1 valor de ENUM inválido** (constraint violation)

**Riesgo**: Si se despliega el código actual, TODOS los posteos de recepciones fallarán con error SQL.

---

## 2. Columnas Fantasma por Tabla

### 2.1 `selemti.inventory_batch`

**Método afectado**: `postReception()` (líneas 203-218)

| Columna en Código | Estado | Acción Requerida |
|-------------------|--------|------------------|
| `uom_base` | ❌ NO EXISTE | ELIMINAR |
| `caducidad` | ⚠️ Nombre incorrecto | RENOMBRAR a `fecha_caducidad` |
| `sucursal_id` | ❌ NO EXISTE | ELIMINAR |
| `almacen_id` | ❌ NO EXISTE | ELIMINAR |
| `meta` | ❌ NO EXISTE | ELIMINAR |

**Columnas FALTANTES (REQUERIDAS en BD)**:
| Columna BD | Tipo | Constraint | Acción |
|------------|------|------------|--------|
| `fecha_recepcion` | date | NOT NULL | AGREGAR |
| `fecha_caducidad` | date | NOT NULL | AGREGAR (renombrar desde `caducidad`) |
| `ubicacion_id` | varchar(10) | NOT NULL, CHECK 'UBIC-%' | AGREGAR |

---

### 2.2 `selemti.mov_inv`

**Método afectado**: `postReception()` (líneas 226-242)

| Columna en Código | Estado | Columna BD Real | Acción Requerida |
|-------------------|--------|-----------------|------------------|
| `tipo => 'RECEPCION'` | 🔴 VALOR INVÁLIDO | CHECK constraint: ENTRADA\|SALIDA\|AJUSTE\|MERMA\|TRASPASO | Cambiar a `'ENTRADA'` |
| `qty` | ❌ NO EXISTE | `cantidad` | RENOMBRAR |
| `uom` | ❌ NO EXISTE | - | ELIMINAR |
| `almacen_id` | ❌ NO EXISTE | - | ELIMINAR |
| `user_id` | ⚠️ Nombre incorrecto | `usuario_id` | RENOMBRAR |
| `batch_id` | ⚠️ Nombre incorrecto | `lote_id` | RENOMBRAR |
| `meta` | ❌ NO EXISTE | - | ELIMINAR |

---

### 2.3 Método Legacy `createReception()` (líneas 271-373)

**Estado**: DEPRECATED pero aún presente en código

**Columnas fantasma adicionales**:
- `recepcion_det`: 8 columnas que NO EXISTEN (`inventory_batch_id`, `lote_proveedor`, `fecha_caducidad`, `qty_presentacion`, `qty_recibida`, `pack_size`, `uom_compra`, `qty_canonica`, `uom_base`, `precio_unit`)
- `recepcion_cab`: `creado_por` (debe ser `usuario_id`)
- `mov_inv`: `inventory_batch_id`, `meta`

**Recomendación**: ELIMINAR método completo y forzar uso de state machine.

---

## 3. Código Correcto (Fix Completo)

### 3.1 Corrección `inventory_batch` (líneas 203-218)

```php
// ❌ ANTES (INCORRECTO - 12 ERRORES)
$batchId = DB::table('selemti.inventory_batch')->insertGetId([
    'item_id' => $line->item_id,
    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
    'cantidad_original' => $line->qty,
    'cantidad_actual' => $line->qty,
    'uom_base' => $meta['uom_base'] ?? 'UND',  // ❌ COLUMNA NO EXISTE
    'caducidad' => $meta['fecha_caducidad'] ?? null,  // ❌ NOMBRE INCORRECTO + NULL INVÁLIDO
    'estado' => 'ACTIVO',
    'temperatura_recepcion' => $line->temperatura,
    'documento_url' => $line->doc_url,
    'sucursal_id' => $reception->sucursal_id,  // ❌ COLUMNA NO EXISTE
    'almacen_id' => $reception->almacen_id,    // ❌ COLUMNA NO EXISTE
    'meta' => $line->meta,                      // ❌ COLUMNA NO EXISTE
    'created_at' => $now,
    'updated_at' => $now,
]);

// ✅ DESPUÉS (CORRECTO)
$batchId = DB::table('selemti.inventory_batch')->insertGetId([
    'item_id' => $line->item_id,
    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
    'fecha_recepcion' => $reception->fecha_recepcion,  // ✅ REQUERIDO
    'fecha_caducidad' => $meta['fecha_caducidad'] ?? now()->addYear(),  // ✅ REQUERIDO (default 1 año)
    'temperatura_recepcion' => $line->temperatura,
    'documento_url' => $line->doc_url,
    'cantidad_original' => $line->qty,
    'cantidad_actual' => $line->qty,
    'estado' => 'ACTIVO',
    'ubicacion_id' => 'UBIC-' . str_pad($reception->almacen_id ?? 1, 5, '0', STR_PAD_LEFT),  // ✅ REQUERIDO (formato: UBIC-00001)
    'unit_cost' => $line->costo_unit ?? 0,  // ✅ AGREGAR (numeric(12,4) DEFAULT 0)
    'created_at' => $now,
    'updated_at' => $now,
]);
```

---

### 3.2 Corrección `mov_inv` (líneas 226-242)

```php
// ❌ ANTES (INCORRECTO - 7 ERRORES)
DB::table('selemti.mov_inv')->insert([
    'item_id' => $line->item_id,
    'tipo' => 'RECEPCION',  // ❌ VALOR INVÁLIDO (constraint violation)
    'qty' => $line->qty,     // ❌ COLUMNA NO EXISTE
    'uom' => $meta['uom_base'] ?? 'UND',  // ❌ COLUMNA NO EXISTE
    'sucursal_id' => $reception->sucursal_id,
    'almacen_id' => $reception->almacen_id,  // ❌ COLUMNA NO EXISTE
    'ref_tipo' => 'recepcion',
    'ref_id' => $receptionId,
    'user_id' => $userId,   // ❌ COLUMNA NO EXISTE (debe ser usuario_id)
    'batch_id' => $batchId, // ❌ COLUMNA NO EXISTE (debe ser lote_id)
    'ts' => $now,
    'meta' => json_encode([  // ❌ COLUMNA NO EXISTE
        'temperatura' => $line->temperatura,
        'costo_unit' => $line->costo_unit,
    ]),
]);

// ✅ DESPUÉS (CORRECTO)
DB::table('selemti.mov_inv')->insert([
    'item_id' => $line->item_id,
    'tipo' => 'ENTRADA',  // ✅ VALOR VÁLIDO (CHECK constraint OK)
    'cantidad' => $line->qty,  // ✅ COLUMNA CORRECTA (numeric(14,6))
    'costo_unit' => $line->costo_unit ?? 0,  // ✅ AGREGAR (usado para cálculo costo promedio)
    'sucursal_id' => (string) $reception->sucursal_id,  // ✅ Cast a varchar(30)
    'ref_tipo' => 'recepcion',
    'ref_id' => $receptionId,
    'usuario_id' => $userId,  // ✅ COLUMNA CORRECTA
    'lote_id' => $batchId,    // ✅ COLUMNA CORRECTA (FK → inventory_batch.id)
    'ts' => $now,
    // ✅ NO hay columna meta - eliminar
]);
```

---

## 4. Evidencia de Validación

### 4.1 Estructura Real de `inventory_batch`

```sql
-- Verificado contra BD real (psql)
\d selemti.inventory_batch

Columnas:
- id                    integer      PK, AUTO
- item_id               varchar(20)  NOT NULL, FK → items(id)
- lote_proveedor        varchar(50)  NOT NULL
- fecha_recepcion       date         NOT NULL  ← FALTANTE EN CÓDIGO
- fecha_caducidad       date         NOT NULL  ← FALTANTE EN CÓDIGO
- temperatura_recepcion numeric(5,2)
- documento_url         varchar(255)
- cantidad_original     numeric(10,3) NOT NULL
- cantidad_actual       numeric(10,3) NOT NULL
- estado                varchar(20)  DEFAULT 'ACTIVO'
- ubicacion_id          varchar(10)  NOT NULL  ← FALTANTE EN CÓDIGO (CHECK: 'UBIC-%')
- created_at            timestamp    DEFAULT now()
- updated_at            timestamp    DEFAULT now()
- unit_cost             numeric(12,4) NOT NULL DEFAULT 0

NO EXISTEN: uom_base, caducidad, sucursal_id, almacen_id, meta
```

### 4.2 Estructura Real de `mov_inv`

```sql
-- Verificado contra BD real (psql)
\d selemti.mov_inv

Columnas:
- id              bigint        PK, AUTO
- ts              timestamp     NOT NULL, DEFAULT now()
- item_id         varchar(20)   NOT NULL, FK → items(id)
- lote_id         integer       FK → inventory_batch(id)  ← NO batch_id
- cantidad        numeric(14,6) NOT NULL  ← NO qty
- qty_original    numeric(14,6)
- uom_original_id integer
- costo_unit      numeric(14,6) DEFAULT 0
- tipo            varchar(20)   NOT NULL
                  CHECK (tipo IN ('ENTRADA','SALIDA','AJUSTE','MERMA','TRASPASO'))
                  ← 'RECEPCION' NO ES VÁLIDO
- ref_tipo        varchar(50)
- ref_id          bigint
- sucursal_id     varchar(30)
- usuario_id      integer       ← NO user_id
- created_at      timestamp     DEFAULT now()

NO EXISTEN: qty, uom, almacen_id, user_id, batch_id, meta
```

---

## 5. Impacto y Riesgo

### 5.1 Si se Deploy sin Corrección

**Error esperado al intentar postear una recepción**:
```sql
ERROR: column "uom_base" of relation "inventory_batch" does not exist
LINE 1: INSERT INTO selemti.inventory_batch (item_id, lote_proveedo...
                                              ^
```

**Otros errores**:
- `CHECK constraint "mov_inv_tipo_check" violated` (tipo='RECEPCION')
- `NOT NULL violation: column "fecha_recepcion" violates not-null constraint`
- `NOT NULL violation: column "ubicacion_id" violates not-null constraint`

### 5.2 Módulos Bloqueados

❌ **INV-002-QWEN-BD**: No puede testear migraciones sin backend funcional
❌ **INV-002-COPILOT-UI**: No puede construir UI sobre servicio roto
❌ **Tests**: ReceptionStateTest fallará en TODOS los casos

---

## 6. Plan de Corrección

### Tareas Generadas:

#### 6.1 CODEX (Backend Fix) - NUEVA TAREA
**Task_ID**: `INV-002-CODEX-FIX`
**Descripción**: Corregir 12 columnas fantasma en ReceptionService
**Bloqueador**: Este ISSUE
**Prioridad**: CRÍTICA
**Archivo**: `app/Services/Inventory/ReceptionService.php`

**Checklist**:
- [ ] Corregir método `postReception()` (líneas 203-218): `inventory_batch` insert
- [ ] Corregir método `postReception()` (líneas 226-242): `mov_inv` insert
- [ ] ELIMINAR o corregir método `createReception()` (legacy, líneas 271-373)
- [ ] Agregar manejo de `ubicacion_id` (generar formato 'UBIC-XXXXX')
- [ ] Validar que `fecha_caducidad` siempre tenga valor (default 1 año)
- [ ] Cambiar tipo 'RECEPCION' a 'ENTRADA' en mov_inv
- [ ] Ejecutar tests: `php artisan test tests/Feature/ReceptionStateTest.php`
- [ ] Generar DEVLOG: `DEVLOG_SPRINT1_INV-002-CODEX-FIX.md`

#### 6.2 QWEN (Migraciones)
**Task_ID**: `INV-002-QWEN-BD` (ya existe, puede avanzar parcialmente)
**Descripción**: Agregar columnas de auditoría state machine
**Columnas a agregar**:
```sql
ALTER TABLE selemti.recepcion_cab
ADD COLUMN validada_por bigint REFERENCES selemti.users(id),
ADD COLUMN validada_at timestamp,
ADD COLUMN posteada_por bigint REFERENCES selemti.users(id),
ADD COLUMN posteada_at timestamp;
```

#### 6.3 Tests
**Task_ID**: `INV-002-CODEX-TEST` (crear después del fix)
**Descripción**: Tests para state machine recepciones
**Casos**:
- [ ] Crear recepción BORRADOR
- [ ] Validar recepción (BORRADOR → VALIDADA)
- [ ] Postear recepción (VALIDADA → POSTEADA)
- [ ] Verificar que batch se creó con todas las columnas
- [ ] Verificar que mov_inv tiene tipo='ENTRADA'
- [ ] Verificar que ubicacion_id tiene formato correcto

---

## 7. Tiempo Estimado de Corrección

| Tarea | Tiempo | Responsable |
|-------|--------|-------------|
| Fix Backend (INV-002-CODEX-FIX) | 30-45 min | CODEX |
| Migraciones BD (INV-002-QWEN-BD) | 15 min | QWEN |
| Tests (INV-002-CODEX-TEST) | 30 min | CODEX |
| **TOTAL** | **1.5-2 horas** | - |

---

## 8. Referencias

- **DEVLOG Auditoría**: `docs/V4.1/Code/DEVLOG_SPRINT1_INV-002-CLAUDE-AUDIT.md`
- **Dump BD**: `database/BD_SCHEMA_SELEMTI.sql` (líneas 3588-3628, 4584-4619, 6649-6740)
- **Documentación BD**: `docs/V4.0/BaseDatos/Tablas.md` (sección 12)
- **Archivo a Corregir**: `app/Services/Inventory/ReceptionService.php`

---

## 9. Criterios de Aceptación (DONE)

Este ISSUE se marca como DONE cuando:

- [x] Auditoría completada (CLAUDE)
- [ ] Backend corregido (CODEX)
- [ ] Tests pasan exitosamente
- [ ] DEVLOG de corrección generado
- [ ] Migraciones BD ejecutadas (QWEN)
- [ ] UI puede consumir servicio sin errores (COPILOT)

---

**Creado por**: CLAUDE-ORQUESTADOR-V4.1
**Fecha**: 2025-11-20
**Última Actualización**: 2025-11-20 15:35
**Estado**: ⏳ OPEN (esperando corrección CODEX)
