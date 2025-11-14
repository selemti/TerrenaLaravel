# AUDITORÍA DE TABLAS DUPLICADAS Y LEGACY

**Fecha**: 02 November 2025 12:55:30
**Total Tablas**: 249
  - Selemti: 142
  - Public: 107

---

## RESUMEN EJECUTIVO

- **Grupos de tablas duplicadas encontrados**: 9
- **Tablas legacy (con sufijo _legacy)**: 4
- **Tablas legacy con datos**: 0
- **Impacto**: MEDIO - Requiere revisión y limpieza

---

## 1. TABLAS DUPLICADAS - Usuarios

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| public.users | 9 | 17 | POS Floreant (Producción) | ✅ MANTENER - NO TOCAR |
| selemti.users | 1 | 13 | Legacy/Antigua | ⚠️ REVISAR - Tiene datos |
| selemti.usuario | 0 | 10 | Legacy/Antigua | ❌ ELIMINAR (vacía) |

**Análisis**:

- **public.users**: Sistema POS Floreant en producción, READ-ONLY, no modificar sin coordinación.
- **selemti.users**: Tabla antigua con **1 registros**, revisar si se está usando.
- **selemti.usuario**: Tabla sin datos, candidata para eliminación.

**Dependencias (Foreign Keys)**:

- **selemti.usuario**:
  - `rol_id` → `selemti.rol(id)`

**Estructura de columnas**:

- **public.users** (17 columnas):
  ```
  auto_id (integer) NOT NULL
  user_id (integer) NULL
  user_pass (character varying(16)) NOT NULL
  first_name (character varying(30)) NULL
  last_name (character varying(30)) NULL
  ssn (character varying(30)) NULL
  cost_per_hour (double precision) NULL
  clocked_in (boolean) NULL
  last_clock_in_time (timestamp without time zone) NULL
  last_clock_out_time (timestamp without time zone) NULL
  ... y 7 columnas más
  ```
- **selemti.users** (13 columnas):
  ```
  id (bigint) NOT NULL
  username (character varying(50)) NOT NULL
  password_hash (character varying(255)) NOT NULL
  email (character varying(255)) NULL
  nombre_completo (character varying(100)) NOT NULL
  sucursal_id (character varying(10)) NULL
  activo (boolean) NULL
  fecha_ultimo_login (timestamp without time zone) NULL
  intentos_login (integer) NULL
  bloqueado_hasta (timestamp without time zone) NULL
  ... y 3 columnas más
  ```
- **selemti.usuario** (10 columnas):
  ```
  id (bigint) NOT NULL
  username (text) NOT NULL
  nombre (text) NOT NULL
  email (text) NULL
  rol_id (integer) NOT NULL
  activo (boolean) NOT NULL
  password_hash (text) NULL
  floreant_user_id (integer) NULL
  meta (jsonb) NULL
  created_at (timestamp without time zone) NOT NULL
  ```

---

## 2. TABLAS DUPLICADAS - Roles

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| selemti.rol | 0 | 3 | Legacy/Antigua | ❌ ELIMINAR (vacía) |
| selemti.roles | 7 | 7 | Legacy/Antigua | ⚠️ REVISAR - Tiene datos |

**Análisis**:

- **selemti.rol**: Tabla sin datos, candidata para eliminación.
- **selemti.roles**: Tabla antigua con **7 registros**, revisar si se está usando.

**Dependencias (Foreign Keys)**:

- Sin foreign keys detectadas.

**Estructura de columnas**:

- **selemti.rol** (3 columnas):
  ```
  id (integer) NOT NULL
  codigo (text) NOT NULL
  nombre (text) NOT NULL
  ```
- **selemti.roles** (7 columnas):
  ```
  id (bigint) NOT NULL
  name (character varying(255)) NOT NULL
  guard_name (character varying(255)) NOT NULL
  created_at (timestamp without time zone) NULL
  updated_at (timestamp without time zone) NULL
  display_name (character varying(255)) NULL
  description (text) NULL
  ```

---

## 3. TABLAS DUPLICADAS - Sucursales

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| selemti.sucursal | 0 | 3 | Legacy/Antigua | ❌ ELIMINAR (vacía) |
| selemti.cat_sucursales | 3 | 8 | Normalizada (Actual) | ✅ MANTENER - Usar en app |

**Análisis**:

- **selemti.sucursal**: Tabla sin datos, candidata para eliminación.
- **selemti.cat_sucursales**: Tabla normalizada del catálogo, usar esta versión en la aplicación.

**Dependencias (Foreign Keys)**:

- Sin foreign keys detectadas.

**Estructura de columnas**:

- **selemti.sucursal** (3 columnas):
  ```
  id (text) NOT NULL
  nombre (text) NOT NULL
  activo (boolean) NOT NULL
  ```
- **selemti.cat_sucursales** (8 columnas):
  ```
  id (bigint) NOT NULL
  clave (character varying(16)) NOT NULL
  nombre (character varying(120)) NOT NULL
  ubicacion (character varying(160)) NULL
  activo (boolean) NOT NULL
  created_at (timestamp without time zone) NULL
  updated_at (timestamp without time zone) NULL
  pos_location (character varying(64)) NULL
  ```

---

## 4. TABLAS DUPLICADAS - Almacenes

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| selemti.almacen | 0 | 4 | Legacy/Antigua | ❌ ELIMINAR (vacía) |
| selemti.cat_almacenes | 0 | 7 | Normalizada (Actual) | ✅ MANTENER - Usar en app |

**Análisis**:

- **selemti.almacen**: Tabla sin datos, candidata para eliminación.
- **selemti.cat_almacenes**: Tabla normalizada del catálogo, usar esta versión en la aplicación.

**Dependencias (Foreign Keys)**:

- **selemti.almacen**:
  - `sucursal_id` → `selemti.cat_sucursales(id)`
- **selemti.cat_almacenes**:
  - `sucursal_id` → `selemti.cat_sucursales(id)`

**Estructura de columnas**:

- **selemti.almacen** (4 columnas):
  ```
  id (text) NOT NULL
  sucursal_id (bigint) NOT NULL
  nombre (text) NOT NULL
  activo (boolean) NOT NULL
  ```
- **selemti.cat_almacenes** (7 columnas):
  ```
  id (bigint) NOT NULL
  clave (character varying(16)) NOT NULL
  nombre (character varying(80)) NOT NULL
  sucursal_id (bigint) NULL
  activo (boolean) NOT NULL
  created_at (timestamp without time zone) NULL
  updated_at (timestamp without time zone) NULL
  ```

---

## 5. TABLAS DUPLICADAS - Proveedores

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| selemti.proveedor | 0 | 4 | Legacy/Antigua | ❌ ELIMINAR (vacía) |
| selemti.cat_proveedores | 0 | 23 | Normalizada (Actual) | ✅ MANTENER - Usar en app |

**Análisis**:

- **selemti.proveedor**: Tabla sin datos, candidata para eliminación.
- **selemti.cat_proveedores**: Tabla normalizada del catálogo, usar esta versión en la aplicación.

**Dependencias (Foreign Keys)**:

- Sin foreign keys detectadas.

**Estructura de columnas**:

- **selemti.proveedor** (4 columnas):
  ```
  id (text) NOT NULL
  nombre (text) NOT NULL
  rfc (text) NULL
  activo (boolean) NOT NULL
  ```
- **selemti.cat_proveedores** (23 columnas):
  ```
  id (bigint) NOT NULL
  rfc (character varying(20)) NOT NULL
  nombre (character varying(120)) NOT NULL
  telefono (character varying(30)) NULL
  email (character varying(120)) NULL
  activo (boolean) NOT NULL
  created_at (timestamp without time zone) NULL
  updated_at (timestamp without time zone) NULL
  razon_social (character varying(200)) NULL
  tipo_comprobante (character varying(10)) NULL
  ... y 13 columnas más
  ```

---

## 6. TABLAS DUPLICADAS - Unidades de Medida

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| selemti.unidad_medida_legacy | 0 | 7 | Legacy | ❌ ELIMINAR (vacía) |
| selemti.unidades_medida_legacy | 0 | 9 | Legacy | ❌ ELIMINAR (vacía) |
| selemti.cat_unidades | 0 | 6 | Normalizada (Actual) | ✅ MANTENER - Usar en app |

**Análisis**:

- **selemti.unidad_medida_legacy**: Tabla legacy vacía, **SAFE TO DROP**.
- **selemti.unidades_medida_legacy**: Tabla legacy vacía, **SAFE TO DROP**.
- **selemti.cat_unidades**: Tabla normalizada del catálogo, usar esta versión en la aplicación.

**Dependencias (Foreign Keys)**:

- Sin foreign keys detectadas.

**Estructura de columnas**:

- **selemti.unidad_medida_legacy** (7 columnas):
  ```
  id (integer) NOT NULL
  codigo (text) NOT NULL
  nombre (text) NOT NULL
  tipo (text) NOT NULL
  es_base (boolean) NOT NULL
  factor_a_base (numeric) NOT NULL
  decimales (integer) NOT NULL
  ```
- **selemti.unidades_medida_legacy** (9 columnas):
  ```
  id (integer) NOT NULL
  codigo (character varying(10)) NOT NULL
  nombre (character varying(50)) NOT NULL
  tipo (character varying(10)) NOT NULL
  categoria (character varying(20)) NULL
  es_base (boolean) NULL
  factor_conversion_base (numeric) NULL
  decimales (integer) NULL
  created_at (timestamp without time zone) NULL
  ```
- **selemti.cat_unidades** (6 columnas):
  ```
  id (bigint) NOT NULL
  created_at (timestamp without time zone) NULL
  updated_at (timestamp without time zone) NULL
  clave (character varying(16)) NULL
  nombre (character varying(64)) NULL
  activo (boolean) NOT NULL
  ```

---

## 7. TABLAS DUPLICADAS - Conversiones de Unidad

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| selemti.conversiones_unidad_legacy | 0 | 8 | Legacy | ❌ ELIMINAR (vacía) |
| selemti.uom_conversion_legacy | 0 | 4 | Legacy | ❌ ELIMINAR (vacía) |

**Análisis**:

- **selemti.conversiones_unidad_legacy**: Tabla legacy vacía, **SAFE TO DROP**.
- **selemti.uom_conversion_legacy**: Tabla legacy vacía, **SAFE TO DROP**.

**Dependencias (Foreign Keys)**:

- **selemti.conversiones_unidad_legacy**:
  - `unidad_destino_id` → `selemti.unidades_medida_legacy(id)`
  - `unidad_origen_id` → `selemti.unidades_medida_legacy(id)`
- **selemti.uom_conversion_legacy**:
  - `destino_id` → `selemti.unidad_medida_legacy(id)`
  - `origen_id` → `selemti.unidad_medida_legacy(id)`

**Estructura de columnas**:

- **selemti.conversiones_unidad_legacy** (8 columnas):
  ```
  id (integer) NOT NULL
  unidad_origen_id (integer) NOT NULL
  unidad_destino_id (integer) NOT NULL
  factor_conversion (numeric) NOT NULL
  formula_directa (text) NULL
  precision_estimada (numeric) NULL
  activo (boolean) NULL
  created_at (timestamp without time zone) NULL
  ```
- **selemti.uom_conversion_legacy** (4 columnas):
  ```
  id (integer) NOT NULL
  origen_id (integer) NOT NULL
  destino_id (integer) NOT NULL
  factor (numeric) NOT NULL
  ```

---

## 8. TABLAS DUPLICADAS - Recetas

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| selemti.receta | 0 | 7 | Legacy/Antigua | ❌ ELIMINAR (vacía) |
| selemti.receta_cab | 0 | 12 | Legacy/Antigua | ❌ ELIMINAR (vacía) |

**Análisis**:

- **selemti.receta**: Tabla sin datos, candidata para eliminación.
- **selemti.receta_cab**: Tabla sin datos, candidata para eliminación.

**Dependencias (Foreign Keys)**:

- Sin foreign keys detectadas.

**Estructura de columnas**:

- **selemti.receta** (7 columnas):
  ```
  id (bigint) NOT NULL
  codigo (text) NULL
  nombre (text) NOT NULL
  porciones (numeric) NOT NULL
  pvp_objetivo (numeric) NULL
  activo (boolean) NOT NULL
  meta (jsonb) NULL
  ```
- **selemti.receta_cab** (12 columnas):
  ```
  id (character varying(20)) NOT NULL
  nombre_plato (character varying(100)) NOT NULL
  codigo_plato_pos (character varying(20)) NULL
  categoria_plato (character varying(50)) NULL
  porciones_standard (integer) NULL
  instrucciones_preparacion (text) NULL
  tiempo_preparacion_min (integer) NULL
  costo_standard_porcion (numeric) NULL
  precio_venta_sugerido (numeric) NULL
  activo (boolean) NULL
  ... y 2 columnas más
  ```

---

## 9. TABLAS DUPLICADAS - Caja Chica / Cash Fund

| Tabla | Registros | Columnas | Tipo | Acción Recomendada |
|-------|-----------|----------|------|--------------------||
| selemti.caja_fondo | 0 | 9 | Legacy/Antigua | ❌ ELIMINAR (vacía) |
| selemti.cash_funds | 0 | 12 | Legacy/Antigua | ❌ ELIMINAR (vacía) |

**Análisis**:

- **selemti.caja_fondo**: Tabla sin datos, candidata para eliminación.
- **selemti.cash_funds**: Tabla sin datos, candidata para eliminación.

**Dependencias (Foreign Keys)**:

- **selemti.cash_funds**:
  - `created_by_user_id` → `selemti.users(id)`
  - `responsable_user_id` → `selemti.users(id)`

**Estructura de columnas**:

- **selemti.caja_fondo** (9 columnas):
  ```
  id (bigint) NOT NULL
  sucursal_id (integer) NOT NULL
  fecha (date) NOT NULL
  monto_inicial (numeric) NOT NULL
  moneda (character varying(3)) NULL
  estado (character varying(16)) NOT NULL
  creado_por (integer) NOT NULL
  created_at (timestamp without time zone) NULL
  updated_at (timestamp without time zone) NULL
  ```
- **selemti.cash_funds** (12 columnas):
  ```
  id (bigint) NOT NULL
  sucursal_id (integer) NOT NULL
  fecha (date) NOT NULL
  monto_inicial (numeric) NOT NULL
  moneda (character varying(3)) NOT NULL
  estado (character varying(255)) NOT NULL
  responsable_user_id (bigint) NOT NULL
  created_by_user_id (bigint) NOT NULL
  closed_at (timestamp without time zone) NULL
  created_at (timestamp without time zone) NULL
  ... y 2 columnas más
  ```

---

## 10. TABLAS CON SUFIJO _legacy

Lista completa de tablas con sufijo `_legacy`:

| Tabla | Registros | Acción |
|-------|-----------|--------|
| selemti.conversiones_unidad_legacy | 0 | ❌ ELIMINAR (vacía) |
| selemti.unidad_medida_legacy | 0 | ❌ ELIMINAR (vacía) |
| selemti.unidades_medida_legacy | 0 | ❌ ELIMINAR (vacía) |
| selemti.uom_conversion_legacy | 0 | ❌ ELIMINAR (vacía) |

---

## 11. PLAN DE LIMPIEZA

### FASE 1: Eliminar tablas legacy VACÍAS (Sin datos)

**Criterio**: Tablas con sufijo `_legacy` o duplicadas que tienen 0 registros.

```sql
DROP TABLE IF EXISTS selemti."conversiones_unidad_legacy" CASCADE;
DROP TABLE IF EXISTS selemti."unidad_medida_legacy" CASCADE;
DROP TABLE IF EXISTS selemti."unidades_medida_legacy" CASCADE;
DROP TABLE IF EXISTS selemti."uom_conversion_legacy" CASCADE;
DROP TABLE IF EXISTS selemti."usuario" CASCADE;
DROP TABLE IF EXISTS selemti."rol" CASCADE;
DROP TABLE IF EXISTS selemti."sucursal" CASCADE;
DROP TABLE IF EXISTS selemti."almacen" CASCADE;
DROP TABLE IF EXISTS selemti."proveedor" CASCADE;
DROP TABLE IF EXISTS selemti."unidad_medida_legacy" CASCADE;
DROP TABLE IF EXISTS selemti."unidades_medida_legacy" CASCADE;
DROP TABLE IF EXISTS selemti."conversiones_unidad_legacy" CASCADE;
DROP TABLE IF EXISTS selemti."uom_conversion_legacy" CASCADE;
DROP TABLE IF EXISTS selemti."receta" CASCADE;
DROP TABLE IF EXISTS selemti."receta_cab" CASCADE;
DROP TABLE IF EXISTS selemti."caja_fondo" CASCADE;
DROP TABLE IF EXISTS selemti."cash_funds" CASCADE;
```

### FASE 2: Migrar datos de tablas legacy CON DATOS

**Criterio**: Tablas legacy que tienen registros, migrar a tablas normalizadas.

```sql
-- EJEMPLO: Migrar sucursal → cat_sucursales
-- INSERT INTO selemti.cat_sucursales (id, nombre, activo, created_at)
-- SELECT id, nombre, activo, NOW() FROM selemti.sucursal;
-- DROP TABLE selemti.sucursal CASCADE;

```

### FASE 3: Verificar código antes de eliminar

Antes de ejecutar drops, buscar referencias en código:

```bash
# Buscar referencias a tablas legacy en código PHP
grep -r "conversiones_unidad_legacy" app/
grep -r "unidad_medida_legacy" app/
grep -r "unidades_medida_legacy" app/
grep -r "uom_conversion_legacy" app/
# ... repetir para todas las tablas a eliminar
```

---

## 12. RIESGOS Y VALIDACIONES

### Riesgos:

1. **Código legacy**: Modelos o queries pueden referenciar tablas antiguas.
2. **Foreign Keys**: CASCADE drops pueden eliminar datos relacionados.
3. **Datos importantes**: Tablas legacy pueden contener datos no migrados.
4. **Coordinación multi-agente**: Gemini, Codex y Claude deben estar alineados.

### Validaciones requeridas antes de DROP:

1. ✅ Verificar 0 registros en tabla (`SELECT COUNT(*)`)
2. ✅ Buscar referencias en código (`grep -r "tabla" app/`)
3. ✅ Verificar foreign keys (`\d+ tabla` en psql)
4. ✅ Backup completo de base de datos (`pg_dump`)
5. ✅ Coordinar con otros agentes (Gemini, Codex)
6. ✅ Ejecutar en ambiente de desarrollo primero

---

## 13. TABLAS A MANTENER (Post-Limpieza)

Lista de tablas correctas que deben permanecer:

### Catálogos (cat_*):
- ✅ selemti.cat_almacenes (0 registros)
- ✅ selemti.cat_proveedores (0 registros)
- ✅ selemti.cat_sucursales (3 registros)
- ✅ selemti.cat_unidades (0 registros)
- ✅ selemti.cat_uom_conversion (0 registros)

### Operaciones actuales:
- ✅ selemti.items (0 registros)
- ✅ selemti.mov_inv (0 registros)
- ✅ selemti.production_orders (0 registros)
- ✅ selemti.cash_funds (0 registros)
- ✅ selemti.cash_fund_movements (0 registros)
- ✅ selemti.purchase_orders (0 registros)

### Sistema POS (READ-ONLY):
- ✅ public.* (todas las tablas de Floreant POS)

---

## ESTADÍSTICAS FINALES

- **Total tablas selemti**: 142
- **Total tablas public**: 107
- **Grupos duplicados**: 9
- **Tablas legacy**: 4
- **Tablas legacy vacías**: 4
- **Tablas legacy con datos**: 0

---

_Reporte generado automáticamente por Laravel Artisan command `db:audit-duplicates`_
