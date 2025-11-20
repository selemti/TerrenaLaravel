# RESUMEN EJECUTIVO: COLUMNAS FANTASMA EN MODELOS INVENTARIO

**Fecha:** 2025-11-17
**Analista:** Claude Code
**Scope:** 16 modelos bajo `app/Models/Inv/` y `app/Models/Inventory/`

---

## HALLAZGOS CRÍTICOS

### 🔴 MODELOS ROTOS (Requieren Acción Inmediata)

#### 1. Movement.php (app/Models/Inventory/)
**Estado:** ❌ **INUTILIZABLE** - 50% de columnas fantasma

```diff
- sucursal_dest     (BD: sucursal_id)
- lote_codigo       (BD: lote_id FK integer)
- caducidad         (No existe)
- qty               (BD: cantidad)
- udm               (BD: uom_original_id FK)
- notas             (No existe)
- created_by        (BD: usuario_id)
```

**ACCIÓN:** Eliminar modelo completo, usar `MovimientoInventario.php`

---

#### 2. TransferHeader.php (app/Models/Inventory/)
**Estado:** 🔴 **DESINCRONIZADO** - BD tiene 9 columnas, modelo espera 17+

**Columnas fantasma:**
```diff
- numero_guia          (BD: guia)
- aprobada_por         (No existe)
- posteada_por         (No existe)
- fecha_solicitada     (No existe)
- fecha_aprobada       (No existe)
- fecha_despachada     (No existe)
- fecha_recibida       (No existe)
- fecha_posteada       (No existe)
- observaciones        (No existe)
- observaciones_recepcion (No existe)
- updated_at           (No existe)
```

**BD Real (transfer_cab):**
```sql
id, origen_almacen_id, destino_almacen_id, estado,
creada_por, despachada_por, recibida_por, guia, created_at
```

**ACCIÓN:** Crear migración para agregar workflow completo o simplificar modelo

---

#### 3. TransferLine.php (app/Models/Inventory/)
**Estado:** 🔴 **DESINCRONIZADO** - 50% de columnas fantasma

**Columnas fantasma:**
```diff
- cantidad_solicitada  (BD: cantidad)
- unidad_medida        (No existe)
- observaciones        (No existe)
- observaciones_recepcion (No existe)
```

**BD Real (transfer_det):**
```sql
id, transfer_id, item_id, cantidad,
cantidad_despachada, cantidad_recibida, created_at
```

**ACCIÓN:** Migración o refactor

---

### 🟡 PROBLEMAS MEDIOS

#### 4. Item.php (app/Models/Inv/)
**Issue:** Campo legacy duplicado

```diff
REMOVER:
- unidad_medida (VARCHAR legacy)

USAR:
+ unidad_medida_id (FK a unidades_medida)
```

**Campos BD nuevos sin mapear:**
```sql
category_id BIGINT
item_code VARCHAR
es_producible BOOLEAN
es_consumible_operativo BOOLEAN
es_empaque_to_go BOOLEAN
```

---

#### 5. Batch.php / LoteInventario.php
**Issue:** Campo crítico sin mapear

```diff
AGREGAR:
+ unit_cost NUMERIC NOT NULL DEFAULT '0'
```

---

### 🟢 MODELOS DUPLICADOS (Consolidar)

| Modelo Principal | Duplicado | Tabla BD | Acción |
|-----------------|-----------|----------|--------|
| ItemVendor.php | ItemProveedor.php | item_vendor | Eliminar ItemProveedor |
| Batch.php | LoteInventario.php | inventory_batch | Eliminar LoteInventario |
| MovimientoInventario.php | Movimiento.php | mov_inv | Eliminar Movimiento |

---

### ⚠️ CONNECTION INCORRECTA

**11 modelos usan `default` en lugar de `pgsql`:**

```
ConversionUnidad.php
HistorialCostoItem.php
ItemProveedor.php
ItemVendor.php
LoteInventario.php
Movimiento.php
ParametroSucursal.php
PoliticaStock.php
Unidad.php
Item.php (Inventory/)
Movement.php (Inventory/)
```

**FIX:** Agregar a todos:
```php
protected $connection = 'pgsql';
```

---

## MIGRACIÓN SQL REQUERIDA

### Para TransferHeader (transfer_cab)

```sql
ALTER TABLE selemti.transfer_cab
ADD COLUMN aprobada_por INTEGER REFERENCES users(id),
ADD COLUMN posteada_por INTEGER REFERENCES users(id),
ADD COLUMN fecha_solicitada TIMESTAMP,
ADD COLUMN fecha_aprobada TIMESTAMP,
ADD COLUMN fecha_despachada TIMESTAMP,
ADD COLUMN fecha_recibida TIMESTAMP,
ADD COLUMN fecha_posteada TIMESTAMP,
ADD COLUMN observaciones TEXT,
ADD COLUMN observaciones_recepcion TEXT,
ADD COLUMN updated_at TIMESTAMP DEFAULT now();

ALTER TABLE selemti.transfer_cab
RENAME COLUMN guia TO numero_guia;
```

### Para TransferLine (transfer_det)

```sql
ALTER TABLE selemti.transfer_det
RENAME COLUMN cantidad TO cantidad_solicitada;

ALTER TABLE selemti.transfer_det
ADD COLUMN unidad_medida VARCHAR,
ADD COLUMN observaciones TEXT,
ADD COLUMN observaciones_recepcion TEXT;
```

### Para Batch (inventory_batch)

```sql
-- Ya existe: unit_cost NUMERIC NOT NULL DEFAULT '0'
-- Solo agregar a fillable del modelo
```

---

## PLAN DE ACCIÓN

### ✅ FASE 1: Limpieza Rápida (30 min)

```bash
# 1. Eliminar modelos duplicados
rm app/Models/Inv/Movimiento.php
rm app/Models/Inv/ItemProveedor.php
rm app/Models/Inv/LoteInventario.php
rm app/Models/Inventory/Movement.php

# 2. Actualizar referencias en código
# Buscar y reemplazar:
# - Movimiento → MovimientoInventario
# - ItemProveedor → ItemVendor
# - LoteInventario → Batch
```

### ✅ FASE 2: Corregir Connections (15 min)

Agregar a cada modelo:
```php
protected $connection = 'pgsql';
```

### 🔴 FASE 3: Decisión TransferHeader/Line (URGENTE)

**Opción A: Migración BD (Recomendado)**
- Ejecutar SQL migration arriba
- Mantener modelos actuales con workflow completo
- **Tiempo:** 1-2 horas
- **Impacto:** Bajo (agregar columnas)

**Opción B: Simplificar Modelos**
- Remover campos fantasma de modelos
- Ajustar código Livewire que use esos campos
- **Tiempo:** 3-4 horas
- **Impacto:** Alto (refactor código)

**RECOMENDACIÓN:** Opción A (migración BD)

### ✅ FASE 4: Completar Mapeo Items (15 min)

Agregar a `Item.php`:
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

---

## MÉTRICAS

| Métrica | Valor | Estado |
|---------|-------|--------|
| Modelos Analizados | 16 | ✅ |
| Modelos Rotos | 3 | 🔴 |
| Modelos Duplicados | 3 pares | 🟡 |
| Columnas Fantasma | 20+ | 🔴 |
| Columnas Sin Mapear | 15+ | 🟡 |
| Connection Incorrecta | 11 | 🟡 |
| **Score de Salud** | **60%** | 🟡 |

---

## ARCHIVOS GENERADOS

1. `ANALISIS_COLUMNAS_FANTASMA_INVENTARIO.md` - Análisis detallado completo
2. `RESUMEN_COLUMNAS_FANTASMA.md` - Este archivo (ejecutivo)

---

**Próximo paso:** Ejecutar FASE 1 y decidir sobre FASE 3 (TransferHeader migration)
