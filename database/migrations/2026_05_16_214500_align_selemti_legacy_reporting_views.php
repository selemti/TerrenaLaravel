<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
CREATE TABLE IF NOT EXISTS selemti.item_vendor (
    item_id text NOT NULL,
    vendor_id text NOT NULL,
    presentacion text NOT NULL,
    unidad_presentacion_id integer NOT NULL,
    factor_a_canonica numeric(14,6) NOT NULL,
    costo_ultimo numeric(14,6) DEFAULT 0 NOT NULL,
    moneda text DEFAULT 'MXN' NOT NULL,
    lead_time_dias integer,
    codigo_proveedor text,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    preferente boolean DEFAULT false,
    vendor_sku character varying(120),
    vendor_descripcion character varying(255),
    currency_code character varying(10),
    lead_time_days integer,
    min_order_qty numeric(14,6),
    pack_qty numeric(14,6),
    pack_uom character varying(20),
    CONSTRAINT item_vendor_pkey PRIMARY KEY (item_id, vendor_id, presentacion),
    CONSTRAINT item_vendor_factor_a_canonica_check CHECK (factor_a_canonica > 0)
);

CREATE INDEX IF NOT EXISTS ix_itemvendor_preferente
    ON selemti.item_vendor(preferente);

CREATE INDEX IF NOT EXISTS ix_itemvendor_vendor_sku
    ON selemti.item_vendor(vendor_id, vendor_sku);

CREATE UNIQUE INDEX IF NOT EXISTS ux_item_vendor_preferente_unique
    ON selemti.item_vendor(item_id)
    WHERE preferente = true;

CREATE TABLE IF NOT EXISTS selemti.stock_policy (
    id bigserial PRIMARY KEY,
    item_id text NOT NULL,
    sucursal_id text NOT NULL,
    almacen_id text,
    min_qty numeric(14,6) DEFAULT 0 NOT NULL,
    max_qty numeric(14,6),
    reorder_lote numeric(14,6),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_stock_policy_item
    ON selemti.stock_policy(item_id);

CREATE INDEX IF NOT EXISTS ix_stock_policy_active
    ON selemti.stock_policy(activo);

INSERT INTO selemti.stock_policy (
    item_id,
    sucursal_id,
    almacen_id,
    min_qty,
    max_qty,
    reorder_lote,
    activo,
    created_at,
    updated_at
)
SELECT
    p.item_id::text,
    p.sucursal_id::text,
    NULL::text,
    p.min_qty,
    p.max_qty,
    p.reorder_qty,
    p.activo,
    COALESCE(p.created_at, now()),
    COALESCE(p.updated_at, p.created_at, now())
FROM selemti.inv_stock_policy p
WHERE NOT EXISTS (
    SELECT 1
    FROM selemti.stock_policy sp
    WHERE sp.item_id = p.item_id::text
      AND sp.sucursal_id = p.sucursal_id::text
      AND sp.almacen_id IS NULL
);

CREATE OR REPLACE VIEW selemti.vw_dashboard_formas_pago AS
SELECT
    t.transaction_time::date AS fecha,
    COALESCE(NULLIF(term.location::text, ''), 'Sin sucursal') AS sucursal_id,
    COALESCE(NULLIF(t.payment_type::text, ''), 'OTRO') AS codigo_fp,
    SUM(COALESCE(t.amount, 0))::numeric(12,2) AS monto
FROM public.transactions t
LEFT JOIN public.terminal term ON term.id = t.terminal_id
WHERE t.transaction_time IS NOT NULL
GROUP BY
    t.transaction_time::date,
    COALESCE(NULLIF(term.location::text, ''), 'Sin sucursal'),
    COALESCE(NULLIF(t.payment_type::text, ''), 'OTRO');

CREATE OR REPLACE VIEW selemti.vw_dashboard_ticket_base AS
SELECT
    t.id AS ticket_id,
    date_trunc('day', t.closing_date)::date AS fecha,
    date_trunc('hour', t.closing_date) AS hora,
    COALESCE(
        NULLIF(term.location::text, ''),
        NULLIF(t.branch_key::text, ''),
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
        t.id::text
    ) AS ticket_ref
FROM public.ticket t
LEFT JOIN public.terminal term ON term.id = t.terminal_id
WHERE t.closing_date IS NOT NULL;

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
WHERE base.paid = true
  AND base.voided = false;

CREATE OR REPLACE VIEW selemti.vw_dashboard_resumen_sucursal AS
SELECT
    base.fecha,
    base.sucursal_id,
    COUNT(DISTINCT base.ticket_id) AS tickets,
    SUM(base.total) AS venta_total,
    SUM(base.sub_total) AS sub_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = true
  AND base.voided = false
GROUP BY base.fecha, base.sucursal_id;

CREATE OR REPLACE VIEW selemti.vw_dashboard_resumen_terminal AS
SELECT
    base.fecha,
    base.terminal_id,
    base.sucursal_id,
    COUNT(DISTINCT base.ticket_id) AS tickets,
    SUM(base.total) AS venta_total,
    SUM(base.sub_total) AS sub_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = true
  AND base.voided = false
GROUP BY base.fecha, base.terminal_id, base.sucursal_id;

CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_productos AS
SELECT
    base.fecha,
    base.sucursal_id,
    base.terminal_id,
    ti.item_id AS plu,
    COALESCE(NULLIF(ti.item_name::text, ''), mi.name::text, ti.item_id::text) AS descripcion,
    COALESCE(mg.name, 'SIN CATEGORIA') AS categoria,
    SUM(COALESCE(NULLIF(ti.item_quantity, 0), NULLIF(ti.item_count, 0)::double precision, 0)) AS unidades,
    SUM(COALESCE(ti.total_price, 0)) AS venta_total
FROM selemti.vw_dashboard_ticket_base base
JOIN public.ticket_item ti ON ti.ticket_id = base.ticket_id
LEFT JOIN public.menu_item mi ON mi.id = ti.item_id
LEFT JOIN public.menu_group mg ON mg.id = mi.group_id
WHERE base.paid = true
  AND base.voided = false
GROUP BY
    base.fecha,
    base.sucursal_id,
    base.terminal_id,
    ti.item_id,
    COALESCE(NULLIF(ti.item_name::text, ''), mi.name::text, ti.item_id::text),
    COALESCE(mg.name, 'SIN CATEGORIA');

CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_categorias AS
SELECT
    p.fecha,
    p.sucursal_id,
    p.categoria,
    SUM(p.unidades) AS unidades,
    SUM(p.venta_total) AS venta_total
FROM selemti.vw_dashboard_ventas_productos p
GROUP BY p.fecha, p.sucursal_id, p.categoria;

CREATE OR REPLACE VIEW selemti.vw_dashboard_ventas_hora AS
SELECT
    base.fecha,
    date_trunc('hour', base.hora) AS hora,
    base.sucursal_id,
    base.terminal_id,
    COUNT(DISTINCT base.ticket_id) AS tickets,
    SUM(base.total) AS venta_total
FROM selemti.vw_dashboard_ticket_base base
WHERE base.paid = true
  AND base.voided = false
GROUP BY base.fecha, date_trunc('hour', base.hora), base.sucursal_id, base.terminal_id;

CREATE OR REPLACE VIEW selemti.vw_sesion_dpr AS
WITH s AS (
    SELECT
        sc.id,
        sc.terminal_id,
        sc.cajero_usuario_id,
        sc.apertura_ts,
        COALESCE(sc.cierre_ts, now()) AS fin_ts
    FROM selemti.sesion_cajon sc
)
SELECT
    s.id AS sesion_id,
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
FROM s
JOIN public.drawer_pull_report dpr
  ON dpr.terminal_id = s.terminal_id
 AND dpr.report_time >= s.apertura_ts
 AND dpr.report_time < s.fin_ts;

CREATE OR REPLACE VIEW selemti.vw_stock_por_lote_fefo AS
SELECT
    ib.item_id::text AS item_key,
    ib.id AS lote_id,
    ib.almacen_id AS ubicacion_id,
    ib.caducidad AS fecha_caducidad,
    ib.cantidad_actual AS stock_lote
FROM selemti.inventory_batch ib
WHERE ib.estado::text = 'ACTIVO'
ORDER BY ib.item_id, ib.caducidad, ib.id;

CREATE OR REPLACE VIEW selemti.vw_stock_valorizado AS
WITH stock AS (
    SELECT
        m.item_id::text AS item_key,
        m.almacen_id::text AS almacen_id,
        MAX(m.sucursal_id)::text AS sucursal_id,
        SUM(COALESCE(m.cantidad, m.qty, 0)) AS stock
    FROM selemti.mov_inv m
    GROUP BY m.item_id::text, m.almacen_id::text
)
SELECT
    i.id::text AS item_key,
    i.id::text AS item_id,
    i.item_code,
    i.nombre AS item_nombre,
    COALESCE(stock.sucursal_id, a.sucursal_id::text, '0') AS sucursal_id,
    stock.almacen_id,
    a.clave AS almacen_clave,
    a.nombre AS almacen_nombre,
    COALESCE(stock.stock, 0) AS stock,
    COALESCE(stock.stock, 0) AS stock_total,
    COALESCE(i.costo_promedio, 0) AS costo_wac,
    COALESCE(stock.stock, 0) * COALESCE(i.costo_promedio, 0) AS valor,
    COALESCE(stock.stock, 0) * COALESCE(i.costo_promedio, 0) AS valor_total
FROM selemti.items i
LEFT JOIN stock ON stock.item_key = i.id::text
LEFT JOIN selemti.cat_almacenes a ON a.id::text = stock.almacen_id
WHERE COALESCE(i.activo, true) = true;

CREATE OR REPLACE VIEW selemti.vw_stock_brechas AS
WITH stock AS (
    SELECT
        m.item_id::text AS item_id,
        m.almacen_id::text AS almacen_id,
        SUM(COALESCE(m.cantidad, m.qty, 0)) AS stock_actual
    FROM selemti.mov_inv m
    GROUP BY m.item_id::text, m.almacen_id::text
)
SELECT
    p.id AS policy_id,
    p.item_id,
    p.sucursal_id,
    p.almacen_id,
    p.min_qty,
    p.max_qty,
    p.reorder_lote,
    COALESCE(SUM(stock.stock_actual), 0) AS stock_actual,
    p.min_qty - COALESCE(SUM(stock.stock_actual), 0) AS brecha_qty
FROM selemti.stock_policy p
LEFT JOIN stock
  ON stock.item_id = p.item_id
 AND (p.almacen_id IS NULL OR stock.almacen_id = p.almacen_id)
WHERE p.activo = true
GROUP BY
    p.id,
    p.item_id,
    p.sucursal_id,
    p.almacen_id,
    p.min_qty,
    p.max_qty,
    p.reorder_lote;

CREATE OR REPLACE VIEW selemti.vw_movimientos_anomalos AS
SELECT
    m.id,
    m.ts,
    m.item_id::text AS item_key,
    COALESCE(m.lote_id, m.inventory_batch_id) AS lote_id,
    m.tipo,
    COALESCE(m.cantidad, m.qty) AS qty,
    m.costo_unit,
    m.ref_tipo,
    m.ref_id,
    m.sucursal_id,
    COALESCE(m.usuario_id, m.user_id) AS usuario_id,
    CASE
        WHEN COALESCE(m.cantidad, m.qty) IS NULL THEN 'QTY_NULL'
        WHEN COALESCE(m.cantidad, m.qty) = 0 THEN 'QTY_CERO'
        WHEN abs(COALESCE(m.cantidad, m.qty)) > 1000000 THEN 'QTY_EXCESIVA'
        WHEN m.costo_unit < 0 THEN 'COSTO_NEGATIVO'
        WHEN m.ts > now() + interval '1 day' THEN 'FUTURO'
        WHEN m.item_id IS NULL OR m.item_id::text = '' THEN 'ITEM_VACIO'
        WHEN m.tipo IS NULL OR m.tipo::text NOT IN (
            'ENTRADA', 'RECEPCION', 'COMPRA', 'TRASPASO_IN',
            'SALIDA', 'MERMA', 'AJUSTE', 'TRASPASO_OUT',
            'PRODUCCION_CONSUMO', 'PRODUCCION_ENTRADA', 'CONSUMO_POS',
            'TRANSFERENCIA_SALIDA', 'TRANSFERENCIA_ENTRADA', 'DEVOLUCION_PROVEEDOR'
        ) THEN 'TIPO_DESCONOCIDO'
        ELSE NULL
    END AS regla
FROM selemti.mov_inv m
WHERE COALESCE(m.cantidad, m.qty) IS NULL
   OR COALESCE(m.cantidad, m.qty) = 0
   OR abs(COALESCE(m.cantidad, m.qty)) > 1000000
   OR m.costo_unit < 0
   OR m.ts > now() + interval '1 day'
   OR m.item_id IS NULL
   OR m.item_id::text = ''
   OR m.tipo IS NULL
   OR m.tipo::text NOT IN (
        'ENTRADA', 'RECEPCION', 'COMPRA', 'TRASPASO_IN',
        'SALIDA', 'MERMA', 'AJUSTE', 'TRASPASO_OUT',
        'PRODUCCION_CONSUMO', 'PRODUCCION_ENTRADA', 'CONSUMO_POS',
        'TRANSFERENCIA_SALIDA', 'TRANSFERENCIA_ENTRADA', 'DEVOLUCION_PROVEEDOR'
   );
SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
DROP VIEW IF EXISTS selemti.vw_movimientos_anomalos;
DROP VIEW IF EXISTS selemti.vw_stock_brechas;
DROP VIEW IF EXISTS selemti.vw_stock_valorizado;
DROP VIEW IF EXISTS selemti.vw_stock_por_lote_fefo;
DROP VIEW IF EXISTS selemti.vw_sesion_dpr;
DROP VIEW IF EXISTS selemti.vw_dashboard_ventas_hora;
DROP VIEW IF EXISTS selemti.vw_dashboard_ventas_categorias;
DROP VIEW IF EXISTS selemti.vw_dashboard_ventas_productos;
DROP VIEW IF EXISTS selemti.vw_dashboard_resumen_terminal;
DROP VIEW IF EXISTS selemti.vw_dashboard_resumen_sucursal;
DROP VIEW IF EXISTS selemti.vw_dashboard_ordenes;
DROP VIEW IF EXISTS selemti.vw_dashboard_ticket_base;
DROP VIEW IF EXISTS selemti.vw_dashboard_formas_pago;
DROP TABLE IF EXISTS selemti.stock_policy;
DROP TABLE IF EXISTS selemti.item_vendor;
SQL);
    }
};
