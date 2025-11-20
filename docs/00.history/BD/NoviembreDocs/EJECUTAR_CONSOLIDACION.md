# GUÍA DE EJECUCIÓN - CONSOLIDACIÓN DE TABLAS

**Fecha**: 02 Noviembre 2025
**Objetivo**: Ejecutar la consolidación de tablas duplicadas en selemti de forma segura

---

## PRE-REQUISITOS

Antes de ejecutar cualquier script:

1. ✅ Backup completo de la base de datos
2. ✅ Verificar que NO estás en producción (solo desarrollo)
3. ✅ Coordinar con Gemini y Codex (revisar `.gemini/WORK_ASSIGNMENTS.md`)
4. ✅ Cerrar la aplicación y cualquier conexión activa a la base de datos

---

## PASO 1: BACKUP COMPLETO

```bash
cd C:/xampp3/htdocs/TerrenaLaravel/docs/docs/BD/NoviembreDocsDocs

# Crear backup completo
"C:/Program Files (x86)/PostgreSQL/9.5/bin/pg_dump.exe" \
  -h localhost -p 5433 -U postgres -d pos \
  -F c \
  -f "backup_antes_consolidacion_$(date +%Y%m%d_%H%M%S).backup"

# Verificar que el backup se creó correctamente
ls -lh backup_antes_consolidacion_*.backup
```

---

## PASO 2: VERIFICAR REFERENCIAS EN CÓDIGO

**Opción A - Bash (Git Bash, WSL)**:
```bash
cd C:/xampp3/htdocs/TerrenaLaravel
bash docs/docs/BD/NoviembreDocsDocs/00_verificar_referencias_codigo.sh
```

**Opción B - Manual con grep**:
```bash
cd C:/xampp3/htdocs/TerrenaLaravel

# Verificar tablas legacy
grep -r "unidad_medida_legacy\|unidades_medida_legacy\|uom_conversion_legacy\|conversiones_unidad_legacy" app/ --include="*.php"

# Verificar catálogos
grep -r "table.*=.*['\"]sucursal['\"]" app/ --include="*.php"
grep -r "table.*=.*['\"]almacen['\"]" app/ --include="*.php"
grep -r "table.*=.*['\"]proveedor['\"]" app/ --include="*.php"

# Verificar usuarios/roles
grep -r "table.*=.*['\"]usuario['\"]" app/ --include="*.php"
grep -r "table.*=.*['\"]rol['\"]" app/ --include="*.php"
```

**Resultado esperado**: No deben aparecer referencias a estas tablas en los modelos.

Si aparecen referencias, debes actualizar los modelos antes de continuar.

---

## PASO 3: EJECUTAR SCRIPTS SQL

### 3.1. Agregar Campos a selemti.users

```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" \
  -h localhost -p 5433 -U postgres -d pos \
  -f docs/docs/BD/NoviembreDocsDocs/01_agregar_campos_users.sql
```

**Verificar resultado**:
```sql
-- Debe mostrar 2 columnas nuevas: floreant_user_id, meta
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'users'
  AND column_name IN ('floreant_user_id', 'meta');
```

### 3.2. (OPCIONAL) Agregar Campo codigo a selemti.roles

**Solo ejecutar si necesitas códigos cortos para roles**:
```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" \
  -h localhost -p 5433 -U postgres -d pos \
  -f docs/docs/BD/NoviembreDocsDocs/02_agregar_codigo_roles.sql
```

### 3.3. Eliminar Tablas Legacy

```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" \
  -h localhost -p 5433 -U postgres -d pos \
  -f docs/docs/BD/NoviembreDocsDocs/03_drop_tables_legacy.sql
```

**Verificar resultado**:
```sql
-- Debe mostrar 0 filas
SELECT tablename FROM pg_tables
WHERE schemaname = 'selemti' AND tablename LIKE '%_legacy';
```

### 3.4. Eliminar Catálogos Vacíos

```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" \
  -h localhost -p 5433 -U postgres -d pos \
  -f docs/docs/BD/NoviembreDocsDocs/04_drop_tables_catalogs_empty.sql
```

**Verificar resultado**:
```sql
-- Debe mostrar 0 filas
SELECT tablename FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename IN ('sucursal', 'almacen', 'proveedor', 'receta', 'receta_cab');
```

### 3.5. Eliminar Tablas de Caja Chica (VERIFICAR ANTES)

**IMPORTANTE**: Verificar qué tabla usa el modelo CashFund:
```bash
grep "protected \$table" app/Models/CashFund/CashFund.php
```

Si NO usa `caja_fondo` ni `cash_funds`, ejecutar:
```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" \
  -h localhost -p 5433 -U postgres -d pos \
  -f docs/docs/BD/NoviembreDocsDocs/05_drop_tables_cash_fund_empty.sql
```

Si sí las usa, **NO ejecutar este script**.

### 3.6. Eliminar Tablas de Usuarios y Roles

```bash
PGPASSWORD=T3rr3n4#p0s "C:/Program Files (x86)/PostgreSQL/9.5/bin/psql.exe" \
  -h localhost -p 5433 -U postgres -d pos \
  -f docs/docs/BD/NoviembreDocsDocs/06_drop_tables_users_roles.sql
```

**Verificar resultado**:
```sql
-- Debe mostrar 0 filas
SELECT tablename FROM pg_tables
WHERE schemaname = 'selemti' AND tablename IN ('usuario', 'rol');
```

---

## PASO 4: VALIDACIÓN POST-CONSOLIDACIÓN

### 4.1. Verificar Tablas Eliminadas

```sql
-- Debe mostrar 0 filas (todas las tablas duplicadas eliminadas)
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND (
    tablename LIKE '%_legacy'
    OR tablename IN ('usuario', 'rol', 'sucursal', 'almacen', 'proveedor', 'receta', 'receta_cab', 'caja_fondo', 'cash_funds')
  )
ORDER BY tablename;
```

### 4.2. Verificar Tablas Correctas Permanecen

```sql
-- Debe mostrar las tablas activas con sus conteos
SELECT
  tablename,
  (SELECT COUNT(*) FROM selemti.cat_sucursales) as sucursales,
  (SELECT COUNT(*) FROM selemti.cat_almacenes) as almacenes,
  (SELECT COUNT(*) FROM selemti.cat_proveedores) as proveedores,
  (SELECT COUNT(*) FROM selemti.users) as users,
  (SELECT COUNT(*) FROM selemti.roles) as roles
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename IN ('cat_sucursales', 'cat_almacenes', 'cat_proveedores', 'users', 'roles')
ORDER BY tablename;
```

### 4.3. Verificar Nuevos Campos en users

```sql
-- Debe mostrar 2 filas: floreant_user_id (integer), meta (jsonb)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'users'
  AND column_name IN ('floreant_user_id', 'meta')
ORDER BY column_name;
```

### 4.4. Contar Tablas Totales

```sql
-- Antes: 142 tablas en selemti
-- Después: ~129 tablas (eliminamos ~13)
SELECT COUNT(*) as total_tablas
FROM pg_tables
WHERE schemaname = 'selemti';
```

---

## PASO 5: PROBAR APLICACIÓN

```bash
cd C:/xampp3/htdocs/TerrenaLaravel

# Limpiar caché
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Ejecutar tests
php artisan test --testsuite=Feature

# Iniciar servidor de desarrollo
php artisan serve
```

**Verificar manualmente**:
1. Login de usuarios funciona
2. Catálogos (sucursales, almacenes, proveedores) se cargan correctamente
3. Módulos principales (Inventario, Compras, Caja Chica) funcionan sin errores

---

## PASO 6: ACTUALIZAR MODELOS LARAVEL (Si es necesario)

Si algún modelo referenciaba tablas eliminadas, actualizar:

```php
// Ejemplo: Si había un modelo Usuario que usaba selemti.usuario
// app/Models/Usuario.php -> Cambiar a usar User.php

// Buscar referencias:
grep -r "class Usuario extends" app/Models/ --include="*.php"
```

---

## PASO 7: DOCUMENTAR CAMBIOS

1. Actualizar `.gemini/WORK_ASSIGNMENTS.md` con estado de consolidación
2. Actualizar `CLAUDE.md` si es necesario (agregar nota sobre nuevos campos en users)
3. Crear migración Laravel que refleje los cambios (para futuros ambientes)

```bash
# Crear migración para registrar cambios
php artisan make:migration add_floreant_fields_to_users_table
```

---

## ROLLBACK (En caso de error)

Si algo sale mal durante la consolidación:

```bash
# Restaurar desde backup
cd C:/xampp3/htdocs/TerrenaLaravel/docs/docs/BD/NoviembreDocsDocs

# Listar backups disponibles
ls -lh backup_antes_consolidacion_*.backup

# Restaurar (CUIDADO: esto sobrescribirá la BD actual)
"C:/Program Files (x86)/PostgreSQL/9.5/bin/pg_restore.exe" \
  -h localhost -p 5433 -U postgres -d pos \
  --clean --if-exists \
  -v \
  backup_antes_consolidacion_YYYYMMDD_HHMMSS.backup
```

---

## RESUMEN DE SCRIPTS

| Script | Descripción | Obligatorio | Orden |
|--------|-------------|-------------|-------|
| `00_verificar_referencias_codigo.sh` | Buscar referencias en código | ✅ Sí | 1 |
| `01_agregar_campos_users.sql` | Agregar campos a users | ✅ Sí | 2 |
| `02_agregar_codigo_roles.sql` | Agregar código a roles | ⚠️ Opcional | 3 |
| `03_drop_tables_legacy.sql` | Eliminar tablas legacy | ✅ Sí | 4 |
| `04_drop_tables_catalogs_empty.sql` | Eliminar catálogos vacíos | ✅ Sí | 5 |
| `05_drop_tables_cash_fund_empty.sql` | Eliminar caja chica duplicadas | ⚠️ Verificar | 6 |
| `06_drop_tables_users_roles.sql` | Eliminar usuarios/roles vacíos | ✅ Sí | 7 |

---

## CHECKLIST FINAL

- [ ] ✅ Backup completo creado
- [ ] ✅ Verificación de referencias en código completada (0 referencias)
- [ ] ✅ Script 01 ejecutado (campos agregados a users)
- [ ] ✅ Script 03 ejecutado (tablas legacy eliminadas)
- [ ] ✅ Script 04 ejecutado (catálogos vacíos eliminados)
- [ ] ✅ Script 05 ejecutado (caja chica verificada y eliminada si aplica)
- [ ] ✅ Script 06 ejecutado (usuarios/roles vacíos eliminados)
- [ ] ✅ Validación post-consolidación completada
- [ ] ✅ Tests de aplicación pasando
- [ ] ✅ Aplicación funciona correctamente
- [ ] ✅ Documentación actualizada

---

**IMPORTANTE**: Si tienes dudas en cualquier paso, detente y consulta el documento completo:
`docs/BD/PLAN_CONSOLIDACION_TABLAS.md`
