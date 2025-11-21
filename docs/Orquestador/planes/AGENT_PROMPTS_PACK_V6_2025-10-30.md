# PACK DE PROMPTS — Agentes paralelos v6 (2025-10-30)

> Copia y pega en tu CLI de agentes. Cada prompt es “token-min” (alto contexto local por rutas y archivos) y prohíbe DDL.

## AGENTE A — POS Map + Counts (UI) + Auditoría v6
Rol: Ingeniero IA (Laravel Livewire 3 + Tailwind). **Prohibido DDL**; sólo código app/ y blade, y lectura SQL de docs/Orquestador/sql/.
Ruta repo: `C:\xampp3\htdocs\TerrenaLaravel`

Contexto fijo:
- WIREFLOWS: `docs\Orquestador\WIREFLOWS_Terrena_v1.md`
- SQL v6: `docs\Orquestador\sql\verification_queries_psql_v6.sql`
- Descubrimiento: `docs\Orquestador\sql\discover_schema_psql_v2.sql`
- Tablas reales: `selemti.pos_map`, `selemti.inventory_counts`, `selemti.inventory_count_lines`
- Dashboard: `app\Inventory\OrquestadorPanel.php` (sólo enlaces; NO tocar servicios)

Tareas:
1) **POS Mapping UI**
   - Crear/ajustar: `app\Livewire\PosMap\Index.php`, `resources\views\livewire\pos-map\index.blade.php`, ruta `/pos-map` en `routes\web.php` si falta.
   - Filtros: `plu`, `tipo`, vigencia, texto libre.
   - Acciones: alta/edición con vigencias; **sin** alteraciones de esquema.
   - Botón “Ver pendientes”: ejecutar Bloques **1 y 1.b** de v6 (pasar `:bdate`, `:sucursal_key`, opcional `:terminal_id`) y pintar tabla.

2) **Conteos físicos**
   - En `app\Livewire\InventoryCount\Index.php` añadir acción **Cerrar conteo** (actualiza `estado` y `cerrado_en`). UI en `resources\views\livewire\inventory-count\index.blade.php`.
   - Botón **Validar v6**: ejecutar Bloque **8** y mostrar si quedan abiertos.

3) **Auditoría rápida**
   - Comando helper (opcional): `php artisan orq:audit --date=YYYY-MM-DD --sucursal=KEY` que sólo llame a los scripts v6 y devuelva counts (stdout). **No DDL**.

Entregables:
- Código Livewire + blades + rutas.
- `docs\Orquestador\UI_Mapping_README.md`
- `docs\Orquestador\Conteos_Evidencia_2025-10-30.md`

Criterios de aceptación:
- Bloques 1, 1.b y 8 de v6 sin errores y coherentes con la UI.
- Navegación desde dashboard al `/pos-map` y `/inventory-counts`.

---

## AGENTE B — Scheduler Costos + SQL Range + Hook Dashboard
Rol: Ingeniero IA (Laravel + Artisan + SQL). **Prohibido DDL**.
Ruta repo: `C:\xampp3\htdocs\TerrenaLaravel`

Contexto fijo:
- SQL v6: `docs\Orquestador\sql\verification_queries_psql_v6.sql`
- SQL range: `docs\Orquestador\sql\verification_queries_psql_range.sql`
- Costos: `app\RecalcularCostosRecetasService.php`, `app\Console\Kernel.php` (tarea 01:10 ok)
- Costos docs: `docs\Orquestador\RECETA_COST_CALCULATION*.md`

Tareas:
1) **Scheduler 01:10**
   - Comando manual: `php artisan recetas:recalcular-costos --date=2025-10-30` y guardar log a `docs\Orquestador\Costos_Scheduler_Log_2025-10-30.md`.
   - Validar con v6 (bloque 6) que `recipe_cost_history.snapshot_at::date = :bdate` tenga filas.

2) **SQL Auditor Range**
   - Confirmar `verification_queries_psql_range.sql` en `docs\Orquestador\sql\` con parámetros: `:bdate_from`, `:bdate_to`, `:sucursal_key`.
   - Añadir doc corto de uso en `docs\Orquestador\SQL_RANGE_README.md` con ejemplos `psql` Windows.

3) **Hook Dashboard**
   - Añadir en `app\Inventory\OrquestadorPanel.php` botón “Auditar hoy (v6)” que corra v6 y muestre resultados (counts) vía modal/toast. **No tocar servicios core**.

Entregables:
- `docs\Orquestador\Costos_Scheduler_Log_2025-10-30.md`
- `docs\Orquestador\SQL_RANGE_README.md`
- Actualización mínima de panel (enlaces/botón).

Criterios de aceptación:
- Bloque 6 reporta snapshots del día si hubo recálculo.
- Range script funciona en 9.5 sin errores.
