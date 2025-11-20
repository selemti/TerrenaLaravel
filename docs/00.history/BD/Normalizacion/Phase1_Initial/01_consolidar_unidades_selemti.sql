-- =============================================================================
-- Script 01: Consolidación de Tablas de Unidades en selemti
-- =============================================================================
-- Fecha: 30 de octubre de 2025
-- Objetivo: Consolidar todas las tablas de unidades en unidades_medida_legacy
--           como tabla canónica, y crear vistas de compatibilidad
-- IMPORTANTE: Solo opera en esquema selemti, NO toca public
-- =============================================================================

SET search_path TO selemti, public;

-- -----------------------------------------------------------------------------
-- PASO 1: Verificar estado actual
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE '=== ESTADO ACTUAL DE TABLAS DE UNIDADES ===';
    RAISE NOTICE 'cat_unidades: % registros', (SELECT COUNT(*) FROM selemti.cat_unidades);
    RAISE NOTICE 'unidades_medida_legacy: % registros', (SELECT COUNT(*) FROM selemti.unidades_medida_legacy);
    RAISE NOTICE 'unidad_medida_legacy: % registros', (SELECT COUNT(*) FROM selemti.unidad_medida_legacy);
END $$;

-- -----------------------------------------------------------------------------
-- PASO 2: Migrar datos de cat_unidades a unidades_medida_legacy
-- -----------------------------------------------------------------------------
-- Mapear las claves de cat_unidades a unidades_medida_legacy

-- Primero, verificar cuáles ya existen
DO $$
DECLARE
    v_clave VARCHAR;
    v_nombre VARCHAR;
    v_tipo VARCHAR;
    v_id INTEGER;
BEGIN
    RAISE NOTICE '=== MIGRANDO DATOS DE cat_unidades ===';

    FOR v_clave, v_nombre IN
        SELECT clave, nombre FROM selemti.cat_unidades
        WHERE activo = true
        ORDER BY clave
    LOOP
        -- Determinar tipo según clave
        v_tipo := CASE
            WHEN v_clave IN ('KG', 'G', 'GR', 'MG', 'TON', 'LB', 'OZ') THEN 'PESO'
            WHEN v_clave IN ('L', 'LT', 'ML', 'GAL', 'FLOZ', 'M3', 'MC') THEN 'VOLUMEN'
            WHEN v_clave IN ('HR', 'MIN') THEN 'TIEMPO'
            ELSE 'UNIDAD'
        END;

        -- Verificar si ya existe
        SELECT id INTO v_id FROM selemti.unidades_medida_legacy WHERE codigo = v_clave;

        IF v_id IS NULL THEN
            -- Insertar nueva unidad
            INSERT INTO selemti.unidades_medida_legacy (codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales)
            VALUES (
                v_clave,
                v_nombre,
                v_tipo,
                CASE
                    WHEN v_tipo IN ('PESO', 'VOLUMEN') THEN 'METRICO'
                    WHEN v_tipo = 'TIEMPO' THEN 'CULINARIO'
                    ELSE 'CULINARIO'
                END,
                CASE WHEN v_clave IN ('KG', 'L', 'LT', 'PZ', 'EA') THEN true ELSE false END,
                1.0,
                CASE
                    WHEN v_tipo = 'PESO' THEN 3
                    WHEN v_tipo = 'VOLUMEN' THEN 3
                    ELSE 0
                END
            )
            RETURNING id INTO v_id;

            RAISE NOTICE 'Migrada unidad: % (%) -> ID %', v_clave, v_nombre, v_id;
        ELSE
            RAISE NOTICE 'Ya existe unidad: % (%) -> ID %', v_clave, v_nombre, v_id;
        END IF;
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 3: Migrar datos de unidad_medida_legacy (singular) si existen
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM selemti.unidad_medida_legacy;

    IF v_count > 0 THEN
        RAISE NOTICE '=== MIGRANDO DATOS DE unidad_medida_legacy (singular) ===';

        INSERT INTO selemti.unidades_medida_legacy (codigo, nombre, tipo, es_base, factor_conversion_base, decimales)
        SELECT
            codigo,
            nombre,
            tipo,
            es_base,
            factor_a_base,
            decimales
        FROM selemti.unidad_medida_legacy u1
        WHERE NOT EXISTS (
            SELECT 1 FROM selemti.unidades_medida_legacy u2
            WHERE u2.codigo = u1.codigo
        )
        ON CONFLICT (codigo) DO NOTHING;

        RAISE NOTICE 'Migración completada desde unidad_medida_legacy';
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 4: Crear vistas de compatibilidad
-- -----------------------------------------------------------------------------

-- Vista: cat_unidades (compatibilidad)
DROP VIEW IF EXISTS selemti.v_cat_unidades_compat CASCADE;
CREATE OR REPLACE VIEW selemti.v_cat_unidades_compat AS
SELECT
    id,
    NOW() as created_at,
    NOW() as updated_at,
    codigo as clave,
    nombre,
    true as activo
FROM selemti.unidades_medida_legacy
WHERE codigo IN ('KG', 'L', 'LT', 'PZ', 'EA', 'G', 'ML', 'OZ', 'LB', 'GAL');

COMMENT ON VIEW selemti.v_cat_unidades_compat IS
'Vista de compatibilidad para cat_unidades. Mapea a unidades_medida_legacy (canónica)';

-- Vista: unidad_medida_legacy (singular) - compatibilidad
DROP VIEW IF EXISTS selemti.v_unidad_medida_singular_compat CASCADE;
CREATE OR REPLACE VIEW selemti.v_unidad_medida_singular_compat AS
SELECT
    id,
    codigo,
    nombre,
    tipo,
    es_base,
    factor_conversion_base as factor_a_base,
    decimales
FROM selemti.unidades_medida_legacy;

COMMENT ON VIEW selemti.v_unidad_medida_singular_compat IS
'Vista de compatibilidad para unidad_medida_legacy (singular). Mapea a unidades_medida_legacy (canónica)';

-- -----------------------------------------------------------------------------
-- PASO 5: Verificar integridad
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_total INTEGER;
    v_huerfanos INTEGER;
BEGIN
    RAISE NOTICE '=== VERIFICACIÓN DE INTEGRIDAD ===';

    -- Total de unidades
    SELECT COUNT(*) INTO v_total FROM selemti.unidades_medida_legacy;
    RAISE NOTICE 'Total unidades en unidades_medida_legacy: %', v_total;

    -- Items con unidades válidas
    SELECT COUNT(*) INTO v_huerfanos
    FROM selemti.items i
    LEFT JOIN selemti.unidades_medida_legacy u ON u.id = i.unidad_medida_id
    WHERE i.unidad_medida_id IS NOT NULL AND u.id IS NULL;

    IF v_huerfanos > 0 THEN
        RAISE WARNING '¡ATENCIÓN! % items con unidades no mapeadas', v_huerfanos;
    ELSE
        RAISE NOTICE '✓ Todos los items tienen unidades válidas';
    END IF;

    -- Unidades base
    SELECT COUNT(*) INTO v_total
    FROM selemti.unidades_medida_legacy
    WHERE es_base = true;
    RAISE NOTICE '✓ Unidades base definidas: %', v_total;
END $$;

-- -----------------------------------------------------------------------------
-- PASO 6: Resumen final
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'CONSOLIDACIÓN DE UNIDADES COMPLETADA';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'Tabla canónica: selemti.unidades_medida_legacy';
    RAISE NOTICE 'Vistas de compatibilidad creadas:';
    RAISE NOTICE '  - v_cat_unidades_compat';
    RAISE NOTICE '  - v_unidad_medida_singular_compat';
    RAISE NOTICE '';
    RAISE NOTICE 'SIGUIENTE PASO: Actualizar código para usar unidades_medida_legacy';
    RAISE NOTICE '=============================================================================';
END $$;
