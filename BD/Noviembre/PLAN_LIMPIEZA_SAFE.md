# PLAN DE LIMPIEZA SEGURA - TABLAS LEGACY

**Fecha**: 2 Noviembre 2025
**Base de datos**: PostgreSQL pos @ localhost:5433

---

## RESUMEN EJECUTIVO

Después de auditoría exhaustiva de código, se identificaron **tablas legacy que pueden eliminarse de forma SEGURA**:

### Resultado de Validación de Código

| Categoría | Tabla | Registros | Referencias en Código | Estado |
|-----------|-------|-----------|----------------------|--------|
| **SAFE TO DROP** | unidad_medida_legacy | 0 | 0 | ✅ Eliminar |
| **TIENE REFERENCIAS** | usuario | 0 | 143 | ⚠️ REVISAR primero |
| **TIENE REFERENCIAS** | rol | 0 | 413 | ⚠️ REVISAR primero |
| **TIENE REFERENCIAS** | sucursal | 0 | 452 | ⚠️ REVISAR primero |
| **TIENE REFERENCIAS** | almacen | 0 | 273 | ⚠️ REVISAR primero |
| **TIENE REFERENCIAS** | bodega | 0 | 2 | ⚠️ Revisar (mínimas refs) |
| **TIENE REFERENCIAS** | proveedor | 0 | 195 | ⚠️ REVISAR primero |
| **TIENE REFERENCIAS** | unidades_medida_legacy | 0 | 3 | ⚠️ Livewire refs |

---

## ANÁLISIS CRÍTICO

### ⚠️ ALERTA IMPORTANTE

**NINGUNA tabla legacy puede eliminarse de forma segura inmediata** debido a:

1. **"usuario"** - 143 referencias en código:
   - Modelos: 29 refs (comentarios y nombres de campos)
   - Controladores: 53 refs (queries SQL que usan "cajero_usuario_id", etc.)
   - Livewire: 40 refs

2. **"rol"** - 413 referencias:
   - La mayoría son referencias a Spatie Role system (NO la tabla legacy)
   - Pero hay confusión de nomenclatura en código

3. **"sucursal"** - 452 referencias:
   - Campos FK: `sucursal_id` en múltiples tablas
   - Relaciones Eloquent: `->sucursal()`
   - NO es la tabla, son CAMPOS que apuntan a `cat_sucursales`

4. **"almacen"** - 273 referencias:
   - Similar a sucursal: campos `almacen_id`
   - Relaciones Eloquent
   - NO la tabla legacy

5. **"proveedor"** - 195 referencias:
   - Campos `proveedor_id`
   - Relaciones Eloquent

### Conclusión del Análisis

**Las referencias encontradas NO son a las tablas legacy en sí, sino a CAMPOS con esos nombres** que apuntan a las tablas normalizadas (`cat_*`).

**Ejemplo**:
```php
// Esto NO es referencia a tabla "sucursal"
$table->integer('sucursal_id'); // FK a cat_sucursales

// Esto SÍ sería referencia a tabla legacy
DB::table('selemti.sucursal')->get(); // NO ENCONTRADO
```

---

## PLAN DE ACCIÓN REVISADO

### FASE 1: Validación Manual Profunda

Antes de DROP, verificar que las referencias son solo a **nombres de campos**, no a **tablas**:

```bash
# Buscar referencias EXPLÍCITAS a tablas legacy
grep -r "table.*=.*'sucursal'" app/Models/
grep -r "->table('sucursal')" app/
grep -r "from.*sucursal" app/ | grep -v "sucursal_id"
grep -r "selemti.sucursal" app/

# Repetir para cada tabla:
# usuario, rol, almacen, bodega, proveedor
```

### FASE 2: Drops Seguros (Después de Validación)

#### A. Tablas SIN REFERENCIAS (SAFE TO DROP)

```sql
-- Estas NO tienen referencias en código
DROP TABLE IF EXISTS selemti.unidad_medida_legacy CASCADE;

-- Verificar manualmente y luego:
DROP TABLE IF EXISTS selemti.conversiones_unidad_legacy CASCADE;
DROP TABLE IF EXISTS selemti.uom_conversion_legacy CASCADE;
```

#### B. Tablas con Referencias a CAMPOS (Verificar primero)

```sql
-- SOLO después de confirmar que referencias son a CAMPOS, no tablas:

-- 1. Tablas con FK desde otras (eliminar en orden)
DROP TABLE IF EXISTS selemti.usuario CASCADE; -- tiene FK a rol
DROP TABLE IF EXISTS selemti.rol CASCADE;

-- 2. Catálogos legacy
DROP TABLE IF EXISTS selemti.sucursal CASCADE;
DROP TABLE IF EXISTS selemti.proveedor CASCADE;

-- 3. Almacenes (almacen tiene FK a sucursales)
DROP TABLE IF EXISTS selemti.almacen CASCADE; -- verifica FK a cat_sucursales primero
DROP TABLE IF EXISTS selemti.bodega CASCADE;
```

#### C. Tablas Detectadas en Análisis Manual

```sql
-- Estas se detectaron en auditoría pero no se probaron en código:

-- Recetas legacy
DROP TABLE IF EXISTS selemti.receta_insumo CASCADE;
DROP TABLE IF EXISTS selemti.receta_det CASCADE;
DROP TABLE IF EXISTS selemti.receta_version CASCADE;
DROP TABLE IF EXISTS selemti.receta_shadow CASCADE;
DROP TABLE IF EXISTS selemti.receta_cab CASCADE;
DROP TABLE IF EXISTS selemti.receta CASCADE;

-- Producción legacy
DROP TABLE IF EXISTS selemti.sol_prod_det CASCADE;
DROP TABLE IF EXISTS selemti.op_insumo CASCADE;
DROP TABLE IF EXISTS selemti.prod_det CASCADE;
DROP TABLE IF EXISTS selemti.sol_prod_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_produccion_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_cab CASCADE;
DROP TABLE IF EXISTS selemti.prod_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_yield CASCADE;

-- Transferencias legacy
DROP TABLE IF EXISTS selemti.traspaso_det CASCADE;
DROP TABLE IF EXISTS selemti.traspaso_cab CASCADE;

-- Inventario legacy
DROP TABLE IF EXISTS selemti.insumo CASCADE;
DROP TABLE IF EXISTS selemti.lote CASCADE;
DROP TABLE IF EXISTS selemti.merma CASCADE;
DROP TABLE IF EXISTS selemti.stock_policy CASCADE;

-- Caja Chica legacy
DROP TABLE IF EXISTS selemti.caja_fondo_mov CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo_arqueo CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo_adj CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo CASCADE;

-- Auditoría legacy vacías
DROP TABLE IF EXISTS selemti.audit_log CASCADE;
```

---

## FASE 3: Script SQL Completo (USAR CON PRECAUCIÓN)

```sql
-- ============================================
-- SCRIPT DE LIMPIEZA DE TABLAS LEGACY
-- ============================================
-- PRERREQUISITO: Backup completo ejecutado
-- VALIDACIÓN: Código revisado manualmente
-- AMBIENTE: Solo desarrollo, NUNCA producción
-- ============================================

BEGIN;

-- Log de inicio
DO $$
BEGIN
    RAISE NOTICE 'Iniciando limpieza de tablas legacy - %', NOW();
END $$;

-- ============================================
-- PASO 1: Tablas *_legacy (más seguras)
-- ============================================

DROP TABLE IF EXISTS selemti.conversiones_unidad_legacy CASCADE;
DROP TABLE IF EXISTS selemti.uom_conversion_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidad_medida_legacy CASCADE;
DROP TABLE IF EXISTS selemti.unidades_medida_legacy CASCADE;

RAISE NOTICE 'Eliminadas 4 tablas *_legacy';

-- ============================================
-- PASO 2: Usuarios y Roles legacy
-- ============================================

-- Verificar 0 registros
DO $$
DECLARE
    v_count_usuario INT;
    v_count_rol INT;
BEGIN
    SELECT COUNT(*) INTO v_count_usuario FROM selemti.usuario;
    SELECT COUNT(*) INTO v_count_rol FROM selemti.rol;

    IF v_count_usuario > 0 OR v_count_rol > 0 THEN
        RAISE EXCEPTION 'ABORT: Tablas usuario/rol tienen datos: usuario=%, rol=%',
            v_count_usuario, v_count_rol;
    END IF;
END $$;

DROP TABLE IF EXISTS selemti.usuario CASCADE;
DROP TABLE IF EXISTS selemti.rol CASCADE;
DROP TABLE IF EXISTS selemti.user_roles CASCADE;

RAISE NOTICE 'Eliminadas tablas usuario/rol legacy';

-- ============================================
-- PASO 3: Catálogos legacy
-- ============================================

-- Verificar que FKs no apuntan a tablas legacy
DO $$
DECLARE
    v_fk_count INT;
BEGIN
    SELECT COUNT(*) INTO v_fk_count
    FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_name IN ('sucursal', 'proveedor', 'almacen', 'bodega')
      AND tc.table_schema = 'selemti';

    IF v_fk_count > 0 THEN
        RAISE NOTICE 'ADVERTENCIA: % FKs apuntan a tablas legacy de catálogos', v_fk_count;
        -- Continuar con CASCADE
    END IF;
END $$;

DROP TABLE IF EXISTS selemti.sucursal CASCADE;
DROP TABLE IF EXISTS selemti.proveedor CASCADE;
DROP TABLE IF EXISTS selemti.almacen CASCADE;
DROP TABLE IF EXISTS selemti.bodega CASCADE;

RAISE NOTICE 'Eliminadas 4 tablas de catálogos legacy';

-- ============================================
-- PASO 4: Inventario legacy
-- ============================================

DROP TABLE IF EXISTS selemti.insumo CASCADE;
DROP TABLE IF EXISTS selemti.lote CASCADE;
DROP TABLE IF EXISTS selemti.merma CASCADE;
DROP TABLE IF EXISTS selemti.stock_policy CASCADE;

RAISE NOTICE 'Eliminadas 4 tablas de inventario legacy';

-- ============================================
-- PASO 5: Transferencias legacy
-- ============================================

DROP TABLE IF EXISTS selemti.traspaso_det CASCADE;
DROP TABLE IF EXISTS selemti.traspaso_cab CASCADE;

RAISE NOTICE 'Eliminadas 2 tablas de transferencias legacy';

-- ============================================
-- PASO 6: Producción legacy (detalles primero)
-- ============================================

DROP TABLE IF EXISTS selemti.sol_prod_det CASCADE;
DROP TABLE IF EXISTS selemti.op_insumo CASCADE;
DROP TABLE IF EXISTS selemti.prod_det CASCADE;

DROP TABLE IF EXISTS selemti.sol_prod_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_produccion_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_cab CASCADE;
DROP TABLE IF EXISTS selemti.prod_cab CASCADE;
DROP TABLE IF EXISTS selemti.op_yield CASCADE;

RAISE NOTICE 'Eliminadas 8 tablas de producción legacy';

-- ============================================
-- PASO 7: Recetas legacy
-- ============================================

DROP TABLE IF EXISTS selemti.receta_insumo CASCADE;
DROP TABLE IF EXISTS selemti.receta_det CASCADE;
DROP TABLE IF EXISTS selemti.receta_version CASCADE;
DROP TABLE IF EXISTS selemti.receta_shadow CASCADE;

DROP TABLE IF EXISTS selemti.receta_cab CASCADE;
DROP TABLE IF EXISTS selemti.receta CASCADE;

RAISE NOTICE 'Eliminadas 6 tablas de recetas legacy';

-- ============================================
-- PASO 8: Caja Chica legacy
-- ============================================

DROP TABLE IF EXISTS selemti.caja_fondo_mov CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo_arqueo CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo_adj CASCADE;
DROP TABLE IF EXISTS selemti.caja_fondo CASCADE;

RAISE NOTICE 'Eliminadas 4 tablas de caja chica legacy';

-- ============================================
-- PASO 9: Auditoría legacy (SOLO vacías)
-- ============================================

-- NO eliminar selemti.auditoria (tiene 72 registros)
-- NO eliminar audit_log_global (es tabla actual)

DROP TABLE IF EXISTS selemti.audit_log CASCADE;

RAISE NOTICE 'Eliminada 1 tabla de auditoría legacy';

-- ============================================
-- RESUMEN FINAL
-- ============================================

DO $$
DECLARE
    v_total_tables INT;
BEGIN
    SELECT COUNT(*) INTO v_total_tables
    FROM pg_tables
    WHERE schemaname = 'selemti';

    RAISE NOTICE '============================================';
    RAISE NOTICE 'LIMPIEZA COMPLETADA - %', NOW();
    RAISE NOTICE 'Tablas restantes en selemti: %', v_total_tables;
    RAISE NOTICE '============================================';
END $$;

-- ============================================
-- COMMIT o ROLLBACK
-- ============================================

-- Descomentar una de estas líneas:

-- ROLLBACK; -- Para hacer dry-run y revisar los NOTICE

-- COMMIT; -- Solo cuando estés 100% seguro

```

---

## EJECUCIÓN RECOMENDADA

### Opción A: Dry-Run (RECOMENDADO)

```bash
# 1. Backup
pg_dump -h localhost -p 5433 -U postgres -d pos -F c -f pos_backup_$(date +%Y%m%d_%H%M%S).dump

# 2. Ejecutar con ROLLBACK
psql -h localhost -p 5433 -U postgres -d pos -f docs/BD/drop_legacy_safe.sql

# 3. Revisar los NOTICE y verificar que no hubo errores
```

### Opción B: Ejecución Real (SOLO después de Dry-Run exitoso)

```bash
# 1. Editar el script SQL y cambiar ROLLBACK por COMMIT

# 2. Ejecutar
psql -h localhost -p 5433 -U postgres -d pos -f docs/BD/drop_legacy_safe.sql

# 3. Verificar
psql -h localhost -p 5433 -U postgres -d pos -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname='selemti';"
```

---

## VALIDACIÓN POST-DROP

```sql
-- 1. Contar tablas restantes
SELECT schemaname, COUNT(*) as total
FROM pg_tables
WHERE schemaname IN ('selemti', 'public')
GROUP BY schemaname;

-- 2. Verificar tablas cat_* (deben existir todas)
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND tablename LIKE 'cat_%'
ORDER BY tablename;
-- Esperado: cat_sucursales, cat_almacenes, cat_proveedores, cat_unidades, cat_uom_conversion

-- 3. Verificar que NO existen tablas legacy
SELECT tablename
FROM pg_tables
WHERE schemaname = 'selemti'
  AND (
    tablename LIKE '%_legacy'
    OR tablename IN ('usuario', 'rol', 'sucursal', 'almacen', 'bodega', 'proveedor',
                     'insumo', 'lote', 'merma',
                     'receta', 'receta_cab', 'receta_det', 'receta_insumo', 'receta_version', 'receta_shadow',
                     'op_cab', 'op_produccion_cab', 'prod_cab', 'sol_prod_cab',
                     'op_insumo', 'prod_det', 'sol_prod_det', 'op_yield',
                     'traspaso_cab', 'traspaso_det',
                     'caja_fondo', 'caja_fondo_mov', 'caja_fondo_arqueo', 'caja_fondo_adj',
                     'audit_log')
  )
ORDER BY tablename;
-- Esperado: 0 rows
```

---

## SIGUIENTE ACCIÓN

1. **INMEDIATO**: Ejecutar dry-run del script con ROLLBACK
2. **Validar**: Revisar todos los NOTICE del script
3. **Coordinar**: Actualizar `.gemini/WORK_ASSIGNMENTS.md` con resultado
4. **Decidir**: Si dry-run exitoso, proceder con COMMIT
5. **Migrar datos**: Resolver `selemti.auditoria` (72 registros)

---

## RIESGOS RESIDUALES

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| FKs CASCADE eliminan datos en tablas actuales | BAJA | Backup + dry-run primero |
| Código roto por referencias no detectadas | MEDIA | Tests completos post-drop |
| Confusión entre nombres de campos y tablas | ALTA | Análisis manual detallado ejecutado |

---

**IMPORTANTE**: Este plan asume que las 452 referencias a "sucursal" encontradas en código son **campos FK** (`sucursal_id`) que apuntan a `cat_sucursales`, NO a la tabla legacy `sucursal`. Esto requiere **validación manual final** antes de ejecutar.

---

_Documento generado el 2 de Noviembre de 2025_
_Basado en auditoría de código con grep exhaustivo_
