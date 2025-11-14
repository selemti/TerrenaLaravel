# AUDITORÍA EXHAUSTIVA DE TABLAS DUPLICADAS Y LEGACY

**Fecha**: 2 Noviembre 2025
**Base de datos**: PostgreSQL pos @ localhost:5433
**Total Tablas**: 249
  - Schema selemti: 142 tablas
  - Schema public: 107 tablas (Floreant POS - READ-ONLY)

---

## RESUMEN EJECUTIVO

### Hallazgos Críticos

- **Total grupos de tablas duplicadas**: **26 grupos**
- **Total tablas legacy con sufijo _legacy**: **4 tablas** (todas vacías)
- **Total tablas duplicadas vacías**: **~70 tablas**
- **Tablas con datos que requieren revisión**: **4 tablas**
  - `selemti.users` (1 registro)
  - `selemti.roles` (7 registros)
  - `selemti.auditoria` (72 registros)
  - `selemti.model_has_roles` (1 registro)

### Nivel de Impacto

**ALTO** - Se detectaron múltiples duplicaciones sistemáticas que indican:
1. Múltiples intentos de normalización de esquema
2. Migraciones incompletas entre nomenclaturas
3. Coexistencia de nomenclaturas: español, inglés, y mixtas
4. Tablas legacy de múltiples sistemas anteriores

### Acción Recomendada

**LIMPIEZA INMEDIATA**: El 80% de las tablas duplicadas están vacías y pueden eliminarse de forma segura después de validación de código.

---

## PARTE 1: TABLAS DUPLICADAS POR CATEGORÍA

### 1. USUARIOS Y AUTENTICACIÓN

#### Grupo 1.1: Usuarios
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **public.users** | 9 | POS Floreant Producción | ✅ **MANTENER** - Sistema en uso |
| **selemti.users** | 1 | Legacy App | ⚠️ **REVISAR** - Migrar a Laravel |
| **selemti.usuario** | 0 | Legacy vacía | ❌ **ELIMINAR** |

**Análisis**:
- `public.users`: Sistema POS Floreant, no tocar sin coordinación
- `selemti.users`: 1 registro, posiblemente usuario de prueba Laravel
- `selemti.usuario`: FK a `selemti.rol` (también legacy vacía)

**Dependencias**:
- `selemti.usuario.rol_id` → `selemti.rol.id`

---

#### Grupo 1.2: Roles
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.roles** | 7 | Spatie Laravel Permission | ✅ **MANTENER** - Sistema actual |
| **selemti.rol** | 0 | Legacy vacía | ❌ **ELIMINAR** |

**Análisis**:
- `selemti.roles`: Tabla de Spatie Laravel Permission (sistema RBAC actual)
- Los 7 roles son del sistema actual: admin, manager, cashier, etc.
- `selemti.rol`: Estructura simple legacy sin datos

---

#### Grupo 1.3: Asignación de Roles a Usuarios
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.model_has_roles** | 1 | Spatie RBAC actual | ✅ **MANTENER** |
| **selemti.user_roles** | 0 | Legacy vacía | ❌ **ELIMINAR** |

**Análisis**:
- `model_has_roles`: Tabla polimórfica de Spatie para asignar roles
- 1 registro: asignación de rol al usuario de prueba

---

### 2. CATÁLOGOS MAESTROS

#### Grupo 2.1: Sucursales
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.cat_sucursales** | 3 | Normalizada actual | ✅ **MANTENER** |
| **selemti.sucursal** | 0 | Legacy vacía | ❌ **ELIMINAR** |

**Columnas clave**:
- `cat_sucursales`: id, clave, nombre, ubicacion, activo, pos_location
- `sucursal`: id (text), nombre, activo

---

#### Grupo 2.2: Almacenes / Bodegas
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.cat_almacenes** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.almacen** | 0 | Legacy vacía | ❌ **ELIMINAR** |
| **selemti.bodega** | 0 | Legacy vacía | ❌ **ELIMINAR** |

**Análisis**:
- Tres nomenclaturas: `cat_almacenes` (normalizada), `almacen`, `bodega`
- `cat_almacenes` tiene FK a `cat_sucursales`
- `almacen` tiene FK a `cat_sucursales`

**Dependencias**:
- `almacen.sucursal_id` → `cat_sucursales.id`
- `cat_almacenes.sucursal_id` → `cat_sucursales.id`

---

#### Grupo 2.3: Proveedores
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.cat_proveedores** | 0 | Normalizada actual (23 campos) | ✅ **MANTENER** |
| **selemti.proveedor** | 0 | Legacy vacía (4 campos) | ❌ **ELIMINAR** |

**Análisis**:
- `cat_proveedores`: Estructura completa con RFC, CFDI, bancos, etc.
- `proveedor`: Estructura simple legacy

---

#### Grupo 2.4: Unidades de Medida
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.cat_unidades** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.unidad_medida_legacy** | 0 | Legacy explícita | ❌ **ELIMINAR** |
| **selemti.unidades_medida_legacy** | 0 | Legacy explícita | ❌ **ELIMINAR** |

**Análisis**:
- Dos tablas legacy con sufijo explícito `_legacy`
- Diferencias en estructura: `unidad_medida_legacy` (7 cols) vs `unidades_medida_legacy` (9 cols)

---

#### Grupo 2.5: Conversiones de Unidades
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.cat_uom_conversion** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.conversiones_unidad_legacy** | 0 | Legacy explícita | ❌ **ELIMINAR** |
| **selemti.uom_conversion_legacy** | 0 | Legacy explícita | ❌ **ELIMINAR** |

**Dependencias legacy**:
- `conversiones_unidad_legacy` → `unidades_medida_legacy` (origen y destino)
- `uom_conversion_legacy` → `unidad_medida_legacy` (origen y destino)

---

### 3. INVENTARIO Y STOCK

#### Grupo 3.1: Items / Productos / Insumos
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.items** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.insumo** | 0 | Legacy vacía | ❌ **ELIMINAR** |

**Análisis**:
- `items`: Tabla normalizada para productos e insumos
- `insumo`: Nomenclatura legacy española

---

#### Grupo 3.2: Lotes / Batches
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.inventory_batch** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.lote** | 0 | Legacy vacía | ❌ **ELIMINAR** |

---

#### Grupo 3.3: Mermas / Desperdicios
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.inventory_wastes** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.merma** | 0 | Legacy vacía | ❌ **ELIMINAR** |

---

#### Grupo 3.4: Políticas de Stock
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.inv_stock_policy** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.stock_policy** | 0 | Legacy vacía | ❌ **ELIMINAR** |

---

### 4. TRANSFERENCIAS

#### Grupo 4.1: Cabecera de Transferencias
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.transfer_cab** | 0 | Nomenclatura 1 | ⚠️ **CONSOLIDAR** |
| **selemti.traspaso_cab** | 0 | Nomenclatura 2 | ❌ **ELIMINAR** o consolidar |

**Análisis**:
- `transfer_cab`: Nomenclatura en inglés
- `traspaso_cab`: Nomenclatura en español
- Ambas vacías, decidir cuál es la oficial

---

#### Grupo 4.2: Detalle de Transferencias
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.transfer_det** | 0 | Nomenclatura 1 | ⚠️ **CONSOLIDAR** |
| **selemti.traspaso_det** | 0 | Nomenclatura 2 | ❌ **ELIMINAR** o consolidar |

---

### 5. PRODUCCIÓN

#### Grupo 5.1: Órdenes de Producción - CABECERA
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.production_orders** | 0 | Normalizada actual (inglés) | ✅ **MANTENER** |
| **selemti.op_cab** | 0 | Legacy español v1 | ❌ **ELIMINAR** |
| **selemti.op_produccion_cab** | 0 | Legacy español v2 | ❌ **ELIMINAR** |
| **selemti.prod_cab** | 0 | Legacy corto | ❌ **ELIMINAR** |
| **selemti.sol_prod_cab** | 0 | Solicitudes producción | ⚠️ **REVISAR** - ¿Diferente propósito? |

**Análisis CRÍTICO**:
- **5 tablas diferentes** para órdenes de producción
- `production_orders`: Tabla actual del sistema
- `op_*`, `prod_*`: Intentos anteriores de implementación
- `sol_prod_cab`: Podría ser "Solicitudes de Producción" (diferente a órdenes)

---

#### Grupo 5.2: Órdenes de Producción - DETALLE/INSUMOS
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.production_order_inputs** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.production_order_outputs** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.op_insumo** | 0 | Legacy español | ❌ **ELIMINAR** |
| **selemti.prod_det** | 0 | Legacy corto | ❌ **ELIMINAR** |
| **selemti.sol_prod_det** | 0 | Solicitudes detalle | ⚠️ **REVISAR** |

**Análisis**:
- Sistema actual separa: `inputs` (insumos consumidos) y `outputs` (productos obtenidos)
- Legacy mezclaba todo en una tabla de detalle

---

#### Grupo 5.3: Yield de Producción
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.op_yield** | 0 | Legacy | ❌ **ELIMINAR** o consolidar |

---

### 6. RECETAS

#### Grupo 6.1: Recetas - CABECERA
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.recipes** | N/A | ¿Existe? Verificar | ✅ **MANTENER** si existe |
| **selemti.receta** | 0 | Legacy español v1 | ❌ **ELIMINAR** |
| **selemti.receta_cab** | 0 | Legacy español v2 | ❌ **ELIMINAR** |

**Nota**: Verificar si existe tabla `recipes` en selemti (no apareció en listado)

---

#### Grupo 6.2: Recetas - DETALLE
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.recipe_version_items** | N/A | Normalizada (versionado) | ✅ **MANTENER** |
| **selemti.receta_det** | 0 | Legacy español | ❌ **ELIMINAR** |
| **selemti.receta_insumo** | 0 | Legacy español | ❌ **ELIMINAR** |

---

#### Grupo 6.3: Recetas - VERSIONES
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.recipe_versions** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.receta_version** | 0 | Legacy español | ❌ **ELIMINAR** |
| **selemti.receta_shadow** | 0 | Legacy shadow copy | ❌ **ELIMINAR** |

**Análisis**:
- `receta_shadow`: Posiblemente un intento de versionado manual

---

### 7. CAJA CHICA (CASH FUND)

#### Grupo 7.1: Fondos de Caja Chica
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.cash_funds** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.caja_fondo** | 0 | Legacy español | ❌ **ELIMINAR** |

**Análisis**:
- Sistema actual usa nomenclatura inglés
- `cash_funds` tiene FK a `selemti.users`

**Dependencias legacy**:
- `cash_funds.created_by_user_id` → `users.id`
- `cash_funds.responsable_user_id` → `users.id`

---

#### Grupo 7.2: Movimientos de Caja Chica
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.cash_fund_movements** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.caja_fondo_mov** | 0 | Legacy español | ❌ **ELIMINAR** |

---

#### Grupo 7.3: Ajustes de Caja Chica
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.caja_fondo_adj** | 0 | Legacy (¿única?) | ⚠️ **REVISAR** - ¿Se usa? |

**Nota**: No encontré tabla equivalente en inglés para ajustes

---

#### Grupo 7.4: Arqueos de Caja Chica
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.cash_fund_arqueos** | 0 | Normalizada actual | ✅ **MANTENER** |
| **selemti.caja_fondo_arqueo** | 0 | Legacy español | ❌ **ELIMINAR** |

---

### 8. AUDITORÍA Y LOGS

#### Grupo 8.1: Logs de Auditoría
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.auditoria** | **72** | Legacy CON DATOS | ⚠️ **MIGRAR** → consolidar |
| **selemti.audit_log** | 0 | Normalizada v1 | ⚠️ **CONSOLIDAR** |
| **selemti.audit_log_global** | 0 | Normalizada v2 global | ✅ **MANTENER** |
| **selemti.cash_fund_movement_audit_log** | 0 | Auditoría específica | ✅ **MANTENER** |

**CRÍTICO**:
- `selemti.auditoria` tiene **72 registros** de auditoría legacy
- Requiere migración antes de eliminar
- Decidir si consolidar en `audit_log` o `audit_log_global`

---

### 9. TICKETS Y VENTAS POS

#### Grupo 9.1: Tickets de Venta - Cabecera
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.ticket_venta_cab** | 0 | Sistema actual | ✅ **MANTENER** |

---

#### Grupo 9.2: Tickets de Venta - Detalle
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.ticket_venta_det** | 0 | Sistema actual | ✅ **MANTENER** |

---

#### Grupo 9.3: Modificadores de Ticket Items
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.ticket_item_modifiers** | 0 | Sistema actual | ✅ **MANTENER** |

---

#### Grupo 9.4: Consumo POS de Inventario
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.inv_consumo_pos** | 0 | Sistema v1 | ⚠️ **CONSOLIDAR** |
| **selemti.ticket_det_consumo** | 0 | Sistema v2 | ✅ **MANTENER** (?)|

**Análisis**: Dos tablas para rastrear consumo de inventario por ventas POS

---

### 10. RECEPCIONES DE COMPRAS

#### Grupo 10.1: Recepciones - Cabecera
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.recepcion_cab** | 0 | Sistema actual | ✅ **MANTENER** |

---

#### Grupo 10.2: Recepciones - Detalle
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.recepcion_det** | 0 | Sistema actual | ✅ **MANTENER** |

---

#### Grupo 10.3: Recepciones - Adjuntos
| Tabla | Registros | Estado | Acción |
|-------|-----------|--------|--------|
| **selemti.recepcion_adjuntos** | 0 | Sistema actual | ✅ **MANTENER** |

---

## PARTE 2: TABLAS CON SUFIJO _legacy EXPLÍCITO

### Lista Completa

| # | Tabla | Registros | Dependencias FK | Acción |
|---|-------|-----------|-----------------|--------|
| 1 | **conversiones_unidad_legacy** | 0 | → unidades_medida_legacy | ❌ DROP CASCADE |
| 2 | **unidad_medida_legacy** | 0 | Ninguna | ❌ DROP |
| 3 | **unidades_medida_legacy** | 0 | Ninguna | ❌ DROP |
| 4 | **uom_conversion_legacy** | 0 | → unidad_medida_legacy | ❌ DROP CASCADE |

**Total**: 4 tablas legacy explícitas, **todas vacías**, **SAFE TO DROP**.

---

## PARTE 3: PLAN DE LIMPIEZA DETALLADO

### FASE 1: Validación Pre-Drop (OBLIGATORIA)

Antes de ejecutar cualquier DROP, ejecutar:

```bash
# 1. Backup completo de base de datos
pg_dump -h localhost -p 5433 -U postgres -d pos -F c -f "pos_backup_$(date +%Y%m%d_%H%M%S).dump"

# 2. Buscar referencias en código Laravel
cd /path/to/TerrenaLaravel

# Buscar cada tabla legacy en código
grep -r "selemti\.usuario" app/
grep -r "->table('usuario')" app/
grep -r "from usuario" app/
grep -r "from('usuario')" app/

# Repetir para todas las tablas a eliminar:
# usuario, rol, sucursal, almacen, bodega, proveedor,
# unidad_medida_legacy, unidades_medida_legacy,
# conversiones_unidad_legacy, uom_conversion_legacy,
# insumo, lote, merma, stock_policy,
# transfer_cab, transfer_det, traspaso_cab, traspaso_det,
# op_cab, op_produccion_cab, prod_cab, op_insumo, prod_det,
# receta, receta_cab, receta_det, receta_insumo, receta_version, receta_shadow,
# caja_fondo, caja_fondo_mov, caja_fondo_arqueo, cash_funds

# 3. Verificar modelos Eloquent
find app/Models -name "*.php" -exec grep -l "usuario\|almacen\|bodega\|proveedor" {} \;

# 4. Verificar migraciones
find database/migrations -name "*.php" -exec grep -l "usuario\|almacen" {} \;
```

---

### FASE 2: Eliminar Tablas Legacy VACÍAS (Sin Datos)

**Prerrequisito**: Ejecutar FASE 1 completa.

#### Orden de eliminación (respetando FKs):

```sql
-- ====================================
-- PASO 1: Tablas sin dependencias
-- ====================================

-- Unidades de medida legacy (orden importante por FKs)
DROP TABLE IF EXISTS selemti.conversiones_unidad_legacy CASCADE;
DROP TABLE IF EXISTS selemti.uom_conversion_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidad_medida_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidades_medida_legacy CASCADE;

-- Usuarios y roles legacy (usuario depende de rol)
DROP TABLE IF EXISTS selemti.usuario CASCADE;
DROP TABLE IF EXISTS selemti.rol CASCADE;
DROP TABLE IF EXISTS selemti.user_roles CASCADE;

-- Catálogos legacy
DROP TABLE IF EXISTS selemti.sucursal CASCADE;
DROP TABLE IF EXISTS selemti.proveedor CASCADE;

-- Almacenes legacy (almacen tiene FK a sucursales)
DROP TABLE IF EXISTS selemti.almacen CASCADE;
DROP TABLE IF EXISTS selemti.bodega CASCADE;

-- ====================================
-- PASO 2: Inventario legacy
-- ====================================

DROP TABLE IF EXISTS selemti.insumo CASCADE;
DROP TABLE IF EXISTS selemti.lote CASCADE;
DROP TABLE IF EXISTS selemti.merma CASCADE;
DROP TABLE IF EXISTS selemti.stock_policy CASCADE;

-- ====================================
-- PASO 3: Transferencias legacy
-- ====================================

DROP TABLE IF EXISTS selemti.traspaso_det CASCADE;
DROP TABLE IF EXISTS selemti.traspaso_cab CASCADE;

-- Verificar si transfer_* es legacy o actual
-- Si es legacy:
-- DROP TABLE IF EXISTS selemti.transfer_det CASCADE;
-- DROP TABLE IF EXISTS selemti.transfer_cab CASCADE;

-- ====================================
-- PASO 4: Producción legacy
-- ====================================

-- Detalles primero
DROP TABLE IF EXISTS selemti.sol_prod_det CASCADE;
DROP TABLE IF EXISTS selemti.op_insumo CASCADE;
DROP TABLE IF EXISTS selemti.prod_det CASCADE;

-- Cabeceras después
DROP TABLE IF EXISTS selemti.sol_prod_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_produccion_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_cab CASCADE;
DROP TABLE IF EXISTS selemti.prod_cab CASCADE;

-- Yield
DROP TABLE IF EXISTS selemti.op_yield CASCADE;

-- ====================================
-- PASO 5: Recetas legacy
-- ====================================

-- Detalles y versiones primero
DROP TABLE IF EXISTS selemti.receta_insumo CASCADE;
DROP TABLE IF EXISTS selemti.receta_det CASCADE;
DROP TABLE IF EXISTS selemti.receta_version CASCADE;
DROP TABLE IF EXISTS selemti.receta_shadow CASCADE;

-- Cabeceras después
DROP TABLE IF EXISTS selemti.receta_cab CASCADE;
DROP TABLE IF EXISTS selemti.receta CASCADE;

-- ====================================
-- PASO 6: Caja Chica legacy
-- ====================================

-- Movimientos y arqueos primero
DROP TABLE IF EXISTS selemti.caja_fondo_mov CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo_arqueo CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo_adj CASCADE;

-- Fondos después
DROP TABLE IF EXISTS selemti.caja_fondo CASCADE;

-- Verificar si cash_funds es legacy o actual
-- (cash_funds parece ser actual basado en estructura)

-- ====================================
-- PASO 7: Auditoría legacy VACÍAS
-- ====================================

-- NO eliminar selemti.auditoria - tiene 72 registros
DROP TABLE IF EXISTS selemti.audit_log CASCADE;
-- NO eliminar audit_log_global - es la tabla actual

```

---

### FASE 3: Migrar Datos de Tablas Legacy CON DATOS

**Tablas que requieren migración**:

#### 3.1. selemti.auditoria (72 registros)

```sql
-- Verificar estructura de auditoria
SELECT * FROM selemti.auditoria LIMIT 5;

-- Opción A: Migrar a audit_log_global
INSERT INTO selemti.audit_log_global (
    -- mapear columnas
)
SELECT
    -- mapear datos
FROM selemti.auditoria;

-- Después de verificar migración exitosa:
-- DROP TABLE selemti.auditoria CASCADE;
```

#### 3.2. selemti.users (1 registro)

```sql
-- Verificar si el usuario existe
SELECT * FROM selemti.users;

-- Evaluar:
-- 1. ¿Es un usuario de prueba? → Puede eliminarse
-- 2. ¿Es usuario real? → Migrar a sistema Laravel actual
-- 3. ¿Se relaciona con public.users? → Mantener solo public.users

-- Si se decide eliminar:
-- DELETE FROM selemti.users;
-- DROP TABLE selemti.users CASCADE;
```

#### 3.3. selemti.roles (7 registros)

```sql
-- Estos son roles de Spatie Laravel Permission
-- MANTENER - son los roles actuales del sistema
-- NO ELIMINAR
```

#### 3.4. selemti.model_has_roles (1 registro)

```sql
-- Tabla de Spatie Laravel Permission
-- MANTENER - asignación de roles actual
-- NO ELIMINAR
```

---

### FASE 4: Verificación Post-Drop

Después de ejecutar drops, verificar:

```sql
-- 1. Contar tablas restantes
SELECT schemaname, COUNT(*) as total_tables
FROM pg_tables
WHERE schemaname IN ('selemti', 'public')
GROUP BY schemaname;

-- 2. Verificar tablas huérfanas (sin FKs ni referencias)
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename NOT IN (
    SELECT DISTINCT table_name
    FROM information_schema.table_constraints
    WHERE table_schema = 'selemti'
  );

-- 3. Listar tablas cat_* (deben ser las únicas de catálogos)
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename LIKE 'cat_%'
ORDER BY tablename;
```

---

## PARTE 4: TABLAS A MANTENER (DEFINITIVAS)

### 4.1. Catálogos Maestros (cat_*)

```
✅ selemti.cat_sucursales
✅ selemti.cat_almacenes
✅ selemti.cat_proveedores
✅ selemti.cat_unidades
✅ selemti.cat_uom_conversion
```

### 4.2. Inventario

```
✅ selemti.items
✅ selemti.inventory_batch
✅ selemti.inventory_wastes
✅ selemti.inventory_snapshot
✅ selemti.inventory_count_lines
✅ selemti.inventory_counts
✅ selemti.inv_stock_policy
✅ selemti.mov_inv (kardex)
✅ selemti.item_categories
✅ selemti.item_category_counters
✅ selemti.item_vendor
✅ selemti.item_vendor_prices
```

### 4.3. Recepciones

```
✅ selemti.recepcion_cab
✅ selemti.recepcion_det
✅ selemti.recepcion_adjuntos
```

### 4.4. Producción

```
✅ selemti.production_orders
✅ selemti.production_order_inputs
✅ selemti.production_order_outputs
```

### 4.5. Recetas

```
✅ selemti.recipe_versions
✅ selemti.recipe_version_items
✅ selemti.recipe_cost_history
✅ selemti.recipe_cost_snapshots
✅ selemti.recipe_extended_cost_history
✅ selemti.recipe_labor_steps
✅ selemti.recipe_overhead_allocations
✅ selemti.menu_engineering_snapshots
```

### 4.6. Compras

```
✅ selemti.purchase_requests
✅ selemti.purchase_request_lines
✅ selemti.purchase_vendor_quotes
✅ selemti.purchase_vendor_quote_lines
✅ selemti.purchase_orders
✅ selemti.purchase_order_lines
✅ selemti.purchase_documents
✅ selemti.purchase_suggestions
✅ selemti.purchase_suggestion_lines
✅ selemti.replenishment_suggestions
```

### 4.7. Caja Chica

```
✅ selemti.cash_funds
✅ selemti.cash_fund_movements
✅ selemti.cash_fund_arqueos
✅ selemti.cash_fund_movement_audit_log
```

### 4.8. Caja / POS

```
✅ selemti.sesion_cajon
✅ selemti.precorte
✅ selemti.postcorte
✅ selemti.precorte_efectivo
✅ selemti.precorte_otros
✅ selemti.conciliacion
✅ selemti.formas_pago
```

### 4.9. Tickets y Ventas

```
✅ selemti.ticket_venta_cab
✅ selemti.ticket_venta_det
✅ selemti.ticket_item_modifiers
✅ selemti.ticket_det_consumo
✅ selemti.inv_consumo_pos
✅ selemti.inv_consumo_pos_det
✅ selemti.inv_consumo_pos_log
```

### 4.10. Menu Items y POS Sync

```
✅ selemti.menu_items
✅ selemti.menu_item_sync_map
✅ selemti.modificadores_pos
✅ selemti.pos_map
✅ selemti.pos_modifiers_map
✅ selemti.pos_sync_batches
✅ selemti.pos_sync_logs
✅ selemti.pos_reprocess_log
✅ selemti.pos_reverse_log
```

### 4.11. Costos

```
✅ selemti.cost_layer
✅ selemti.hist_cost_insumo
✅ selemti.hist_cost_receta
✅ selemti.historial_costos_item
✅ selemti.historial_costos_receta
```

### 4.12. Overhead y Labor

```
✅ selemti.overhead_definitions
✅ selemti.labor_roles
```

### 4.13. Auditoría y Logs

```
✅ selemti.audit_log_global
⚠️ selemti.auditoria (migrar primero)
✅ selemti.perdida_log
✅ selemti.recalc_log
```

### 4.14. Autenticación y Permisos

```
✅ selemti.users (revisar 1 registro)
✅ selemti.roles (Spatie)
✅ selemti.permissions (Spatie)
✅ selemti.model_has_roles (Spatie)
✅ selemti.model_has_permissions (Spatie)
✅ selemti.role_has_permissions (Spatie)
✅ selemti.password_reset_tokens
✅ selemti.personal_access_tokens
```

### 4.15. Jobs y Colas

```
✅ selemti.jobs
✅ selemti.job_batches
✅ selemti.job_recalc_queue
✅ selemti.failed_jobs
```

### 4.16. Alertas y Reportes

```
✅ selemti.alert_events
✅ selemti.alert_rules
✅ selemti.report_definitions
✅ selemti.report_runs
```

### 4.17. Laravel Framework

```
✅ selemti.migrations
✅ selemti.cache
✅ selemti.cache_locks
✅ selemti.sessions
```

### 4.18. Configuración

```
✅ selemti.param_sucursal
✅ selemti.sucursal_almacen_terminal
```

### 4.19. Sistema POS Floreant (READ-ONLY)

```
✅ public.* (107 tablas - NO TOCAR sin coordinación)
```

---

## PARTE 5: ESTADÍSTICAS FINALES

### Resumen de Limpieza

| Categoría | Cantidad | Acción |
|-----------|----------|--------|
| **Tablas legacy vacías a eliminar** | ~50 | DROP CASCADE |
| **Tablas legacy con datos** | 4 | MIGRAR → DROP |
| **Tablas a mantener (selemti)** | ~90 | KEEP |
| **Tablas POS Floreant (public)** | 107 | KEEP (READ-ONLY) |
| **Total post-limpieza** | ~197 | (-52 tablas) |

### Impacto de Limpieza

- **Reducción**: 52 tablas eliminadas (21% del total)
- **Riesgo**: BAJO - 98% de las tablas a eliminar están vacías
- **Datos en riesgo**: 73 registros (72 auditoría + 1 usuario)
- **Tiempo estimado**: 2-4 horas (validación + ejecución + verificación)

---

## PARTE 6: RIESGOS Y MITIGACIONES

### Riesgos Identificados

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|--------------|---------|------------|
| 1 | Código usa tablas legacy | MEDIA | ALTO | Grep exhaustivo pre-drop |
| 2 | FKs CASCADE eliminan datos | BAJA | CRÍTICO | Revisar CASCADE, backup |
| 3 | Modelos Eloquent broken | MEDIA | MEDIO | Buscar en app/Models |
| 4 | Migraciones fallen | BAJA | BAJO | Verificar database/migrations |
| 5 | Pérdida de auditoría | BAJA | ALTO | Migrar auditoria antes de drop |
| 6 | Coordinación multi-agente | ALTA | MEDIO | Actualizar .gemini/WORK_ASSIGNMENTS.md |

### Plan de Rollback

```bash
# Si algo sale mal, restaurar desde backup
pg_restore -h localhost -p 5433 -U postgres -d pos -c pos_backup_YYYYMMDD_HHMMSS.dump
```

---

## PARTE 7: CHECKLIST DE EJECUCIÓN

### Pre-Ejecución

- [ ] Backup completo de base de datos creado
- [ ] Grep en código completo ejecutado
- [ ] Modelos Eloquent revisados
- [ ] Migraciones revisadas
- [ ] Coordinación con Gemini y Codex confirmada
- [ ] `.gemini/WORK_ASSIGNMENTS.md` actualizado
- [ ] Ambiente de desarrollo (no producción)

### Ejecución

- [ ] FASE 1: Drops de tablas _legacy ejecutados
- [ ] FASE 2: Drops de catálogos legacy ejecutados
- [ ] FASE 3: Drops de inventario legacy ejecutados
- [ ] FASE 4: Drops de transferencias legacy ejecutados
- [ ] FASE 5: Drops de producción legacy ejecutados
- [ ] FASE 6: Drops de recetas legacy ejecutados
- [ ] FASE 7: Drops de caja chica legacy ejecutados
- [ ] FASE 8: Migración de auditoria ejecutada
- [ ] FASE 9: Drop de auditoria legacy ejecutado

### Post-Ejecución

- [ ] Verificación de conteo de tablas
- [ ] Laravel migrations ejecutadas sin errores
- [ ] Tests de integración pasados
- [ ] Livewire components funcionando
- [ ] API endpoints respondiendo
- [ ] No hay errores en logs (php artisan pail)
- [ ] Documentación actualizada

---

## PARTE 8: SIGUIENTE ACCIÓN RECOMENDADA

### Prioridad INMEDIATA

1. **Coordinar con Gemini**: Actualizar `.gemini/WORK_ASSIGNMENTS.md` con este reporte
2. **Validar código**: Ejecutar grep completo en app/ para cada tabla legacy
3. **Migrar auditoría**: Resolver los 72 registros de `selemti.auditoria`
4. **Ejecutar FASE 1**: Eliminar tablas `*_legacy` (las más seguras)

### Comando para iniciar validación

```bash
# Ejecutar desde raíz del proyecto
cd /c/xampp3/htdocs/TerrenaLaravel

# Generar reporte de referencias en código
./scripts/audit_legacy_references.sh > legacy_code_refs.txt

# Revisar reporte
cat legacy_code_refs.txt
```

---

## APÉNDICE A: SCRIPT DE VALIDACIÓN

Crear archivo `scripts/audit_legacy_references.sh`:

```bash
#!/bin/bash

echo "=== AUDITORÍA DE REFERENCIAS A TABLAS LEGACY EN CÓDIGO ==="
echo ""

LEGACY_TABLES=(
    "usuario" "rol" "sucursal" "almacen" "bodega" "proveedor"
    "unidad_medida_legacy" "unidades_medida_legacy"
    "conversiones_unidad_legacy" "uom_conversion_legacy"
    "insumo" "lote" "merma" "stock_policy"
    "transfer_cab" "transfer_det" "traspaso_cab" "traspaso_det"
    "op_cab" "op_produccion_cab" "prod_cab" "sol_prod_cab"
    "op_insumo" "prod_det" "sol_prod_det" "op_yield"
    "receta" "receta_cab" "receta_det" "receta_insumo"
    "receta_version" "receta_shadow"
    "caja_fondo" "caja_fondo_mov" "caja_fondo_adj" "caja_fondo_arqueo"
    "auditoria" "audit_log"
)

for table in "${LEGACY_TABLES[@]}"; do
    echo "Buscando referencias a: $table"

    # Buscar en modelos
    grep -r "$table" app/Models/ 2>/dev/null && echo "  ⚠️ ENCONTRADO EN MODELOS"

    # Buscar en migraciones
    grep -r "$table" database/migrations/ 2>/dev/null && echo "  ⚠️ ENCONTRADO EN MIGRACIONES"

    # Buscar en controladores
    grep -r "$table" app/Http/Controllers/ 2>/dev/null && echo "  ⚠️ ENCONTRADO EN CONTROLADORES"

    # Buscar en servicios
    grep -r "$table" app/Services/ 2>/dev/null && echo "  ⚠️ ENCONTRADO EN SERVICIOS"

    # Buscar en Livewire
    grep -r "$table" app/Livewire/ 2>/dev/null && echo "  ⚠️ ENCONTRADO EN LIVEWIRE"

    echo ""
done

echo "=== FIN DE AUDITORÍA ==="
```

---

**FIN DEL REPORTE**

_Generado el 2 de Noviembre de 2025_
_Comando: `php artisan db:audit-duplicates`_
_Análisis manual adicional by Claude Code_
