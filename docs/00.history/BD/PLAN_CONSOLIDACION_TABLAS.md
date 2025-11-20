# PLAN DE CONSOLIDACIÓN DE TABLAS DUPLICADAS - SELEMTI

**Fecha**: 02 Noviembre 2025
**Auditoría Base**: `REPORTE_AUDITORIA_DUPLICADOS.md`
**Objetivo**: Consolidar tablas duplicadas asegurando que NO se pierda información

---

## RESUMEN EJECUTIVO

- **Total grupos duplicados**: 9
- **Tablas con datos**: 2 (selemti.users, selemti.roles)
- **Tablas vacías a eliminar**: 13 tablas
- **Campos únicos a migrar**: 2 campos en usuarios

**Estrategia**:
1. Agregar campos únicos faltantes a tablas activas
2. Eliminar tablas vacías (sin migración de datos)
3. Verificar referencias en código antes de eliminar

---

## ANÁLISIS DE CAMPOS ÚNICOS

### 1. USUARIOS: selemti.users vs selemti.usuario

#### Estado Actual:
- ✅ **selemti.users**: 1 registro, 13 columnas, **ACTIVA** (múltiples FK apuntan aquí)
- ❌ **selemti.usuario**: 0 registros, 10 columnas, **VACÍA**

#### Comparación de Campos:

**Campos ÚNICOS en selemti.usuario (NO en users)**:
| Campo | Tipo | Descripción | Acción |
|-------|------|-------------|--------|
| `floreant_user_id` | integer | Link al usuario del sistema POS Floreant | ⚠️ **AGREGAR a users** |
| `meta` | jsonb | Metadata flexible en formato JSON | ⚠️ **AGREGAR a users** |
| `rol_id` | integer | FK a selemti.rol (tabla vacía, no útil) | ❌ NO migrar (tabla destino vacía) |

**Campos ÚNICOS en selemti.users (NO en usuario)**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `sucursal_id` | varchar(10) | Sucursal asignada al usuario |
| `fecha_ultimo_login` | timestamp | Tracking de último login |
| `intentos_login` | integer | Contador de intentos fallidos (seguridad) |
| `bloqueado_hasta` | timestamp | Timestamp de bloqueo temporal |
| `updated_at` | timestamp | Auditoría de actualizaciones |
| `remember_token` | varchar(100) | Token de sesión Laravel |

#### Migración Requerida:
```sql
-- PASO 1: Agregar campos únicos a selemti.users
ALTER TABLE selemti.users
  ADD COLUMN floreant_user_id INTEGER NULL,
  ADD COLUMN meta JSONB NULL;

-- PASO 2: Comentar para documentación
COMMENT ON COLUMN selemti.users.floreant_user_id IS 'Link al usuario en el sistema POS Floreant (public.users.user_id)';
COMMENT ON COLUMN selemti.users.meta IS 'Metadata flexible en formato JSON para almacenar propiedades adicionales del usuario';

-- PASO 3: Crear índice para búsquedas por floreant_user_id
CREATE INDEX idx_users_floreant_user_id ON selemti.users(floreant_user_id) WHERE floreant_user_id IS NOT NULL;

-- PASO 4: Agregar FK opcional a public.users (si se requiere integridad referencial)
-- ALTER TABLE selemti.users
--   ADD CONSTRAINT fk_users_floreant_user
--   FOREIGN KEY (floreant_user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;
```

#### Después de Migración:
```sql
-- PASO 5: Eliminar tabla vacía selemti.usuario
DROP TABLE IF EXISTS selemti.usuario CASCADE;
```

---

### 2. ROLES: selemti.roles vs selemti.rol

#### Estado Actual:
- ✅ **selemti.roles**: 7 registros, 7 columnas, **ACTIVA** (Sistema Spatie Laravel Permission)
- ❌ **selemti.rol**: 0 registros, 3 columnas, **VACÍA**

#### Comparación de Campos:

**Campos ÚNICOS en selemti.rol (NO en roles)**:
| Campo | Tipo | Descripción | Acción |
|-------|------|-------------|--------|
| `codigo` | text | Código corto del rol | ⚠️ **OPCIONAL - Evaluar agregar** |

**Campos ÚNICOS en selemti.roles (NO en rol)**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `guard_name` | varchar(255) | Guard de autenticación Laravel |
| `display_name` | varchar(255) | Nombre para mostrar en UI |
| `description` | text | Descripción del rol |
| `created_at`, `updated_at` | timestamp | Auditoría |

#### Migración Requerida:
```sql
-- OPCIÓN 1: Agregar campo 'codigo' a selemti.roles (OPCIONAL)
-- Solo si se necesita un código corto para los roles
ALTER TABLE selemti.roles
  ADD COLUMN codigo VARCHAR(20) NULL;

COMMENT ON COLUMN selemti.roles.codigo IS 'Código corto del rol (ej: ADM, GER, VEN)';

-- Agregar constraint de unicidad
ALTER TABLE selemti.roles
  ADD CONSTRAINT roles_codigo_unique UNIQUE (codigo);

-- OPCIÓN 2: No agregar nada (el campo 'name' ya sirve como código único)
-- El sistema Spatie ya usa 'name' como identificador único
```

#### Después de Migración:
```sql
-- Eliminar tabla vacía selemti.rol
DROP TABLE IF EXISTS selemti.rol CASCADE;
```

---

## PLAN DE EJECUCIÓN

### FASE 1: Preparación (SIN ELIMINAR NADA)

#### 1.1. Verificar Referencias en Código

```bash
# Buscar referencias a tablas que se van a eliminar
cd /c/xampp3/htdocs/TerrenaLaravel

# Buscar 'usuario' (tabla a eliminar)
grep -r "usuario" app/ --include="*.php" | grep -v "usuario_" | grep -v "usuarios"

# Buscar 'rol' (tabla a eliminar, no confundir con 'roles')
grep -r "\\brol\\b" app/ --include="*.php"

# Buscar referencias a tablas legacy
grep -r "unidad_medida_legacy\|unidades_medida_legacy\|uom_conversion_legacy\|conversiones_unidad_legacy" app/ --include="*.php"
```

#### 1.2. Backup de Base de Datos

```bash
# Backup completo antes de cualquier cambio
cd C:/xampp3/htdocs/TerrenaLaravel/BD
"C:/Program Files (x86)/PostgreSQL/9.5/bin/pg_dump.exe" -h localhost -p 5433 -U postgres -d pos -F c -f "backup_antes_consolidacion_$(date +%Y%m%d_%H%M%S).backup"
```

---

### FASE 2: Migración de Campos Únicos

#### 2.1. Agregar Campos a selemti.users

```sql
-- Script: 01_agregar_campos_users.sql
BEGIN;

-- Agregar campos únicos de selemti.usuario a selemti.users
ALTER TABLE selemti.users
  ADD COLUMN IF NOT EXISTS floreant_user_id INTEGER NULL,
  ADD COLUMN IF NOT EXISTS meta JSONB NULL;

-- Comentarios de documentación
COMMENT ON COLUMN selemti.users.floreant_user_id IS 'Link al usuario en el sistema POS Floreant (public.users.user_id)';
COMMENT ON COLUMN selemti.users.meta IS 'Metadata flexible en formato JSON para almacenar propiedades adicionales del usuario';

-- Índice para búsquedas
CREATE INDEX IF NOT EXISTS idx_users_floreant_user_id
  ON selemti.users(floreant_user_id)
  WHERE floreant_user_id IS NOT NULL;

-- FK opcional (comentado por defecto, descomentar si se requiere integridad referencial estricta)
-- ALTER TABLE selemti.users
--   ADD CONSTRAINT fk_users_floreant_user
--   FOREIGN KEY (floreant_user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;

COMMIT;
```

**Ejecutar**:
```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" -h localhost -p 5433 -U postgres -d pos -f BD/01_agregar_campos_users.sql
```

#### 2.2. (OPCIONAL) Agregar Campo 'codigo' a selemti.roles

```sql
-- Script: 02_agregar_codigo_roles.sql
-- SOLO ejecutar si se necesita un código corto para los roles

BEGIN;

ALTER TABLE selemti.roles
  ADD COLUMN IF NOT EXISTS codigo VARCHAR(20) NULL;

COMMENT ON COLUMN selemti.roles.codigo IS 'Código corto del rol (ej: ADM, GER, VEN)';

ALTER TABLE selemti.roles
  ADD CONSTRAINT roles_codigo_unique UNIQUE (codigo);

COMMIT;
```

---

### FASE 3: Eliminación de Tablas Vacías

#### 3.1. Eliminar Tablas Legacy (Sin Datos, Sin FK entrantes)

```sql
-- Script: 03_drop_tables_legacy.sql
-- SOLO ejecutar después de verificar que no hay referencias en código

BEGIN;

-- Tablas de Unidades de Medida Legacy (4 tablas)
DROP TABLE IF EXISTS selemti.conversiones_unidad_legacy CASCADE;
DROP TABLE IF EXISTS selemti.uom_conversion_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidad_medida_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidades_medida_legacy CASCADE;

COMMIT;
```

**Verificar antes de ejecutar**:
```bash
# Verificar que no hay referencias en código
grep -r "conversiones_unidad_legacy\|uom_conversion_legacy\|unidad_medida_legacy\|unidades_medida_legacy" app/ --include="*.php"
```

**Ejecutar**:
```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" -h localhost -p 5433 -U postgres -d pos -f BD/03_drop_tables_legacy.sql
```

#### 3.2. Eliminar Tablas Duplicadas de Catálogos (Vacías)

```sql
-- Script: 04_drop_tables_catalogs_empty.sql

BEGIN;

-- Catálogos vacíos (5 tablas)
DROP TABLE IF EXISTS selemti.sucursal CASCADE;
DROP TABLE IF EXISTS selemti.almacen CASCADE;
DROP TABLE IF EXISTS selemti.proveedor CASCADE;
DROP TABLE IF EXISTS selemti.receta CASCADE;
DROP TABLE IF EXISTS selemti.receta_cab CASCADE;

COMMIT;
```

**Verificar antes de ejecutar**:
```bash
# Verificar que no hay referencias en código
grep -r "\\bsucursal\\b\|\\balmacen\\b\|\\bproveedor\\b" app/Models/ --include="*.php" | grep "table = "
grep -r "\\breceta\\b\|receta_cab" app/Models/ --include="*.php" | grep "table = "
```

**Ejecutar**:
```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" -h localhost -p 5433 -U postgres -d pos -f BD/04_drop_tables_catalogs_empty.sql
```

#### 3.3. Eliminar Tablas de Caja Chica Duplicadas (Vacías)

```sql
-- Script: 05_drop_tables_cash_fund_empty.sql

BEGIN;

-- Caja Chica duplicadas vacías (2 tablas)
-- Nota: Mantener las tablas que están siendo usadas por el módulo CashFund actual
DROP TABLE IF EXISTS selemti.caja_fondo CASCADE;
DROP TABLE IF EXISTS selemti.cash_funds CASCADE;

-- Verificar qué tabla está siendo usada antes de eliminar
-- Revisar: app/Models/CashFund.php para ver qué tabla usa

COMMIT;
```

**Verificar antes de ejecutar**:
```bash
# Ver qué tabla está usando el modelo CashFund
grep "protected \$table" app/Models/CashFund/CashFund.php

# Si el modelo usa 'cash_funds', NO ejecutar el DROP de cash_funds
# Si el modelo usa 'caja_fondo', NO ejecutar el DROP de caja_fondo
```

#### 3.4. Eliminar Tablas de Usuarios y Roles Vacías

```sql
-- Script: 06_drop_tables_users_roles.sql
-- EJECUTAR SOLO DESPUÉS de agregar campos a users en FASE 2

BEGIN;

-- Eliminar tabla usuario vacía (ya migramos campos únicos a users)
DROP TABLE IF EXISTS selemti.usuario CASCADE;

-- Eliminar tabla rol vacía
DROP TABLE IF EXISTS selemti.rol CASCADE;

COMMIT;
```

**Ejecutar**:
```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" -h localhost -p 5433 -U postgres -d pos -f BD/06_drop_tables_users_roles.sql
```

---

### FASE 4: Validación Post-Consolidación

#### 4.1. Verificar Tablas Eliminadas

```sql
-- Verificar que las tablas fueron eliminadas
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND (
    tablename LIKE '%_legacy'
    OR tablename IN ('usuario', 'rol', 'sucursal', 'almacen', 'proveedor', 'receta', 'receta_cab')
  )
ORDER BY tablename;

-- Resultado esperado: 0 filas
```

#### 4.2. Verificar Tablas Activas

```sql
-- Verificar que las tablas correctas permanecen
SELECT
  schemaname,
  tablename,
  (SELECT COUNT(*) FROM selemti.cat_sucursales) as count_sucursales,
  (SELECT COUNT(*) FROM selemti.cat_almacenes) as count_almacenes,
  (SELECT COUNT(*) FROM selemti.cat_proveedores) as count_proveedores,
  (SELECT COUNT(*) FROM selemti.cat_unidades) as count_unidades,
  (SELECT COUNT(*) FROM selemti.users) as count_users,
  (SELECT COUNT(*) FROM selemti.roles) as count_roles
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename IN ('cat_sucursales', 'cat_almacenes', 'cat_proveedores', 'cat_unidades', 'users', 'roles')
ORDER BY tablename;
```

#### 4.3. Verificar Nuevos Campos en selemti.users

```sql
-- Verificar que los campos fueron agregados
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name = 'users'
  AND column_name IN ('floreant_user_id', 'meta')
ORDER BY column_name;

-- Resultado esperado: 2 filas (floreant_user_id, meta)
```

#### 4.4. Probar Aplicación

```bash
# Ejecutar tests de la aplicación
cd /c/xampp3/htdocs/TerrenaLaravel
php artisan test --testsuite=Feature

# Verificar que los modelos funcionan correctamente
php artisan tinker
# >>> App\Models\User::first();
# >>> App\Models\Catalogs\Sucursal::count();
# >>> exit
```

---

## RESUMEN DE TABLAS A ELIMINAR

### Tablas Legacy (4):
- ❌ `selemti.conversiones_unidad_legacy` (0 registros)
- ❌ `selemti.unidad_medida_legacy` (0 registros)
- ❌ `selemti.unidades_medida_legacy` (0 registros)
- ❌ `selemti.uom_conversion_legacy` (0 registros)

### Tablas Duplicadas de Catálogos (5):
- ❌ `selemti.sucursal` (0 registros) → Usar `cat_sucursales`
- ❌ `selemti.almacen` (0 registros) → Usar `cat_almacenes`
- ❌ `selemti.proveedor` (0 registros) → Usar `cat_proveedores`
- ❌ `selemti.receta` (0 registros) → Usar `recipes` (si existe)
- ❌ `selemti.receta_cab` (0 registros) → Usar `recipes` (si existe)

### Tablas Duplicadas de Usuarios/Roles (2):
- ❌ `selemti.usuario` (0 registros) → Usar `users` (después de agregar campos)
- ❌ `selemti.rol` (0 registros) → Usar `roles`

### Tablas Duplicadas de Caja Chica (2):
- ⚠️ `selemti.caja_fondo` (0 registros) → Verificar cuál usa el módulo
- ⚠️ `selemti.cash_funds` (0 registros) → Verificar cuál usa el módulo

**TOTAL A ELIMINAR**: 13 tablas (11 seguras + 2 verificar)

---

## TABLAS A MANTENER (Post-Consolidación)

### Catálogos (cat_*):
- ✅ `selemti.cat_sucursales` (3 registros)
- ✅ `selemti.cat_almacenes` (0 registros)
- ✅ `selemti.cat_proveedores` (0 registros)
- ✅ `selemti.cat_unidades` (0 registros)
- ✅ `selemti.cat_uom_conversion` (0 registros)

### Usuarios y Roles:
- ✅ `selemti.users` (1 registro) + campos nuevos: `floreant_user_id`, `meta`
- ✅ `selemti.roles` (7 registros)

### Operaciones:
- ✅ `selemti.items`
- ✅ `selemti.batches`
- ✅ `selemti.mov_inv`
- ✅ `selemti.recepciones`
- ✅ `selemti.recipes`
- ✅ `selemti.recipe_lines`
- ✅ `selemti.production_orders`
- ✅ `selemti.purchase_orders`
- ✅ Módulo CashFund (cash_fund_movements, cash_fund_settlements, etc.)

### Sistema POS (READ-ONLY):
- ✅ `public.*` (todas las tablas de Floreant POS) - NO TOCAR

---

## RIESGOS Y MITIGACIONES

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Código legacy referencia tablas eliminadas | Media | Alto | Buscar referencias con grep antes de eliminar |
| CASCADE drops eliminan datos relacionados | Baja | Alto | Todas las tablas a eliminar están vacías |
| Modelos Laravel usan tabla incorrecta | Baja | Medio | Verificar `protected $table` en modelos |
| Pérdida de campos únicos | Baja | Alto | Agregar campos a tablas activas ANTES de eliminar |
| FK break en producción | Baja | Alto | Verificar FK con `\d+ tabla` antes de DROP |

---

## CHECKLIST DE VALIDACIÓN

Antes de ejecutar FASE 3 (eliminación):

- [ ] ✅ Backup completo de base de datos creado
- [ ] ✅ Campos únicos agregados a selemti.users (FASE 2.1)
- [ ] ✅ Verificar referencias en código con grep (todas las tablas)
- [ ] ✅ Verificar que todas las tablas a eliminar tienen 0 registros
- [ ] ✅ Verificar que los modelos Laravel usan las tablas correctas
- [ ] ✅ Coordinar con Gemini y Codex (revisar .gemini/WORK_ASSIGNMENTS.md)
- [ ] ✅ Ejecutar en ambiente de desarrollo (no producción)
- [ ] ✅ Tests de aplicación pasan correctamente post-migración

Después de ejecutar FASE 3 (eliminación):

- [ ] ✅ Verificar que tablas fueron eliminadas (FASE 4.1)
- [ ] ✅ Verificar que tablas activas permanecen (FASE 4.2)
- [ ] ✅ Verificar nuevos campos en users (FASE 4.3)
- [ ] ✅ Probar aplicación y ejecutar tests (FASE 4.4)
- [ ] ✅ Actualizar modelos Laravel si es necesario
- [ ] ✅ Actualizar documentación del proyecto

---

## SCRIPTS SQL GENERADOS

Todos los scripts SQL están en la carpeta `docs/docs/BD/NoviembreDocsDocs/`:

1. `01_agregar_campos_users.sql` - Agregar campos a selemti.users
2. `02_agregar_codigo_roles.sql` - (Opcional) Agregar código a roles
3. `03_drop_tables_legacy.sql` - Eliminar tablas legacy
4. `04_drop_tables_catalogs_empty.sql` - Eliminar catálogos vacíos
5. `05_drop_tables_cash_fund_empty.sql` - Eliminar caja chica duplicadas
6. `06_drop_tables_users_roles.sql` - Eliminar usuarios/roles vacíos

**Orden de ejecución recomendado**:
1. Backup completo
2. Ejecutar script 01 (agregar campos)
3. Verificar con grep (buscar referencias en código)
4. Ejecutar scripts 03, 04, 05, 06 (eliminaciones)
5. Validar con queries de FASE 4

---

## COORDINACIÓN MULTI-AGENTE

### Antes de ejecutar:
- **Gemini CLI**: Revisar si hay trabajo pendiente en `.gemini/WORK_ASSIGNMENTS.md` que use estas tablas
- **Codex**: Verificar si hay PRs pendientes con migraciones que creen/modifiquen estas tablas
- **Claude Code**: Actualizar modelos Laravel después de consolidación

### Después de ejecutar:
- Actualizar `.gemini/WORK_ASSIGNMENTS.md` con estado de consolidación
- Documentar cambios en `CLAUDE.md` si es necesario
- Crear migración Laravel que refleje los cambios en estructura (para futuros ambientes)

---

_Documento generado el 02 Noviembre 2025 por Claude Code_
_Basado en auditoría: docs/BD/REPORTE_AUDITORIA_DUPLICADOS.md_
