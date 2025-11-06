-- Script para crear TODAS las vistas faltantes del dashboard
-- Fecha: 2025-11-06
-- Propósito: Incorporar todas las vistas necesarias del sistema SelemTI

SET search_path TO selemti, public;

-- ============================================================
-- VISTAS DE STOCK E INVENTARIO
-- ============================================================

-- Stock actual por item y sucursal (tolerante a qty/cantidad y item_id/insumo_id)
CREATE OR REPLACE VIEW selemti.vw_stock_actual AS
SELECT
  COALESCE((row_to_json(mi)->>'item_id')::text, (row_to_json(mi)->>'insumo_id')::text) AS item_key,
  mi.sucursal_id::text AS sucursal_id,
  SUM(
    CASE WHEN mi.tipo IN ('ENTRADA','RECEPCION','COMPRA','TRASPASO_IN')
         THEN COALESCE((row_to_json(mi)->>'qty')::numeric, (row_to_json(mi)->>'cantidad')::numeric)
         WHEN mi.tipo IN ('SALIDA','MERMA','AJUSTE','TRASPASO_OUT')
         THEN -COALESCE((row_to_json(mi)->>'qty')::numeric, (row_to_json(mi)->>'cantidad')::numeric)
         ELSE 0 END
  ) AS stock
FROM selemti.mov_inv mi
GROUP BY 1,2;

-- Costos actuales por insumo (último registro por fecha_efectiva)
CREATE OR REPLACE VIEW selemti.vw_costos_insumo_actual AS
SELECT DISTINCT ON (h.item_id)
  h.item_id::bigint AS insumo_id,
  h.fecha_efectiva,
  h.costo_wac,
  h.algoritmo_principal
FROM selemti.hist_cost_insumo h
WHERE h.item_id IS NOT NULL AND h.item_id != ''
ORDER BY h.item_id, h.fecha_efectiva DESC;

-- Brechas contra política de stock si existe selemti.stock_policy (min/max)
CREATE OR REPLACE VIEW selemti.vw_stock_brechas AS
SELECT
  sp.sucursal_id,
  sp.item_id,
  sp.min_qty,
  sp.max_qty,
  COALESCE(sa.stock,0) AS stock_actual,
  GREATEST(sp.min_qty - COALESCE(sa.stock,0), 0) AS faltante,
  GREATEST(COALESCE(sa.stock,0) - sp.max_qty, 0) AS excedente
FROM selemti.stock_policy sp
LEFT JOIN (
  SELECT item_key, sucursal_id, SUM(stock) AS stock
  FROM selemti.vw_stock_actual
  GROUP BY item_key, sucursal_id
) sa ON sa.item_key = sp.item_id AND sa.sucursal_id = sp.sucursal_id;

-- Stock valorizado por item/sucursal
CREATE OR REPLACE VIEW selemti.vw_stock_valorizado AS
SELECT
  sa.item_key,
  sa.sucursal_id,
  sa.stock::numeric AS stock,
  ca.costo_wac,
  (sa.stock::numeric * COALESCE(ca.costo_wac,0)) AS valor
FROM selemti.vw_stock_actual sa
LEFT JOIN selemti.vw_costos_insumo_actual ca
  ON ca.insumo_id = NULLIF(sa.item_key,'')::bigint;

-- ============================================================
-- VISTAS DE RECETAS Y BOM
-- ============================================================

-- BOM de una receta (receta_version + insumos)
CREATE OR REPLACE VIEW selemti.vw_receta_completa AS
SELECT
  rv.id AS receta_version_id,
  rv.receta_id,
  rv.version,
  rins.insumo_id,
  rins.cantidad
FROM selemti.receta_version rv
JOIN selemti.receta_insumo rins ON rins.receta_version_id = rv.id;

-- BOM por item de menú (pos_map -> receta -> insumos)
CREATE OR REPLACE VIEW selemti.vw_bom_menu_item AS
SELECT
  pm.pos_system,
  pm.plu,
  pm.tipo,
  (row_to_json(pm)->>'receta_version_id')::bigint AS receta_version_id,
  rins.insumo_id,
  rins.cantidad * COALESCE((row_to_json(pm)->>'factor_insumo')::numeric, 1) AS cantidad_por_menu
FROM selemti.pos_map pm
LEFT JOIN selemti.receta_version rv ON rv.id = (row_to_json(pm)->>'receta_version_id')::bigint
LEFT JOIN selemti.receta_insumo rins ON rins.receta_version_id = rv.id
WHERE pm.tipo IN ('PLATO','MODIFICADOR');

-- ============================================================
-- VISTAS DE CONSUMO Y ANÁLISIS
-- ============================================================

-- Consumo teorico por insumo segun BOM y ventas por PLU
CREATE OR REPLACE VIEW selemti.vw_consumo_teorico AS
SELECT
  v.fecha,
  v.sucursal_id,
  bmi.insumo_id,
  SUM(v.unidades * COALESCE(bmi.cantidad_por_menu,0)) AS consumo_teorico
FROM selemti.vw_ventas_por_item v
JOIN selemti.vw_bom_menu_item bmi ON bmi.plu = v.plu
GROUP BY 1,2,3;

-- Consumo real vs teorico por dia/sucursal/insumo
CREATE OR REPLACE VIEW selemti.vw_consumo_vs_movimientos AS
WITH real AS (
  SELECT
    date_trunc('day', k.ts)::date AS fecha,
    k.sucursal_id::text AS sucursal_id,
    NULLIF(k.item_key,'')::bigint AS insumo_id,
    SUM(CASE WHEN k.tipo IN ('SALIDA','MERMA','AJUSTE') THEN k.qty ELSE 0 END) AS consumo_real
  FROM selemti.vw_kardex k
  GROUP BY 1,2,3
)
SELECT
  COALESCE(t.fecha, r.fecha) AS fecha,
  COALESCE(t.sucursal_id, r.sucursal_id) AS sucursal_id,
  COALESCE(t.insumo_id, r.insumo_id) AS insumo_id,
  COALESCE(t.consumo_teorico, 0) AS consumo_teorico,
  COALESCE(r.consumo_real, 0) AS consumo_real,
  COALESCE(r.consumo_real, 0) - COALESCE(t.consumo_teorico, 0) AS diferencia
FROM selemti.vw_consumo_teorico t
FULL OUTER JOIN real r
  ON r.fecha = t.fecha AND r.sucursal_id = t.sucursal_id AND r.insumo_id = t.insumo_id;

-- ============================================================
-- VISTAS DE VENTAS
-- ============================================================

-- Ventas por item (PLU) por dia y sucursal
CREATE OR REPLACE VIEW selemti.vw_ventas_por_item AS
SELECT
  date_trunc('day', t.closing_date)::date AS fecha,
  t.terminal_id,
  COALESCE((row_to_json(t)->>'branch_key')::text, (row_to_json(t)->>'location')::text, '') AS sucursal_id,
  (row_to_json(ti)->>'plu')::text AS plu,
  SUM(COALESCE((row_to_json(ti)->>'qty')::numeric, (row_to_json(ti)->>'quantity')::numeric, 0)) AS unidades,
  SUM(
    COALESCE((row_to_json(ti)->>'precio')::numeric, (row_to_json(ti)->>'price')::numeric, 0)
    * COALESCE((row_to_json(ti)->>'qty')::numeric, (row_to_json(ti)->>'quantity')::numeric, 0)
  ) AS venta_total
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = (row_to_json(ti)->>'ticket_id')::bigint OR t.id = ti.ticket_id
GROUP BY 1,2,3,4;

-- Ventas por familia (usa pos_map.tipo como familia básica)
CREATE OR REPLACE VIEW selemti.vw_ventas_por_familia AS
SELECT
  v.fecha,
  v.sucursal_id,
  COALESCE(pm.tipo,'DESCONOCIDO') AS familia,
  SUM(v.unidades) AS unidades,
  SUM(v.venta_total) AS venta_total
FROM selemti.vw_ventas_por_item v
LEFT JOIN selemti.pos_map pm ON pm.plu = v.plu
GROUP BY 1,2,3;

-- Mapeo terminal->sucursal por dia, derivado de ventas (PLU)
CREATE OR REPLACE VIEW selemti.vw_terminal_sucursal_dia AS
SELECT fecha, terminal_id, sucursal_id
FROM selemti.vw_ventas_por_item
GROUP BY fecha, terminal_id, sucursal_id;

-- ============================================================
-- VISTAS DE DASHBOARD - PRODUCTOS Y CATEGORÍAS
-- ============================================================

-- Ventas por producto (PLU) con categoría
CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_productos AS
SELECT
  base.fecha,
  base.sucursal_id,
  base.terminal_id,
  ti.item_id AS plu,
  COALESCE(NULLIF(ti.item_name, ''), mi.name, ti.item_id::text) AS descripcion,
  COALESCE(mg.name, 'SIN CATEGORIA') AS categoria,
  SUM(
    COALESCE(
      NULLIF(ti.item_quantity, 0),
      NULLIF(ti.item_count, 0),
      0
    )
  ) AS unidades,
  SUM(COALESCE(ti.total_price, 0)) AS venta_total
FROM selemti.vw_dashboard_ticket_base base
JOIN public.ticket_item ti
  ON ti.ticket_id = base.ticket_id
LEFT JOIN public.menu_item mi
  ON mi.id = ti.item_id
LEFT JOIN public.menu_group mg
  ON mg.id = mi.group_id
WHERE base.paid = TRUE
  AND base.voided = FALSE
GROUP BY base.fecha, base.sucursal_id, base.terminal_id, ti.item_id, descripcion, categoria;

-- Ventas agregadas por categoría de producto
CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_categorias AS
SELECT
  fecha,
  sucursal_id,
  categoria,
  SUM(unidades) AS unidades,
  SUM(venta_total) AS venta_total
FROM selemti.vw_dashboard_ventas_productos
GROUP BY fecha, sucursal_id, categoria;

-- ============================================================
-- VISTAS DE DASHBOARD - FORMAS DE PAGO
-- ============================================================

-- Formas de pago normalizadas
CREATE OR REPLACE VIEW selemti.vw_dashboard_formas_pago AS
SELECT
  t.transaction_time::date AS fecha,
  COALESCE(NULLIF(term.location, ''), 'Sin sucursal') AS sucursal_id,
  COALESCE(
    fp.codigo,
    selemti.fn_normalizar_forma_pago(
      t.payment_type,
      t.transaction_type,
      t.payment_sub_type,
      t.custom_payment_name
    )
  ) AS codigo_fp,
  SUM(t.amount)::numeric(12,2) AS monto
FROM public.transactions t
LEFT JOIN selemti.sesion_cajon s
  ON t.transaction_time >= s.apertura_ts
 AND t.transaction_time < COALESCE(s.cierre_ts, now())
 AND t.terminal_id = s.terminal_id
 AND t.user_id = s.cajero_usuario_id
LEFT JOIN selemti.formas_pago fp
  ON fp.payment_type = t.payment_type
 AND COALESCE(fp.transaction_type, '') = COALESCE(t.transaction_type, '')
 AND COALESCE(fp.payment_sub_type, '') = COALESCE(t.payment_sub_type, '')
 AND COALESCE(fp.custom_name, '') = COALESCE(t.custom_payment_name, '')
 AND COALESCE(fp.custom_ref, '') = COALESCE(t.custom_payment_ref, '')
LEFT JOIN public.terminal term
  ON term.id = t.terminal_id
WHERE t.transaction_time IS NOT NULL
GROUP BY t.transaction_time::date, COALESCE(NULLIF(term.location, ''), 'Sin sucursal'), COALESCE(
    fp.codigo,
    selemti.fn_normalizar_forma_pago(
      t.payment_type,
      t.transaction_type,
      t.payment_sub_type,
      t.custom_payment_name
    )
  );

-- ============================================================
-- VISTAS DE DASHBOARD - ÓRDENES
-- ============================================================

-- Órdenes recientes
CREATE OR REPLACE VIEW selemti.vw_dashboard_ordenes AS
SELECT
  base.ticket_id,
  base.fecha,
  base.hora,
  base.sucursal_id,
  base.terminal_id,
  base.ticket_ref,
  base.total,
  base.closing_date
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE;

-- ============================================================
-- VISTAS DE KPIs
-- ============================================================

-- KPIs diarios por terminal (agrega métricas desde sesion_cajon)
-- NOTA: Esta vista requiere la vista vw_conciliacion_sesion que puede no existir aún
-- Se crea de forma condicional si las columnas existen
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'selemti' AND tablename = 'sesion_cajon') THEN
    CREATE OR REPLACE VIEW selemti.vw_kpis_terminal_dia AS
    SELECT
      date_trunc('day', sc.apertura_ts)::date AS fecha,
      sc.terminal_id,
      COUNT(*) AS sesiones,
      SUM(COALESCE(sc.sistema_efectivo, 0)) AS sistema_efectivo,
      SUM(COALESCE(sc.sistema_total, 0) - COALESCE(sc.sistema_efectivo, 0)) AS sistema_no_efectivo,
      SUM(COALESCE(sc.sistema_descuentos, 0)) AS descuentos,
      SUM(COALESCE(sc.sistema_anulaciones, 0)) AS anulaciones,
      SUM(COALESCE(sc.sistema_retiros, 0)) AS retiros,
      SUM(COALESCE(sc.sistema_reembolsos_efectivo, 0)) AS reembolsos_efectivo,
      SUM(COALESCE(sc.sistema_efectivo_esperado, 0)) AS efectivo_esperado,
      SUM(COALESCE(sc.declarado_precorte_efectivo, 0)) AS declarado_precorte,
      SUM(COALESCE(sc.declarado_post_efectivo, 0)) AS declarado_post_efectivo,
      SUM(COALESCE(sc.declarado_post_tarjetas, 0)) AS declarado_post_tarjetas,
      SUM(COALESCE(sc.diferencia_efectivo, 0)) AS diferencia_efectivo,
      SUM(COALESCE(sc.diferencia_no_efectivo, 0)) AS diferencia_no_efectivo
    FROM selemti.sesion_cajon sc
    WHERE sc.apertura_ts IS NOT NULL
    GROUP BY 1,2;
  END IF;
END $$;

-- KPIs diarios por sucursal agregando KPIs por terminal
-- Depende de vw_kpis_terminal_dia
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'selemti' AND viewname = 'vw_kpis_terminal_dia') THEN
    CREATE OR REPLACE VIEW selemti.vw_kpis_sucursal_dia AS
    SELECT
      k.fecha,
      COALESCE(m.sucursal_id,'') AS sucursal_id,
      SUM(k.sesiones) AS sesiones,
      SUM(k.sistema_efectivo) AS sistema_efectivo,
      SUM(k.sistema_no_efectivo) AS sistema_no_efectivo,
      SUM(k.descuentos) AS descuentos,
      SUM(k.anulaciones) AS anulaciones,
      SUM(k.retiros) AS retiros,
      SUM(k.reembolsos_efectivo) AS reembolsos_efectivo,
      SUM(k.efectivo_esperado) AS efectivo_esperado,
      SUM(k.declarado_precorte) AS declarado_precorte,
      SUM(k.declarado_post_efectivo) AS declarado_post_efectivo,
      SUM(k.declarado_post_tarjetas) AS declarado_post_tarjetas,
      SUM(k.diferencia_efectivo) AS diferencia_efectivo,
      SUM(k.diferencia_no_efectivo) AS diferencia_no_efectivo
    FROM selemti.vw_kpis_terminal_dia k
    LEFT JOIN selemti.vw_terminal_sucursal_dia m
      ON m.fecha = k.fecha AND m.terminal_id = k.terminal_id
    GROUP BY k.fecha, COALESCE(m.sucursal_id,'');
  END IF;
END $$;

-- Ticket promedio por sucursal/dia
CREATE OR REPLACE VIEW selemti.vw_ticket_promedio_sucursal_dia AS
WITH tbase AS (
  SELECT
    fecha,
    sucursal_id,
    ticket_id,
    total
  FROM selemti.vw_dashboard_ticket_base
  WHERE paid = TRUE
    AND voided = FALSE
)
SELECT
  fecha,
  sucursal_id,
  COUNT(DISTINCT ticket_id) AS tickets,
  SUM(total) AS venta_total,
  CASE WHEN COUNT(DISTINCT ticket_id) > 0 THEN SUM(total) / COUNT(DISTINCT ticket_id) ELSE 0 END AS ticket_promedio
FROM tbase
GROUP BY fecha, sucursal_id;

-- Ventas por hora (tickets y monto) por sucursal y terminal
CREATE OR REPLACE VIEW selemti.vw_ventas_por_hora AS
SELECT
  fecha,
  hora,
  sucursal_id,
  terminal_id,
  tickets,
  venta_total
FROM selemti.vw_dashboard_ventas_hora
ORDER BY hora DESC;

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================

SELECT 'Vistas creadas correctamente' AS resultado;
