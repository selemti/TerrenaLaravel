SET search_path TO selemti, public;

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

-- Stock por lote FEFO desde inventory_batch (usa cantidad_actual y fecha_caducidad)
CREATE OR REPLACE VIEW selemti.vw_stock_por_lote_fefo AS
SELECT
  ib.item_id::text AS item_key,
  ib.id AS lote_id,
  ib.ubicacion_id,
  ib.fecha_caducidad,
  ib.cantidad_actual::numeric AS stock_lote
FROM selemti.inventory_batch ib
WHERE ib.estado = 'ACTIVO'
ORDER BY ib.item_id, ib.fecha_caducidad NULLS LAST, ib.id;

-- Costos actuales por insumo (último registro por fecha_efectiva)
CREATE OR REPLACE VIEW selemti.vw_costos_insumo_actual AS
SELECT DISTINCT ON (h.insumo_id)
  h.insumo_id,
  h.fecha_efectiva,
  h.costo_wac,
  h.algoritmo_principal
FROM selemti.hist_cost_insumo h
ORDER BY h.insumo_id, h.fecha_efectiva DESC;

-- POS map resuelto al día (vigente al momento)
CREATE OR REPLACE VIEW selemti.vw_pos_map_resuelto AS
SELECT
  pm.pos_system,
  pm.plu,
  pm.tipo,
  (row_to_json(pm)->>'receta_version_id')::bigint AS receta_version_id,
  (row_to_json(pm)->>'insumo_id')::bigint AS insumo_id,
  COALESCE((row_to_json(pm)->>'factor_insumo')::numeric, 1) AS factor_insumo,
  (row_to_json(pm)->>'vigente_desde')::timestamp AS vigente_desde,
  (row_to_json(pm)->>'vigente_hasta')::timestamp AS vigente_hasta
FROM selemti.pos_map pm
WHERE (row_to_json(pm)->>'vigente_hasta') IS NULL OR (row_to_json(pm)->>'vigente_hasta')::date >= CURRENT_DATE;

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

-- Kardex (movimientos) expuesto con columnas clave
CREATE OR REPLACE VIEW selemti.vw_kardex AS
SELECT
  mi.id,
  mi.ts,
  COALESCE((row_to_json(mi)->>'item_id')::text, (row_to_json(mi)->>'insumo_id')::text) AS item_key,
  mi.lote_id,
  mi.tipo,
  COALESCE((row_to_json(mi)->>'qty')::numeric, (row_to_json(mi)->>'cantidad')::numeric) AS qty,
  mi.costo_unit,
  mi.ref_tipo,
  mi.ref_id,
  mi.sucursal_id,
  mi.usuario_id
FROM selemti.mov_inv mi
ORDER BY mi.ts DESC, mi.id DESC;

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

-- KPIs diarios por terminal (agrega métricas desde conciliación de sesión)
CREATE OR REPLACE VIEW selemti.vw_kpis_terminal_dia AS
SELECT
  date_trunc('day', c.apertura_ts)::date AS fecha,
  c.terminal_id,
  COUNT(*) AS sesiones,
  SUM(c.sistema_efectivo) AS sistema_efectivo,
  SUM(c.sistema_no_efectivo) AS sistema_no_efectivo,
  SUM(c.sistema_descuentos) AS descuentos,
  SUM(c.sistema_anulaciones) AS anulaciones,
  SUM(c.sistema_retiros) AS retiros,
  SUM(c.sistema_reembolsos_efectivo) AS reembolsos_efectivo,
  SUM(c.sistema_efectivo_esperado) AS efectivo_esperado,
  SUM(c.declarado_precorte_efectivo) AS declarado_precorte,
  SUM(c.declarado_post_efectivo) AS declarado_post_efectivo,
  SUM(c.declarado_post_tarjetas) AS declarado_post_tarjetas,
  SUM(c.diferencia_efectivo) AS diferencia_efectivo,
  SUM(c.diferencia_no_efectivo) AS diferencia_no_efectivo
FROM selemti.vw_conciliacion_sesion c
GROUP BY 1,2;

-- Movimientos anómalos (reglas básicas sobre vw_kardex)
CREATE OR REPLACE VIEW selemti.vw_movimientos_anomalos AS
SELECT
  k.*,
  CASE
    WHEN k.qty IS NULL THEN 'QTY_NULL'
    WHEN k.qty = 0 THEN 'QTY_CERO'
    WHEN ABS(k.qty) > 1000000 THEN 'QTY_EXCESIVA'
    WHEN k.costo_unit < 0 THEN 'COSTO_NEGATIVO'
    WHEN k.ts::timestamp > (now() + interval '1 day') THEN 'FUTURO'
    WHEN k.item_key IS NULL OR k.item_key = '' THEN 'ITEM_VACIO'
    WHEN k.tipo NOT IN ('ENTRADA','RECEPCION','COMPRA','TRASPASO_IN','SALIDA','MERMA','AJUSTE','TRASPASO_OUT') THEN 'TIPO_DESCONOCIDO'
    ELSE NULL END AS regla
FROM selemti.vw_kardex k
WHERE
  (k.qty IS NULL OR k.qty = 0 OR ABS(k.qty) > 1000000 OR k.costo_unit < 0 OR k.ts::timestamp > (now() + interval '1 day') OR k.item_key IS NULL OR k.item_key = '' OR k.tipo NOT IN ('ENTRADA','RECEPCION','COMPRA','TRASPASO_IN','SALIDA','MERMA','AJUSTE','TRASPASO_OUT'));

-- Mapeo terminal->sucursal por dia, derivado de ventas (PLU)
CREATE OR REPLACE VIEW selemti.vw_terminal_sucursal_dia AS
SELECT fecha, terminal_id, sucursal_id
FROM selemti.vw_ventas_por_item
GROUP BY fecha, terminal_id, sucursal_id;

-- Tickets normalizados (base para dashboard)
CREATE OR REPLACE VIEW selemti.vw_dashboard_ticket_base AS
SELECT
  t.id AS ticket_id,
  date_trunc('day', t.closing_date)::date AS fecha,
  date_trunc('hour', t.closing_date) AS hora,
  COALESCE(
    NULLIF(term.location, ''),
    NULLIF((row_to_json(t)->>'branch_key'), ''),
    'Sin sucursal'
  ) AS sucursal_id,
  t.terminal_id,
  COALESCE(t.total_price, 0)::numeric(12,2) AS total,
  COALESCE(t.sub_total, 0)::numeric(12,2) AS sub_total,
  t.paid,
  t.voided,
  t.closing_date,
  COALESCE(
    NULLIF(t.daily_folio::text, ''),
    NULLIF(t.global_id::text, ''),
    (row_to_json(t)->>'ticket_number'),
    t.id::text
  ) AS ticket_ref
FROM public.ticket t
LEFT JOIN public.terminal term
  ON term.id = t.terminal_id
WHERE t.closing_date IS NOT NULL;

-- Resumen diario por sucursal (tickets pagados y no anulados)
CREATE OR REPLACE VIEW selemti.vw_dashboard_resumen_sucursal AS
SELECT
  base.fecha,
  base.sucursal_id,
  COUNT(DISTINCT base.ticket_id) AS tickets,
  SUM(base.total) AS venta_total,
  SUM(base.sub_total) AS sub_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE
GROUP BY base.fecha, base.sucursal_id;

-- Resumen diario por terminal
CREATE OR REPLACE VIEW selemti.vw_dashboard_resumen_terminal AS
SELECT
  base.fecha,
  base.terminal_id,
  base.sucursal_id,
  COUNT(DISTINCT base.ticket_id) AS tickets,
  SUM(base.total) AS venta_total,
  SUM(base.sub_total) AS sub_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE
GROUP BY base.fecha, base.terminal_id, base.sucursal_id;

-- Ventas por hora agregadas desde tickets normalizados
CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_hora AS
SELECT
  base.fecha,
  date_trunc('hour', base.hora) AS hora,
  base.sucursal_id,
  base.terminal_id,
  COUNT(DISTINCT base.ticket_id) AS tickets,
  SUM(base.total) AS venta_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE
GROUP BY base.fecha, date_trunc('hour', base.hora), base.sucursal_id, base.terminal_id;

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

-- Órdenes recientes
CREATE OR REPLACE VIEW selemti.vw_dashboard_ordenes AS
SELECT
  base.ticket_id,
  base.fecha,
  base.hora,
  base.sucursal_id,
  base.terminal_id,
  base.ticket_ref,
  base.total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = TRUE
  AND base.voided = FALSE;

-- KPIs diarios por sucursal agregando KPIs por terminal
CREATE OR REPLACE VIEW selemti.vw_kpis_sucursal_dia AS
WITH k AS (
  SELECT
    date_trunc('day', c.apertura_ts)::date AS fecha,
    c.terminal_id,
    COUNT(*) AS sesiones,
    SUM(c.sistema_efectivo) AS sistema_efectivo,
    SUM(c.sistema_no_efectivo) AS sistema_no_efectivo,
    SUM(c.sistema_descuentos) AS descuentos,
    SUM(c.sistema_anulaciones) AS anulaciones,
    SUM(c.sistema_retiros) AS retiros,
    SUM(c.sistema_reembolsos_efectivo) AS reembolsos_efectivo,
    SUM(c.sistema_efectivo_esperado) AS efectivo_esperado,
    SUM(c.declarado_precorte_efectivo) AS declarado_precorte,
    SUM(c.declarado_post_efectivo) AS declarado_post_efectivo,
    SUM(c.declarado_post_tarjetas) AS declarado_post_tarjetas,
    SUM(c.diferencia_efectivo) AS diferencia_efectivo,
    SUM(c.diferencia_no_efectivo) AS diferencia_no_efectivo
  FROM selemti.vw_conciliacion_sesion c
  GROUP BY 1,2
)
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
FROM k
LEFT JOIN selemti.vw_terminal_sucursal_dia m
  ON m.fecha = k.fecha AND m.terminal_id = k.terminal_id
GROUP BY k.fecha, COALESCE(m.sucursal_id,'');

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
