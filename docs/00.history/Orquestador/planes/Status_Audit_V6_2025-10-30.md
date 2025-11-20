# Terrena · Auditoría rápida (v6) — **Cómo usarla**

> Objetivo: que tú y tus IAs verifiquen en minutos que TODO el flujo (POS → Consumo → Conteos → Snapshot → Costos) quedó correcto **sin tocar el esquema** y con **psql 9.5**.

---

## 1) Dónde poner los archivos
Coloca estos archivos en tu repo (si no existen ya):
```
C:\xampp3\htdocs\TerrenaLaravel\docs\Orquestador\sql\verification_queries_psql_v6.sql
C:\xampp3\htdocs\TerrenaLaravel\docs\Orquestador\sql\discover_schema_psql_v2.sql
```
*(Si ya los tienes, solo confirma ruta y nombre.)*

---

## 2) Ejecutar las verificaciones (psql 9.5)

1. Abre psql y conéctate:
   ```psql
   psql -h localhost -p 5433 -U postgres -d pos
   ```

2. Define variables **por día y sucursal** (ajusta valores):
   ```psql
   \set bdate 2025-10-29
   \set sucursal_key '1'
   ```

3. Ejecuta **TODAS** las verificaciones v6:
   ```psql
   \i C:\xampp3\htdocs\TerrenaLaravel\docs\Orquestador\sql\verification_queries_psql_v6.sql
   ```

> **Interpretación:**  
> - **0 filas** ⇒ sin problemas.  
> - **con filas** ⇒ pendientes o huecos que debes resolver (ver sección 4).

---

## 3) Módulos cubiertos por v6 y qué valida cada bloque

- **Bloque 1 — Ventas MENÚ sin mapeo (pos_map.tipo='MENU')**  
  Si arroja filas: faltan PLUs en `selemti.pos_map` (columnas `plu`, fechas `valid_from/valid_to` o `vigente_desde`).

- **Bloque 1.b — Modificadores sin mapeo (pos_map.tipo='MODIFIER')**  
  Si arroja filas: faltan PLUs de `ticket_item_modifier.item_id` en `pos_map` con `tipo='MODIFIER'`.

- **Bloque 2 — Pendientes en inv_consumo_pos/_det**  
  Muestra líneas con `requiere_reproceso = true` o `procesado = false` para el día/sucursal.

- **Bloque 3 — Tickets expandidos sin mov_inv**  
  Tickets que ya se expandieron a `inv_consumo_pos` pero **no** tienen movimientos definitivos en `selemti.mov_inv` (`ref_tipo IN ('TICKET','AJUSTE_REPROCESO_POS')`).

- **Bloque 4 — Cobertura de snapshot**  
  Conteo de **items con movimientos** vs **items en `inventory_snapshot`** para `branch_id = :'sucursal_key'` y `snapshot_date = :'bdate'`.

- **Bloque 5 — Stocks teóricos negativos**  
  `SUM(cantidad)` en `mov_inv` < 0 al cierre del día filtro. Señal de fuga o mal mapeo.

- **Bloque 6 — Recetas mapeadas sin snapshot de costo**  
  Valida que todo `pos_map.receta_id` tenga snapshot en `recipe_cost_history.snapshot_at <= :'bdate'`.

- **Bloque 7 — Candidatos a reproceso**  
  Ventas del día **con mapeo vigente** y `_det.requiere_reproceso = true` (útiles para re-correr consumo).

- **Bloque 8 — Conteos abiertos**  
  Conteos del día/sucursal que **no** están cerrados. Deben irse a **0** tras cierre.

---

## 4) Criterios de aceptación por módulo (lo que debería verse en resultados)

- **POS Mapping UI (MENU/MODIFIER)**:  
  - Bloques **1 y 1.b** → **0 filas** (o lista residual controlada y documentada).
  - CRUD de `selemti.pos_map` funcionando y **sin romper vistas existentes**.

- **Consumo POS y Reproceso**:  
  - Bloque **2** → **0 filas** post-proceso.  
  - Bloque **3** → **0 filas** después de confirmar consumo / reprocesos.

- **Snapshot Diario**:  
  - Bloque **4** → `faltantes_en_snapshot = 0` para la sucursal/fecha objetivo.  
  - Bloque **5** → **0 filas** (o casos explicados en evidencia).

- **Costos de Recetas**:  
  - Bloque **6** → **0 filas** después del `recetas:recalcular-costos` (01:10 America/Mexico_City).

- **Conteos Físicos**:  
  - Bloque **8** → **0 filas** tras ejecutar cierre de conteo desde UI.

---

## 5) Evidencias mínimas (para fast‑track con IAs)

Crea la carpeta del día:
```
C:\xampp3\htdocs\TerrenaLaravel\docs\Orquestador\evidencias\2025-10-30\
```
Guarda ahí:
- `SQL_Run_2025-10-30.txt` → copia pegada de resultados psql para cada bloque (1, 1.b, 2, 3, 4, 5, 6, 8).  
- `UI_Mapping_Screenshots/` → capturas antes/después.  
- `Counts_Close_Screenshots/` → evidencia de cierre y resultado del Bloque 8=0.  
- `Cost_Scheduler_Log_2025-10-30.md` → salida/Log del comando y filas nuevas en `recipe_cost_history`.  
- `Snapshot_Report_2025-10-30.md` → totales de cobertura del Bloque 4.

> Tip: usa nombres **exactos** para que tus agentes puedan ubicarlos sin gastar tokens preguntando.

---

## 6) Prompts ultra‑cortos (por módulo)

**A) POS Mapping (MENU/MODIFIER)**  
```
Tarea: eliminar filas en bloques 1 y 1.b (v6).
Ruta SQL: docs/Orquestador/sql/verification_queries_psql_v6.sql
Aceptación: 0 filas en ambos bloques. No cambios de esquema. Mantener UI existente.
Evidencia: capturas de CRUD pos_map + salida psql (bloques 1 y 1.b).
```

**B) Consumo POS / Reproceso**  
```
Tarea: dejar bloques 2 y 3 en 0 usando servicios actuales (sin DDL).
Aceptación: 0 filas en v6 bloques 2 y 3.
Evidencia: salida psql antes/después y log de servicio (trace_id).
```

**C) Snapshot Diario**  
```
Tarea: asegurar cobertura completa (bloque 4) y sin negativos (bloque 5).
Aceptación: faltantes_en_snapshot=0; 0 filas en negativos.
Evidencia: Snapshot_Report_YYYY-MM-DD.md y salida psql.
```

**D) Costos de Recetas**  
```
Tarea: scheduler 01:10 OK y snapshots de costo presentes (bloque 6=0).
Aceptación: nuevas filas en recipe_cost_history y v6 bloque 6=0.
Evidencia: Cost_Scheduler_Log_YYYY-MM-DD.md + salida psql.
```

**E) Conteos Físicos**  
```
Tarea: cerrar conteos del día/sucursal desde UI.
Aceptación: v6 bloque 8=0.
Evidencia: capturas de cierre + salida psql bloque 8.
```

---

## 7) Troubleshooting común

- **“no existe la columna/tabla”**: re‑ejecuta `discover_schema_psql_v2.sql` y ajusta rutas/alias.  
- **Resultados vacíos en todo**: confirma `:'bdate'` y `:'sucursal_key'` correctos y que existan tickets/movimientos ese día.  
- **Faltantes en snapshot**: ejecuta tu `generateDailySnapshot` para la fecha y revisa triggers/restricciones del UPSERT.  
- **Costos sin snapshot**: asegura que `recetas:recalcular-costos` corra y respete vigencias.


---

## 8) Enlaces rápidos (para tus agentes)
- SQL v6: `docs/Orquestador/sql/verification_queries_psql_v6.sql`
- Descubrimiento: `docs/Orquestador/sql/discover_schema_psql_v2.sql`
- Evidencias del día: `docs/Orquestador/evidencias/2025-10-30/`
