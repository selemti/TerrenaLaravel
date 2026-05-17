# Gemini Task: KardexView — Diagnóstico y validación de datos

**Assignee:** Gemini CLI  
**Schema:** `selemti` (writable) — `public` READ ONLY  
**Priority:** 🟡 Medium — UI existe pero puede mostrar datos incorrectos

---

## Contexto

`KardexService` (`app/Services/Inventory/KardexService.php`) fue implementado por Codex y calcula un balance corriente en PHP (no ventanas SQL — compatible con PG 9.5). El `KardexController` expone `GET /api/inventory/items/{id}/kardex`.

El componente Livewire `KardexView` (`app/Livewire/Inventory/KardexView.php`) ya existe pero puede estar usando una query directa desactualizada en lugar del servicio.

**Tu trabajo es 100% DB/diagnóstico — no toques PHP ni Blade.**

---

## Objetivo

Verificar que la tabla `selemti.mov_inv` tiene datos coherentes y que el balance corriente que calcula `KardexService` tendría sentido con los datos reales.

---

## Tareas

### 1. Diagnóstico de mov_inv

```sql
-- Distribución de movimientos por tipo
SELECT tipo, COUNT(*) as total, SUM(COALESCE(cantidad, qty)) as suma_qty
FROM selemti.mov_inv
GROUP BY tipo
ORDER BY total DESC;

-- Items con más movimientos
SELECT item_id, COUNT(*) as movs
FROM selemti.mov_inv
GROUP BY item_id
ORDER BY movs DESC
LIMIT 10;

-- ¿Hay cantidades NULL?
SELECT COUNT(*) as rows_with_null_qty
FROM selemti.mov_inv
WHERE cantidad IS NULL AND qty IS NULL;

-- ¿El campo ts (timestamp) está poblado?
SELECT COUNT(*) as sin_ts FROM selemti.mov_inv WHERE ts IS NULL;
```

### 2. Validar que `almacen_id` es consistente

```sql
-- ¿Qué valores únicos de almacen_id existen en mov_inv?
SELECT almacen_id, COUNT(*) as total
FROM selemti.mov_inv
GROUP BY almacen_id
ORDER BY total DESC
LIMIT 10;

-- ¿Esos almacen_id existen en cat_almacenes?
SELECT m.almacen_id, COUNT(*) as movs, a.nombre
FROM selemti.mov_inv m
LEFT JOIN selemti.cat_almacenes a ON a.id = m.almacen_id
WHERE m.almacen_id IS NOT NULL
GROUP BY m.almacen_id, a.nombre
ORDER BY movs DESC
LIMIT 10;
```

### 3. Verificar integridad de inventory_batch

```sql
-- ¿Batches con cantidad_actual negativa?
SELECT COUNT(*) as negativos
FROM selemti.inventory_batch
WHERE cantidad_actual < 0;

-- ¿Batches referenciados en mov_inv pero inexistentes en inventory_batch?
SELECT COUNT(*) as huerfanos
FROM selemti.mov_inv m
WHERE m.lote_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM selemti.inventory_batch b WHERE b.id = m.lote_id);
```

### 4. Sample de kardex para un ítem real

Toma el `item_id` con más movimientos del paso 1 y corre:

```sql
SELECT
    m.id,
    m.ts,
    m.tipo,
    COALESCE(m.cantidad, m.qty) as qty,
    m.ref_tipo,
    m.ref_id,
    m.almacen_id
FROM selemti.mov_inv m
WHERE m.item_id = '<item_id_con_mas_movs>'
ORDER BY m.ts, m.id
LIMIT 30;
```

---

## Entregable

Un reporte en `docs/gemini-tasks/kardex-view-diagnosis-report.md` con:
1. Resumen de mov_inv (tipos, totales, NULLs)
2. Cualquier inconsistencia de datos encontrada (almacenes huérfanos, batches negativos)
3. Muestra del kardex de 1 ítem real (copy-paste de la query)
4. Opinión: ¿los datos están limpios o hay deuda técnica de datos que bloquee la UI?

**No hagas ningún UPDATE/INSERT/DELETE.** Solo diagnóstico de lectura.

---

## Invariantes críticos

- `public.*` → READ ONLY
- `selemti.*` → este diagnóstico es solo SELECT
- No corras `migrate:fresh` ni nada destructivo
