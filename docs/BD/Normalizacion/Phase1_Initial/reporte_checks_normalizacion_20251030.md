# Reporte de Checks de Normalización de Base de Datos
**Fecha**: 30 de octubre de 2025, 13:15 hrs
**Base de Datos**: PostgreSQL 9.5 - `pos`
**Esquemas analizados**: `public`, `selemti`

---

## Resumen Ejecutivo

Se ejecutaron 4 checks de validación para confirmar el estado de la normalización de la base de datos. Se encontraron **inconsistencias críticas** que deben resolverse antes de continuar con ajustes de código.

**Estado General**: ⚠️ **ACCIÓN REQUERIDA**

---

## Check 1: Tablas Duplicadas por Estructura (Shape)

### Resultados
Se encontraron **23 pares de tablas** con estructuras idénticas (mismo conjunto de columnas).

### Hallazgos Críticos en Esquema `selemti`

| Tabla Principal | Tabla Duplicada | Estado |
|----------------|-----------------|---------|
| `conversiones_unidad` | `conversiones_unidad_legacy` | ⚠️ Duplicado |
| `unidad_medida` | `unidad_medida_legacy` | ⚠️ Duplicado |
| `unidades_medida` | `unidades_medida_legacy` | ⚠️ Duplicado |
| `uom_conversion` | `uom_conversion_legacy` | ⚠️ Duplicado |
| `vw_item_last_price` | `vw_item_last_price_pref` | ℹ️ Vistas similares |

### Impacto
- **Alto**: Hay **4 tablas de unidades de medida** activas simultáneamente
- **Confusión**: El código usa diferentes tablas de forma inconsistente
- **Ejemplo detectado**:
  - `InsumoCreate` intentó usar `unidad_medida_legacy` (singular)
  - `ItemsManage` esperaba `unidades_medida_legacy` (plural)
  - `items` tabla tiene FK a `unidades_medida_legacy` (plural)

### Recomendaciones
1. **Consolidar tablas de unidades** en una sola tabla canónica
2. Crear **vista de compatibilidad** para los nombres antiguos
3. Migrar datos de tablas legacy a tablas principales
4. Eliminar tablas duplicadas después de la migración

---

## Check 2: Tablas Huérfanas (sin Foreign Keys)

### Resultados
Se encontraron **61 tablas** sin foreign keys entrantes ni salientes.

### Tablas Críticas que Deberían Tener FK

| Tabla | FK Esperada | Estado Actual |
|-------|-------------|---------------|
| `inventory_snapshot` | → `items.id` | ❌ Sin FK |
| `recipe_cost_history` | → `receta_cab.id` | ❌ Sin FK |
| `pos_map` | → `receta_cab.id` | ❌ Sin FK |
| `purchase_orders` | → `cat_proveedores.id` | ❌ Sin FK |
| `inventory_counts` | → `cat_almacenes.id` | ❌ Sin FK |

### Tablas Legítimas (Catálogos/Sistema)
- `formas_pago`, `labor_roles`, `overhead_definitions` (catálogos independientes)
- `migrations`, `jobs`, `cache`, `sessions` (Laravel framework)
- `global_config`, `printer_configuration` (configuración)

### Impacto
- **Alto**: Sin FKs, no hay integridad referencial garantizada
- **Riesgo**: Posibles datos huérfanos sin detectar

### Recomendaciones
1. **Añadir FKs faltantes** en tablas transaccionales
2. Ejecutar **cleanup de datos huérfanos** antes de añadir FKs
3. Documentar tablas sin FK intencionales (catálogos)

---

## Check 3: Consistencia de Unidades de Medida

### Resultados

#### 3a. Unidades en `cat_unidades`
- **Total de unidades**: 28 unidades activas
- **Unidades estándar**: KG, L, EA, LT, PZ
- **Unidades extendidas**: 25 unidades adicionales (CAJA, PAQ, OZ, GAL, etc.)

**Estado**: ✅ OK - El catálogo es extenso pero controlado

#### 3b. Items con Unidades No Mapeadas
- **Total verificado**: Todos los items en `selemti.items`
- **Items sin unidad**: **0 items** (✅ Perfecto)
- **Items con unidad inválida**: **0 items** (✅ Perfecto)

**Estado**: ✅ OK - Todos los items tienen unidades válidas

### Observaciones
- La tabla `cat_unidades` usa campo `clave` (no `codigo`)
- Hay unidades culinarias (TAZA, CDTA, TBSP) y métricas (KG, L, ML)
- FK `items.unidad_medida_id` → `cat_unidades.id` funciona correctamente

---

## Check 4: Validación de `inventory_snapshot`

### Resultados

#### Estructura de Tabla
```sql
inventory_snapshot.item_id: UUID
items.id: VARCHAR(20)
```

**Estado**: ❌ **INCOMPATIBILIDAD CRÍTICA DE TIPOS**

#### Datos
- **Total de snapshots**: 0 registros
- **Items únicos**: 0
- **Fechas únicas**: 0

**Estado**: ℹ️ Tabla vacía (sin datos que migrar)

### Impacto
- **Crítico**: El tipo `UUID` en `inventory_snapshot.item_id` es incompatible con `items.id` (VARCHAR)
- No se puede crear FK entre tipos incompatibles
- Consultas JOIN fallarán con error de tipo

### Solución Requerida
```sql
-- Opción 1: Cambiar inventory_snapshot.item_id a VARCHAR(20)
ALTER TABLE selemti.inventory_snapshot
  ALTER COLUMN item_id TYPE VARCHAR(20);

-- Opción 2: Cambiar items.id a UUID (más complejo, afecta más tablas)
-- NO RECOMENDADO por impacto en todo el sistema
```

---

## Resumen de Problemas Críticos

### 1. ❌ **Tablas de Unidades Duplicadas**
- **Afectación**: Alta
- **Componentes impactados**: InsumoCreate, ItemsManage, modelos
- **Acción**: Consolidar en `cat_unidades` y crear vistas de compatibilidad

### 2. ❌ **Incompatibilidad de Tipos: inventory_snapshot**
- **Afectación**: Crítica
- **Componentes impactados**: DailyCloseService, InventorySnapshotService
- **Acción**: Cambiar `inventory_snapshot.item_id` a VARCHAR(20)

### 3. ⚠️ **Foreign Keys Faltantes**
- **Afectación**: Media
- **Componentes impactados**: Integridad referencial general
- **Acción**: Añadir FKs en tablas transaccionales

---

## Plan de Acción Recomendado

### Prioridad 1 (URGENTE)
1. ✅ **Cambiar tipo de `inventory_snapshot.item_id`** a VARCHAR(20)
2. ✅ **Consolidar tablas de unidades**:
   - Usar `unidades_medida_legacy` como tabla canónica
   - Migrar datos de otras tablas de unidades
   - Crear vistas de compatibilidad
3. ✅ **Actualizar código** para usar tabla canónica

### Prioridad 2 (IMPORTANTE)
4. ⏭️ Añadir FKs faltantes en tablas críticas
5. ⏭️ Ejecutar cleanup de datos huérfanos
6. ⏭️ Actualizar modelos Eloquent con relaciones correctas

### Prioridad 3 (SEGUIMIENTO)
7. ⏭️ Eliminar tablas legacy después de migración completa
8. ⏭️ Actualizar documentación de esquema
9. ⏭️ Crear tests de integridad referencial

---

## Siguiente Paso Inmediato

**ANTES de continuar con ajustes de código**, ejecutar:

```bash
# 1. Cambiar tipo de inventory_snapshot.item_id
psql -h localhost -p 5433 -U postgres -d pos -f docs/BD/fix_inventory_snapshot_type.sql

# 2. Consolidar tablas de unidades
psql -h localhost -p 5433 -U postgres -d pos -f docs/BD/consolidar_unidades.sql

# 3. Verificar cambios
psql -h localhost -p 5433 -U postgres -d pos -f docs/BD/verify_normalizacion.sql
```

---

**Generado por**: Claude Code
**Contexto**: Normalización de BD post-migración TerrenaLaravel
