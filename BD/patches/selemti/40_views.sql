-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
DROP VIEW IF EXISTS v_ingenieria_menu_completa CASCADE;
CREATE OR REPLACE VIEW v_ingenieria_menu_completa AS
 SELECT rc.id AS receta_id,
    rc.nombre_plato,
    rc.codigo_plato_pos,
    rc.precio_venta_sugerido,
    rc.costo_standard_porcion AS costo_actual,
    (rc.precio_venta_sugerido - rc.costo_standard_porcion) AS margen_actual,
        CASE
            WHEN (rc.precio_venta_sugerido > (0)::numeric) THEN (((rc.precio_venta_sugerido - rc.costo_standard_porcion) / rc.precio_venta_sugerido) * (100)::numeric)
            ELSE (0)::numeric
        END AS porcentaje_margen,
    (rc.costo_standard_porcion > (rc.precio_venta_sugerido * 0.4)) AS alerta_costo_alto,
    (( SELECT count(*) AS count
           FROM ticket_venta_det td
          WHERE ((td.item_id)::text = (rc.id)::text)) = 0) AS alerta_sin_ventas
   FROM receta_cab rc
  WHERE (rc.activo = true);



DROP VIEW IF EXISTS v_items_con_uom CASCADE;
CREATE OR REPLACE VIEW v_items_con_uom AS
 SELECT i.id,
    i.nombre,
    i.descripcion,
    i.categoria_id,
    i.unidad_medida,
    i.perishable,
    i.temperatura_min,
    i.temperatura_max,
    i.costo_promedio,
    i.activo,
    i.created_at,
    i.updated_at,
    i.unidad_medida_id,
    i.factor_conversion,
    i.unidad_compra_id,
    i.factor_compra,
    i.tipo,
    i.unidad_salida_id,
    um.codigo AS uom_codigo,
    um.nombre AS uom_nombre,
    um.tipo AS uom_tipo
   FROM (items i
     LEFT JOIN unidades_medida um ON ((um.id = i.unidad_medida_id)));



DROP VIEW IF EXISTS v_merma_por_item CASCADE;
CREATE OR REPLACE VIEW v_merma_por_item AS
 SELECT m.item_id,
    (date_trunc('week'::text, m.ts))::date AS semana,
    sum(
        CASE
            WHEN ((m.tipo)::text = 'MERMA'::text) THEN m.cantidad
            ELSE (0)::numeric
        END) AS qty_mermada,
    sum(
        CASE
            WHEN ((m.tipo)::text = 'ENTRADA'::text) THEN m.cantidad
            ELSE (0)::numeric
        END) AS qty_recibida,
    round(((100.0 * NULLIF(sum(
        CASE
            WHEN ((m.tipo)::text = 'MERMA'::text) THEN m.cantidad
            ELSE (0)::numeric
        END), (0)::numeric)) / NULLIF(sum(
        CASE
            WHEN ((m.tipo)::text = 'ENTRADA'::text) THEN m.cantidad
            ELSE (0)::numeric
        END), (0)::numeric)), 2) AS merma_pct
   FROM mov_inv m
  GROUP BY m.item_id, ((date_trunc('week'::text, m.ts))::date);



DROP VIEW IF EXISTS v_stock_actual CASCADE;
CREATE OR REPLACE VIEW v_stock_actual AS
 SELECT i.id AS item_id,
    i.nombre,
    COALESCE(sum(
        CASE
            WHEN ((m.tipo)::text = 'ENTRADA'::text) THEN m.cantidad
            WHEN ((m.tipo)::text = 'SALIDA'::text) THEN (- m.cantidad)
            ELSE (0)::numeric
        END), (0)::numeric) AS stock_actual
   FROM (items i
     LEFT JOIN mov_inv m ON (((i.id)::text = (m.item_id)::text)))
  GROUP BY i.id, i.nombre;



DROP VIEW IF EXISTS v_stock_brechas CASCADE;
CREATE OR REPLACE VIEW v_stock_brechas AS
 SELECT sp.sucursal_id,
    sp.almacen_id,
    sp.item_id,
    sp.min_qty,
    sp.max_qty,
    COALESCE(sa.stock_actual, (0)::numeric) AS stock_actual,
    GREATEST((sp.min_qty - COALESCE(sa.stock_actual, (0)::numeric)), (0)::numeric) AS qty_a_comprar
   FROM (stock_policy sp
     LEFT JOIN ( SELECT mov_inv.item_id,
            sum(
                CASE
                    WHEN ((mov_inv.tipo)::text = 'ENTRADA'::text) THEN mov_inv.cantidad
                    WHEN ((mov_inv.tipo)::text = ANY ((ARRAY['SALIDA'::character varying, 'MERMA'::character varying, 'AJUSTE'::character varying, 'TRASPASO'::character varying])::text[])) THEN (- mov_inv.cantidad)
                    ELSE (0)::numeric
                END) AS stock_actual
           FROM mov_inv
          GROUP BY mov_inv.item_id) sa ON (((sa.item_id)::text = sp.item_id)));



DROP VIEW IF EXISTS vw_anulaciones_por_terminal_dia CASCADE;
CREATE OR REPLACE VIEW vw_anulaciones_por_terminal_dia AS
 SELECT tk.terminal_id,
    date(tx.transaction_time) AS fecha,
    (sum(
        CASE
            WHEN ((tx.payment_type)::text = ANY ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[])) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS anulaciones_total
   FROM (public.transactions tx
     JOIN public.ticket tk ON ((tk.id = tx.ticket_id)))
  GROUP BY tk.terminal_id, (date(tx.transaction_time));



DROP VIEW IF EXISTS vw_bom_menu_item CASCADE;
CREATE OR REPLACE VIEW vw_bom_menu_item AS
 SELECT pm.pos_system,
    pm.plu,
    pm.tipo,
    ((row_to_json(pm.*) ->> 'receta_version_id'::text))::bigint AS receta_version_id,
    rins.insumo_id,
    (rins.cantidad * COALESCE(((row_to_json(pm.*) ->> 'factor_insumo'::text))::numeric, (1)::numeric)) AS cantidad_por_menu
   FROM ((pos_map pm
     LEFT JOIN receta_version rv ON ((rv.id = ((row_to_json(pm.*) ->> 'receta_version_id'::text))::bigint)))
     LEFT JOIN receta_insumo rins ON ((rins.receta_version_id = rv.id)))
  WHERE (pm.tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text]));



DROP VIEW IF EXISTS vw_sesion_anulaciones CASCADE;
CREATE OR REPLACE VIEW vw_sesion_anulaciones AS
 SELECT s.id AS sesion_id,
    (COALESCE(sum(
        CASE
            WHEN ((tk.status)::text = ANY ((ARRAY['VOID'::character varying, 'REFUND'::character varying])::text[])) THEN tk.total_price
            ELSE (0)::double precision
        END), (0)::double precision))::numeric AS total_anulado
   FROM (sesion_cajon s
     LEFT JOIN public.ticket tk ON (((tk.closing_date >= s.apertura_ts) AND (tk.closing_date < COALESCE(s.cierre_ts, now())) AND (tk.terminal_id = s.terminal_id) AND (tk.owner_id = s.cajero_usuario_id))))
  GROUP BY s.id;



DROP VIEW IF EXISTS vw_sesion_descuentos CASCADE;
CREATE OR REPLACE VIEW vw_sesion_descuentos AS
 SELECT s.id AS sesion_id,
    (0)::numeric AS descuentos
   FROM sesion_cajon s;



DROP VIEW IF EXISTS vw_sesion_reembolsos_efectivo CASCADE;
CREATE OR REPLACE VIEW vw_sesion_reembolsos_efectivo AS
 SELECT s.id AS sesion_id,
    (COALESCE(sum(
        CASE
            WHEN ((((t.transaction_type)::text = ANY ((ARRAY['REFUND'::character varying, 'RETURN'::character varying])::text[])) OR (COALESCE(t.voided, false) = true)) AND (((t.payment_type)::text = 'CASH'::text) OR ((t.transaction_type)::text = 'CASH'::text))) THEN (t.amount)::numeric
            ELSE (0)::numeric
        END), (0)::numeric))::numeric(12,2) AS reembolsos_efectivo
   FROM (sesion_cajon s
     JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
  GROUP BY s.id;



DROP VIEW IF EXISTS vw_sesion_retiros CASCADE;
CREATE OR REPLACE VIEW vw_sesion_retiros AS
 SELECT s.id AS sesion_id,
    (COALESCE(sum(
        CASE
            WHEN ((t.transaction_type)::text = ANY ((ARRAY['PAYOUT'::character varying, 'EXPENSE'::character varying])::text[])) THEN (t.amount)::numeric
            ELSE (0)::numeric
        END), (0)::numeric))::numeric(12,2) AS retiros
   FROM (sesion_cajon s
     JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
  GROUP BY s.id;



DROP VIEW IF EXISTS vw_sesion_ventas CASCADE;
CREATE OR REPLACE VIEW vw_sesion_ventas AS
 WITH base AS (
         SELECT s.id AS sesion_id,
            (t.amount)::numeric(12,2) AS monto,
            COALESCE(fp.codigo, fn_normalizar_forma_pago((t.payment_type)::text, (t.transaction_type)::text, (t.payment_sub_type)::text, (t.custom_payment_name)::text)) AS codigo_fp
           FROM ((sesion_cajon s
             JOIN public.transactions t ON (((t.transaction_time >= s.apertura_ts) AND (t.transaction_time < COALESCE(s.cierre_ts, now())) AND (t.terminal_id = s.terminal_id) AND (t.user_id = s.cajero_usuario_id))))
             LEFT JOIN formas_pago fp ON (((fp.payment_type = (t.payment_type)::text) AND (COALESCE(fp.transaction_type, ''::text) = (COALESCE(t.transaction_type, ''::character varying))::text) AND (COALESCE(fp.payment_sub_type, ''::text) = (COALESCE(t.payment_sub_type, ''::character varying))::text) AND (COALESCE(fp.custom_name, ''::text) = (COALESCE(t.custom_payment_name, ''::character varying))::text) AND (COALESCE(fp.custom_ref, ''::text) = (COALESCE(t.custom_payment_ref, ''::character varying))::text))))
        )
 SELECT base.sesion_id,
    base.codigo_fp,
    (sum(base.monto))::numeric(12,2) AS monto
   FROM base
  GROUP BY base.sesion_id, base.codigo_fp;



DROP VIEW IF EXISTS vw_conciliacion_sesion CASCADE;
CREATE OR REPLACE VIEW vw_conciliacion_sesion AS
 WITH ventas AS (
         SELECT vw_sesion_ventas.sesion_id,
            sum(
                CASE
                    WHEN (vw_sesion_ventas.codigo_fp = 'CASH'::text) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END) AS ventas_efectivo,
            sum(
                CASE
                    WHEN ((vw_sesion_ventas.codigo_fp = ANY (ARRAY['CREDIT'::text, 'DEBIT'::text, 'TRANSFER'::text])) OR (vw_sesion_ventas.codigo_fp ~~ 'CUSTOM:%'::text)) THEN vw_sesion_ventas.monto
                    ELSE (0)::numeric
                END) AS ventas_no_efectivo
           FROM vw_sesion_ventas
          GROUP BY vw_sesion_ventas.sesion_id
        ), decl AS (
         SELECT s_1.id AS sesion_id,
            COALESCE(max(p.declarado_efectivo), (0)::numeric) AS precorte_efectivo,
            COALESCE(max(pc.declarado_efectivo), (0)::numeric) AS post_efectivo,
            COALESCE(max(pc.declarado_tarjetas), (0)::numeric) AS post_tarjetas
           FROM ((sesion_cajon s_1
             LEFT JOIN precorte p ON ((p.sesion_id = s_1.id)))
             LEFT JOIN postcorte pc ON ((pc.sesion_id = s_1.id)))
          GROUP BY s_1.id
        )
 SELECT s.id AS sesion_id,
    s.terminal_id,
    s.cajero_usuario_id,
    s.apertura_ts,
    s.cierre_ts,
    s.estatus,
    s.opening_float,
    COALESCE(v.ventas_efectivo, (0)::numeric) AS sistema_efectivo,
    COALESCE(v.ventas_no_efectivo, (0)::numeric) AS sistema_no_efectivo,
    COALESCE(dsc.descuentos, (0)::numeric) AS sistema_descuentos,
    COALESCE(an.total_anulado, (0)::numeric) AS sistema_anulaciones,
    COALESCE(re.retiros, (0)::numeric) AS sistema_retiros,
    COALESCE(rc.reembolsos_efectivo, (0)::numeric) AS sistema_reembolsos_efectivo,
    (((s.opening_float + COALESCE(v.ventas_efectivo, (0)::numeric)) - COALESCE(re.retiros, (0)::numeric)) - COALESCE(rc.reembolsos_efectivo, (0)::numeric)) AS sistema_efectivo_esperado,
    COALESCE(dl.precorte_efectivo, (0)::numeric) AS declarado_precorte_efectivo,
    COALESCE(dl.post_efectivo, (0)::numeric) AS declarado_post_efectivo,
    COALESCE(dl.post_tarjetas, (0)::numeric) AS declarado_post_tarjetas,
    (COALESCE(dl.post_efectivo, (0)::numeric) - (((s.opening_float + COALESCE(v.ventas_efectivo, (0)::numeric)) - COALESCE(re.retiros, (0)::numeric)) - COALESCE(rc.reembolsos_efectivo, (0)::numeric))) AS diferencia_efectivo,
    (COALESCE(dl.post_tarjetas, (0)::numeric) - COALESCE(v.ventas_no_efectivo, (0)::numeric)) AS diferencia_no_efectivo,
    s.closing_float AS cierre_pos_snapshot,
    COALESCE(s.closing_float, (((s.opening_float + COALESCE(v.ventas_efectivo, (0)::numeric)) - COALESCE(re.retiros, (0)::numeric)) - COALESCE(rc.reembolsos_efectivo, (0)::numeric))) AS cierre_pos_efectivo_final
   FROM ((((((sesion_cajon s
     LEFT JOIN ventas v ON ((v.sesion_id = s.id)))
     LEFT JOIN vw_sesion_descuentos dsc ON ((dsc.sesion_id = s.id)))
     LEFT JOIN vw_sesion_anulaciones an ON ((an.sesion_id = s.id)))
     LEFT JOIN vw_sesion_retiros re ON ((re.sesion_id = s.id)))
     LEFT JOIN vw_sesion_reembolsos_efectivo rc ON ((rc.sesion_id = s.id)))
     LEFT JOIN decl dl ON ((dl.sesion_id = s.id)));



DROP VIEW IF EXISTS vw_ventas_por_item CASCADE;
CREATE OR REPLACE VIEW vw_ventas_por_item AS
 SELECT (date_trunc('day'::text, t.closing_date))::date AS fecha,
    t.terminal_id,
    COALESCE((row_to_json(t.*) ->> 'branch_key'::text), (row_to_json(t.*) ->> 'location'::text), ''::text) AS sucursal_id,
    (row_to_json(ti.*) ->> 'plu'::text) AS plu,
    sum(COALESCE(((row_to_json(ti.*) ->> 'qty'::text))::numeric, ((row_to_json(ti.*) ->> 'quantity'::text))::numeric, (0)::numeric)) AS unidades,
    sum((COALESCE(((row_to_json(ti.*) ->> 'precio'::text))::numeric, ((row_to_json(ti.*) ->> 'price'::text))::numeric, (0)::numeric) * COALESCE(((row_to_json(ti.*) ->> 'qty'::text))::numeric, ((row_to_json(ti.*) ->> 'quantity'::text))::numeric, (0)::numeric))) AS venta_total
   FROM (public.ticket_item ti
     JOIN public.ticket t ON (((t.id = ((row_to_json(ti.*) ->> 'ticket_id'::text))::bigint) OR (t.id = ti.ticket_id))))
  GROUP BY ((date_trunc('day'::text, t.closing_date))::date), t.terminal_id, COALESCE((row_to_json(t.*) ->> 'branch_key'::text), (row_to_json(t.*) ->> 'location'::text), ''::text), (row_to_json(ti.*) ->> 'plu'::text);



DROP VIEW IF EXISTS vw_consumo_teorico CASCADE;
CREATE OR REPLACE VIEW vw_consumo_teorico AS
 SELECT v.fecha,
    v.sucursal_id,
    bmi.insumo_id,
    sum((v.unidades * COALESCE(bmi.cantidad_por_menu, (0)::numeric))) AS consumo_teorico
   FROM (vw_ventas_por_item v
     JOIN vw_bom_menu_item bmi ON ((bmi.plu = v.plu)))
  GROUP BY v.fecha, v.sucursal_id, bmi.insumo_id;



DROP VIEW IF EXISTS vw_kardex CASCADE;
CREATE OR REPLACE VIEW vw_kardex AS
 SELECT mi.id,
    mi.ts,
    COALESCE((row_to_json(mi.*) ->> 'item_id'::text), (row_to_json(mi.*) ->> 'insumo_id'::text)) AS item_key,
    mi.lote_id,
    mi.tipo,
    COALESCE(((row_to_json(mi.*) ->> 'qty'::text))::numeric, ((row_to_json(mi.*) ->> 'cantidad'::text))::numeric) AS qty,
    mi.costo_unit,
    mi.ref_tipo,
    mi.ref_id,
    mi.sucursal_id,
    mi.usuario_id
   FROM mov_inv mi
  ORDER BY mi.ts DESC, mi.id DESC;



DROP VIEW IF EXISTS vw_consumo_vs_movimientos CASCADE;
CREATE OR REPLACE VIEW vw_consumo_vs_movimientos AS
 WITH "real" AS (
         SELECT (date_trunc('day'::text, k.ts))::date AS fecha,
            (k.sucursal_id)::text AS sucursal_id,
            (NULLIF(k.item_key, ''::text))::bigint AS insumo_id,
            sum(
                CASE
                    WHEN ((k.tipo)::text = ANY ((ARRAY['SALIDA'::character varying, 'MERMA'::character varying, 'AJUSTE'::character varying])::text[])) THEN k.qty
                    ELSE (0)::numeric
                END) AS consumo_real
           FROM vw_kardex k
          GROUP BY ((date_trunc('day'::text, k.ts))::date), (k.sucursal_id)::text, (NULLIF(k.item_key, ''::text))::bigint
        )
 SELECT COALESCE(t.fecha, r.fecha) AS fecha,
    COALESCE(t.sucursal_id, r.sucursal_id) AS sucursal_id,
    COALESCE(t.insumo_id, r.insumo_id) AS insumo_id,
    COALESCE(t.consumo_teorico, (0)::numeric) AS consumo_teorico,
    COALESCE(r.consumo_real, (0)::numeric) AS consumo_real,
    (COALESCE(r.consumo_real, (0)::numeric) - COALESCE(t.consumo_teorico, (0)::numeric)) AS diferencia
   FROM (vw_consumo_teorico t
     FULL JOIN "real" r ON (((r.fecha = t.fecha) AND (r.sucursal_id = t.sucursal_id) AND (r.insumo_id = t.insumo_id))));



DROP VIEW IF EXISTS vw_costos_insumo_actual CASCADE;
CREATE OR REPLACE VIEW vw_costos_insumo_actual AS
 SELECT DISTINCT ON (h.insumo_id) h.insumo_id,
    h.fecha_efectiva,
    h.costo_wac,
    h.algoritmo_principal
   FROM hist_cost_insumo h
  ORDER BY h.insumo_id, h.fecha_efectiva DESC;



DROP VIEW IF EXISTS vw_descuentos_por_terminal_dia CASCADE;
CREATE OR REPLACE VIEW vw_descuentos_por_terminal_dia AS
 SELECT tk.terminal_id,
    date(tk.closing_date) AS fecha,
    (sum(COALESCE(td.value, (0)::double precision)))::numeric(12,2) AS descuentos_ticket,
    (sum(COALESCE(tid.amount, (0)::double precision)))::numeric(12,2) AS descuentos_items,
    (sum(
        CASE
            WHEN (COALESCE(tk.total_price, (0)::double precision) <= COALESCE(tk.total_discount, (0)::double precision)) THEN LEAST(tk.total_discount, tk.total_price)
            ELSE (0)::double precision
        END))::numeric(12,2) AS descuentos_100,
    (GREATEST(((sum(COALESCE(td.value, (0)::double precision)) + sum(COALESCE(tid.amount, (0)::double precision))) - sum(
        CASE
            WHEN (COALESCE(tk.total_price, (0)::double precision) <= COALESCE(tk.total_discount, (0)::double precision)) THEN LEAST(tk.total_discount, tk.total_price)
            ELSE (0)::double precision
        END)), (0)::double precision))::numeric(12,2) AS descuentos_parciales,
    ((sum(COALESCE(td.value, (0)::double precision)) + sum(COALESCE(tid.amount, (0)::double precision))))::numeric(12,2) AS total_descuentos
   FROM (((public.ticket tk
     LEFT JOIN public.ticket_discount td ON ((td.ticket_id = tk.id)))
     LEFT JOIN public.ticket_item ti ON ((ti.ticket_id = tk.id)))
     LEFT JOIN public.ticket_item_discount tid ON ((tid.ticket_itemid = ti.id)))
  WHERE ((tk.paid = true) AND (tk.voided = false))
  GROUP BY tk.terminal_id, (date(tk.closing_date));



DROP VIEW IF EXISTS vw_fast_tickets CASCADE;
CREATE OR REPLACE VIEW vw_fast_tickets AS
 SELECT tk.id,
    tk.terminal_id,
    tk.owner_id,
    tk.create_date,
    tk.closing_date,
    tk.status,
    tk.total_discount,
    tk.total_price
   FROM public.ticket tk;



DROP VIEW IF EXISTS vw_fast_tx CASCADE;
CREATE OR REPLACE VIEW vw_fast_tx AS
 SELECT t.terminal_id,
    t.user_id,
    t.transaction_time,
    t.payment_type,
    t.transaction_type,
    t.payment_sub_type,
    t.custom_payment_name,
    t.custom_payment_ref,
    t.amount,
    t.voided
   FROM public.transactions t;



DROP VIEW IF EXISTS vw_terminal_sucursal_dia CASCADE;
CREATE OR REPLACE VIEW vw_terminal_sucursal_dia AS
 SELECT vw_ventas_por_item.fecha,
    vw_ventas_por_item.terminal_id,
    vw_ventas_por_item.sucursal_id
   FROM vw_ventas_por_item
  GROUP BY vw_ventas_por_item.fecha, vw_ventas_por_item.terminal_id, vw_ventas_por_item.sucursal_id;



DROP VIEW IF EXISTS vw_kpis_sucursal_dia CASCADE;
CREATE OR REPLACE VIEW vw_kpis_sucursal_dia AS
 WITH k AS (
         SELECT (date_trunc('day'::text, c.apertura_ts))::date AS fecha,
            c.terminal_id,
            count(*) AS sesiones,
            sum(c.sistema_efectivo) AS sistema_efectivo,
            sum(c.sistema_no_efectivo) AS sistema_no_efectivo,
            sum(c.sistema_descuentos) AS descuentos,
            sum(c.sistema_anulaciones) AS anulaciones,
            sum(c.sistema_retiros) AS retiros,
            sum(c.sistema_reembolsos_efectivo) AS reembolsos_efectivo,
            sum(c.sistema_efectivo_esperado) AS efectivo_esperado,
            sum(c.declarado_precorte_efectivo) AS declarado_precorte,
            sum(c.declarado_post_efectivo) AS declarado_post_efectivo,
            sum(c.declarado_post_tarjetas) AS declarado_post_tarjetas,
            sum(c.diferencia_efectivo) AS diferencia_efectivo,
            sum(c.diferencia_no_efectivo) AS diferencia_no_efectivo
           FROM vw_conciliacion_sesion c
          GROUP BY ((date_trunc('day'::text, c.apertura_ts))::date), c.terminal_id
        )
 SELECT k.fecha,
    COALESCE(m.sucursal_id, ''::text) AS sucursal_id,
    sum(k.sesiones) AS sesiones,
    sum(k.sistema_efectivo) AS sistema_efectivo,
    sum(k.sistema_no_efectivo) AS sistema_no_efectivo,
    sum(k.descuentos) AS descuentos,
    sum(k.anulaciones) AS anulaciones,
    sum(k.retiros) AS retiros,
    sum(k.reembolsos_efectivo) AS reembolsos_efectivo,
    sum(k.efectivo_esperado) AS efectivo_esperado,
    sum(k.declarado_precorte) AS declarado_precorte,
    sum(k.declarado_post_efectivo) AS declarado_post_efectivo,
    sum(k.declarado_post_tarjetas) AS declarado_post_tarjetas,
    sum(k.diferencia_efectivo) AS diferencia_efectivo,
    sum(k.diferencia_no_efectivo) AS diferencia_no_efectivo
   FROM (k
     LEFT JOIN vw_terminal_sucursal_dia m ON (((m.fecha = k.fecha) AND (m.terminal_id = k.terminal_id))))
  GROUP BY k.fecha, COALESCE(m.sucursal_id, ''::text);



DROP VIEW IF EXISTS vw_kpis_terminal_dia CASCADE;
CREATE OR REPLACE VIEW vw_kpis_terminal_dia AS
 SELECT (date_trunc('day'::text, c.apertura_ts))::date AS fecha,
    c.terminal_id,
    count(*) AS sesiones,
    sum(c.sistema_efectivo) AS sistema_efectivo,
    sum(c.sistema_no_efectivo) AS sistema_no_efectivo,
    sum(c.sistema_descuentos) AS descuentos,
    sum(c.sistema_anulaciones) AS anulaciones,
    sum(c.sistema_retiros) AS retiros,
    sum(c.sistema_reembolsos_efectivo) AS reembolsos_efectivo,
    sum(c.sistema_efectivo_esperado) AS efectivo_esperado,
    sum(c.declarado_precorte_efectivo) AS declarado_precorte,
    sum(c.declarado_post_efectivo) AS declarado_post_efectivo,
    sum(c.declarado_post_tarjetas) AS declarado_post_tarjetas,
    sum(c.diferencia_efectivo) AS diferencia_efectivo,
    sum(c.diferencia_no_efectivo) AS diferencia_no_efectivo
   FROM vw_conciliacion_sesion c
  GROUP BY ((date_trunc('day'::text, c.apertura_ts))::date), c.terminal_id;



DROP VIEW IF EXISTS vw_movimientos_anomalos CASCADE;
CREATE OR REPLACE VIEW vw_movimientos_anomalos AS
 SELECT k.id,
    k.ts,
    k.item_key,
    k.lote_id,
    k.tipo,
    k.qty,
    k.costo_unit,
    k.ref_tipo,
    k.ref_id,
    k.sucursal_id,
    k.usuario_id,
        CASE
            WHEN (k.qty IS NULL) THEN 'QTY_NULL'::text
            WHEN (k.qty = (0)::numeric) THEN 'QTY_CERO'::text
            WHEN (abs(k.qty) > (1000000)::numeric) THEN 'QTY_EXCESIVA'::text
            WHEN (k.costo_unit < (0)::numeric) THEN 'COSTO_NEGATIVO'::text
            WHEN (k.ts > (now() + '1 day'::interval)) THEN 'FUTURO'::text
            WHEN ((k.item_key IS NULL) OR (k.item_key = ''::text)) THEN 'ITEM_VACIO'::text
            WHEN ((k.tipo)::text <> ALL ((ARRAY['ENTRADA'::character varying, 'RECEPCION'::character varying, 'COMPRA'::character varying, 'TRASPASO_IN'::character varying, 'SALIDA'::character varying, 'MERMA'::character varying, 'AJUSTE'::character varying, 'TRASPASO_OUT'::character varying])::text[])) THEN 'TIPO_DESCONOCIDO'::text
            ELSE NULL::text
        END AS regla
   FROM vw_kardex k
  WHERE ((k.qty IS NULL) OR (k.qty = (0)::numeric) OR (abs(k.qty) > (1000000)::numeric) OR (k.costo_unit < (0)::numeric) OR (k.ts > (now() + '1 day'::interval)) OR (k.item_key IS NULL) OR (k.item_key = ''::text) OR ((k.tipo)::text <> ALL ((ARRAY['ENTRADA'::character varying, 'RECEPCION'::character varying, 'COMPRA'::character varying, 'TRASPASO_IN'::character varying, 'SALIDA'::character varying, 'MERMA'::character varying, 'AJUSTE'::character varying, 'TRASPASO_OUT'::character varying])::text[])));



DROP VIEW IF EXISTS vw_pagos_por_terminal_dia CASCADE;
CREATE OR REPLACE VIEW vw_pagos_por_terminal_dia AS
 SELECT tk.terminal_id,
    date(tx.transaction_time) AS fecha,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CASH'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS efectivo,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CREDIT_CARD'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS credito,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'DEBIT_CARD'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS debito,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CUSTOM_PAYMENT'::text) AND (upper((COALESCE(tx.custom_payment_name, ''::character varying))::text) = 'TRANSFER'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS transfer,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CUSTOM_PAYMENT'::text) AND (upper((COALESCE(tx.custom_payment_name, ''::character varying))::text) = 'GIFT_CERT'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS gift,
    (sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CUSTOM_PAYMENT'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false) AND (upper((COALESCE(tx.custom_payment_name, ''::character varying))::text) <> ALL (ARRAY['TRANSFER'::text, 'GIFT_CERT'::text]))) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS custom,
    ((sum(
        CASE
            WHEN (((tx.payment_type)::text = ANY ((ARRAY['CREDIT_CARD'::character varying, 'DEBIT_CARD'::character varying])::text[])) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END) + sum(
        CASE
            WHEN (((tx.payment_type)::text = 'CUSTOM_PAYMENT'::text) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND (tx.voided = false)) THEN tx.amount
            ELSE (0)::double precision
        END)))::numeric(12,2) AS total_tarjetas
   FROM (public.transactions tx
     JOIN public.ticket tk ON ((tk.id = tx.ticket_id)))
  GROUP BY tk.terminal_id, (date(tx.transaction_time));



DROP VIEW IF EXISTS vw_pos_map_resuelto CASCADE;
CREATE OR REPLACE VIEW vw_pos_map_resuelto AS
 SELECT pm.pos_system,
    pm.plu,
    pm.tipo,
    ((row_to_json(pm.*) ->> 'receta_version_id'::text))::bigint AS receta_version_id,
    ((row_to_json(pm.*) ->> 'insumo_id'::text))::bigint AS insumo_id,
    COALESCE(((row_to_json(pm.*) ->> 'factor_insumo'::text))::numeric, (1)::numeric) AS factor_insumo,
    ((row_to_json(pm.*) ->> 'vigente_desde'::text))::timestamp without time zone AS vigente_desde,
    ((row_to_json(pm.*) ->> 'vigente_hasta'::text))::timestamp without time zone AS vigente_hasta
   FROM pos_map pm
  WHERE (((row_to_json(pm.*) ->> 'vigente_hasta'::text) IS NULL) OR (((row_to_json(pm.*) ->> 'vigente_hasta'::text))::date >= ('now'::text)::date));



DROP VIEW IF EXISTS vw_receta_completa CASCADE;
CREATE OR REPLACE VIEW vw_receta_completa AS
 SELECT rv.id AS receta_version_id,
    rv.receta_id,
    rv.version,
    rins.insumo_id,
    rins.cantidad
   FROM (receta_version rv
     JOIN receta_insumo rins ON ((rins.receta_version_id = rv.id)));



DROP VIEW IF EXISTS vw_resumen_conciliacion_terminal_dia CASCADE;
CREATE OR REPLACE VIEW vw_resumen_conciliacion_terminal_dia AS
 WITH ventas AS (
         SELECT ticket.terminal_id,
            date(ticket.closing_date) AS fecha,
            (sum((ticket.total_price - ticket.total_discount)))::numeric(12,2) AS ventas_netas
           FROM public.ticket
          WHERE ((ticket.paid = true) AND (ticket.voided = false))
          GROUP BY ticket.terminal_id, (date(ticket.closing_date))
        ), pagos AS (
         SELECT vw_pagos_por_terminal_dia.terminal_id,
            vw_pagos_por_terminal_dia.fecha,
            (sum(vw_pagos_por_terminal_dia.efectivo))::numeric(12,2) AS efectivo,
            (sum(vw_pagos_por_terminal_dia.credito))::numeric(12,2) AS credito,
            (sum(vw_pagos_por_terminal_dia.debito))::numeric(12,2) AS debito,
            (sum(vw_pagos_por_terminal_dia.transfer))::numeric(12,2) AS transfer,
            (sum(vw_pagos_por_terminal_dia.custom))::numeric(12,2) AS custom,
            (sum(vw_pagos_por_terminal_dia.gift))::numeric(12,2) AS gift,
            (sum(vw_pagos_por_terminal_dia.total_tarjetas))::numeric(12,2) AS total_tarjetas
           FROM vw_pagos_por_terminal_dia
          GROUP BY vw_pagos_por_terminal_dia.terminal_id, vw_pagos_por_terminal_dia.fecha
        ), descuentos AS (
         SELECT vw_descuentos_por_terminal_dia.terminal_id,
            vw_descuentos_por_terminal_dia.fecha,
            vw_descuentos_por_terminal_dia.descuentos_ticket,
            vw_descuentos_por_terminal_dia.descuentos_items,
            vw_descuentos_por_terminal_dia.descuentos_100,
            vw_descuentos_por_terminal_dia.descuentos_parciales,
            vw_descuentos_por_terminal_dia.total_descuentos
           FROM vw_descuentos_por_terminal_dia
        ), anu AS (
         SELECT vw_anulaciones_por_terminal_dia.terminal_id,
            vw_anulaciones_por_terminal_dia.fecha,
            vw_anulaciones_por_terminal_dia.anulaciones_total
           FROM vw_anulaciones_por_terminal_dia
        )
 SELECT v.terminal_id,
    v.fecha,
    v.ventas_netas,
    p.efectivo,
    p.credito,
    p.debito,
    p.transfer,
    p.custom,
    p.gift,
    p.total_tarjetas,
    d.descuentos_ticket,
    d.descuentos_items,
    d.descuentos_100,
    d.descuentos_parciales,
    d.total_descuentos,
    a.anulaciones_total
   FROM (((ventas v
     LEFT JOIN pagos p USING (terminal_id, fecha))
     LEFT JOIN descuentos d USING (terminal_id, fecha))
     LEFT JOIN anu a USING (terminal_id, fecha));



DROP VIEW IF EXISTS vw_sesion_dpr CASCADE;
CREATE OR REPLACE VIEW vw_sesion_dpr AS
 WITH s AS (
         SELECT sesion_cajon.id,
            sesion_cajon.terminal_id,
            sesion_cajon.cajero_usuario_id,
            sesion_cajon.apertura_ts,
            COALESCE(sesion_cajon.cierre_ts, now()) AS fin_ts
           FROM sesion_cajon
        )
 SELECT s.id AS sesion_id,
    dpr.id,
    dpr.report_time,
    dpr.reg,
    dpr.ticket_count,
    dpr.begin_cash,
    dpr.net_sales,
    dpr.sales_tax,
    dpr.cash_tax,
    dpr.total_revenue,
    dpr.gross_receipts,
    dpr.giftcertreturncount,
    dpr.giftcertreturnamount,
    dpr.giftcertchangeamount,
    dpr.cash_receipt_no,
    dpr.cash_receipt_amount,
    dpr.credit_card_receipt_no,
    dpr.credit_card_receipt_amount,
    dpr.debit_card_receipt_no,
    dpr.debit_card_receipt_amount,
    dpr.refund_receipt_count,
    dpr.refund_amount,
    dpr.receipt_differential,
    dpr.cash_back,
    dpr.cash_tips,
    dpr.charged_tips,
    dpr.tips_paid,
    dpr.tips_differential,
    dpr.pay_out_no,
    dpr.pay_out_amount,
    dpr.drawer_bleed_no,
    dpr.drawer_bleed_amount,
    dpr.drawer_accountable,
    dpr.cash_to_deposit,
    dpr.variance,
    dpr.delivery_charge,
    dpr.totalvoidwst,
    dpr.totalvoid,
    dpr.totaldiscountcount,
    dpr.totaldiscountamount,
    dpr.totaldiscountsales,
    dpr.totaldiscountguest,
    dpr.totaldiscountpartysize,
    dpr.totaldiscountchecksize,
    dpr.totaldiscountpercentage,
    dpr.totaldiscountratio,
    dpr.user_id,
    dpr.terminal_id
   FROM (s
     JOIN public.drawer_pull_report dpr ON (((dpr.terminal_id = s.terminal_id) AND (dpr.report_time >= s.apertura_ts) AND (dpr.report_time < s.fin_ts))));



DROP VIEW IF EXISTS vw_stock_actual CASCADE;
CREATE OR REPLACE VIEW vw_stock_actual AS
 SELECT COALESCE((row_to_json(mi.*) ->> 'item_id'::text), (row_to_json(mi.*) ->> 'insumo_id'::text)) AS item_key,
    (mi.sucursal_id)::text AS sucursal_id,
    sum(
        CASE
            WHEN ((mi.tipo)::text = ANY ((ARRAY['ENTRADA'::character varying, 'RECEPCION'::character varying, 'COMPRA'::character varying, 'TRASPASO_IN'::character varying])::text[])) THEN COALESCE(((row_to_json(mi.*) ->> 'qty'::text))::numeric, ((row_to_json(mi.*) ->> 'cantidad'::text))::numeric)
            WHEN ((mi.tipo)::text = ANY ((ARRAY['SALIDA'::character varying, 'MERMA'::character varying, 'AJUSTE'::character varying, 'TRASPASO_OUT'::character varying])::text[])) THEN (- COALESCE(((row_to_json(mi.*) ->> 'qty'::text))::numeric, ((row_to_json(mi.*) ->> 'cantidad'::text))::numeric))
            ELSE (0)::numeric
        END) AS stock
   FROM mov_inv mi
  GROUP BY COALESCE((row_to_json(mi.*) ->> 'item_id'::text), (row_to_json(mi.*) ->> 'insumo_id'::text)), (mi.sucursal_id)::text;



DROP VIEW IF EXISTS vw_stock_brechas CASCADE;
CREATE OR REPLACE VIEW vw_stock_brechas AS
 SELECT sp.sucursal_id,
    sp.item_id,
    sp.min_qty,
    sp.max_qty,
    COALESCE(sa.stock, (0)::numeric) AS stock_actual,
    GREATEST((sp.min_qty - COALESCE(sa.stock, (0)::numeric)), (0)::numeric) AS faltante,
    GREATEST((COALESCE(sa.stock, (0)::numeric) - sp.max_qty), (0)::numeric) AS excedente
   FROM (stock_policy sp
     LEFT JOIN ( SELECT vw_stock_actual.item_key,
            vw_stock_actual.sucursal_id,
            sum(vw_stock_actual.stock) AS stock
           FROM vw_stock_actual
          GROUP BY vw_stock_actual.item_key, vw_stock_actual.sucursal_id) sa ON (((sa.item_key = sp.item_id) AND (sa.sucursal_id = sp.sucursal_id))));



DROP VIEW IF EXISTS vw_stock_por_lote_fefo CASCADE;
CREATE OR REPLACE VIEW vw_stock_por_lote_fefo AS
 SELECT (ib.item_id)::text AS item_key,
    ib.id AS lote_id,
    ib.ubicacion_id,
    ib.fecha_caducidad,
    ib.cantidad_actual AS stock_lote
   FROM inventory_batch ib
  WHERE ((ib.estado)::text = 'ACTIVO'::text)
  ORDER BY ib.item_id, ib.fecha_caducidad, ib.id;



DROP VIEW IF EXISTS vw_stock_valorizado CASCADE;
CREATE OR REPLACE VIEW vw_stock_valorizado AS
 SELECT sa.item_key,
    sa.sucursal_id,
    sa.stock,
    ca.costo_wac,
    (sa.stock * COALESCE(ca.costo_wac, (0)::numeric)) AS valor
   FROM (vw_stock_actual sa
     LEFT JOIN vw_costos_insumo_actual ca ON ((ca.insumo_id = (NULLIF(sa.item_key, ''::text))::bigint)));



DROP VIEW IF EXISTS vw_ticket_promedio_sucursal_dia CASCADE;
CREATE OR REPLACE VIEW vw_ticket_promedio_sucursal_dia AS
 WITH tbase AS (
         SELECT (date_trunc('day'::text, t.closing_date))::date AS fecha,
            COALESCE((row_to_json(t.*) ->> 'branch_key'::text), (row_to_json(t.*) ->> 'location'::text), ''::text) AS sucursal_id,
            COALESCE((t.id)::bigint, ((row_to_json(t.*) ->> 'id'::text))::bigint) AS ticket_id,
            COALESCE(((row_to_json(t.*) ->> 'total_price'::text))::numeric, ((row_to_json(t.*) ->> 'total'::text))::numeric, (0)::numeric) AS total_ticket
           FROM public.ticket t
        )
 SELECT tbase.fecha,
    tbase.sucursal_id,
    count(DISTINCT tbase.ticket_id) AS tickets,
    sum(tbase.total_ticket) AS venta_total,
        CASE
            WHEN (count(DISTINCT tbase.ticket_id) > 0) THEN (sum(tbase.total_ticket) / (count(DISTINCT tbase.ticket_id))::numeric)
            ELSE (0)::numeric
        END AS ticket_promedio
   FROM tbase
  GROUP BY tbase.fecha, tbase.sucursal_id;



DROP VIEW IF EXISTS vw_ventas_por_familia CASCADE;
CREATE OR REPLACE VIEW vw_ventas_por_familia AS
 SELECT v.fecha,
    v.sucursal_id,
    COALESCE(pm.tipo, 'DESCONOCIDO'::text) AS familia,
    sum(v.unidades) AS unidades,
    sum(v.venta_total) AS venta_total
   FROM (vw_ventas_por_item v
     LEFT JOIN pos_map pm ON ((pm.plu = v.plu)))
  GROUP BY v.fecha, v.sucursal_id, COALESCE(pm.tipo, 'DESCONOCIDO'::text);



DROP VIEW IF EXISTS vw_ventas_por_hora CASCADE;
CREATE OR REPLACE VIEW vw_ventas_por_hora AS
 SELECT date_trunc('hour'::text, t.closing_date) AS hora,
    COALESCE((row_to_json(t.*) ->> 'branch_key'::text), (row_to_json(t.*) ->> 'location'::text), ''::text) AS sucursal_id,
    t.terminal_id,
    count(*) AS tickets,
    sum(COALESCE(((row_to_json(t.*) ->> 'total_price'::text))::numeric, ((row_to_json(t.*) ->> 'total'::text))::numeric, (0)::numeric)) AS venta_total
   FROM public.ticket t
  GROUP BY (date_trunc('hour'::text, t.closing_date)), COALESCE((row_to_json(t.*) ->> 'branch_key'::text), (row_to_json(t.*) ->> 'location'::text), ''::text), t.terminal_id
  ORDER BY (date_trunc('hour'::text, t.closing_date)) DESC;



SET search_path = public, pg_catalog;

COMMIT;
