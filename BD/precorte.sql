CREATE TABLE pc_precorte (
    id                bigserial PRIMARY KEY,
    terminal_id       integer NOT NULL REFERENCES public.terminal(id),
    terminal_location text NOT NULL,
    cashier_user_id   integer NOT NULL REFERENCES public.users(auto_id),
    from_ts           timestamptz NOT NULL,
    to_ts             timestamptz NOT NULL,
    opening_cash      numeric(12,2) DEFAULT 0,
    system_sales      numeric(12,2) DEFAULT 0,
    system_cash_exp   numeric(12,2) DEFAULT 0,
    system_card_exp   numeric(12,2) DEFAULT 0,
    system_other_exp  numeric(12,2) DEFAULT 0,
    counted_cash      numeric(12,2) DEFAULT 0,
    declared_card     numeric(12,2) DEFAULT 0,
    declared_other    numeric(12,2) DEFAULT 0,
    cash_diff         numeric(12,2) DEFAULT 0,
    card_diff         numeric(12,2) DEFAULT 0,
    other_diff        numeric(12,2) DEFAULT 0,
    discounts_cnt     integer DEFAULT 0,
    voids_cnt         integer DEFAULT 0,
    refunds_cnt       integer DEFAULT 0,
    open_tickets_cnt  integer DEFAULT 0,
    tips_cash         numeric(12,2) DEFAULT 0,
    tips_card         numeric(12,2) DEFAULT 0,
    notes             text,
    warnings          jsonb DEFAULT '[]'::jsonb,
    status            text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'PRINTED')),
    created_at        timestamptz NOT NULL DEFAULT now(),
    created_by        integer NOT NULL REFERENCES public.users(auto_id),
    submitted_at      timestamptz,
    submitted_by      integer REFERENCES public.users(auto_id),
    approved_at       timestamptz,
    approved_by       integer REFERENCES public.users(auto_id),
    CONSTRAINT unique_precorte UNIQUE (terminal_id, cashier_user_id, from_ts, to_ts, status)
);

CREATE TABLE pc_precorte_cash_count (
    id          bigserial PRIMARY KEY,
    precorte_id bigint NOT NULL REFERENCES pc_precorte(id) ON DELETE CASCADE,
    denom       numeric(8,2) NOT NULL,
    qty         integer NOT NULL,
    subtotal    numeric(12,2) GENERATED ALWAYS AS (denom * qty) STORED,
    other_denom numeric(8,2),
    other_desc  text
);

CREATE TABLE pc_precorte_payments (
    id           bigserial PRIMARY KEY,
    precorte_id  bigint NOT NULL REFERENCES pc_precorte(id) ON DELETE CASCADE,
    method       text NOT NULL CHECK (method IN ('CASH', 'DEBIT_CARD', 'CREDIT_CARD', 'GIFT_CARD', 'TRANSFER', 'OTHER')),
    brand        text CHECK (brand IN ('VISA', 'MASTERCARD', 'AMEX', 'OTHER', NULL)),
    terminal_ext text,
    amount       numeric(12,2) NOT NULL
);

CREATE TABLE pc_precorte_adjustments (
    id           bigserial PRIMARY KEY,
    precorte_id  bigint NOT NULL REFERENCES pc_precorte(id) ON DELETE CASCADE,
    kind         text NOT NULL CHECK (kind IN ('FALTANTE', 'SOBRANTE', 'ERROR', 'MERMAS', 'PAYOUT', 'DROP', 'NOSALE')),
    description  text,
    amount       numeric(12,2) NOT NULL DEFAULT 0
);

CREATE TABLE pc_precorte_audit (
    id           bigserial PRIMARY KEY,
    precorte_id  bigint NOT NULL REFERENCES pc_precorte(id) ON DELETE CASCADE,
    at           timestamptz NOT NULL DEFAULT now(),
    actor_user   integer NOT NULL REFERENCES public.users(auto_id),
    action       text NOT NULL CHECK (action IN ('CREATE', 'UPDATE', 'SUBMIT', 'APPROVE', 'REJECT', 'PRINT')),
    details      jsonb
);

-- Índices recomendados
CREATE INDEX idx_pc_precorte_terminal ON pc_precorte (terminal_id, from_ts, to_ts);
CREATE INDEX idx_pc_precorte_cashier ON pc_precorte (cashier_user_id, from_ts, to_ts);
CREATE INDEX idx_pc_precorte_warnings ON pc_precorte USING GIN (warnings);

-- Vistas SQL adaptadas al esquema del dump
CREATE VIEW vw_precorte_sales AS
SELECT
    t.terminal_id,
    t.owner_id AS cashier_user_id,
    t.branch_key AS terminal_location,
    SUM(t.total_amount) AS total_sales,
    SUM(t.discount) AS total_discounts,
    SUM(t.tip_amount) AS total_tips,
    COUNT(*) FILTER (WHERE t.voided = true) AS voids_cnt,
    COUNT(*) FILTER (WHERE t.total_amount < 0 OR t.ticket_type = 'REFUND') AS refunds_cnt,
    COUNT(*) FILTER (WHERE t.closed = false OR t.paid = false) AS open_tickets_cnt
FROM public.ticket t
WHERE t.create_date AT TIME ZONE 'America/Mexico_City' >= $1
    AND t.create_date AT TIME ZONE 'America/Mexico_City' < $2
    AND (t.voided = false OR t.voided IS NULL)
GROUP BY t.terminal_id, t.owner_id, t.branch_key;

CREATE VIEW vw_precorte_payments AS
SELECT
    tr.terminal_id,
    tr.user_id AS cashier_user_id,
    t.branch_key AS terminal_location,
    tr.transaction_type AS method,
    tr.card_type AS brand,
    SUM(tr.amount) AS amount,
    SUM(CASE WHEN tr.transaction_type = 'CASH' THEN tr.tip_amount ELSE 0 END) AS tips_cash,
    SUM(CASE WHEN tr.transaction_type IN ('CREDIT_CARD', 'DEBIT_CARD') THEN tr.tip_amount ELSE 0 END) AS tips_card
FROM public.transactions tr
JOIN public.ticket t ON t.id = tr.ticket_id
WHERE t.create_date AT TIME ZONE 'America/Mexico_City' >= $1
    AND t.create_date AT TIME ZONE 'America/Mexico_City' < $2
    AND (t.voided = false OR t.voided IS NULL)
GROUP BY tr.terminal_id, tr.user_id, t.branch_key, tr.transaction_type, tr.card_type;

CREATE VIEW vw_precorte_discounts AS
SELECT
    t.terminal_id,
    t.owner_id AS cashier_user_id,
    t.branch_key AS terminal_location,
    COUNT(*) AS discounts_cnt,
    SUM(ti.discount_amount) AS discounts_amount
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE t.create_date AT TIME ZONE 'America/Mexico_City' >= $1
    AND t.create_date AT TIME ZONE 'America/Mexico_City' < $2
    AND (t.voided = false OR t.voided IS NULL)
    AND ti.discount_amount > 0
GROUP BY t.terminal_id, t.owner_id, t.branch_key;

CREATE VIEW vw_precorte_voids AS
SELECT
    t.terminal_id,
    t.owner_id AS cashier_user_id,
    t.branch_key AS terminal_location,
    COUNT(*) AS voids_cnt,
    SUM(ti.unit_price * ti.item_count) AS voids_amount
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE t.create_date AT TIME ZONE 'America/Mexico_City' >= $1
    AND t.create_date AT TIME ZONE 'America/Mexico_City' < $2
    AND (t.voided = false OR t.voided IS NULL)
    AND ti.voided = true
GROUP BY t.terminal_id, t.owner_id, t.branch_key;