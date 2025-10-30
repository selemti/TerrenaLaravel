SET search_path TO selemti, public;
DROP VIEW IF EXISTS selemti.vw_conciliacion_sesion CASCADE;
DROP VIEW IF EXISTS selemti.vw_sesion_ventas CASCADE;
CREATE OR REPLACE VIEW selemti.vw_sesion_ventas AS
WITH base AS (
  SELECT
    s.id AS sesion_id,
    (t.amount::numeric(12,2)) AS monto,
    COALESCE(
      fp.codigo,
      selemti.fn_normalizar_forma_pago(t.payment_type, t.transaction_type, t.payment_sub_type, t.custom_payment_name)
    ) AS codigo_fp
  FROM selemti.sesion_cajon s
  JOIN public.transactions t
    ON t.transaction_time >= s.apertura_ts
   AND t.transaction_time <  COALESCE(s.cierre_ts, now())
   AND t.terminal_id       = s.terminal_id
   AND t.user_id           = s.cajero_usuario_id
  LEFT JOIN selemti.formas_pago fp
    ON fp.payment_type             = t.payment_type
   AND COALESCE(fp.transaction_type,'') = COALESCE(t.transaction_type,'')
   AND COALESCE(fp.payment_sub_type,'') = COALESCE(t.payment_sub_type,'')
   AND COALESCE(fp.custom_name,'')      = COALESCE(t.custom_payment_name,'')
   AND COALESCE(fp.custom_ref,'')       = COALESCE(t.custom_payment_ref,'')
)
SELECT sesion_id, codigo_fp, SUM(monto)::numeric(12,2) AS monto
FROM base
GROUP BY sesion_id, codigo_fp;

CREATE OR REPLACE VIEW selemti.vw_sesion_descuentos AS
SELECT s.id AS sesion_id, 0::numeric AS descuentos
FROM selemti.sesion_cajon s;

CREATE OR REPLACE VIEW selemti.vw_sesion_anulaciones AS
SELECT s.id AS sesion_id,
       COALESCE(SUM(CASE WHEN tk.status IN ('VOID','REFUND') THEN tk.total_price ELSE 0 END),0)::numeric AS total_anulado
FROM selemti.sesion_cajon s
LEFT JOIN public.ticket tk
  ON tk.closing_date >= s.apertura_ts
 AND tk.closing_date <  COALESCE(s.cierre_ts, now())
 AND tk.terminal_id   = s.terminal_id
 AND tk.owner_id      = s.cajero_usuario_id
GROUP BY s.id;

CREATE OR REPLACE VIEW selemti.vw_sesion_retiros AS
SELECT s.id AS sesion_id,
       COALESCE(SUM(CASE WHEN t.transaction_type IN ('PAYOUT','EXPENSE') THEN t.amount::numeric ELSE 0 END),0)::numeric(12,2) AS retiros
FROM selemti.sesion_cajon s
JOIN public.transactions t
  ON t.transaction_time >= s.apertura_ts
 AND t.transaction_time <  COALESCE(s.cierre_ts, now())
 AND t.terminal_id       = s.terminal_id
 AND t.user_id           = s.cajero_usuario_id
GROUP BY s.id;

CREATE OR REPLACE VIEW selemti.vw_sesion_reembolsos_efectivo AS
SELECT s.id AS sesion_id,
       COALESCE(SUM(CASE
         WHEN (t.transaction_type IN ('REFUND','RETURN') OR COALESCE(t.voided,false)=true)
          AND (t.payment_type = 'CASH' OR t.transaction_type = 'CASH')
         THEN t.amount::numeric ELSE 0 END),0)::numeric(12,2) AS reembolsos_efectivo
FROM selemti.sesion_cajon s
JOIN public.transactions t
  ON t.transaction_time >= s.apertura_ts
 AND t.transaction_time <  COALESCE(s.cierre_ts, now())
 AND t.terminal_id       = s.terminal_id
 AND t.user_id           = s.cajero_usuario_id
GROUP BY s.id;

CREATE OR REPLACE VIEW selemti.vw_conciliacion_sesion AS
WITH ventas AS (
  SELECT
    sesion_id,
    SUM(CASE WHEN codigo_fp = 'CASH' THEN monto ELSE 0 END) AS ventas_efectivo,
    SUM(CASE WHEN codigo_fp IN ('CREDIT','DEBIT','TRANSFER') OR codigo_fp LIKE 'CUSTOM:%'
             THEN monto ELSE 0 END) AS ventas_no_efectivo
  FROM selemti.vw_sesion_ventas
  GROUP BY sesion_id
),
decl AS (
  SELECT
    s.id AS sesion_id,
    COALESCE(MAX(p.declarado_efectivo),0)::numeric      AS precorte_efectivo,
    COALESCE(MAX(pc.declarado_efectivo),0)::numeric     AS post_efectivo,
    COALESCE(MAX(pc.declarado_tarjetas),0)::numeric     AS post_tarjetas
  FROM selemti.sesion_cajon s
  LEFT JOIN selemti.precorte  p  ON p.sesion_id  = s.id
  LEFT JOIN selemti.postcorte pc ON pc.sesion_id = s.id
  GROUP BY s.id
)
SELECT
  s.id                AS sesion_id,
  s.terminal_id,
  s.cajero_usuario_id,
  s.apertura_ts,
  s.cierre_ts,
  s.estatus,

  s.opening_float,
  COALESCE(v.ventas_efectivo,0)      AS sistema_efectivo,
  COALESCE(v.ventas_no_efectivo,0)   AS sistema_no_efectivo,
  COALESCE(dsc.descuentos,0)         AS sistema_descuentos,
  COALESCE(an.total_anulado,0)       AS sistema_anulaciones,
  COALESCE(re.retiros,0)             AS sistema_retiros,
  COALESCE(rc.reembolsos_efectivo,0) AS sistema_reembolsos_efectivo,

  ( s.opening_float
    + COALESCE(v.ventas_efectivo,0)
    - COALESCE(re.retiros,0)
    - COALESCE(rc.reembolsos_efectivo,0)
  ) AS sistema_efectivo_esperado,

  COALESCE(dl.precorte_efectivo,0) AS declarado_precorte_efectivo,
  COALESCE(dl.post_efectivo,0)     AS declarado_post_efectivo,
  COALESCE(dl.post_tarjetas,0)     AS declarado_post_tarjetas,

  (COALESCE(dl.post_efectivo,0)  - ( s.opening_float
                                   + COALESCE(v.ventas_efectivo,0)
                                   - COALESCE(re.retiros,0)
                                   - COALESCE(rc.reembolsos_efectivo,0))) AS diferencia_efectivo,
  (COALESCE(dl.post_tarjetas,0) - COALESCE(v.ventas_no_efectivo,0))        AS diferencia_no_efectivo,

  s.closing_float AS cierre_pos_snapshot,
  COALESCE(s.closing_float,
           ( s.opening_float
             + COALESCE(v.ventas_efectivo,0)
             - COALESCE(re.retiros,0)
             - COALESCE(rc.reembolsos_efectivo,0)
           )) AS cierre_pos_efectivo_final

FROM selemti.sesion_cajon s
LEFT JOIN ventas                           v   ON v.sesion_id   = s.id
LEFT JOIN selemti.vw_sesion_descuentos     dsc ON dsc.sesion_id = s.id
LEFT JOIN selemti.vw_sesion_anulaciones    an  ON an.sesion_id  = s.id
LEFT JOIN selemti.vw_sesion_retiros        re  ON re.sesion_id  = s.id
LEFT JOIN selemti.vw_sesion_reembolsos_efectivo rc ON rc.sesion_id = s.id
LEFT JOIN decl                             dl  ON dl.sesion_id  = s.id;
