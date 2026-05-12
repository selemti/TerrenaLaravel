-- Actualizar la función fn_generar_postcorte para incluir cálculo de descuentos reales
-- Integración completa con métricas de descuentos

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

   -- Descuentos (NUEVO)
   v_descuentos_drawer NUMERIC;
   v_descuentos_reales NUMERIC;
   v_diferencia_descuentos NUMERIC;

   -- Diferencias
   v_dif_ef NUMERIC;
   v_dif_tj NUMERIC;
   v_dif_tr NUMERIC;

   -- Totales de ventas
   v_total_ventas_brutas NUMERIC;
   v_total_ventas_netas NUMERIC;
BEGIN
   -- Obtener datos de sesión
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

   -- Calcular totales de ventas (NUEVO)
   SELECT
       COALESCE(SUM(CASE WHEN t.voided = false THEN t.total_price ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN t.voided = false THEN (t.total_price - t.total_discount) ELSE 0 END), 0)
   INTO v_total_ventas_brutas, v_total_ventas_netas
   FROM public.ticket t
   WHERE t.terminal_id = v_terminal_id
     AND t.closing_date >= v_apertura_ts
     AND t.closing_date < COALESCE(v_cierre_ts, now());

   -- Calcular descuentos drawer vs reales (NUEVO)
   SELECT
       COALESCE(dpr.totaldiscountamount, 0),
       COALESCE(public.fn_descuentos_reales_sesion_simple(p_sesion_id), 0)
   INTO v_descuentos_drawer, v_descuentos_reales
   FROM public.drawer_pull_report dpr
   WHERE dpr.terminal_id = v_terminal_id
     AND dpr.report_time::date = v_apertura_ts::date
   ORDER BY dpr.report_time DESC LIMIT 1;

   -- Si no hay drawer report, asignar 0
   IF v_descuentos_drawer IS NULL THEN
       v_descuentos_drawer := 0;
   END IF;

   v_diferencia_descuentos := v_descuentos_drawer - v_descuentos_reales;

   -- Calcular diferencias
   v_dif_ef := v_decl_ef - v_sys_ef;
   v_dif_tj := (v_decl_cr + v_decl_db) - (v_sys_cr + v_sys_db);
   v_dif_tr := v_decl_tr - v_sys_tr;

   -- Insertar postcorte con métricas adicionales de descuentos y ventas
   INSERT INTO selemti.postcorte (
       sesion_id,
       sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo,
       sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas,
       sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias,
       -- Nuevos campos
       total_ventas_brutas,
       total_ventas_netas,
       total_descuentos_drawer,
       total_descuentos_reales,
       diferencia_descuentos,
       porcentaje_error_descuentos,
       calidad_reporte_descuentos,
       creado_en, creado_por
   ) VALUES (
       p_sesion_id,
       v_sys_ef, v_decl_ef, v_dif_ef,
       CASE WHEN ABS(v_dif_ef) < 0.01 THEN 'CUADRA' WHEN v_dif_ef > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
       v_sys_cr + v_sys_db, v_decl_cr + v_decl_db, v_dif_tj,
       CASE WHEN ABS(v_dif_tj) < 0.01 THEN 'CUADRA' WHEN v_dif_tj > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
       v_sys_tr, v_decl_tr, v_dif_tr,
       CASE WHEN ABS(v_dif_tr) < 0.01 THEN 'CUADRA' WHEN v_dif_tr > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
       -- Nuevos valores
       v_total_ventas_brutas,
       v_total_ventas_netas,
       v_descuentos_drawer,
       v_descuentos_reales,
       v_diferencia_descuentos,
       CASE
           WHEN v_descuentos_reales > 0
           THEN ROUND(((v_diferencia_descuentos::numeric / v_descuentos_reales) * 100), 2)
           ELSE 0
       END,
       CASE
           WHEN ABS(v_diferencia_descuentos) < 10 THEN 'EXCELENTE'
           WHEN ABS(v_diferencia_descuentos) < 50 THEN 'BUENO'
           WHEN ABS(v_diferencia_descuentos) < 200 THEN 'ACEPTABLE'
           WHEN ABS(v_diferencia_descuentos) < 500 THEN 'REVISAR'
           ELSE 'CRITICO'
       END,
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
       -- Actualizar nuevos campos
       total_ventas_brutas = EXCLUDED.total_ventas_brutas,
       total_ventas_netas = EXCLUDED.total_ventas_netas,
       total_descuentos_drawer = EXCLUDED.total_descuentos_drawer,
       total_descuentos_reales = EXCLUDED.total_descuentos_reales,
       diferencia_descuentos = EXCLUDED.diferencia_descuentos,
       porcentaje_error_descuentos = EXCLUDED.porcentaje_error_descuentos,
       calidad_reporte_descuentos = EXCLUDED.calidad_reporte_descuentos,
       creado_en = EXCLUDED.creado_en
   RETURNING id INTO v_postcorte_id;

   RETURN v_postcorte_id;
END;
$$;