# Orquestador Terrena — **v6** (Guía de Operación Rápida)
**Scope:** Cierre diario, consumo POS, reproceso, snapshots, conteos físicos, costos de receta y auditoría SQL.  
**Compatibilidad:** PostgreSQL **9.5**, Laravel 11 + Livewire 3. **Sin cambios de esquema.**

---

## 1) Estructura y ubicaciones
```
C:\xampp3\htdocs\TerrenaLaravel\
 ├─ app\
 │   ├─ Operations\DailyCloseService.php
 │   ├─ Services\RecalcularCostosRecetasService.php
 │   └─ Livewire\
 │       ├─ PosMap\Index.php                (UI mapeos POS)
 │       └─ InventoryCount\Index.php        (UI de conteos físicos)
 ├─ app\Inventory\OrquestadorPanel.php      (Dashboard de orquestación)
 └─ docs\Orquestador\
     ├─ sql\
     │   ├─ verification_queries_psql_v6.sql
     │   ├─ verification_queries_psql_range.sql
     │   └─ discover_schema_psql_v2.sql
     ├─ Cierre_Diario.md
     ├─ RECETA_COST_CALCULATION.md
     ├─ RECETA_COST_CALCULATION_TECHNICAL.md
     ├─ RECETA_COST_CALCULATION_COMMAND.md
     └─ Snapshot_Report_*.md
```

---

## 2) Parámetros y convenciones (v6)
- **Sucursal (clave textual)**: `:'sucursal_key'` se mapea desde **`public.terminal.location`**.  
- **Fecha objetivo**: `:'bdate'` (formato `YYYY-MM-DD`).  
- **Terminal opcional**: `:'terminal_id'` (entero).  
- **`selemti.pos_map`** vigencia: usa `valid_from / valid_to` **o** `vigente_desde` (cualquiera válida).
- **Campos reales** confirmados (dump):
  - `selemti.inv_consumo_pos_det`.`mp_id` (no `item_id`).
  - `selemti.mov_inv.sucursal_id` **TEXT**.
  - `selemti.inventory_snapshot.branch_id` **TEXT**.
  - `selemti.recipe_cost_history.snapshot_at` (fecha/hora del snapshot).

---

## 3) Scripts SQL de verificación (psql 9.5)
### 3.1 Ejecutar **v6** (día puntual)
```sql
\set bdate 2025-10-29
\set sucursal_key '1'
-- Opcional: \set terminal_id 9939
\i docs/Orquestador/sql/verification_queries_psql_v6.sql
```
**Bloques críticos y metas:**
- **1 / 1.b** (ventas MENÚ/MODIFIER sin mapa): **0 filas**.
- **2** (pendientes en inv_consumo_pos/_det): **0 filas**.
- **8** (conteos abiertos): **0 filas**.

### 3.2 Rango de fechas (tendencias)
```sql
\set from_date 2025-10-01
\set to_date   2025-10-31
\set sucursal_key '1'
\i docs/Orquestador/sql/verification_queries_psql_range.sql
```

### 3.3 Descubrimiento de esquema actualizado
```sql
\i docs/Orquestador/sql/discover_schema_psql_v2.sql
```

---

## 4) Flujos y UI
### 4.1 POS Mapping (Livewire)
- **Ruta:** `/pos-map` (o equivalente ya configurado).
- **Funciones:** lista con filtros `tipo`, `plu`, vigencia; CRUD de filas `MENU/MODIFIER`.
- **Acción rápida:** “Auditar hoy” → ejecuta v6/1 y v6/1.b → meta **0** sin mapa.

### 4.2 Conteos Físicos
- **Ruta:** `/inventory-counts`.
- **Funciones:** listar por `sucursal_id`, estado y fechas; **Cerrar** conteo.
- **Validación post-cierre:** v6/8 → **0 abiertos**.

### 4.3 Panel de Orquestación
- **Tiles/semáforos:**
  - **POS Mapping OK** (v6/1 y v6/1.b = 0)
  - **Pendientes POS** (v6/2 = 0)
  - **Conteos abiertos** (v6/8 = 0)
  - **Costos / Snapshots**: última ejecución + totales (lee `recipe_cost_history` del día)
- **Botón de prueba:** `php artisan recetas:recalcular-costos --date=YYYY-MM-DD`

---

## 5) Jobs y scheduler
- **Kernel:** tarea diaria a **01:10** (TZ `America/Mexico_City`)
  - `recetas:recalcular-costos` (costos de receta)
  - (Cierre diario si lo programaste en Kernel)
- **Cron del servidor** habilitado y apuntando a `php artisan schedule:run` minutely.
- **Evidencia:** nuevas filas en `selemti.recipe_cost_history` con `snapshot_at` del día.

---

## 6) Smoke tests por rol
### 6.1 Operaciones
1) Cargar mapeos faltantes → repetir v6/1 y 1.b → **0 filas**.  
2) Forzar consumo POS si procede → v6/2 → **0 filas**.  
3) Cerrar conteos → v6/8 → **0 filas**.

### 6.2 Finanzas / Costeo
1) Verificar snapshots del día en `recipe_cost_history`.  
2) Validar log/bitácora del recálculo (según `RECETA_COST_CALCULATION_COMMAND.md`).

### 6.3 TI
1) Cron activo.  
2) Servicios sin errores en logs de Laravel (`storage/logs`).

---

## 7) Troubleshooting
- **Sin cambios en UI**: confirmar que los componentes referencian **v6** (no v5) y que pasan `bdate/sucursal_key` correctos.
- **Pendientes persisten**: revisar `inv_consumo_pos_det.requiere_reproceso/procesado` y existencia de movimientos `mov_inv` por `ref_id/ref_tipo`.
- **Conteo no cierra**: verificar transición de `estado` y que v6/8 usa la misma sucursal/fecha.

---

## 8) Criterios de aceptación (fin de día)
- v6/1 = 0  **y** v6/1.b = 0
- v6/2 = 0
- v6/8 = 0
- Nuevos `recipe_cost_history.snapshot_at` **del día**
- Tiles del panel todos en **verde**

---

**Fin — Orquestador v6**  
Mantener este documento en: `docs/Orquestador/README_orquestador_v6.md`
