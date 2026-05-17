# Gemini Task: Phase 0 — Migraciones de estandarización

**Assignee:** Gemini CLI
**Schema:** `selemti` (writable) — `public` READ ONLY
**Prioridad:** 🔴 Alta — bloqueante para corrida completa

---

## Contexto

El plan aprobado en `C:\Users\Tavo\.claude\plans\curried-humming-tulip.md` requiere tres
cambios en la BD local antes de que la corrida end-to-end pueda ejecutarse.
Estos cambios son **solo DDL + seed en `selemti`**. Nada en `public`.

---

## Tarea 1 — Ampliar `cat_tipo_mov_inv` (fuente única de verdad de tipos de movimiento)

### 1a. Agregar columnas (PG 9.5 — NO uses `ADD COLUMN IF NOT EXISTS`, usa `DO $$`)

```sql
DO $$ BEGIN
  BEGIN ALTER TABLE selemti.cat_tipo_mov_inv ADD COLUMN signo SMALLINT NOT NULL DEFAULT 0; EXCEPTION WHEN duplicate_column THEN NULL; END;
  BEGIN ALTER TABLE selemti.cat_tipo_mov_inv ADD COLUMN afecta_costo BOOLEAN NOT NULL DEFAULT true; EXCEPTION WHEN duplicate_column THEN NULL; END;
  BEGIN ALTER TABLE selemti.cat_tipo_mov_inv ADD COLUMN activo BOOLEAN NOT NULL DEFAULT true; EXCEPTION WHEN duplicate_column THEN NULL; END;
END $$;
```

### 1b. Poblar vocabulario canónico (UPSERT — idempotente)

```sql
INSERT INTO selemti.cat_tipo_mov_inv (clave, descripcion, signo, afecta_costo, activo)
VALUES
  ('RECEPCION_COMPRA',   'Entrada por recepción de orden de compra',                  1,  true,  true),
  ('PRODUCCION_ENTRADA', 'Entrada de subreceta o producto elaborado a inventario',    1,  true,  true),
  ('TRASPASO_ENTRADA',   'Entrada de mercancía por traspaso entre almacenes',         1,  false, true),
  ('AJUSTE_ENTRADA',     'Ajuste positivo por conteo físico o corrección',            1,  true,  true),
  ('APERTURA',           'Carga inicial de inventario al arranque del sistema',       1,  true,  true),
  ('PRODUCCION_SALIDA',  'Salida de materia prima para producción interna',           -1, true,  true),
  ('VENTA_POS',          'Salida de inventario por venta en punto de venta',         -1, true,  true),
  ('TRASPASO_SALIDA',    'Salida de mercancía por traspaso entre almacenes',         -1, false, true),
  ('AJUSTE_SALIDA',      'Ajuste negativo por conteo físico o corrección',           -1, true,  true),
  ('MERMA',              'Pérdida por caducidad, daño o merma operativa',            -1, true,  true),
  ('CONSUMO_OPERATIVO',  'Consumo no vendible: limpieza, empaque, capacitación',     -1, true,  true)
ON CONFLICT (clave) DO UPDATE SET
  descripcion   = EXCLUDED.descripcion,
  signo         = EXCLUDED.signo,
  afecta_costo  = EXCLUDED.afecta_costo,
  activo        = EXCLUDED.activo;
```

### 1c. Marcar como inactivas las claves legacy (ya no las escriben los servicios)

```sql
UPDATE selemti.cat_tipo_mov_inv
SET activo = false
WHERE clave IN ('VENTA_POS', 'AJUSTE_REPROCESO_POS', 'AJUSTE_REVERSO',
                'APERTURA_INVENTARIO', 'AJUSTE_RECETA_ERRONEA',
                'AJUSTE_COSTO_BATCH', 'CONSUMO_OPERATIVO',
                'PRODUCCION_SALIDA_CRUDO', 'PRODUCCION_ENTRADA_ELABORADO')
  AND clave NOT IN (SELECT clave FROM selemti.cat_tipo_mov_inv WHERE signo != 0);
-- (solo marca inactivas las que no están en el vocabulario nuevo — las que signo=0 por DEFAULT)
```

**Nota**: `APERTURA_INVENTARIO` (legacy) → renombrado a `APERTURA` en el canónico.
`CONSUMO_OPERATIVO` existe en ambos — el nuevo tiene `signo=-1` correcto.

---

## Tarea 2 — Verificar / crear tabla `selemti.recipes`

Ejecuta este diagnóstico primero:

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'selemti' AND table_name IN ('recipes','recipe_versions','recipe_version_items');
```

**Si las 3 tablas existen**: solo procede a Tarea 3.

**Si faltan**: créalas con esta DDL (no hay migración Laravel para ellas — fueron creadas a mano en producción):

```sql
CREATE TABLE IF NOT EXISTS selemti.recipes (
    id              BIGSERIAL PRIMARY KEY,
    codigo          VARCHAR(60)  NOT NULL UNIQUE,
    nombre          VARCHAR(200) NOT NULL,
    descripcion     TEXT,
    porciones       NUMERIC(10,3) NOT NULL DEFAULT 1,
    tiempo_preparacion INTEGER,
    activo          BOOLEAN NOT NULL DEFAULT true,
    created_by_user_id INTEGER,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS selemti.recipe_versions (
    id          BIGSERIAL PRIMARY KEY,
    recipe_id   BIGINT NOT NULL REFERENCES selemti.recipes(id) ON DELETE CASCADE,
    version_no  INTEGER NOT NULL DEFAULT 1,
    notes       TEXT,
    valid_from  DATE,
    valid_to    DATE,
    created_at  TIMESTAMPTZ DEFAULT now(),
    UNIQUE (recipe_id, version_no)
);

CREATE TABLE IF NOT EXISTS selemti.recipe_version_items (
    id                  BIGSERIAL PRIMARY KEY,
    recipe_version_id   BIGINT NOT NULL REFERENCES selemti.recipe_versions(id) ON DELETE CASCADE,
    item_id             BIGINT,
    sub_recipe_id       BIGINT REFERENCES selemti.recipes(id),
    qty                 NUMERIC(18,6) NOT NULL,
    uom_receta          VARCHAR(20)   NOT NULL,
    orden               INTEGER DEFAULT 0,
    CONSTRAINT chk_rvi_item_xor_recipe CHECK (
        (item_id IS NOT NULL AND sub_recipe_id IS NULL) OR
        (item_id IS NULL AND sub_recipe_id IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_recipe_versions_recipe_id ON selemti.recipe_versions(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_version_items_version_id ON selemti.recipe_version_items(recipe_version_id);
```

---

## Tarea 3 — Agregar `sub_recipe_id` a `recipe_version_items` (si ya existía la tabla)

```sql
DO $$ BEGIN
  BEGIN
    ALTER TABLE selemti.recipe_version_items ADD COLUMN sub_recipe_id BIGINT REFERENCES selemti.recipes(id);
  EXCEPTION WHEN duplicate_column THEN NULL;
  END;
  BEGIN
    ALTER TABLE selemti.recipe_version_items ADD CONSTRAINT chk_rvi_item_xor_recipe
      CHECK ((item_id IS NOT NULL AND sub_recipe_id IS NULL) OR (item_id IS NULL AND sub_recipe_id IS NOT NULL));
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;
```

---

## Tarea 4 — Crear la migración Laravel correspondiente

Crea `database/migrations/2026_05_16_100000_phase0_estandarizacion_inventario.php` que encapsule
todo lo anterior usando el patrón `DO $$` para PG 9.5. Patrón `createIfNotExists` para las tablas
nuevas. La migración debe ser **idempotente** — segura de re-ejecutar.

---

## Entregable

1. Los SQL de arriba ejecutados localmente sin errores.
2. El archivo de migración Laravel creado.
3. Verificación final:

```sql
-- Debe mostrar las 11 claves canónicas con signo != 0
SELECT clave, signo, afecta_costo, activo
FROM selemti.cat_tipo_mov_inv
WHERE activo = true
ORDER BY signo DESC, clave;

-- Debe mostrar las 3 tablas
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'selemti' AND table_name IN ('recipes','recipe_versions','recipe_version_items');
```

## Invariantes críticos

- `public.*` → READ ONLY sin excepción
- PG 9.5 → no `ADD COLUMN IF NOT EXISTS`, usar `DO $$ ... EXCEPTION WHEN duplicate_column`
- No `migrate:fresh`, no DROP en tablas existentes con datos
