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
No inventa ninguna columna. Todos los campos usados existen en BD real.

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

**Validación vs Código**:

| Columna ReceptionService | Columna BD Real | Estado | Notas |
|--------------------------|-----------------|--------|-------|
| `recepcion_id` | `recepcion_id` | ✅ OK | Bigint NOT NULL |
| `item_id` | `item_id` | ✅ OK | Varchar(20) |
| `bodega_id` | `bodega_id` | ✅ OK | Bigint NOT NULL |
| `qty` | `qty` | ✅ OK | Numeric(14,6) |
| `um_id` | `um_id` | ✅ OK | Integer |
| `costo_unit` | `costo_unit` | ✅ OK | Numeric(14,6) |
| `batch_id` | `batch_id` | ✅ OK | Bigint (nullable) |
| `temperatura` | `temperatura` | ✅ OK | Numeric(6,2) |
| `doc_url` | `doc_url` | ✅ OK | Text |
| `meta` | `meta` | ✅ OK | JSONB |

**Resultado**: ✅ **100% Alineado**

---

### 3.3 `selemti.inventory_batch`

**Columnas en BD Real**:
```sql
id                    integer      PK, AUTO
item_id               varchar(20)  NOT NULL, FK → items(id)
lote_proveedor        varchar(50)  NOT NULL
fecha_recepcion       date         NOT NULL
fecha_caducidad       date         NOT NULL
temperatura_recepcion numeric(5,2)
documento_url         varchar(255)
cantidad_original     numeric(10,3) NOT NULL
cantidad_actual       numeric(10,3) NOT NULL
estado                varchar(20)  DEFAULT 'ACTIVO'
ubicacion_id          varchar(10)  NOT NULL (CHECK: 'UBIC-%')
created_at            timestamp    DEFAULT now()
updated_at            timestamp    DEFAULT now()
unit_cost             numeric(12,4) NOT NULL DEFAULT 0
```

**⚠️ DISCREPANCIA DETECTADA**:

| Campo en Código | Campo en BD Real | Estado | Problema |
|-----------------|------------------|--------|----------|
| `uom_base` (meta) | ❌ NO EXISTE | 🔴 ERROR | ReceptionService líneas 208, 230 intentan insertar columna `uom_base` |
| `sucursal_id` (línea 213) | ❌ NO EXISTE | 🔴 ERROR | `inventory_batch` NO tiene `sucursal_id` |
| `almacen_id` (línea 214) | ❌ NO EXISTE | 🔴 ERROR | `inventory_batch` NO tiene `almacen_id` |
| `meta` (línea 215) | ❌ NO EXISTE | 🔴 ERROR | `inventory_batch` NO tiene columna `meta` |
| `caducidad` (línea 209) | `fecha_caducidad` | ⚠️ MISMATCH | Nombre de columna diferente |
| `cantidad_original/actual` | ✅ OK | ✅ OK | Numeric(10,3) |

**Código Problemático** (ReceptionService.php líneas 203-218):
```php
$batchId = DB::table('selemti.inventory_batch')->insertGetId([
    'item_id' => $line->item_id,
    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
    'cantidad_original' => $line->qty,
    'cantidad_actual' => $line->qty,
    'uom_base' => $meta['uom_base'] ?? 'UND',  // ❌ NO EXISTE
    'caducidad' => $meta['fecha_caducidad'] ?? null,  // ❌ Debe ser 'fecha_caducidad'
    'estado' => 'ACTIVO',
    'temperatura_recepcion' => $line->temperatura,
    'documento_url' => $line->doc_url,
    'sucursal_id' => $reception->sucursal_id,  // ❌ NO EXISTE
    'almacen_id' => $reception->almacen_id,    // ❌ NO EXISTE
    'meta' => $line->meta,                      // ❌ NO EXISTE
    'created_at' => $now,
    'updated_at' => $now,
]);
```

---

### 3.4 `selemti.mov_inv`

**Columnas en BD Real**:
```sql
id              bigint        PK, AUTO
ts              timestamp     NOT NULL, DEFAULT now()
item_id         varchar(20)   NOT NULL, FK → items(id)
lote_id         integer       FK → inventory_batch(id)
cantidad        numeric(14,6) NOT NULL
qty_original    numeric(14,6)
uom_original_id integer
costo_unit      numeric(14,6) DEFAULT 0
tipo            varchar(20)   NOT NULL (CHECK: ENTRADA|SALIDA|AJUSTE|MERMA|TRASPASO)
ref_tipo        varchar(50)
ref_id          bigint
sucursal_id     varchar(30)
usuario_id      integer
created_at      timestamp     DEFAULT now()
```

**⚠️ DISCREPANCIA DETECTADA**:

| Campo en Código | Campo en BD Real | Estado | Problema |
|-----------------|------------------|--------|----------|
| `tipo => 'RECEPCION'` | ✅ CHECK constraint permite solo: ENTRADA, SALIDA, AJUSTE, MERMA, TRASPASO | 🔴 ERROR | **'RECEPCION' NO ES VÁLIDO** |
| `qty` (línea 229) | `cantidad` | 🔴 ERROR | Columna incorrecta |
| `uom` (línea 230) | ❌ NO EXISTE | 🔴 ERROR | No hay columna `uom` |
| `batch_id` (línea 236) | `lote_id` | 🔴 ERROR | Nombre de columna incorrecto |
| `meta` (línea 238) | ❌ NO EXISTE | 🔴 ERROR | `mov_inv` NO tiene columna `meta` |
| `almacen_id` (línea 232) | ❌ NO EXISTE | 🔴 ERROR | `mov_inv` NO tiene `almacen_id` |
| `user_id` (línea 235) | `usuario_id` | 🔴 ERROR | Nombre de columna diferente |

**Código Problemático** (ReceptionService.php líneas 226-242):
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

## 4. Resumen de Discrepancias Críticas

### 4.1 `inventory_batch` (5 columnas fantasma)

| Columna Fantasma | Usado en Línea | Corrección Necesaria |
|------------------|----------------|----------------------|
| `uom_base` | 208 | ❌ ELIMINAR - no existe en BD |
| `caducidad` | 209 | ✅ RENOMBRAR a `fecha_caducidad` |
| `sucursal_id` | 213 | ❌ ELIMINAR - no existe en tabla |
| `almacen_id` | 214 | ❌ ELIMINAR - no existe en tabla |
| `meta` | 215 | ❌ ELIMINAR - no existe en tabla |

**Columnas FALTANTES en código**:
- `fecha_recepcion` (date NOT NULL) - **REQUERIDO**
- `fecha_caducidad` (date NOT NULL) - **REQUERIDO**
- `ubicacion_id` (varchar(10) NOT NULL) - **REQUERIDO** (CHECK: debe empezar con 'UBIC-%')

### 4.2 `mov_inv` (5 columnas/valores incorrectos)

| Campo Incorrecto | Línea | Corrección |
|------------------|-------|------------|
| `tipo => 'RECEPCION'` | 228 | ✅ Cambiar a `'ENTRADA'` |
| `qty` | 229 | ✅ Cambiar a `cantidad` |
| `uom` | 230 | ❌ ELIMINAR - no existe |
| `almacen_id` | 232 | ❌ ELIMINAR - no existe |
| `user_id` | 235 | ✅ Cambiar a `usuario_id` |
| `batch_id` | 236 | ✅ Cambiar a `lote_id` |
| `meta` | 238 | ❌ ELIMINAR - no existe |

---

## 5. Análisis del Método Legacy (líneas 271-373)

**Método**: `createReception()` (deprecated)

### Discrepancias Detectadas:

**`recepcion_cab` (línea 291)**:
- ❌ Usa tabla SIN schema: `recepcion_cab` (debe ser `selemti.recepcion_cab`)
- ❌ Campo `creado_por` (línea 281) - NO EXISTE (debe ser `usuario_id`)
- ❌ Estado `'RECIBIDO'` (línea 284) - No documentado en state machine

**`inventory_batch` (línea 300)**:
- ❌ Usa tabla SIN schema: `inventory_batch`
- ✅ Campos correctos PERO sin ubicacion_id y fecha_recepcion

**`recepcion_det` (línea 321)**:
- ❌ Usa tabla SIN schema: `recepcion_det`
- ❌ Campo `inventory_batch_id` (línea 324) - NO EXISTE (debe ser `batch_id`)
- ❌ Campo `lote_proveedor` (línea 325) - NO EXISTE en recepcion_det
- ❌ Campo `fecha_caducidad` (línea 326) - NO EXISTE en recepcion_det
- ❌ Campos `qty_presentacion`, `qty_recibida`, `pack_size`, `uom_compra`, `qty_canonica`, `uom_base`, `precio_unit` - **NINGUNO EXISTE**

**`mov_inv` (línea 357)**:
- ❌ Usa tabla SIN schema: `mov_inv`
- ❌ Campo `inventory_batch_id` (línea 342) - NO EXISTE (debe ser `lote_id`)
- ❌ Campo `meta` (línea 352) - NO EXISTE

---

## 6. Validación de Lógica de Negocio

### 6.1 State Machine

**Estados Definidos** (líneas 22-25):
```php
const ESTADO_BORRADOR = 'BORRADOR';
const ESTADO_VALIDADA = 'VALIDADA';
const ESTADO_POSTEADA = 'POSTEADA';
const ESTADO_CANCELADA = 'CANCELADA';
```

✅ **Lógica Correcta**:
- `createDraftReception()` → BORRADOR
- `validateReception()` → VALIDADA
- `postReception()` → POSTEADA

⚠️ **Columnas Propuestas NO EXISTEN** (comentarios en código):
- `validada_por` (línea 155) - TODO: No existe aún
- `validada_at` (línea 156) - TODO: No existe aún
- `posteada_por` (línea 171) - TODO: No existe aún
- `posteada_at` (línea 171) - TODO: No existe aún

**Acción Recomendada**: Estas columnas deben ser creadas por QWEN en tarea `INV-002-QWEN-BD`

### 6.2 Número Secuencial (líneas 381-390)

```php
protected function buildSequentialNumber(): string
{
    $today = now()->format('Ymd');
    $count = DB::table('selemti.recepcion_cab')
        ->whereDate('fecha_recepcion', now()->toDateString())
        ->count();
    return sprintf('RC-%s-%04d', $today, $count + 1);
}
```

✅ **Lógica Correcta**: Genera formato `RC-20251120-0001`
✅ **Columnas Usadas Existen**: `fecha_recepcion` existe en BD

---

## 7. Validación de Transacciones

### Métodos con DB::transaction:
1. ✅ `createDraftReception()` (línea 56)
2. ✅ `postReception()` (línea 179)
3. ✅ `createReception()` (línea 273 - legacy)

**Resultado**: ✅ Todas las operaciones multi-tabla están correctamente envueltas en transacciones.

---

## 8. Resultado Final de la Auditoría

### ✅ APROBADO con CORRECCIONES OBLIGATORIAS

**Estado del Servicio**:
- ✅ Lógica de negocio CORRECTA
- ✅ State machine bien diseñada
- ✅ Transacciones correctamente implementadas
- 🔴 **BLOQUEADO para producción** hasta corregir columnas fantasma

### Columnas Fantasma Totales: **12 errores críticos**

**Por Tabla**:
- `inventory_batch`: 5 columnas fantasma + 3 requeridas faltantes
- `mov_inv`: 5 columnas fantasma + 2 columnas con nombre incorrecto
- `recepcion_det` (método legacy): 8 columnas fantasma

---

## 9. Plan de Acción (Bloquea tareas posteriores)

### 9.1 Para CODEX (Backend)

**Archivo**: `app/Services/Inventory/ReceptionService.php`

**Correcciones Requeridas** (método `postReception()`):

**inventory_batch** (líneas 203-218):
```php
// ANTES (❌ INCORRECTO)
$batchId = DB::table('selemti.inventory_batch')->insertGetId([
    'item_id' => $line->item_id,
    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
    'cantidad_original' => $line->qty,
    'cantidad_actual' => $line->qty,
    'uom_base' => $meta['uom_base'] ?? 'UND',  // ❌ ELIMINAR
    'caducidad' => $meta['fecha_caducidad'] ?? null,  // ❌ RENOMBRAR
    'estado' => 'ACTIVO',
    'temperatura_recepcion' => $line->temperatura,
    'documento_url' => $line->doc_url,
    'sucursal_id' => $reception->sucursal_id,  // ❌ ELIMINAR
    'almacen_id' => $reception->almacen_id,    // ❌ ELIMINAR
    'meta' => $line->meta,                      // ❌ ELIMINAR
    'created_at' => $now,
    'updated_at' => $now,
]);

// DESPUÉS (✅ CORRECTO)
$batchId = DB::table('selemti.inventory_batch')->insertGetId([
    'item_id' => $line->item_id,
    'lote_proveedor' => $meta['lote_proveedor'] ?? (string) Str::uuid(),
    'fecha_recepcion' => $reception->fecha_recepcion,  // ✅ AGREGAR (REQUERIDO)
    'fecha_caducidad' => $meta['fecha_caducidad'] ?? now()->addYear(),  // ✅ RENOMBRAR + REQUERIDO
    'temperatura_recepcion' => $line->temperatura,
    'documento_url' => $line->doc_url,
    'cantidad_original' => $line->qty,
    'cantidad_actual' => $line->qty,
    'estado' => 'ACTIVO',
    'ubicacion_id' => 'UBIC-' . str_pad($reception->almacen_id ?? 1, 5, '0', STR_PAD_LEFT),  // ✅ AGREGAR (REQUERIDO)
    'created_at' => $now,
    'updated_at' => $now,
]);
```

**mov_inv** (líneas 226-242):
```php
// ANTES (❌ INCORRECTO)
DB::table('selemti.mov_inv')->insert([
    'item_id' => $line->item_id,
    'tipo' => 'RECEPCION',  // ❌ VALOR INVÁLIDO
    'qty' => $line->qty,     // ❌ COLUMNA INCORRECTA
    'uom' => $meta['uom_base'] ?? 'UND',  // ❌ ELIMINAR
    'sucursal_id' => $reception->sucursal_id,
    'almacen_id' => $reception->almacen_id,  // ❌ ELIMINAR
    'ref_tipo' => 'recepcion',
    'ref_id' => $receptionId,
    'user_id' => $userId,   // ❌ COLUMNA INCORRECTA
    'batch_id' => $batchId, // ❌ COLUMNA INCORRECTA
    'ts' => $now,
    'meta' => json_encode([...]),  // ❌ ELIMINAR
]);

// DESPUÉS (✅ CORRECTO)
DB::table('selemti.mov_inv')->insert([
    'item_id' => $line->item_id,
    'tipo' => 'ENTRADA',  // ✅ VALOR VÁLIDO
    'cantidad' => $line->qty,  // ✅ COLUMNA CORRECTA
    'sucursal_id' => (string) $reception->sucursal_id,  // ✅ Cast a varchar(30)
    'ref_tipo' => 'recepcion',
    'ref_id' => $receptionId,
    'usuario_id' => $userId,  // ✅ COLUMNA CORRECTA
    'lote_id' => $batchId,    // ✅ COLUMNA CORRECTA
    'costo_unit' => $line->costo_unit,  // ✅ AGREGAR
    'ts' => $now,
]);
```

**Método legacy** (líneas 271-373):
- ⚠️ **DEPRECAR COMPLETAMENTE** o corregir todas las columnas fantasma (8 errores)
- Recomendación: ELIMINAR y migrar todo a state machine

### 9.2 Para QWEN (Migraciones)

**Tarea**: `INV-002-QWEN-BD`

**Agregar Columnas de Auditoría** en `recepcion_cab`:
```sql
ALTER TABLE selemti.recepcion_cab
ADD COLUMN validada_por bigint REFERENCES selemti.users(id),
ADD COLUMN validada_at timestamp,
ADD COLUMN posteada_por bigint REFERENCES selemti.users(id),
ADD COLUMN posteada_at timestamp;
```

**Verificar Constraints**:
- ✅ `mov_inv.tipo` CHECK constraint no incluye 'RECEPCION' (usar 'ENTRADA')
- ✅ `inventory_batch.ubicacion_id` CHECK requiere formato 'UBIC-%'

---

## 10. Dependencias Bloqueadas

Hasta que CODEX corrija las columnas fantasma en ReceptionService:

- ❌ **BLOQUEADO**: `INV-002-CODEX-SRV` (marcar como POR_VALIDAR → BLOCKED)
- ❌ **BLOQUEADO**: `INV-002-QWEN-BD` (puede avanzar parcialmente, pero no testear sin backend correcto)
- ❌ **BLOQUEADO**: `INV-002-COPILOT-UI` (no puede consumir servicio roto)

---

## 11. Evidencia de Validación

### Queries Ejecutadas:
```bash
# Estructura de tablas verificada
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.recepcion_cab"
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.recepcion_det"
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.inventory_batch"
psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.mov_inv"
```

### Archivos de Referencia:
- ✅ `database/BD_SCHEMA_SELEMTI.sql` (líneas 6649-6740: recepcion_cab/det)
- ✅ `database/BD_SCHEMA_SELEMTI.sql` (líneas 3588-3628: inventory_batch)
- ✅ `database/BD_SCHEMA_SELEMTI.sql` (líneas 4584-4619: mov_inv)
- ✅ `docs/V4.0/BaseDatos/Tablas.md` (sección 12)

---

## 12. Conclusión

**Estado**: ✅ **AUDITORÍA COMPLETADA**

**Veredicto**:
- ✅ Lógica de negocio: **APROBADA**
- 🔴 Implementación técnica: **BLOQUEADA** (12 columnas fantasma)

**Siguiente Acción**:
1. ✅ CLAUDE marca esta tarea como DONE
2. 🔄 ORQUESTADOR asigna corrección a CODEX (crear nueva tarea: `INV-002-CODEX-FIX`)
3. ⏳ QWEN espera a que backend esté corregido antes de ejecutar migraciones completas

**Riesgo si se Deploy sin Correcciones**:
- 🔴 **CRÍTICO**: PostgreSQL rechazará TODOS los inserts con error de columna inexistente
- 🔴 **CRÍTICO**: Constraint violation en `mov_inv.tipo` ('RECEPCION' no permitido)
- 🔴 **CRÍTICO**: NOT NULL violation en `inventory_batch` (faltan `fecha_recepcion`, `fecha_caducidad`, `ubicacion_id`)

---

**Firmado**: CLAUDE-ORQUESTADOR-V4.1
**Timestamp**: 2025-11-20 15:30:00
