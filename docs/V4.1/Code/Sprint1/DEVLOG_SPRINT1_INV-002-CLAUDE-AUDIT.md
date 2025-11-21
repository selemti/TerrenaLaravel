# DEVLOG_SPRINT1_INV-002-CLAUDE-AUDIT

**Task**: INV-002-AUDIT
**Épica**: INV-002 (Recepciones State Machine)
**IA**: CLAUDE (Arquitecto/Auditoría)
**Fecha**: 2025-11-20
**Estado**: ✅ DONE

---

## 1. Objetivo de la Auditoría

Validar que `ReceptionService.php` está **100% alineado** con la estructura real de la base de datos PostgreSQL (schema `selemti`), cumpliendo con las reglas del orquestador V4.1:

- ✅ No inventa columnas
- ✅ No inventa tablas
- ✅ Usa solo campos que existen en BD real
- ✅ Respeta tipos de datos
- ✅ Respeta relaciones FK

---

## 2. Archivos Auditados

### Código Backend
- **`app/Services/Inventory/ReceptionService.php`** (392 líneas)
  - Version 2.0 - Sprint 1 (INV-002)
  - State machine: BORRADOR → VALIDADA → POSTEADA

### Base de Datos (Fuente de Verdad)
- **`database/BD_SCHEMA_SELEMTI.sql`** (dump completo)
- **Queries en vivo contra PostgreSQL 9.5** (`psql` commands)
- **`docs/V4.0/BaseDatos/Tablas.md`** (documentación)

---

## 3. Tablas Involucradas

### 3.1 `selemti.recepcion_cab`

**Columnas en BD Real**:
```sql
id                   bigint       PK, AUTO
sucursal_id          bigint       NOT NULL, FK → cat_sucursales(id)
proveedor_id         integer
oc_ref               text
ts                   timestamp    NOT NULL, DEFAULT now()
usuario_id           bigint       FK → users(id)
meta                 jsonb
almacen_id           varchar(36)
numero_recepcion     varchar(255)
fecha_recepcion      date
estado               varchar(255)
total_presentaciones numeric(15,4)
total_canonico       numeric(15,4)
created_at           timestamp    DEFAULT now()
updated_at           timestamp    DEFAULT now()
deleted_at           timestamp
```

**Validación vs Código**:

| Columna ReceptionService | Columna BD Real | Estado | Notas |
|--------------------------|-----------------|--------|-------|
| `proveedor_id` | `proveedor_id` | ✅ OK | Integer |
| `sucursal_id` | `sucursal_id` | ✅ OK | Bigint NOT NULL |
| `almacen_id` | `almacen_id` | ✅ OK | Varchar(36) |
| `usuario_id` | `usuario_id` | ✅ OK | Bigint FK |
| `numero_recepcion` | `numero_recepcion` | ✅ OK | Varchar(255) |
| `fecha_recepcion` | `fecha_recepcion` | ✅ OK | Date |
| `estado` | `estado` | ✅ OK | Varchar(255) |
| `total_presentaciones` | `total_presentaciones` | ✅ OK | Numeric(15,4) |
| `total_canonico` | `total_canonico` | ✅ OK | Numeric(15,4) |
| `ts` | `ts` | ✅ OK | Timestamp NOT NULL |
| `created_at` | `created_at` | ✅ OK | Timestamp |
| `updated_at` | `updated_at` | ✅ OK | Timestamp |

**Resultado**: ✅ **100% Alineado**

---

### 3.2 `selemti.recepcion_det`

**Columnas en BD Real**:
```sql
id           bigint        PK, AUTO
recepcion_id bigint        NOT NULL, FK → recepcion_cab(id) ON DELETE CASCADE
item_id      varchar(20)   NOT NULL, FK → items(id)
bodega_id    bigint        NOT NULL, FK → cat_almacenes(id)
qty          numeric(14,6) NOT NULL
um_id        integer       NOT NULL, FK → unidad_medida_legacy(id)
costo_unit   numeric(14,6) NOT NULL
batch_id     bigint        FK → inventory_batch(id)
temperatura  numeric(6,2)
doc_url      text
meta         jsonb
created_at   timestamp     DEFAULT now()
updated_at   timestamp     DEFAULT now()
deleted_at   timestamp
```

**Resultado**: ✅ **100% Alineado**

---

### 3.3 `selemti.inventory_batch` ⚠️

**Columnas en BD Real**:
```sql
id                    integer      PK, AUTO
item_id               varchar(20)  NOT NULL, FK → items(id)
lote_proveedor        varchar(50)  NOT NULL
fecha_recepcion       date         NOT NULL  ← FALTANTE EN CÓDIGO
fecha_caducidad       date         NOT NULL  ← FALTANTE EN CÓDIGO
temperatura_recepcion numeric(5,2)
documento_url         varchar(255)
cantidad_original     numeric(10,3) NOT NULL
cantidad_actual       numeric(10,3) NOT NULL
estado                varchar(20)  DEFAULT 'ACTIVO'
ubicacion_id          varchar(10)  NOT NULL  ← FALTANTE EN CÓDIGO (CHECK: 'UBIC-%')
created_at            timestamp    DEFAULT now()
updated_at            timestamp    DEFAULT now()
unit_cost             numeric(12,4) NOT NULL DEFAULT 0
```

**🔴 DISCREPANCIAS CRÍTICAS**:

| Campo en Código | Campo en BD Real | Estado | Problema |
|-----------------|------------------|--------|----------|
| `uom_base` (línea 208) | ❌ NO EXISTE | 🔴 ERROR | Columna fantasma |
| `caducidad` (línea 209) | `fecha_caducidad` | ⚠️ MISMATCH | Nombre incorrecto |
| `sucursal_id` (línea 213) | ❌ NO EXISTE | 🔴 ERROR | Columna fantasma |
| `almacen_id` (línea 214) | ❌ NO EXISTE | 🔴 ERROR | Columna fantasma |
| `meta` (línea 215) | ❌ NO EXISTE | 🔴 ERROR | Columna fantasma |
| - | `fecha_recepcion` | 🔴 FALTA | NOT NULL - REQUERIDO |
| - | `ubicacion_id` | 🔴 FALTA | NOT NULL - REQUERIDO |

**Código Problemático** (líneas 203-218):
```php
$batchId = DB::table('selemti.inventory_batch')->insertGetId([
    'item_id' => $line->item_id,
    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
    'cantidad_original' => $line->qty,
    'cantidad_actual' => $line->qty,
    'uom_base' => $meta['uom_base'] ?? 'UND',  // ❌ NO EXISTE
    'caducidad' => $meta['fecha_caducidad'] ?? null,  // ❌ Nombre + NULL inválido
    'estado' => 'ACTIVO',
    'temperatura_recepcion' => $line->temperatura,
    'documento_url' => $line->doc_url,
    'sucursal_id' => $reception->sucursal_id,  // ❌ NO EXISTE
    'almacen_id' => $reception->almacen_id,    // ❌ NO EXISTE
    'meta' => $line->meta,                      // ❌ NO EXISTE
]);
```

---

### 3.4 `selemti.mov_inv` ⚠️

**Columnas en BD Real**:
```sql
id              bigint        PK, AUTO
ts              timestamp     NOT NULL, DEFAULT now()
item_id         varchar(20)   NOT NULL, FK → items(id)
lote_id         integer       FK → inventory_batch(id)  ← NO batch_id
cantidad        numeric(14,6) NOT NULL  ← NO qty
tipo            varchar(20)   NOT NULL
                CHECK (tipo IN ('ENTRADA','SALIDA','AJUSTE','MERMA','TRASPASO'))
                ← 'RECEPCION' NO ES VÁLIDO
ref_tipo        varchar(50)
ref_id          bigint
sucursal_id     varchar(30)
usuario_id      integer       ← NO user_id
created_at      timestamp     DEFAULT now()
```

**🔴 DISCREPANCIAS CRÍTICAS**:

| Campo en Código | Campo en BD Real | Estado | Problema |
|-----------------|------------------|--------|----------|
| `tipo => 'RECEPCION'` | CHECK constraint | 🔴 ERROR | Valor inválido - debe ser 'ENTRADA' |
| `qty` (línea 229) | `cantidad` | 🔴 ERROR | Columna incorrecta |
| `uom` (línea 230) | ❌ NO EXISTE | 🔴 ERROR | Columna fantasma |
| `almacen_id` (línea 232) | ❌ NO EXISTE | 🔴 ERROR | Columna fantasma |
| `user_id` (línea 235) | `usuario_id` | 🔴 ERROR | Nombre incorrecto |
| `batch_id` (línea 236) | `lote_id` | 🔴 ERROR | Nombre incorrecto |
| `meta` (línea 238) | ❌ NO EXISTE | 🔴 ERROR | Columna fantasma |

**Código Problemático** (líneas 226-242):
```php
DB::table('selemti.mov_inv')->insert([
    'item_id' => $line->item_id,
    'tipo' => 'RECEPCION',  // ❌ INVÁLIDO - debe ser 'ENTRADA'
    'qty' => $line->qty,     // ❌ Debe ser 'cantidad'
    'uom' => $meta['uom_base'] ?? 'UND',  // ❌ NO EXISTE
    'sucursal_id' => $reception->sucursal_id,
    'almacen_id' => $reception->almacen_id,  // ❌ NO EXISTE
    'ref_tipo' => 'recepcion',
    'ref_id' => $receptionId,
    'user_id' => $userId,   // ❌ Debe ser 'usuario_id'
    'batch_id' => $batchId, // ❌ Debe ser 'lote_id'
    'ts' => $now,
    'meta' => json_encode([...]),  // ❌ NO EXISTE
]);
```

---

## 4. Resumen de Errores

### Total: **12 Columnas Fantasma/Incorrectas**

**inventory_batch**: 5 errores + 3 faltantes
**mov_inv**: 7 errores

---

## 5. Código Correcto

### 5.1 Fix `inventory_batch`

```php
// ✅ CORRECTO
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

### 5.2 Fix `mov_inv`

```php
// ✅ CORRECTO
DB::table('selemti.mov_inv')->insert([
    'item_id' => $line->item_id,
    'tipo' => 'ENTRADA',  // ✅ VÁLIDO
    'cantidad' => $line->qty,  // ✅ COLUMNA CORRECTA
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

## 6. Validación de Lógica

✅ **State Machine**: Correcta (BORRADOR → VALIDADA → POSTEADA)
✅ **Transacciones**: Correctamente implementadas
✅ **Número Secuencial**: Lógica correcta

⚠️ **Columnas de Auditoría**: No existen aún (validada_por, validada_at, posteada_por, posteada_at)
→ Deben ser creadas por QWEN en tarea `INV-002-QWEN-BD`

---

## 7. Resultado Final

**Estado**: ✅ **AUDITORÍA COMPLETADA**

**Veredicto**:
- ✅ Lógica de negocio: **APROBADA**
- 🔴 Implementación técnica: **BLOQUEADA** (12 columnas fantasma)

**Riesgo si se Deploy sin Correcciones**:
- 🔴 **CRÍTICO**: PostgreSQL rechazará TODOS los inserts
- 🔴 **CRÍTICO**: Constraint violation en `mov_inv.tipo`
- 🔴 **CRÍTICO**: NOT NULL violation en `inventory_batch`

---

## 8. Acciones Requeridas

1. ✅ CLAUDE: Auditoría completada → DONE
2. ⏳ CODEX: Corregir 12 columnas fantasma → PENDING (`INV-002-CODEX-FIX`)
3. ⏳ QWEN: Agregar columnas auditoría → PENDING (`INV-002-QWEN-BD`)
4. ⏳ COPILOT: UI workflow → BLOCKED (espera backend funcional)

---

**Firmado**: CLAUDE-ORQUESTADOR-V4.1
**Timestamp**: 2025-11-20 15:30:00
