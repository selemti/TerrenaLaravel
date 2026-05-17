# PROMPT GEMINI — Tareas SQL Auditoría 2026-05-17

## Contexto

TerrenaLaravel — ERP de restaurante. PostgreSQL 9.5, schema `selemti`.
- `public` schema = FloreantPOS READ ONLY (nunca INSERT/UPDATE/DELETE/ALTER)
- `selemti` schema = ERP, libremente modificable

Conexión local: `localhost:5433`, database `pos`, user `postgres`

---

## TAREA 1 — Diagnosticar y reparar `vw_dashboard_formas_pago` (causa del 500)

### Contexto

La vista existe y tiene datos (209 filas para el rango 2026-04-17 → 2026-05-17).
Sin embargo el endpoint `/api/reports/ventas/formas` retorna HTTP 500 cuando lo llama
el backend PHP (Laravel).

### Definición actual de la vista

```sql
SELECT (t.transaction_time)::date AS fecha,
    COALESCE(NULLIF((term.location)::text, ''), 'Sin sucursal') AS sucursal_id,
    COALESCE(NULLIF((t.payment_type)::text, ''), 'OTRO') AS codigo_fp,
    (SUM(COALESCE(t.amount, 0)))::numeric(12,2) AS monto
FROM transactions t
LEFT JOIN terminal term ON term.id = t.terminal_id
WHERE t.transaction_time IS NOT NULL
GROUP BY (t.transaction_time)::date,
    COALESCE(NULLIF(term.location::text, ''), 'Sin sucursal'),
    COALESCE(NULLIF(t.payment_type::text, ''), 'OTRO');
```

**Problema identificado:** La vista referencia `transactions` y `terminal` **sin prefijo de
schema**. Funciona cuando `search_path = selemti,public` (default del user `postgres`), pero
PHP/Laravel puede conectarse con un `search_path` diferente o sin `public`, causando que
PostgreSQL no encuentre las tablas y retorne error.

### Tarea

1. Verificar que la vista falla cuando `search_path` no incluye `public`:
   ```sql
   SET search_path TO selemti;
   SELECT COUNT(*) FROM selemti.vw_dashboard_formas_pago
   WHERE fecha BETWEEN '2026-04-17' AND '2026-05-17';
   -- Si falla con "relation transactions does not exist" → confirmado
   ```

2. Recrear la vista con prefijos de schema explícitos (READ ONLY en `public`):
   ```sql
   CREATE OR REPLACE VIEW selemti.vw_dashboard_formas_pago AS
   SELECT
       (t.transaction_time)::date AS fecha,
       COALESCE(NULLIF(term.location::text, ''), 'Sin sucursal') AS sucursal_id,
       COALESCE(NULLIF(t.payment_type::text, ''), 'OTRO') AS codigo_fp,
       SUM(COALESCE(t.amount, 0))::numeric(12,2) AS monto
   FROM public.transactions t
   LEFT JOIN public.terminal term ON term.id = t.terminal_id
   WHERE t.transaction_time IS NOT NULL
   GROUP BY
       (t.transaction_time)::date,
       COALESCE(NULLIF(term.location::text, ''), 'Sin sucursal'),
       COALESCE(NULLIF(t.payment_type::text, ''), 'OTRO');
   ```

3. Verificar que funciona con y sin `public` en `search_path`:
   ```sql
   -- Con public
   SET search_path TO selemti,public;
   SELECT COUNT(*) FROM selemti.vw_dashboard_formas_pago WHERE fecha = CURRENT_DATE;

   -- Sin public
   SET search_path TO selemti;
   SELECT COUNT(*) FROM selemti.vw_dashboard_formas_pago WHERE fecha = CURRENT_DATE;
   -- Ambos deben retornar el mismo resultado
   ```

4. Revisar si hay **otras vistas en `selemti`** que también referencian tablas de `public`
   sin prefijo de schema. Si las hay, listarlas para que se corrijan:
   ```sql
   SELECT table_name, view_definition
   FROM information_schema.views
   WHERE table_schema = 'selemti'
     AND (view_definition LIKE '%FROM transactions%'
       OR view_definition LIKE '%FROM ticket%'
       OR view_definition LIKE '%FROM terminal%'
       OR view_definition LIKE '%FROM employee%')
     AND view_definition NOT LIKE '%public.%';
   ```

Reportar: cuáles vistas tienen el problema y cuáles se corrigieron.

---

## TAREA 2 — Verificar otras vistas `selemti.vw_dashboard_*` con el mismo problema

Ejecutar:
```sql
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'selemti'
  AND table_name LIKE 'vw_dashboard%'
ORDER BY table_name;
```

Para cada vista encontrada, verificar que no referencie tablas `public.*` sin prefijo.
Si alguna lo hace, aplicar el mismo fix que en TAREA 1 (agregar `public.` al nombre de tabla).

---

## TAREA 3 — Optimización defensiva: agregar `WHERE codigo_fp IS NOT NULL` en la vista

Aunque actualmente `codigo_fp` tiene COALESCE y nunca es NULL, agregar la guarda
defensivamente en la vista para evitar problemas futuros:

```sql
-- En la vista recreada (Tarea 1), agregar al WHERE:
WHERE t.transaction_time IS NOT NULL
  AND t.payment_type IS NOT NULL  -- guarda defensiva
```

O simplemente confirmar que el COALESCE ya garantiza que `codigo_fp` nunca es NULL
y documentarlo en un comentario de la vista.

---

## Entregables esperados

1. Vista `selemti.vw_dashboard_formas_pago` recreada con prefijos `public.*` explícitos
2. Lista de otras vistas `selemti.*` con el mismo problema (si las hay) — con su fix aplicado
3. Resultado de la query de verificación (con y sin `public` en search_path) mostrando que
   el problema quedó resuelto
4. Si hay migraciones `.php` correspondientes en
   `database/migrations/2026_05_16_214500_align_selemti_legacy_reporting_views.php`,
   actualizar ese archivo para que incluya el fix del `CREATE OR REPLACE VIEW` correcto.

---

## Restricciones

- Solo schema `selemti` para CREATE/ALTER — `public` es READ ONLY
- PostgreSQL 9.5 — no usar sintaxis de PG10+
- No tocar tablas `public.*`, solo referenciarlas en vistas con `SELECT`
