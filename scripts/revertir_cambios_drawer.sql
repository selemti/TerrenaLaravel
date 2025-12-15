-- SCRIPT DE REVERSIÓN DE CAMBIOS EN TABLAS DRAWER
-- Para revertir las modificaciones realizadas

-- 1. REVERTIR CAMBIOS EN POSTCORTE (SI SE HICIERON)
\echo '=== REVIRTIENDO CAMBIOS EN POSTCORTE ==='

-- Eliminar columnas agregadas si existen
DO $$
BEGIN
    -- Verificar si existen las nuevas columnas
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'postcorte'
          AND column_name = 'total_ventas_brutas'
    ) THEN
        ALTER TABLE selemti.postcorte DROP COLUMN total_ventas_brutas;
        RAISE NOTICE 'Columna total_ventas_brutas eliminada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'postcorte'
          AND column_name = 'total_ventas_netas'
    ) THEN
        ALTER TABLE selemti.postcorte DROP COLUMN total_ventas_netas;
        RAISE NOTICE 'Columna total_ventas_netas eliminada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'postcorte'
          AND column_name = 'total_descuentos_drawer'
    ) THEN
        ALTER TABLE selemti.postcorte DROP COLUMN total_descuentos_drawer;
        RAISE NOTICE 'Columna total_descuentos_drawer eliminada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'postcorte'
          AND column_name = 'total_descuentos_reales'
    ) THEN
        ALTER TABLE selemti.postcorte DROP COLUMN total_descuentos_reales;
        RAISE NOTICE 'Columna total_descuentos_reales eliminada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'postcorte'
          AND column_name = 'diferencia_descuentos'
    ) THEN
        ALTER TABLE selemti.postcorte DROP COLUMN diferencia_descuentos;
        RAISE NOTICE 'Columna diferencia_descuentos eliminada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'postcorte'
          AND column_name = 'porcentaje_error_descuentos'
    ) THEN
        ALTER TABLE selemti.postcorte DROP COLUMN porcentaje_error_descuentos;
        RAISE NOTICE 'Columna porcentaje_error_descuentos eliminada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'selemti'
          AND table_name = 'postcorte'
          AND column_name = 'calidad_reporte_descuentos'
    ) THEN
        ALTER TABLE selemti.postcorte DROP COLUMN calidad_reporte_descuentos;
        RAISE NOTICE 'Columna calidad_reporte_descuentos eliminada';
    END IF;

    -- Eliminar constraint si existe
    IF EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_schema = 'selemti'
          AND constraint_name = 'postcorte_calidad_reporte_descuentos_check'
    ) THEN
        ALTER TABLE selemti.postcorte DROP CONSTRAINT postcorte_calidad_reporte_descuentos_check;
        RAISE NOTICE 'Constraint de calidad_reporte_descuentos eliminado';
    END IF;

END;
$$;

-- 2. RESTAURAR FUNCIÓN ORIGINAL (SI FUE MODIFICADA)
\echo '=== RESTAURANDO FUNCIÓN ORIGINAL ==='
DROP FUNCTION IF EXISTS selemti.fn_generar_postcorte(BIGINT);

-- Crear función original básica (sin descuentos)
CREATE OR REPLACE FUNCTION selemti.fn_generar_postcorte(p_sesion_id BIGINT)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
   v_postcorte_id BIGINT;
   v_precorte_id BIGINT;
   v_terminal_id INT;
   v_apertura_ts TIMESTAMPTZ;
   v_cierre_ts TIMESTAMPTZ;

   -- Declarados
   v_decl_ef NUMERIC;
   v_decl_cr NUMERIC;
   v_decl_db NUMERIC;
   v_decl_tr NUMERIC;

   -- Sistema
   v_sys_ef NUMERIC;
   v_sys_cr NUMERIC;
   v_sys_db NUMERIC;
   v_sys_tr NUMERIC;

   -- Diferencias
   v_dif_ef NUMERIC;
   v_dif_tj NUMERIC;
   v_dif_tr NUMERIC;
BEGIN
   -- Obtener datos de la sesión
   SELECT terminal_id, apertura_ts, cierre_ts
   INTO v_terminal_id, v_apertura_ts, v_cierre_ts
   FROM selemti.sesion_cajon
   WHERE id = p_sesion_id;

   -- Obtener precorte_id
   SELECT id INTO v_precorte_id
   FROM selemti.precorte
   WHERE sesion_id = p_sesion_id
   ORDER BY id DESC LIMIT 1;

   -- Calcular declarados (desde precorte)
   SELECT
       COALESCE(SUM(subtotal), 0)
   INTO v_decl_ef
   FROM selemti.precorte_efectivo
   WHERE precorte_id = v_precorte_id;

   SELECT
       COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('CREDITO') THEN monto ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('DEBITO', 'DÉBITO') THEN monto ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('TRANSFER', 'TRANSFERENCIA') THEN monto ELSE 0 END), 0)
   INTO v_decl_cr, v_decl_db, v_decl_tr
   FROM selemti.precorte_otros
   WHERE precorte_id = v_precorte_id;

   -- Calcular sistema (desde transactions POS)
   SELECT
       COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CASH' THEN amount ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CREDIT_CARD' THEN amount ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'DEBIT_CARD' THEN amount ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CUSTOM_PAYMENT' AND UPPER(custom_payment_name) LIKE 'TRANSFER%' THEN amount ELSE 0 END), 0)
   INTO v_sys_ef, v_sys_cr, v_sys_db, v_sys_tr
   FROM public.transactions
   WHERE terminal_id = v_terminal_id
     AND transaction_time BETWEEN v_apertura_ts AND COALESCE(v_cierre_ts, now())
     AND UPPER(transaction_type) = 'CREDIT'
     AND voided = false;

   -- Calcular diferencias
   v_dif_ef := v_decl_ef - v_sys_ef;
   v_dif_tj := (v_decl_cr + v_decl_db) - (v_sys_cr + v_sys_db);
   v_dif_tr := v_decl_tr - v_sys_tr;

   -- Insertar postcorte
   INSERT INTO selemti.postcorte (
       sesion_id,
       sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo,
       sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas,
       sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias,
       creado_en, creado_por
   ) VALUES (
       p_sesion_id,
       v_sys_ef, v_decl_ef, v_dif_ef,
       CASE WHEN ABS(v_dif_ef) < 0.01 THEN 'CUADRA' WHEN v_dif_ef > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
       v_sys_cr + v_sys_db, v_decl_cr + v_decl_db, v_dif_tj,
       CASE WHEN ABS(v_dif_tj) < 0.01 THEN 'CUADRA' WHEN v_dif_tj > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
       v_sys_tr, v_decl_tr, v_dif_tr,
       CASE WHEN ABS(v_dif_tr) < 0.01 THEN 'CUADRA' WHEN v_dif_tr > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
       now(), 1
   ) ON CONFLICT (sesion_id) DO UPDATE SET
       sistema_efectivo_esperado = EXCLUDED.sistema_efectivo_esperado,
       declarado_efectivo = EXCLUDED.declarado_efectivo,
       diferencia_efectivo = EXCLUDED.diferencia_efectivo,
       veredicto_efectivo = EXCLUDED.veredicto_efectivo,
       sistema_tarjetas = EXCLUDED.sistema_tarjetas,
       declarado_tarjetas = EXCLUDED.declarado_tarjetas,
       diferencia_tarjetas = EXCLUDED.diferencia_tarjetas,
       veredicto_tarjetas = EXCLUDED.veredicto_tarjetas,
       sistema_transferencias = EXCLUDED.sistema_transferencias,
       declarado_transferencias = EXCLUDED.declarado_transferencias,
       diferencia_transferencias = EXCLUDED.diferencia_transferencias,
       veredicto_transferencias = EXCLUDED.veredicto_transferencias,
       creado_en = EXCLUDED.creado_en
   RETURNING id INTO v_postcorte_id;

   RETURN v_postcorte_id;
END;
$$;

-- 3. ELIMINAR FUNCIONES AUXILIARES (SI SE CREARON)
\echo '=== ELIMINANDO FUNCIONES AUXILIARES ==='
DROP FUNCTION IF EXISTS public.fn_descuentos_reales_sesion_simple(BIGINT);
DROP FUNCTION IF EXISTS public.fn_calcular_descuentos_reales_sesion(BIGINT);

-- 4. ELIMINAR VISTAS (SI SE CREARON)
\echo '=== ELIMINANDO VISTAS ==='
DROP VIEW IF EXISTS selemti.vw_postcortes_con_descuentos;
DROP VIEW IF EXISTS selemti.vw_calidad_reportes_descuentos;

-- 5. REVERTIR CAMBIOS EN MODELO ELOQUENT
-- Esto se hace manualmente en el archivo PHP

-- 6. VERIFICAR ESTADO FINAL
\echo '=== ESTADO FINAL DE REVERSIÓN ==='
SELECT
    'postcorte_columns' as elemento,
    COUNT(*) as count,
    STRING_AGG(column_name, ', ') as columns
FROM information_schema.columns
WHERE table_schema = 'selemti'
  AND table_name = 'postcorte'
GROUP BY 'postcorte_columns'

UNION ALL

SELECT
    'functions_selemti' as elemento,
    COUNT(*) as count,
    STRING_AGG(routine_name, ', ') as functions
FROM information_schema.routines
WHERE routine_schema = 'selemti'
  AND routine_name LIKE '%postcorte%'
GROUP BY 'functions_selemti'

UNION ALL

SELECT
    'functions_public' as elemento,
    COUNT(*) as count,
    STRING_AGG(routine_name, ', ') as functions
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%descuento%'
GROUP BY 'functions_public';