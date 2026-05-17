# Gemini Task: Fix `fn_postcorte_after_insert` — Sales Totals Always NULL

**Assignee:** Gemini CLI  
**Schema:** `selemti` (writable) — `public` is **READ ONLY** (see Critical Rules below)  
**Priority:** 🔴 High — broken in production

---

## ⚠️ CRITICAL RULES — READ FIRST

This project has a **dual-schema PostgreSQL database** with strict access rules:

| Schema | Owner | Rule |
|--------|-------|------|
| `selemti` | TerrenaLaravel ERP | Full read/write — this is your workspace |
| `public` | FloreantPOS (Java POS system) | **READ ONLY — NEVER INSERT/UPDATE/DELETE/ALTER** |

The `public` schema contains 108 live production tables used by FloreantPOS (the Java cash register system). Altering, dropping, or writing to any `public.*` table in production **will break the live POS system** and require a full restore.

**You MAY read from `public.*`** (e.g., `public.ticket`, `public.transactions`) — that is how the trigger gets sales data. But you must NEVER write to it.

**Never run `migrate:fresh`** — it would drop all tables in `selemti` and if `public` is in the search path, the POS tables too.

---

## Background

TerrenaLaravel's cash register closing flow works like this:

```
SesionCajon (drawer session)
  → Precorte (pre-close count, cashier declares cash/cards)
    → fn_precorte_after_insert trigger: marks session EN_CORTE
    → fn_precorte_after_update_aprobado trigger: calls fn_generar_postcorte()
      → fn_generar_postcorte(): reads public.transactions, inserts into selemti.postcorte
        → fn_postcorte_after_insert trigger: (should) populate sales totals FROM public.ticket
  → Postcorte (final closing record with totals)
  → Conciliacion (optional reconciliation step)
```

### The Bug

`fn_postcorte_after_insert` currently only marks the session as CERRADA. It does **not** populate the `total_ventas_*` columns on the postcorte row. Those columns end up NULL, which means supervisors cannot see gross/net sales in the closing report.

### Current trigger definition (what's in production)

```sql
CREATE OR REPLACE FUNCTION selemti.fn_postcorte_after_insert()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = 'CERRADA',
      cierre_ts = COALESCE(cierre_ts, now())
  WHERE id = NEW.sesion_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

This is **missing the sales totals update**.

---

## selemti.postcorte — Table Structure

```
id                          BIGSERIAL PK
sesion_id                   BIGINT FK → selemti.sesion_cajon.id
sistema_efectivo_esperado   NUMERIC(12,2)   -- expected cash (from POS transactions)
declarado_efectivo          NUMERIC(12,2)   -- cashier's declared cash
diferencia_efectivo         NUMERIC(12,2)   -- declared - sistema
veredicto_efectivo          TEXT            -- 'CUADRA' | 'A_FAVOR' | 'EN_CONTRA'
sistema_tarjetas            NUMERIC(12,2)
declarado_tarjetas          NUMERIC(12,2)
diferencia_tarjetas         NUMERIC(12,2)
veredicto_tarjetas          TEXT
sistema_transferencias      NUMERIC(12,2)
declarado_transferencias    NUMERIC(12,2)
diferencia_transferencias   NUMERIC(12,2)
veredicto_transferencias    TEXT
total_ventas_brutas         NUMERIC(12,2)   -- ← NULL (bug)
total_descuentos_reales     NUMERIC(12,2)   -- ← NULL (bug)
total_ventas_netas          NUMERIC(12,2)   -- ← NULL (bug)
creado_en                   TIMESTAMPTZ
creado_por                  BIGINT
notas                       TEXT
validado                    BOOLEAN
validado_por                BIGINT
validado_en                 TIMESTAMPTZ
requiere_aprobacion         BOOLEAN
aprobado_por                BIGINT
aprobado_en                 TIMESTAMPTZ
motivo_irregular            TEXT
rechazado                   BOOLEAN
motivo_rechazo              TEXT
```

> **Verify these columns exist** before writing the fix. If `total_ventas_brutas`, `total_descuentos_reales`, or `total_ventas_netas` are missing from the actual table, add them first (see PG 9.5 note below).

---

## selemti.sesion_cajon — Relevant columns

```
id          BIGSERIAL PK
terminal_id INT         -- FK to public.terminal (POS terminal ID)
apertura_ts TIMESTAMPTZ -- when the session was opened
cierre_ts   TIMESTAMPTZ -- when closed
estatus     TEXT        -- 'ACTIVA' | 'EN_CORTE' | 'CERRADA' | ...
```

---

## public.ticket — READ ONLY — Sales source

```
id            BIGINT PK
terminal_id   INT         -- matches sesion_cajon.terminal_id
create_date   TIMESTAMPTZ -- ticket creation time
sub_total     NUMERIC     -- gross sales (pre-discount)
total_discount NUMERIC    -- discounts applied
total_price   NUMERIC     -- net total (what customer paid)
voided        BOOLEAN     -- true = cancelled, exclude
closing_date  TIMESTAMPTZ nullable
```

---

## Proposed Fix

The trigger should compute sales totals from `public.ticket` (READ from public, WRITE to selemti) and update the postcorte row:

```sql
CREATE OR REPLACE FUNCTION selemti.fn_postcorte_after_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_apertura_ts   TIMESTAMPTZ;
    v_cierre_ts     TIMESTAMPTZ;
    v_terminal_id   INT;
    v_ventas_brutas NUMERIC(12,2) := 0;
    v_descuentos    NUMERIC(12,2) := 0;
    v_ventas_netas  NUMERIC(12,2) := 0;
BEGIN
    -- 1. Close the session
    UPDATE selemti.sesion_cajon
    SET estatus   = 'CERRADA',
        cierre_ts = COALESCE(cierre_ts, now())
    WHERE id = NEW.sesion_id
    RETURNING apertura_ts, cierre_ts, terminal_id
    INTO v_apertura_ts, v_cierre_ts, v_terminal_id;

    -- 2. Aggregate sales from POS tickets (READ ONLY from public.ticket)
    SELECT
        COALESCE(SUM(sub_total), 0),
        COALESCE(SUM(total_discount), 0),
        COALESCE(SUM(total_price), 0)
    INTO v_ventas_brutas, v_descuentos, v_ventas_netas
    FROM public.ticket
    WHERE terminal_id = v_terminal_id
      AND create_date >= (v_apertura_ts - interval '1 hour')
      AND create_date <= (v_cierre_ts + interval '2 hours')
      AND voided = false;

    -- 3. Update totals on the postcorte row (WRITE to selemti.postcorte)
    UPDATE selemti.postcorte
    SET total_ventas_brutas     = v_ventas_brutas,
        total_descuentos_reales = v_descuentos,
        total_ventas_netas      = v_ventas_netas
    WHERE id = NEW.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

> **Important:** `RETURNING` from `UPDATE sesion_cajon` may not work cleanly if `cierre_ts` was already set. Fall back to a `SELECT` first if the `RETURNING` approach is problematic.

---

## Your Diagnosis Steps

Before applying any fix:

1. **Check if columns exist:**
   ```sql
   SELECT column_name
   FROM information_schema.columns
   WHERE table_schema = 'selemti'
     AND table_name   = 'postcorte'
     AND column_name IN ('total_ventas_brutas', 'total_descuentos_reales', 'total_ventas_netas');
   ```

2. **Check current trigger definition:**
   ```sql
   SELECT pg_get_functiondef(p.oid)
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'selemti'
     AND p.proname = 'fn_postcorte_after_insert';
   ```

3. **Verify trigger is attached:**
   ```sql
   SELECT tgname, tgenabled
   FROM pg_trigger
   WHERE tgrelid = 'selemti.postcorte'::regclass
     AND tgname = 'trg_postcorte_after_insert';
   ```

4. **Sample a broken postcorte row:**
   ```sql
   SELECT id, sesion_id, total_ventas_brutas, total_descuentos_reales, total_ventas_netas
   FROM selemti.postcorte
   ORDER BY id DESC
   LIMIT 5;
   ```

---

## PG 9.5 Compatibility Notes

- No `ADD COLUMN IF NOT EXISTS`. To safely add columns:
  ```sql
  DO $$ BEGIN
    BEGIN ALTER TABLE selemti.postcorte ADD COLUMN total_ventas_brutas NUMERIC(12,2) DEFAULT 0;
    EXCEPTION WHEN duplicate_column THEN NULL; END;
  END $$;
  ```
- No window functions needed here.
- `CREATE OR REPLACE FUNCTION` is safe to re-run.
- `DROP TRIGGER IF EXISTS` + `CREATE TRIGGER` is the safest pattern for triggers.

---

## Deliverables

1. **Diagnosis report** — confirm which columns are missing/present, current trigger state, sample NULL rows
2. **Migration SQL** — a `.sql` file or inline SQL that:
   - Adds missing columns with PG 9.5-safe `DO $$...$$` blocks if needed
   - Replaces `selemti.fn_postcorte_after_insert` with the corrected version
   - Drops and recreates the trigger if needed
3. **Verification query** — SQL that confirms the fix works on an existing postcorte row (backfill the NULL rows)
4. **Backfill** — if there are existing postcorte rows with NULL totals, provide a one-time UPDATE to populate them from `public.ticket` (same join logic as the trigger)

---

## Backfill Template

```sql
-- One-time backfill for existing NULL postcorte rows
UPDATE selemti.postcorte p
SET
    total_ventas_brutas     = t.ventas_brutas,
    total_descuentos_reales = t.descuentos,
    total_ventas_netas      = t.ventas_netas
FROM (
    SELECT
        pc.id AS postcorte_id,
        COALESCE(SUM(tk.sub_total), 0)      AS ventas_brutas,
        COALESCE(SUM(tk.total_discount), 0) AS descuentos,
        COALESCE(SUM(tk.total_price), 0)    AS ventas_netas
    FROM selemti.postcorte pc
    JOIN selemti.sesion_cajon sc ON sc.id = pc.sesion_id
    JOIN public.ticket tk ON tk.terminal_id = sc.terminal_id
        AND tk.create_date >= (sc.apertura_ts - interval '1 hour')
        AND tk.create_date <= (COALESCE(sc.cierre_ts, now()) + interval '2 hours')
        AND tk.voided = false
    WHERE pc.total_ventas_brutas IS NULL
    GROUP BY pc.id
) t
WHERE p.id = t.postcorte_id;
```

> **Always run inside a transaction and check row counts before committing.** Roll back if counts look wrong.

---

## Definition of Done

- [ ] Diagnosis: confirmed which columns are missing
- [ ] Columns added (if missing) with PG 9.5-safe syntax
- [ ] `fn_postcorte_after_insert` replaced with corrected version
- [ ] Trigger re-attached and verified active on `selemti.postcorte`
- [ ] Existing NULL rows backfilled
- [ ] Verification: new postcorte insertion results in non-NULL totals
- [ ] No writes to `public.*` schema
