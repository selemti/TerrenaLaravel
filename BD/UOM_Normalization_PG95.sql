-- ====================================================================
-- UOM NORMALIZATION SCRIPT FOR POSTGRESQL 9.5
-- TerrenaLaravel - SelemTI Schema
-- ====================================================================
--
-- Purpose: Normalize UOM (Unit of Measure) system to canonical tables
--          with backward compatibility views for legacy tables
--
-- Canonical Tables:
--   - selemti.cat_unidades (master UOM catalog)
--   - selemti.cat_uom_conversion (conversion factors with metadata)
--
-- Legacy Tables (to be deprecated via views):
--   - selemti.unidad_medida
--   - selemti.unidades_medida
--   - selemti.uom_conversion
--   - selemti.conversiones_unidad
--
-- PostgreSQL Version: 9.5 (no ON CONFLICT, no GENERATED columns)
-- Schema: selemti (default search path)
-- ====================================================================

SET search_path TO selemti, public;
SET client_encoding TO 'UTF8';

-- ====================================================================
-- STEP 1: ENSURE CANONICAL TABLES EXIST WITH ALL REQUIRED COLUMNS
-- ====================================================================

-- Table: cat_unidades
-- Description: Master catalog of units of measure
DO $$
BEGIN
    -- Check if table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'selemti'
                   AND table_name = 'cat_unidades') THEN

        CREATE TABLE cat_unidades (
            id bigint NOT NULL,
            clave character varying(16) NOT NULL,
            nombre character varying(64) NOT NULL,
            activo boolean DEFAULT true NOT NULL,
            created_at timestamp(0) without time zone,
            updated_at timestamp(0) without time zone,
            CONSTRAINT cat_unidades_pkey PRIMARY KEY (id),
            CONSTRAINT cat_unidades_clave_unique UNIQUE (clave)
        );

        CREATE SEQUENCE cat_unidades_id_seq
            START WITH 1
            INCREMENT BY 1
            NO MINVALUE
            NO MAXVALUE
            CACHE 1;

        ALTER SEQUENCE cat_unidades_id_seq OWNED BY cat_unidades.id;
        ALTER TABLE cat_unidades ALTER COLUMN id SET DEFAULT nextval('cat_unidades_id_seq'::regclass);

        RAISE NOTICE 'Created table: cat_unidades';
    ELSE
        -- Table exists, ensure columns exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_schema = 'selemti'
                       AND table_name = 'cat_unidades'
                       AND column_name = 'clave') THEN
            ALTER TABLE cat_unidades ADD COLUMN clave character varying(16);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_schema = 'selemti'
                       AND table_name = 'cat_unidades'
                       AND column_name = 'nombre') THEN
            ALTER TABLE cat_unidades ADD COLUMN nombre character varying(64);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_schema = 'selemti'
                       AND table_name = 'cat_unidades'
                       AND column_name = 'activo') THEN
            ALTER TABLE cat_unidades ADD COLUMN activo boolean DEFAULT true NOT NULL;
        END IF;

        -- Ensure UNIQUE constraint on clave
        IF NOT EXISTS (SELECT 1 FROM pg_constraint
                       WHERE conname = 'cat_unidades_clave_unique') THEN
            ALTER TABLE cat_unidades ADD CONSTRAINT cat_unidades_clave_unique UNIQUE (clave);
        END IF;

        RAISE NOTICE 'Verified table: cat_unidades';
    END IF;
END $$;

-- Table: cat_uom_conversion
-- Description: UOM conversion factors with metadata (exact/approx, scope, notes)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_schema = 'selemti'
                   AND table_name = 'cat_uom_conversion') THEN

        CREATE TABLE cat_uom_conversion (
            id bigint NOT NULL,
            origen_id bigint NOT NULL,
            destino_id bigint NOT NULL,
            factor numeric(18,6) NOT NULL,
            is_exact boolean DEFAULT true NOT NULL,
            scope character varying(16) DEFAULT 'global'::character varying NOT NULL,
            notes text,
            created_at timestamp(0) without time zone,
            updated_at timestamp(0) without time zone,
            CONSTRAINT cat_uom_conversion_pkey PRIMARY KEY (id),
            CONSTRAINT cat_uom_conversion_unique UNIQUE (origen_id, destino_id),
            CONSTRAINT cat_uom_conversion_check CHECK (origen_id <> destino_id),
            CONSTRAINT cat_uom_conversion_factor_check CHECK (factor > 0::numeric),
            CONSTRAINT cat_uom_conversion_scope_check CHECK (scope::text = ANY (ARRAY['global'::character varying::text, 'house'::character varying::text]))
        );

        CREATE SEQUENCE cat_uom_conversion_id_seq
            START WITH 1
            INCREMENT BY 1
            NO MINVALUE
            NO MAXVALUE
            CACHE 1;

        ALTER SEQUENCE cat_uom_conversion_id_seq OWNED BY cat_uom_conversion.id;
        ALTER TABLE cat_uom_conversion ALTER COLUMN id SET DEFAULT nextval('cat_uom_conversion_id_seq'::regclass);

        RAISE NOTICE 'Created table: cat_uom_conversion';
    ELSE
        -- Add missing columns to existing table
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_schema = 'selemti'
                       AND table_name = 'cat_uom_conversion'
                       AND column_name = 'is_exact') THEN
            ALTER TABLE cat_uom_conversion ADD COLUMN is_exact boolean DEFAULT true NOT NULL;
            RAISE NOTICE 'Added column: is_exact to cat_uom_conversion';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_schema = 'selemti'
                       AND table_name = 'cat_uom_conversion'
                       AND column_name = 'scope') THEN
            ALTER TABLE cat_uom_conversion ADD COLUMN scope character varying(16) DEFAULT 'global'::character varying NOT NULL;
            RAISE NOTICE 'Added column: scope to cat_uom_conversion';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_schema = 'selemti'
                       AND table_name = 'cat_uom_conversion'
                       AND column_name = 'notes') THEN
            ALTER TABLE cat_uom_conversion ADD COLUMN notes text;
            RAISE NOTICE 'Added column: notes to cat_uom_conversion';
        END IF;

        -- Ensure UNIQUE constraint on (origen_id, destino_id)
        IF NOT EXISTS (SELECT 1 FROM pg_constraint
                       WHERE conname = 'cat_uom_conversion_unique') THEN
            ALTER TABLE cat_uom_conversion ADD CONSTRAINT cat_uom_conversion_unique UNIQUE (origen_id, destino_id);
        END IF;

        RAISE NOTICE 'Verified table: cat_uom_conversion';
    END IF;
END $$;

-- Create Foreign Keys for cat_uom_conversion
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cat_uom_conversion_origen_id_foreign') THEN
        ALTER TABLE cat_uom_conversion
            ADD CONSTRAINT cat_uom_conversion_origen_id_foreign
            FOREIGN KEY (origen_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;
        RAISE NOTICE 'Created FK: cat_uom_conversion_origen_id_foreign';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cat_uom_conversion_destino_id_foreign') THEN
        ALTER TABLE cat_uom_conversion
            ADD CONSTRAINT cat_uom_conversion_destino_id_foreign
            FOREIGN KEY (destino_id) REFERENCES cat_unidades(id) ON DELETE CASCADE;
        RAISE NOTICE 'Created FK: cat_uom_conversion_destino_id_foreign';
    END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_cat_unidades_clave ON cat_unidades(clave);
CREATE INDEX IF NOT EXISTS idx_cat_unidades_activo ON cat_unidades(activo);
CREATE INDEX IF NOT EXISTS idx_cat_uom_conversion_origen ON cat_uom_conversion(origen_id);
CREATE INDEX IF NOT EXISTS idx_cat_uom_conversion_destino ON cat_uom_conversion(destino_id);
CREATE INDEX IF NOT EXISTS idx_cat_uom_conversion_scope ON cat_uom_conversion(scope);


-- ====================================================================
-- STEP 2: SEED CANONICAL UOM DATA (IDEMPOTENT)
-- ====================================================================

-- Insert base UOM units (metric, imperial, culinary, unit)
DO $$
DECLARE
    v_now timestamp := now();
BEGIN
    -- MASA (Mass)
    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'KG', 'Kilogramo', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'KG');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'G', 'Gramo', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'G');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'MG', 'Miligramo', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'MG');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'LB', 'Libra', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'LB');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'OZ', 'Onza', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'OZ');

    -- VOLUMEN (Volume)
    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'L', 'Litro', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'L');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'ML', 'Mililitro', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'ML');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'M3', 'Metro cúbico', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'M3');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'FLOZ', 'Onza fluida (US)', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'FLOZ');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'CUP', 'Taza', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'CUP');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'TBSP', 'Cucharada', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'TBSP');

    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'TSP', 'Cucharadita', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'TSP');

    -- UNIDAD (Unit/Piece)
    INSERT INTO cat_unidades (clave, nombre, activo, created_at, updated_at)
    SELECT 'PZ', 'Pieza', true, v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_unidades WHERE clave = 'PZ');

    RAISE NOTICE 'UOM seeds completed';
END $$;


-- ====================================================================
-- STEP 3: SEED CONVERSION FACTORS (IDEMPOTENT, BIDIRECTIONAL)
-- ====================================================================

DO $$
DECLARE
    v_now timestamp := now();
    v_kg_id bigint; v_g_id bigint; v_mg_id bigint; v_lb_id bigint; v_oz_id bigint;
    v_l_id bigint; v_ml_id bigint; v_m3_id bigint;
    v_floz_id bigint; v_cup_id bigint; v_tbsp_id bigint; v_tsp_id bigint;
BEGIN
    -- Resolve IDs from clave
    SELECT id INTO v_kg_id FROM cat_unidades WHERE clave = 'KG';
    SELECT id INTO v_g_id FROM cat_unidades WHERE clave = 'G';
    SELECT id INTO v_mg_id FROM cat_unidades WHERE clave = 'MG';
    SELECT id INTO v_lb_id FROM cat_unidades WHERE clave = 'LB';
    SELECT id INTO v_oz_id FROM cat_unidades WHERE clave = 'OZ';
    SELECT id INTO v_l_id FROM cat_unidades WHERE clave = 'L';
    SELECT id INTO v_ml_id FROM cat_unidades WHERE clave = 'ML';
    SELECT id INTO v_m3_id FROM cat_unidades WHERE clave = 'M3';
    SELECT id INTO v_floz_id FROM cat_unidades WHERE clave = 'FLOZ';
    SELECT id INTO v_cup_id FROM cat_unidades WHERE clave = 'CUP';
    SELECT id INTO v_tbsp_id FROM cat_unidades WHERE clave = 'TBSP';
    SELECT id INTO v_tsp_id FROM cat_unidades WHERE clave = 'TSP';

    -- ===== METRIC MASS CONVERSIONS (exact, global) =====

    -- KG ↔ G
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_kg_id, v_g_id, 1000.0, true, 'global', 'Métrica estándar', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_kg_id AND destino_id = v_g_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_g_id, v_kg_id, 0.001, true, 'global', 'Métrica estándar', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_g_id AND destino_id = v_kg_id);

    -- G ↔ MG
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_g_id, v_mg_id, 1000.0, true, 'global', 'Métrica estándar', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_g_id AND destino_id = v_mg_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_mg_id, v_g_id, 0.001, true, 'global', 'Métrica estándar', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_mg_id AND destino_id = v_g_id);

    -- ===== METRIC VOLUME CONVERSIONS (exact, global) =====

    -- L ↔ ML
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_l_id, v_ml_id, 1000.0, true, 'global', 'Métrica estándar', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_l_id AND destino_id = v_ml_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_ml_id, v_l_id, 0.001, true, 'global', 'Métrica estándar', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_ml_id AND destino_id = v_l_id);

    -- M3 ↔ L
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_m3_id, v_l_id, 1000.0, true, 'global', 'Métrica estándar', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_m3_id AND destino_id = v_l_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_l_id, v_m3_id, 0.001, true, 'global', 'Métrica estándar', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_l_id AND destino_id = v_m3_id);

    -- ===== IMPERIAL MASS CONVERSIONS (exact, global) =====

    -- LB ↔ G (exact conversion)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_lb_id, v_g_id, 453.59237, true, 'global', 'Conversión imperial exacta (definición internacional)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_lb_id AND destino_id = v_g_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_g_id, v_lb_id, 0.00220462, true, 'global', 'Conversión imperial exacta', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_g_id AND destino_id = v_lb_id);

    -- OZ ↔ G (exact conversion)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_oz_id, v_g_id, 28.349523125, true, 'global', 'Conversión avoirdupois ounce exacta', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_oz_id AND destino_id = v_g_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_g_id, v_oz_id, 0.035274, true, 'global', 'Conversión avoirdupois ounce exacta', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_g_id AND destino_id = v_oz_id);

    -- LB ↔ OZ (exact)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_lb_id, v_oz_id, 16.0, true, 'global', '1 libra = 16 onzas exactas', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_lb_id AND destino_id = v_oz_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_oz_id, v_lb_id, 0.0625, true, 'global', '1 onza = 1/16 libra', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_oz_id AND destino_id = v_lb_id);

    -- ===== CULINARY VOLUME CONVERSIONS (approx, house scope) =====

    -- FLOZ ↔ ML (US fluid ounce, approximate)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_floz_id, v_ml_id, 29.5735, false, 'house', 'US customary fluid ounce (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_floz_id AND destino_id = v_ml_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_ml_id, v_floz_id, 0.033814, false, 'house', 'US customary fluid ounce (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_ml_id AND destino_id = v_floz_id);

    -- CUP ↔ ML (US cup, approximate)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_cup_id, v_ml_id, 240.0, false, 'house', 'Taza US estándar (aproximado, varía 236-250ml)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_cup_id AND destino_id = v_ml_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_ml_id, v_cup_id, 0.004167, false, 'house', 'Taza US estándar (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_ml_id AND destino_id = v_cup_id);

    -- TBSP ↔ ML (tablespoon, approximate)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_tbsp_id, v_ml_id, 15.0, false, 'house', 'Cucharada US (aproximado, varía 14.7-15ml)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_tbsp_id AND destino_id = v_ml_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_ml_id, v_tbsp_id, 0.066667, false, 'house', 'Cucharada US (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_ml_id AND destino_id = v_tbsp_id);

    -- TSP ↔ ML (teaspoon, approximate)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_tsp_id, v_ml_id, 5.0, false, 'house', 'Cucharadita US (aproximado, varía 4.9-5ml)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_tsp_id AND destino_id = v_ml_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_ml_id, v_tsp_id, 0.2, false, 'house', 'Cucharadita US (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_ml_id AND destino_id = v_tsp_id);

    -- CUP ↔ TBSP (house scope)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_cup_id, v_tbsp_id, 16.0, false, 'house', '1 taza = 16 cucharadas (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_cup_id AND destino_id = v_tbsp_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_tbsp_id, v_cup_id, 0.0625, false, 'house', '1 cucharada = 1/16 taza (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_tbsp_id AND destino_id = v_cup_id);

    -- TBSP ↔ TSP (house scope)
    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_tbsp_id, v_tsp_id, 3.0, false, 'house', '1 cucharada = 3 cucharaditas (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_tbsp_id AND destino_id = v_tsp_id);

    INSERT INTO cat_uom_conversion (origen_id, destino_id, factor, is_exact, scope, notes, created_at, updated_at)
    SELECT v_tsp_id, v_tbsp_id, 0.333333, false, 'house', '1 cucharadita = 1/3 cucharada (aproximado)', v_now, v_now
    WHERE NOT EXISTS (SELECT 1 FROM cat_uom_conversion WHERE origen_id = v_tsp_id AND destino_id = v_tbsp_id);

    RAISE NOTICE 'Conversion seeds completed';
END $$;


-- ====================================================================
-- STEP 4: CREATE COMPATIBILITY VIEWS FOR LEGACY TABLES
-- ====================================================================
-- Purpose: Maintain backward compatibility with existing queries and FKs
--          while transitioning to canonical tables
-- ====================================================================

-- Drop legacy tables if they are actual tables (we'll recreate as views)
-- Note: This is safe only if no critical data exists. Skip if uncertain.
-- For maximum safety, we keep them and rename to _legacy suffix

DO $$
BEGIN
    -- Rename unidad_medida to unidad_medida_legacy if it exists as table
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'selemti' AND table_name = 'unidad_medida'
               AND table_type = 'BASE TABLE') THEN

        -- Check if legacy table already exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                       WHERE table_schema = 'selemti' AND table_name = 'unidad_medida_legacy') THEN
            ALTER TABLE unidad_medida RENAME TO unidad_medida_legacy;
            RAISE NOTICE 'Renamed unidad_medida to unidad_medida_legacy';
        END IF;
    END IF;

    -- Rename unidades_medida to unidades_medida_legacy
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'selemti' AND table_name = 'unidades_medida'
               AND table_type = 'BASE TABLE') THEN

        IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                       WHERE table_schema = 'selemti' AND table_name = 'unidades_medida_legacy') THEN
            ALTER TABLE unidades_medida RENAME TO unidades_medida_legacy;
            RAISE NOTICE 'Renamed unidades_medida to unidades_medida_legacy';
        END IF;
    END IF;

    -- Rename uom_conversion to uom_conversion_legacy
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'selemti' AND table_name = 'uom_conversion'
               AND table_type = 'BASE TABLE') THEN

        IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                       WHERE table_schema = 'selemti' AND table_name = 'uom_conversion_legacy') THEN
            ALTER TABLE uom_conversion RENAME TO uom_conversion_legacy;
            RAISE NOTICE 'Renamed uom_conversion to uom_conversion_legacy';
        END IF;
    END IF;

    -- Rename conversiones_unidad to conversiones_unidad_legacy
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'selemti' AND table_name = 'conversiones_unidad'
               AND table_type = 'BASE TABLE') THEN

        IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                       WHERE table_schema = 'selemti' AND table_name = 'conversiones_unidad_legacy') THEN
            ALTER TABLE conversiones_unidad RENAME TO conversiones_unidad_legacy;
            RAISE NOTICE 'Renamed conversiones_unidad to conversiones_unidad_legacy';
        END IF;
    END IF;
END $$;

-- Create view: unidad_medida (maps to cat_unidades)
CREATE OR REPLACE VIEW unidad_medida AS
SELECT
    id::integer AS id,
    clave AS codigo,
    nombre,
    CASE
        WHEN clave IN ('KG', 'G', 'MG', 'LB', 'OZ') THEN 'PESO'
        WHEN clave IN ('L', 'ML', 'M3', 'FLOZ', 'CUP', 'TBSP', 'TSP') THEN 'VOLUMEN'
        WHEN clave IN ('PZ') THEN 'UNIDAD'
        ELSE 'UNIDAD'
    END AS tipo,
    CASE
        WHEN clave IN ('KG', 'L', 'PZ') THEN true
        ELSE false
    END AS es_base,
    1.0::numeric(14,6) AS factor_a_base,  -- Simplified for view
    2 AS decimales
FROM cat_unidades
WHERE activo = true;

COMMENT ON VIEW unidad_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidad_medida';

-- Create view: unidades_medida (maps to cat_unidades with categoria)
CREATE OR REPLACE VIEW unidades_medida AS
SELECT
    id::integer AS id,
    clave AS codigo,
    nombre,
    CASE
        WHEN clave IN ('KG', 'G', 'MG', 'LB', 'OZ') THEN 'PESO'
        WHEN clave IN ('L', 'ML', 'M3', 'FLOZ', 'CUP', 'TBSP', 'TSP') THEN 'VOLUMEN'
        WHEN clave IN ('PZ') THEN 'UNIDAD'
        ELSE 'UNIDAD'
    END::character varying(10) AS tipo,
    CASE
        WHEN clave IN ('KG', 'G', 'MG', 'L', 'ML', 'M3') THEN 'METRICO'
        WHEN clave IN ('LB', 'OZ', 'FLOZ') THEN 'IMPERIAL'
        WHEN clave IN ('CUP', 'TBSP', 'TSP') THEN 'CULINARIO'
        ELSE 'METRICO'
    END::character varying(20) AS categoria,
    CASE
        WHEN clave IN ('KG', 'L', 'PZ') THEN true
        ELSE false
    END AS es_base,
    1.0::numeric(12,6) AS factor_conversion_base,  -- Simplified for view
    2 AS decimales,
    created_at
FROM cat_unidades
WHERE activo = true;

COMMENT ON VIEW unidades_medida IS 'Vista de compatibilidad: mapea cat_unidades a estructura legacy unidades_medida con categoria';

-- Create view: uom_conversion (maps to cat_uom_conversion)
CREATE OR REPLACE VIEW uom_conversion AS
SELECT
    id::integer AS id,
    origen_id::integer AS origen_id,
    destino_id::integer AS destino_id,
    factor::numeric(14,6) AS factor
FROM cat_uom_conversion;

COMMENT ON VIEW uom_conversion IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy uom_conversion';

-- Create view: conversiones_unidad (maps to cat_uom_conversion with more columns)
CREATE OR REPLACE VIEW conversiones_unidad AS
SELECT
    id::integer AS id,
    origen_id::integer AS unidad_origen_id,
    destino_id::integer AS unidad_destino_id,
    factor AS factor_conversion,
    notes AS formula_directa,
    CASE
        WHEN is_exact THEN 1.0
        ELSE 0.95
    END::numeric(5,4) AS precision_estimada,
    true AS activo,  -- All canonical conversions are active
    created_at
FROM cat_uom_conversion;

COMMENT ON VIEW conversiones_unidad IS 'Vista de compatibilidad: mapea cat_uom_conversion a estructura legacy conversiones_unidad';


-- ====================================================================
-- STEP 5: FIX FOREIGN KEY INCONSISTENCIES (if needed)
-- ====================================================================
-- Note: Since we created views, existing FKs pointing to legacy tables
--       will still work. No immediate FK changes needed.
--       Future migrations should update FKs to point to cat_unidades.
-- ====================================================================

-- Example: If we need to change insumo.um_id FK from unidad_medida to cat_unidades
-- This would be done in a future migration with data migration first.
-- For now, views maintain compatibility.

RAISE NOTICE '===================================================';
RAISE NOTICE 'UOM Normalization completed successfully!';
RAISE NOTICE '===================================================';
RAISE NOTICE 'Canonical tables: cat_unidades, cat_uom_conversion';
RAISE NOTICE 'Legacy tables renamed to: *_legacy';
RAISE NOTICE 'Compatibility views created: unidad_medida, unidades_medida, uom_conversion, conversiones_unidad';
RAISE NOTICE '===================================================';
