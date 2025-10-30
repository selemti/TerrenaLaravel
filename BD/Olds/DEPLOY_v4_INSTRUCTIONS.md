# 📋 INSTRUCCIONES DE DEPLOY - PostgreSQL 9.5
## Version 4 - FIXED (Compatible con PostgreSQL 9.5)

**Fecha:** 2025-10-17
**Archivo SQL:** `DEPLOY_CONSOLIDADO_FULL_PG95-v4-FIXED.sql`
**Script Deploy:** `DEPLOY_v4_SAFE.ps1`

---

## 🎯 CORRECCIONES APLICADAS

### Corrección Principal
✅ **EXECUTE FUNCTION → EXECUTE PROCEDURE** (153 ocurrencias corregidas)

PostgreSQL 9.5 no soporta la sintaxis `EXECUTE FUNCTION` en triggers. Todas las referencias fueron actualizadas a `EXECUTE PROCEDURE`.

### Correcciones Previas (ya incluidas en v3)
✅ ALTER TABLE ADD COLUMN IF NOT EXISTS reemplazado con bloques DO
✅ UNIQUE constraints con COALESCE reemplazados con CREATE UNIQUE INDEX
✅ Metacomandos de psql eliminados
✅ IF NOT EXISTS agregado a todas las tablas y tipos

---

## ⚠️ PRE-REQUISITOS

### 1. Verificar Versión de PostgreSQL
```powershell
psql --version
# Debe mostrar: psql (PostgreSQL) 9.5.x
```

### 2. Verificar Conexión
```powershell
psql -h localhost -p 5432 -U postgres -d floreant -c "SELECT version();"
```

### 3. Backup de Base de Datos
```powershell
pg_dump -h localhost -p 5432 -U postgres -d floreant -F c -f "backup_floreant_$(Get-Date -Format 'yyyyMMdd_HHmmss').backup"
```

---

## 🚀 MÉTODO 1: DEPLOY AUTOMÁTICO (RECOMENDADO)

### Paso 1: Ejecutar Script PowerShell

```powershell
cd C:\xampp3\htdocs\TerrenaLaravel\BD

# Dry Run (prueba sin cambios reales)
.\DEPLOY_v4_SAFE.ps1 -DryRun

# Ejecución Real
.\DEPLOY_v4_SAFE.ps1 -Host localhost -Port 5432 -Database floreant -User postgres
```

### Paso 2: Revisar Resultados

El script generará:
- ✅ **Backup automático** del esquema selemti
- ✅ **Log detallado** de la ejecución
- ✅ **Verificación automática** de objetos críticos
- ✅ **Reporte de errores** con colores

**Códigos de salida:**
- `0` = Éxito total
- `1` = Éxito con errores menores (revisar log)
- `2` = Falló (requiere intervención)

---

## 🔧 MÉTODO 2: DEPLOY MANUAL

### Paso 1: Crear Backup Manual
```powershell
pg_dump -h localhost -p 5432 -U postgres -d floreant -n selemti -n public --schema-only -F p -f "backup_pre_deploy.sql"
```

### Paso 2: Ejecutar SQL
```powershell
psql -h localhost -p 5432 -U postgres -d floreant -v ON_ERROR_STOP=0 -f "DEPLOY_CONSOLIDADO_FULL_PG95-v4-FIXED.sql" 2>&1 | Tee-Object -FilePath "deploy_manual.log"
```

**Parámetros importantes:**
- `-v ON_ERROR_STOP=0` = Continuar después de errores
- `2>&1` = Capturar tanto stdout como stderr
- `Tee-Object` = Mostrar en consola Y guardar en log

### Paso 3: Verificar Objetos Críticos
```sql
-- Verificar esquema
SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='selemti';
-- Debe retornar: 1

-- Verificar tablas críticas
SELECT table_name
FROM information_schema.tables
WHERE table_schema='selemti'
  AND table_name IN ('users', 'sesion_cajon', 'precorte', 'postcorte', 'conciliacion')
ORDER BY table_name;
-- Debe retornar: 5 tablas

-- Verificar triggers
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema='selemti'
  AND trigger_name IN ('trg_precorte_after_insert', 'trg_postcorte_after_insert')
ORDER BY trigger_name;
-- Debe retornar: 2+ triggers

-- Verificar funciones
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema='selemti'
  AND routine_name LIKE '%postcorte%'
ORDER BY routine_name;
-- Debe retornar: fn_generar_postcorte, fn_postcorte_after_insert
```

---

## 🔍 PROBLEMAS COMUNES Y SOLUCIONES

### Error: "role 'selemti_user' already exists"
**Causa:** Usuario ya fue creado en deploy previo
**Solución:** Es un error esperado, puede ignorarse

### Error: "relation already exists"
**Causa:** Tablas ya existen de deploy previo
**Solución:** Normal en deploy idempotente, puede ignorarse

### Error: "syntax error near EXECUTE FUNCTION"
**Causa:** Archivo SQL no corregido
**Solución:** Asegúrese de usar `DEPLOY_CONSOLIDADO_FULL_PG95-v4-FIXED.sql`

### Error: "permission denied for schema selemti"
**Causa:** Usuario sin permisos
**Solución:**
```sql
GRANT ALL ON SCHEMA selemti TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA selemti TO postgres;
```

### Error: "password authentication failed"
**Causa:** Contraseña incorrecta
**Solución:** Verificar en `pg_hba.conf` o usar variable de entorno:
```powershell
$env:PGPASSWORD = "tu_password"
```

---

## ✅ VERIFICACIÓN POST-DEPLOY

### Script Automático
```powershell
psql -h localhost -p 5432 -U postgres -d floreant -f "post_deploy_verify.sql"
```

### Verificación Manual
```sql
-- 1. Contar tablas en esquema selemti
SELECT COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema='selemti';
-- Esperado: 50+ tablas

-- 2. Verificar triggers activos
SELECT COUNT(*) as total_triggers
FROM information_schema.triggers
WHERE trigger_schema='selemti';
-- Esperado: 3+ triggers

-- 3. Verificar funciones
SELECT COUNT(*) as total_functions
FROM information_schema.routines
WHERE routine_schema='selemti' AND routine_type='FUNCTION';
-- Esperado: 10+ funciones

-- 4. Verificar constraint crítico
SELECT conname
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'selemti'
  AND c.conrelid = 'selemti.precorte'::regclass
  AND conname = 'uq_precorte_sesion_id';
-- Esperado: 1 fila

-- 5. Verificar CHECK constraint actualizado
SELECT pg_get_constraintdef(c.oid) as constraint_def
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'selemti'
  AND c.conrelid = 'selemti.sesion_cajon'::regclass
  AND conname = 'sesion_cajon_estatus_check';
-- Debe contener: EN_CORTE, CONCILIADA, OBSERVADA
```

---

## 🛑 ROLLBACK (En caso de error crítico)

### Opción 1: Restaurar desde Backup
```powershell
# Eliminar esquema corrupto
psql -h localhost -p 5432 -U postgres -d floreant -c "DROP SCHEMA IF EXISTS selemti CASCADE;"

# Restaurar backup
psql -h localhost -p 5432 -U postgres -d floreant -f "backup_pre_deploy.sql"
```

### Opción 2: Eliminar y Reintentar
```sql
-- Eliminar esquema completo
DROP SCHEMA IF EXISTS selemti CASCADE;

-- Re-ejecutar deploy
-- (Volver a ejecutar el archivo SQL)
```

---

## 📊 ESTADÍSTICAS DEL ARCHIVO SQL

**Archivo:** DEPLOY_CONSOLIDADO_FULL_PG95-v4-FIXED.sql
**Tamaño:** 6.1 MB
**Líneas:** ~170,000
**Objetos creados (aprox):**
- Esquemas: 1
- Tablas: 55+
- Funciones: 15+
- Triggers: 5+
- Vistas: 10+
- Índices: 20+
- Constraints: 100+

**Tiempo estimado de ejecución:** 2-5 minutos (dependiendo del hardware)

---

## 📞 SOPORTE

Si encuentra errores no documentados:

1. **Revisar el log generado** para encontrar el error exacto
2. **Verificar versión de PostgreSQL:** Debe ser 9.5.x
3. **Verificar permisos** del usuario de base de datos
4. **Consultar documentación** en `docs/GAP_ANALYSIS_COMPLETED-20251017.md`

---

## 📝 NOTAS IMPORTANTES

### ⚠️ Encoding UTF-8
El archivo SQL debe ejecutarse con encoding UTF-8. Si ve caracteres raros en los comentarios (Ãƒâ€), es un problema de encoding pero **NO afecta la funcionalidad**.

### ⚠️ Idempotencia
Este script es idempotente, lo que significa que puede ejecutarse múltiples veces sin causar errores. Los objetos existentes se omiten automáticamente.

### ⚠️ ON_ERROR_STOP=0
Recomendamos usar `ON_ERROR_STOP=0` para continuar después de errores esperados (como "object already exists"). Esto es normal en deploys idempotentes.

### ⚠️ Migraciones Futuras
Para cambios futuros, use el sistema de migraciones de Laravel:
```bash
php artisan migrate
```

Este deploy SQL es para la creación inicial del esquema completo.

---

**Última actualización:** 2025-10-17
**Versión:** 4.0 (PostgreSQL 9.5 Compatible)
**Autor:** Sistema de Análisis Automatizado
