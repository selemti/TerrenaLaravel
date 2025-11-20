# DOCUMENTACIÓN: ANÁLISIS DE MODELOS DE INVENTARIO

**Fecha de Generación:** 2025-11-17
**Analista:** Claude Code
**Versión:** 1.0

---

## DESCRIPCIÓN

Este análisis exhaustivo detecta **columnas fantasma** (definidas en modelos pero que NO existen en la base de datos) en todos los modelos de inventario del sistema TerrenaLaravel.

### ¿Qué es una columna fantasma?

Una columna fantasma es un campo definido en `$fillable` o `$casts` de un modelo Eloquent que **NO existe** en la tabla de base de datos correspondiente. Esto causa:

- ❌ Errores silenciosos en inserts/updates
- ❌ Datos perdidos sin notificación
- ❌ Confusión en el equipo de desarrollo
- ❌ Bugs difíciles de debuggear

---

## ARCHIVOS GENERADOS

### 1. ANALISIS_COLUMNAS_FANTASMA_INVENTARIO.md
**Ruta:** `docs/V4.0/Code/ANALISIS_COLUMNAS_FANTASMA_INVENTARIO.md`
**Contenido:** Análisis detallado modelo por modelo

**Incluye:**
- Análisis completo de 16 modelos
- $fillable, $casts, $appends de cada modelo
- Relaciones FK mapeadas
- Columnas fantasma detectadas
- Columnas BD no usadas
- Diagnóstico por modelo
- Plan de acción completo

**Uso:** Consulta técnica detallada para cada modelo específico

---

### 2. RESUMEN_COLUMNAS_FANTASMA.md
**Ruta:** `docs/V4.0/Code/RESUMEN_COLUMNAS_FANTASMA.md`
**Contenido:** Resumen ejecutivo para decisiones rápidas

**Incluye:**
- Hallazgos críticos (modelos rotos)
- Problemas medios (campos legacy)
- Modelos duplicados
- Connection incorrecta (11 modelos)
- Migración SQL requerida
- Plan de acción por fases
- Métricas globales

**Uso:** Presentación a stakeholders, planning de correcciones

---

### 3. TABLA_COMPARATIVA_MODELOS_BD.md
**Ruta:** `docs/V4.0/Code/TABLA_COMPARATIVA_MODELOS_BD.md`
**Contenido:** Referencia rápida tabla por tabla

**Incluye:**
- Mapeo columna a columna (BD vs Modelo)
- Status de cada campo (✅/❌/⚠️)
- Recomendaciones por tabla
- Score de completitud por tabla
- Resumen global con métricas

**Uso:** Referencia diaria durante desarrollo

---

### 4. fix_transfer_tables.sql
**Ruta:** `docs/V4.0/Code/fix_transfer_tables.sql`
**Contenido:** Script SQL para corregir transfer_cab y transfer_det

**Incluye:**
- Backup automático antes de modificar
- ALTER TABLE para agregar columnas faltantes
- Renombrado de columnas (guia → numero_guia)
- Copia de datos (cantidad → cantidad_solicitada)
- Verificación de estructura final
- Script de rollback (comentado)
- Notas post-ejecución

**Uso:** Ejecutar en PostgreSQL para sincronizar BD con modelos

---

### 5. validate_inventory_models.php
**Ruta:** `validate_inventory_models.php` (raíz del proyecto)
**Contenido:** Script de validación automatizada

**Incluye:**
- Validación de 5 modelos críticos
- Detección de columnas fantasma en tiempo real
- Detección de modelos duplicados
- Verificación de campos críticos
- Verificación de connection correcta
- Output coloreado en consola

**Uso:**
```bash
cd /c/xampp3/htdocs/TerrenaLaravel
php validate_inventory_models.php
```

**Salida esperada:**
- Exit code 0: Todo OK
- Exit code 1: Problemas detectados

---

### 6. analyze_inventory_models.php
**Ruta:** `analyze_inventory_models.php` (raíz del proyecto)
**Contenido:** Script de análisis de esquema BD

**Incluye:**
- Conexión a PostgreSQL vía Laravel
- Extracción de columnas de 15 tablas
- Tipos de datos y constraints
- Total de columnas por tabla

**Uso:**
```bash
cd /c/xampp3/htdocs/TerrenaLaravel
php analyze_inventory_models.php
```

---

## HALLAZGOS PRINCIPALES

### 🔴 CRÍTICO (Acción Inmediata)

#### 1. Movement.php - MODELO ROTO
```
app/Models/Inventory/Movement.php
❌ 50% de columnas fantasma (7 de 14)
❌ No coincide con estructura BD de mov_inv
ACCIÓN: Eliminar modelo, usar MovimientoInventario.php
```

#### 2. TransferHeader.php - DESINCRONIZADO
```
app/Models/Inventory/TransferHeader.php
❌ 10+ columnas fantasma de workflow completo
✅ BD solo tiene 9 columnas básicas
ACCIÓN: Ejecutar fix_transfer_tables.sql
```

#### 3. TransferLine.php - DESINCRONIZADO
```
app/Models/Inventory/TransferLine.php
❌ 4 columnas fantasma
✅ BD solo tiene 7 columnas básicas
ACCIÓN: Ejecutar fix_transfer_tables.sql
```

### 🟡 MEDIO (Limpieza)

- Item.php: Campo `unidad_medida` legacy duplicado
- 11 modelos con `connection` incorrecta (default en vez de pgsql)
- 5 campos nuevos en `items` no mapeados
- `unit_cost` faltante en Batch.php

### 🟢 BAJO (Consolidación)

- 3 pares de modelos duplicados:
  - ItemVendor / ItemProveedor
  - Batch / LoteInventario
  - MovimientoInventario / Movimiento

---

## PLAN DE EJECUCIÓN

### FASE 1: Limpieza Inmediata ⏱️ 30 minutos

```bash
# 1. Eliminar modelos duplicados
rm app/Models/Inv/Movimiento.php
rm app/Models/Inv/ItemProveedor.php
rm app/Models/Inv/LoteInventario.php
rm app/Models/Inventory/Movement.php

# 2. Buscar y reemplazar en código:
# - Movimiento → MovimientoInventario
# - ItemProveedor → ItemVendor
# - LoteInventario → Batch

# 3. Validar
php validate_inventory_models.php
```

### FASE 2: Corregir Connections ⏱️ 15 minutos

Agregar a estos 11 modelos:
```php
protected $connection = 'pgsql';
```

Lista de archivos:
- app/Models/Inv/ConversionUnidad.php
- app/Models/Inv/HistorialCostoItem.php
- app/Models/Inv/ItemProveedor.php (si no eliminado)
- app/Models/Inv/ItemVendor.php
- app/Models/Inv/LoteInventario.php (si no eliminado)
- app/Models/Inv/Movimiento.php (si no eliminado)
- app/Models/Inv/ParametroSucursal.php
- app/Models/Inv/PoliticaStock.php
- app/Models/Inv/Unidad.php
- app/Models/Inventory/Item.php
- app/Models/Inventory/Movement.php (si no eliminado)

### FASE 3: Migración Transfer ⏱️ 1-2 horas

**Opción A: Migración BD (Recomendado)**
```bash
# Ejecutar script SQL
psql -h localhost -U postgres -d selemti -f docs/V4.0/Code/fix_transfer_tables.sql

# Validar
php validate_inventory_models.php
```

**Opción B: Simplificar Modelos**
- Remover campos fantasma de TransferHeader.php y TransferLine.php
- Refactorizar código Livewire dependiente
- ⚠️ Mayor impacto en código

**RECOMENDACIÓN:** Opción A (menor riesgo)

### FASE 4: Completar Mapeo ⏱️ 15 minutos

**1. Agregar a Item.php (app/Models/Inv/):**
```php
protected $fillable = [
    // ... existing
    'category_id',
    'item_code',
    'es_producible',
    'es_consumible_operativo',
    'es_empaque_to_go',
];

protected $casts = [
    // ... existing
    'es_producible' => 'boolean',
    'es_consumible_operativo' => 'boolean',
    'es_empaque_to_go' => 'boolean',
];
```

**2. Agregar a Batch.php (app/Models/Inv/):**
```php
protected $fillable = [
    // ... existing
    'unit_cost',
];

protected $casts = [
    // ... existing
    'unit_cost' => 'decimal:6',
];
```

---

## MÉTRICAS DE SALUD

| Métrica | Antes | Después (esperado) | Mejora |
|---------|-------|-------------------|--------|
| Modelos Rotos | 3 | 0 | 100% |
| Columnas Fantasma | 20+ | 0 | 100% |
| Modelos Duplicados | 6 | 3 | 50% |
| Connection Incorrecta | 11 | 0 | 100% |
| Score de Salud | 60% | 95%+ | +35% |

---

## VALIDACIÓN POST-CORRECCIÓN

### 1. Ejecutar script de validación
```bash
php validate_inventory_models.php
```

**Salida esperada:**
```
✅ VALIDACIÓN EXITOSA - Sin problemas detectados
```

### 2. Verificar en BD
```sql
-- Verificar transfer_cab
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'transfer_cab'
ORDER BY ordinal_position;

-- Debe mostrar 17+ columnas

-- Verificar transfer_det
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'selemti' AND table_name = 'transfer_det'
ORDER BY ordinal_position;

-- Debe mostrar 10+ columnas
```

### 3. Tests de integración
```bash
# Ejecutar tests de transferencias
php artisan test --filter TransferTest

# Ejecutar tests de inventario
php artisan test --filter InventoryTest
```

---

## NOTAS IMPORTANTES

### 1. Sobre transfer_cab y transfer_det

El modelo TransferHeader implementa un **workflow completo** de transferencias con múltiples estados:
- SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA

La BD actual solo tiene soporte para un workflow **simplificado**:
- CREADA → DESPACHADA → RECIBIDA

**Decisión tomada:** Migrar BD para soportar workflow completo (menor impacto)

### 2. Sobre modelos duplicados

Existen **3 pares de modelos** que apuntan a la misma tabla:
- Nomenclatura inconsistente (español/inglés)
- Diferentes niveles de completitud
- Confusión en el equipo

**Decisión tomada:** Consolidar usando versiones más completas

### 3. Sobre connection = 'pgsql'

**11 modelos** no especifican connection explícitamente:
- Asumen `default` (SQLite en desarrollo)
- Causan errores en queries cruzadas
- Dificultan debugging

**Decisión tomada:** Especificar `pgsql` explícitamente en todos

### 4. Sobre campos nuevos en items

La tabla `items` tiene **5 campos nuevos** no mapeados:
- category_id (BIGINT) - Nueva categorización
- item_code (VARCHAR) - Código de item
- es_producible (BOOLEAN) - Flag de producción
- es_consumible_operativo (BOOLEAN) - Flag operativo
- es_empaque_to_go (BOOLEAN) - Flag empaque

**Decisión tomada:** Agregar al modelo para funcionalidad completa

---

## CONTACTO Y SOPORTE

**Documentación generada por:** Claude Code (Anthropic)
**Fecha:** 2025-11-17
**Versión:** 1.0

Para preguntas o issues:
1. Revisar documentación detallada en archivos MD
2. Ejecutar `validate_inventory_models.php` para verificar estado actual
3. Consultar `TABLA_COMPARATIVA_MODELOS_BD.md` para mapeo específico

---

## CHANGELOG

### v1.0 - 2025-11-17
- ✅ Análisis inicial de 16 modelos
- ✅ Detección de 20+ columnas fantasma
- ✅ Identificación de 3 modelos rotos
- ✅ Script de validación automatizada
- ✅ Script SQL de corrección
- ✅ Documentación completa

---

**Próximos pasos:** Ejecutar FASE 1 del plan de acción
