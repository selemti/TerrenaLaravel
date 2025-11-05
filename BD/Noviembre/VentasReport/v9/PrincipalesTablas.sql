-- Table: public.cash_drawer

-- DROP TABLE public.cash_drawer;

CREATE TABLE public.cash_drawer
(
  id integer NOT NULL DEFAULT nextval('cash_drawer_id_seq'::regclass),
  terminal_id integer,
  CONSTRAINT cash_drawer_pkey PRIMARY KEY (id),
  CONSTRAINT fk6221077d2ad2d031 FOREIGN KEY (terminal_id)
      REFERENCES public.terminal (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.cash_drawer
  OWNER TO floreant;
	
	
	
-- Table: public.action_history

-- DROP TABLE public.action_history;

CREATE TABLE public.action_history
(
  id integer NOT NULL DEFAULT nextval('action_history_id_seq'::regclass),
  action_time timestamp without time zone,
  action_name character varying(255),
  description character varying(255),
  user_id integer,
  CONSTRAINT action_history_pkey PRIMARY KEY (id),
  CONSTRAINT fk3f3af36b3e20ad51 FOREIGN KEY (user_id)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.action_history
  OWNER TO floreant;


-- Table: public.cash_drawer_reset_history

-- DROP TABLE public.cash_drawer_reset_history;

CREATE TABLE public.cash_drawer_reset_history
(
  id integer NOT NULL DEFAULT nextval('cash_drawer_reset_history_id_seq'::regclass),
  reset_time timestamp without time zone,
  user_id integer,
  CONSTRAINT cash_drawer_reset_history_pkey PRIMARY KEY (id),
  CONSTRAINT fk719418223e20ad51 FOREIGN KEY (user_id)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.cash_drawer_reset_history
  OWNER TO floreant;
-- Table: public.coupon_and_discount

-- DROP TABLE public.coupon_and_discount;

CREATE TABLE public.coupon_and_discount
(
  id integer NOT NULL DEFAULT nextval('coupon_and_discount_id_seq'::regclass),
  name character varying(120),
  type integer,
  barcode character varying(120),
  qualification_type integer,
  apply_to_all boolean,
  minimum_buy integer,
  maximum_off integer,
  value double precision,
  expiry_date timestamp without time zone,
  enabled boolean,
  auto_apply boolean,
  modifiable boolean,
  never_expire boolean,
  uuid character varying(36),
  CONSTRAINT coupon_and_discount_pkey PRIMARY KEY (id),
  CONSTRAINT coupon_and_discount_uuid_key UNIQUE (uuid)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.coupon_and_discount
  OWNER TO floreant;
-- Table: public.currency_balance

-- DROP TABLE public.currency_balance;

CREATE TABLE public.currency_balance
(
  id integer NOT NULL DEFAULT nextval('currency_balance_id_seq'::regclass),
  balance double precision,
  currency_id integer,
  cash_drawer_id integer,
  dpr_id integer,
  CONSTRAINT currency_balance_pkey PRIMARY KEY (id),
  CONSTRAINT fk2cc0e08e28dd6c11 FOREIGN KEY (currency_id)
      REFERENCES public.currency (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk2cc0e08e9006558 FOREIGN KEY (cash_drawer_id)
      REFERENCES public.cash_drawer (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk2cc0e08efb910735 FOREIGN KEY (dpr_id)
      REFERENCES public.drawer_pull_report (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.currency_balance
  OWNER TO floreant;


-- Table: public.custom_payment

-- DROP TABLE public.custom_payment;

CREATE TABLE public.custom_payment
(
  id integer NOT NULL DEFAULT nextval('custom_payment_id_seq'::regclass),
  name character varying(60),
  required_ref_number boolean,
  ref_number_field_name character varying(60),
  CONSTRAINT custom_payment_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.custom_payment
  OWNER TO floreant;
-- Table: public.drawer_assigned_history

-- DROP TABLE public.drawer_assigned_history;

CREATE TABLE public.drawer_assigned_history
(
  id integer NOT NULL DEFAULT nextval('drawer_assigned_history_id_seq'::regclass),
  "time" timestamp without time zone,
  operation character varying(60),
  a_user integer,
  CONSTRAINT drawer_assigned_history_pkey PRIMARY KEY (id),
  CONSTRAINT fk5a823c91f1dd782b FOREIGN KEY (a_user)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.drawer_assigned_history
  OWNER TO floreant;

-- Index: public.idx_dah_user_op_time

-- DROP INDEX public.idx_dah_user_op_time;

CREATE INDEX idx_dah_user_op_time
  ON public.drawer_assigned_history
  USING btree
  (a_user, operation COLLATE pg_catalog."default", "time" DESC);

-- Index: public.idx_drawer_assigned_history_user_time

-- DROP INDEX public.idx_drawer_assigned_history_user_time;

CREATE INDEX idx_drawer_assigned_history_user_time
  ON public.drawer_assigned_history
  USING btree
  (a_user, "time");


-- Trigger: trg_selemti_dah_ai on public.drawer_assigned_history

-- DROP TRIGGER trg_selemti_dah_ai ON public.drawer_assigned_history;

CREATE TRIGGER trg_selemti_dah_ai
  AFTER INSERT
  ON public.drawer_assigned_history
  FOR EACH ROW
  EXECUTE PROCEDURE selemti.fn_dah_after_insert();

-- Table: public.drawer_pull_report

-- DROP TABLE public.drawer_pull_report;

CREATE TABLE public.drawer_pull_report
(
  id integer NOT NULL DEFAULT nextval('drawer_pull_report_id_seq'::regclass),
  report_time timestamp without time zone,
  reg character varying(15),
  ticket_count integer,
  begin_cash double precision,
  net_sales double precision,
  sales_tax double precision,
  cash_tax double precision,
  total_revenue double precision,
  gross_receipts double precision,
  giftcertreturncount integer,
  giftcertreturnamount double precision,
  giftcertchangeamount double precision,
  cash_receipt_no integer,
  cash_receipt_amount double precision,
  credit_card_receipt_no integer,
  credit_card_receipt_amount double precision,
  debit_card_receipt_no integer,
  debit_card_receipt_amount double precision,
  refund_receipt_count integer,
  refund_amount double precision,
  receipt_differential double precision,
  cash_back double precision,
  cash_tips double precision,
  charged_tips double precision,
  tips_paid double precision,
  tips_differential double precision,
  pay_out_no integer,
  pay_out_amount double precision,
  drawer_bleed_no integer,
  drawer_bleed_amount double precision,
  drawer_accountable double precision,
  cash_to_deposit double precision,
  variance double precision,
  delivery_charge double precision,
  totalvoidwst double precision,
  totalvoid double precision,
  totaldiscountcount integer,
  totaldiscountamount double precision,
  totaldiscountsales double precision,
  totaldiscountguest integer,
  totaldiscountpartysize integer,
  totaldiscountchecksize integer,
  totaldiscountpercentage double precision,
  totaldiscountratio double precision,
  user_id integer,
  terminal_id integer,
  CONSTRAINT drawer_pull_report_pkey PRIMARY KEY (id),
  CONSTRAINT fkaec362202ad2d031 FOREIGN KEY (terminal_id)
      REFERENCES public.terminal (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fkaec362203e20ad51 FOREIGN KEY (user_id)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.drawer_pull_report
  OWNER TO floreant;

-- Index: public.drawer_report_time

-- DROP INDEX public.drawer_report_time;

CREATE INDEX drawer_report_time
  ON public.drawer_pull_report
  USING btree
  (report_time);

-- Table: public.drawer_pull_report_voidtickets

-- DROP TABLE public.drawer_pull_report_voidtickets;

CREATE TABLE public.drawer_pull_report_voidtickets
(
  dpreport_id integer NOT NULL,
  code integer,
  reason character varying(255),
  hast character varying(255),
  quantity integer,
  amount double precision,
  CONSTRAINT fk98cf9b143ef4cd9b FOREIGN KEY (dpreport_id)
      REFERENCES public.drawer_pull_report (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.drawer_pull_report_voidtickets
  OWNER TO floreant;
-- Table: public.menu_group

-- DROP TABLE public.menu_group;

CREATE TABLE public.menu_group
(
  id integer NOT NULL DEFAULT nextval('menu_group_id_seq'::regclass),
  name character varying(120) NOT NULL,
  translated_name character varying(120),
  visible boolean,
  sort_order integer,
  btn_color integer,
  text_color integer,
  category_id integer,
  CONSTRAINT menu_group_pkey PRIMARY KEY (id),
  CONSTRAINT fk4dc1ab7f2e347ff0 FOREIGN KEY (category_id)
      REFERENCES public.menu_category (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.menu_group
  OWNER TO floreant;

-- Index: public.menugroupvisible

-- DROP INDEX public.menugroupvisible;

CREATE INDEX menugroupvisible
  ON public.menu_group
  USING btree
  (visible);

-- Table: public.menu_item

-- DROP TABLE public.menu_item;

CREATE TABLE public.menu_item
(
  id integer NOT NULL DEFAULT nextval('menu_item_id_seq'::regclass),
  name character varying(120) NOT NULL,
  description character varying(255),
  unit_name character varying(20),
  translated_name character varying(120),
  barcode character varying(120),
  buy_price double precision NOT NULL,
  stock_amount double precision,
  price double precision NOT NULL,
  discount_rate double precision,
  visible boolean,
  disable_when_stock_amount_is_zero boolean,
  sort_order integer,
  btn_color integer,
  text_color integer,
  image bytea,
  show_image_only boolean,
  fractional_unit boolean,
  pizza_type boolean,
  default_sell_portion integer,
  group_id integer,
  tax_group_id character varying(128),
  recepie integer,
  pg_id integer,
  tax_id integer,
  CONSTRAINT menu_item_pkey PRIMARY KEY (id),
  CONSTRAINT fk4cd5a1f35188aa24 FOREIGN KEY (group_id)
      REFERENCES public.menu_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk4cd5a1f35cf1375f FOREIGN KEY (pg_id)
      REFERENCES public.printer_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk4cd5a1f35ee9f27a FOREIGN KEY (tax_group_id)
      REFERENCES public.tax_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk4cd5a1f3a4802f83 FOREIGN KEY (tax_id)
      REFERENCES public.tax (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk4cd5a1f3f3b77c57 FOREIGN KEY (recepie)
      REFERENCES public.recepie (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.menu_item
  OWNER TO floreant;
-- Table: public.menu_modifier

-- DROP TABLE public.menu_modifier;

CREATE TABLE public.menu_modifier
(
  id integer NOT NULL DEFAULT nextval('menu_modifier_id_seq'::regclass),
  name character varying(120),
  translated_name character varying(120),
  price double precision,
  extra_price double precision,
  sort_order integer,
  btn_color integer,
  text_color integer,
  enable boolean,
  fixed_price boolean,
  print_to_kitchen boolean,
  section_wise_pricing boolean,
  pizza_modifier boolean,
  group_id integer,
  tax_id integer,
  CONSTRAINT menu_modifier_pkey PRIMARY KEY (id),
  CONSTRAINT fk59b6b1b72501cb2c FOREIGN KEY (group_id)
      REFERENCES public.menu_modifier_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk59b6b1b75e0c7b8d FOREIGN KEY (group_id)
      REFERENCES public.menu_modifier_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk59b6b1b7a4802f83 FOREIGN KEY (tax_id)
      REFERENCES public.tax (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.menu_modifier
  OWNER TO floreant;

-- Index: public.modifierenabled

-- DROP INDEX public.modifierenabled;

CREATE INDEX modifierenabled
  ON public.menu_modifier
  USING btree
  (enable);

-- Table: public.menu_modifier

-- DROP TABLE public.menu_modifier;

CREATE TABLE public.menu_modifier
(
  id integer NOT NULL DEFAULT nextval('menu_modifier_id_seq'::regclass),
  name character varying(120),
  translated_name character varying(120),
  price double precision,
  extra_price double precision,
  sort_order integer,
  btn_color integer,
  text_color integer,
  enable boolean,
  fixed_price boolean,
  print_to_kitchen boolean,
  section_wise_pricing boolean,
  pizza_modifier boolean,
  group_id integer,
  tax_id integer,
  CONSTRAINT menu_modifier_pkey PRIMARY KEY (id),
  CONSTRAINT fk59b6b1b72501cb2c FOREIGN KEY (group_id)
      REFERENCES public.menu_modifier_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk59b6b1b75e0c7b8d FOREIGN KEY (group_id)
      REFERENCES public.menu_modifier_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk59b6b1b7a4802f83 FOREIGN KEY (tax_id)
      REFERENCES public.tax (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.menu_modifier
  OWNER TO floreant;

-- Index: public.modifierenabled

-- DROP INDEX public.modifierenabled;

CREATE INDEX modifierenabled
  ON public.menu_modifier
  USING btree
  (enable);

-- Table: public.menu_modifier_group

-- DROP TABLE public.menu_modifier_group;

CREATE TABLE public.menu_modifier_group
(
  id integer NOT NULL DEFAULT nextval('menu_modifier_group_id_seq'::regclass),
  name character varying(60),
  translated_name character varying(60),
  enabled boolean,
  exclusived boolean,
  required boolean,
  CONSTRAINT menu_modifier_group_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.menu_modifier_group
  OWNER TO floreant;

-- Index: public.mg_enable

-- DROP INDEX public.mg_enable;

CREATE INDEX mg_enable
  ON public.menu_modifier_group
  USING btree
  (enabled);

-- Table: public.menucategory_discount

-- DROP TABLE public.menucategory_discount;

CREATE TABLE public.menucategory_discount
(
  discount_id integer NOT NULL,
  menucategory_id integer NOT NULL,
  CONSTRAINT fk4f8523e38d9ea931 FOREIGN KEY (menucategory_id)
      REFERENCES public.menu_category (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk4f8523e3d3e91e11 FOREIGN KEY (discount_id)
      REFERENCES public.coupon_and_discount (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.menucategory_discount
  OWNER TO floreant;
-- Table: public.menuitem_modifiergroup

-- DROP TABLE public.menuitem_modifiergroup;

CREATE TABLE public.menuitem_modifiergroup
(
  id integer NOT NULL DEFAULT nextval('menuitem_modifiergroup_id_seq'::regclass),
  min_quantity integer,
  max_quantity integer,
  sort_order integer,
  modifier_group integer,
  menuitem_modifiergroup_id integer,
  CONSTRAINT menuitem_modifiergroup_pkey PRIMARY KEY (id),
  CONSTRAINT fk312b355b40fda3c9 FOREIGN KEY (modifier_group)
      REFERENCES public.menu_modifier_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk312b355b6e7b8b68 FOREIGN KEY (menuitem_modifiergroup_id)
      REFERENCES public.menu_item (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk312b355b7f2f368 FOREIGN KEY (modifier_group)
      REFERENCES public.menu_modifier_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.menuitem_modifiergroup
  OWNER TO floreant;
-- Table: public.order_type

-- DROP TABLE public.order_type;

CREATE TABLE public.order_type
(
  id integer NOT NULL DEFAULT nextval('order_type_id_seq'::regclass),
  name character varying(120) NOT NULL,
  enabled boolean,
  show_table_selection boolean,
  show_guest_selection boolean,
  should_print_to_kitchen boolean,
  prepaid boolean,
  close_on_paid boolean,
  required_customer_data boolean,
  delivery boolean,
  show_item_barcode boolean,
  show_in_login_screen boolean,
  consolidate_tiems_in_receipt boolean,
  allow_seat_based_order boolean,
  hide_item_with_empty_inventory boolean,
  has_forhere_and_togo boolean,
  pre_auth_credit_card boolean,
  bar_tab boolean,
  retail_order boolean,
  show_price_on_button boolean,
  show_stock_count_on_button boolean,
  show_unit_price_in_ticket_grid boolean,
  properties text,
  CONSTRAINT order_type_pkey PRIMARY KEY (id),
  CONSTRAINT order_type_name_key UNIQUE (name)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.order_type
  OWNER TO floreant;
-- Table: public.payout_reasons

-- DROP TABLE public.payout_reasons;

CREATE TABLE public.payout_reasons
(
  id integer NOT NULL DEFAULT nextval('payout_reasons_id_seq'::regclass),
  reason character varying(255),
  CONSTRAINT payout_reasons_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.payout_reasons
  OWNER TO floreant;
-- Table: public.payout_recepients

-- DROP TABLE public.payout_recepients;

CREATE TABLE public.payout_recepients
(
  id integer NOT NULL DEFAULT nextval('payout_recepients_id_seq'::regclass),
  name character varying(255),
  CONSTRAINT payout_recepients_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.payout_recepients
  OWNER TO floreant;
-- Table: public.recepie

-- DROP TABLE public.recepie;

CREATE TABLE public.recepie
(
  id integer NOT NULL DEFAULT nextval('recepie_id_seq'::regclass),
  menu_item integer,
  CONSTRAINT recepie_pkey PRIMARY KEY (id),
  CONSTRAINT fk6b4e177764931efc FOREIGN KEY (menu_item)
      REFERENCES public.menu_item (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.recepie
  OWNER TO floreant;
-- Table: public.recepie_item

-- DROP TABLE public.recepie_item;

CREATE TABLE public.recepie_item
(
  id integer NOT NULL DEFAULT nextval('recepie_item_id_seq'::regclass),
  percentage double precision,
  inventory_deductable boolean,
  inventory_item integer,
  recepie_id integer,
  CONSTRAINT recepie_item_pkey PRIMARY KEY (id),
  CONSTRAINT fk855626db1682b10e FOREIGN KEY (inventory_item)
      REFERENCES public.inventory_item (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk855626dbcae89b83 FOREIGN KEY (recepie_id)
      REFERENCES public.recepie (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.recepie_item
  OWNER TO floreant;
-- Table: public.terminal

-- DROP TABLE public.terminal;

CREATE TABLE public.terminal
(
  id integer NOT NULL,
  name character varying(60),
  terminal_key character varying(120),
  opening_balance double precision,
  current_balance double precision,
  has_cash_drawer boolean,
  in_use boolean,
  active boolean,
  location character varying(320),
  floor_id integer,
  assigned_user integer,
  CONSTRAINT terminal_pkey PRIMARY KEY (id),
  CONSTRAINT fke83d827c969c6de FOREIGN KEY (assigned_user)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.terminal
  OWNER TO floreant;

-- Trigger: trg_selemti_terminal_bu_snapshot on public.terminal

-- DROP TRIGGER trg_selemti_terminal_bu_snapshot ON public.terminal;

CREATE TRIGGER trg_selemti_terminal_bu_snapshot
  BEFORE UPDATE
  ON public.terminal
  FOR EACH ROW
  EXECUTE PROCEDURE selemti.fn_terminal_bu_snapshot_cierre();

-- Table: public.ticket

-- DROP TABLE public.ticket;

CREATE TABLE public.ticket
(
  id integer NOT NULL DEFAULT nextval('ticket_id_seq'::regclass),
  global_id character varying(16),
  create_date timestamp without time zone,
  closing_date timestamp without time zone,
  active_date timestamp without time zone,
  deliveery_date timestamp without time zone,
  creation_hour integer,
  paid boolean,
  voided boolean,
  void_reason character varying(255),
  wasted boolean,
  refunded boolean,
  settled boolean,
  drawer_resetted boolean,
  sub_total double precision,
  total_discount double precision,
  total_tax double precision,
  total_price double precision,
  paid_amount double precision,
  due_amount double precision,
  advance_amount double precision,
  adjustment_amount double precision,
  number_of_guests integer,
  status character varying(30),
  bar_tab boolean,
  is_tax_exempt boolean,
  is_re_opened boolean,
  service_charge double precision,
  delivery_charge double precision,
  customer_id integer,
  delivery_address character varying(120),
  customer_pickeup boolean,
  delivery_extra_info character varying(255),
  ticket_type character varying(20),
  shift_id integer,
  owner_id integer,
  driver_id integer,
  gratuity_id integer,
  void_by_user integer,
  terminal_id integer,
  folio_date date,
  branch_key text,
  daily_folio integer,
  CONSTRAINT ticket_pkey PRIMARY KEY (id),
  CONSTRAINT fk937b5f0c1f6a9a4a FOREIGN KEY (void_by_user)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk937b5f0c2ad2d031 FOREIGN KEY (terminal_id)
      REFERENCES public.terminal (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk937b5f0c7660a5e3 FOREIGN KEY (shift_id)
      REFERENCES public.shift (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk937b5f0caa075d69 FOREIGN KEY (owner_id)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk937b5f0cc188ea51 FOREIGN KEY (gratuity_id)
      REFERENCES public.gratuity (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk937b5f0cf575c7d4 FOREIGN KEY (driver_id)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT ticket_global_id_key UNIQUE (global_id),
  CONSTRAINT ck_ticket_daily_folio_positive CHECK (daily_folio IS NULL OR daily_folio > 0)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.ticket
  OWNER TO floreant;

-- Index: public.creationhour

-- DROP INDEX public.creationhour;

CREATE INDEX creationhour
  ON public.ticket
  USING btree
  (creation_hour);

-- Index: public.deliverydate

-- DROP INDEX public.deliverydate;

CREATE INDEX deliverydate
  ON public.ticket
  USING btree
  (deliveery_date);

-- Index: public.drawerresetted

-- DROP INDEX public.drawerresetted;

CREATE INDEX drawerresetted
  ON public.ticket
  USING btree
  (drawer_resetted);

-- Index: public.idx_ticket_close_term_owner

-- DROP INDEX public.idx_ticket_close_term_owner;

CREATE INDEX idx_ticket_close_term_owner
  ON public.ticket
  USING btree
  (closing_date, terminal_id, owner_id);

-- Index: public.idx_ticket_closing_date

-- DROP INDEX public.idx_ticket_closing_date;

CREATE INDEX idx_ticket_closing_date
  ON public.ticket
  USING btree
  (closing_date);

-- Index: public.ix_ticket_branch_key

-- DROP INDEX public.ix_ticket_branch_key;

CREATE INDEX ix_ticket_branch_key
  ON public.ticket
  USING btree
  (branch_key COLLATE pg_catalog."default");

-- Index: public.ix_ticket_folio_date

-- DROP INDEX public.ix_ticket_folio_date;

CREATE INDEX ix_ticket_folio_date
  ON public.ticket
  USING btree
  (folio_date);

-- Index: public.ticketactivedate

-- DROP INDEX public.ticketactivedate;

CREATE INDEX ticketactivedate
  ON public.ticket
  USING btree
  (active_date);

-- Index: public.ticketclosingdate

-- DROP INDEX public.ticketclosingdate;

CREATE INDEX ticketclosingdate
  ON public.ticket
  USING btree
  (closing_date);

-- Index: public.ticketcreatedate

-- DROP INDEX public.ticketcreatedate;

CREATE INDEX ticketcreatedate
  ON public.ticket
  USING btree
  (create_date);

-- Index: public.ticketpaid

-- DROP INDEX public.ticketpaid;

CREATE INDEX ticketpaid
  ON public.ticket
  USING btree
  (paid);

-- Index: public.ticketsettled

-- DROP INDEX public.ticketsettled;

CREATE INDEX ticketsettled
  ON public.ticket
  USING btree
  (settled);

-- Index: public.ticketvoided

-- DROP INDEX public.ticketvoided;

CREATE INDEX ticketvoided
  ON public.ticket
  USING btree
  (voided);

-- Index: public.ux_ticket_dailyfolio

-- DROP INDEX public.ux_ticket_dailyfolio;

CREATE UNIQUE INDEX ux_ticket_dailyfolio
  ON public.ticket
  USING btree
  (folio_date, branch_key COLLATE pg_catalog."default", daily_folio)
  WHERE daily_folio IS NOT NULL;


-- Trigger: trg_assign_daily_folio on public.ticket

-- DROP TRIGGER trg_assign_daily_folio ON public.ticket;

CREATE TRIGGER trg_assign_daily_folio
  BEFORE INSERT
  ON public.ticket
  FOR EACH ROW
  EXECUTE PROCEDURE public.assign_daily_folio();
-- Table: public.ticket_discount

-- DROP TABLE public.ticket_discount;

CREATE TABLE public.ticket_discount
(
  id integer NOT NULL DEFAULT nextval('ticket_discount_id_seq'::regclass),
  discount_id integer,
  name character varying(30),
  type integer,
  auto_apply boolean,
  minimum_amount integer,
  value double precision,
  ticket_id integer,
  CONSTRAINT ticket_discount_pkey PRIMARY KEY (id),
  CONSTRAINT fk1fa465141df2d7f1 FOREIGN KEY (ticket_id)
      REFERENCES public.ticket (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.ticket_discount
  OWNER TO floreant;

-- Table: public.ticket_item

-- DROP TABLE public.ticket_item;

CREATE TABLE public.ticket_item
(
  id integer NOT NULL DEFAULT nextval('ticket_item_id_seq'::regclass),
  item_id integer,
  item_count integer,
  item_quantity double precision,
  item_name character varying(120),
  item_unit_name character varying(20),
  group_name character varying(120),
  category_name character varying(120),
  item_price double precision,
  item_tax_rate double precision,
  sub_total double precision,
  sub_total_without_modifiers double precision,
  discount double precision,
  tax_amount double precision,
  tax_amount_without_modifiers double precision,
  total_price double precision,
  total_price_without_modifiers double precision,
  beverage boolean,
  inventory_handled boolean,
  print_to_kitchen boolean,
  treat_as_seat boolean,
  seat_number integer,
  fractional_unit boolean,
  has_modiiers boolean,
  printed_to_kitchen boolean,
  status character varying(255),
  stock_amount_adjusted boolean,
  pizza_type boolean,
  size_modifier_id integer,
  ticket_id integer,
  pg_id integer,
  pizza_section_mode integer,
  CONSTRAINT ticket_item_pkey PRIMARY KEY (id),
  CONSTRAINT fk979f54661df2d7f1 FOREIGN KEY (ticket_id)
      REFERENCES public.ticket (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk979f546633e5d3b2 FOREIGN KEY (size_modifier_id)
      REFERENCES public.ticket_item_modifier (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk979f54665cf1375f FOREIGN KEY (pg_id)
      REFERENCES public.printer_group (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.ticket_item
  OWNER TO floreant;

-- Index: public.idx_ticket_item_ticket

-- DROP INDEX public.idx_ticket_item_ticket;

CREATE INDEX idx_ticket_item_ticket
  ON public.ticket_item
  USING btree
  (ticket_id);

-- Index: public.ix_ticket_item_ticket_pg

-- DROP INDEX public.ix_ticket_item_ticket_pg;

CREATE INDEX ix_ticket_item_ticket_pg
  ON public.ticket_item
  USING btree
  (ticket_id, pg_id);


-- Trigger: trg_kds_notify_ti on public.ticket_item

-- DROP TRIGGER trg_kds_notify_ti ON public.ticket_item;

CREATE TRIGGER trg_kds_notify_ti
  AFTER INSERT OR UPDATE OF status
  ON public.ticket_item
  FOR EACH ROW
  EXECUTE PROCEDURE public.kds_notify();
-- Table: public.ticket_item_modifier

-- DROP TABLE public.ticket_item_modifier;

CREATE TABLE public.ticket_item_modifier
(
  id integer NOT NULL DEFAULT nextval('ticket_item_modifier_id_seq'::regclass),
  item_id integer,
  group_id integer,
  item_count integer,
  modifier_name character varying(120),
  modifier_price double precision,
  modifier_tax_rate double precision,
  modifier_type integer,
  subtotal_price double precision,
  total_price double precision,
  tax_amount double precision,
  info_only boolean,
  section_name character varying(20),
  multiplier_name character varying(20),
  print_to_kitchen boolean,
  section_wise_pricing boolean,
  status character varying(10),
  printed_to_kitchen boolean,
  ticket_item_id integer,
  CONSTRAINT ticket_item_modifier_pkey PRIMARY KEY (id),
  CONSTRAINT fk8fd6290dec6120a FOREIGN KEY (ticket_item_id)
      REFERENCES public.ticket_item (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.ticket_item_modifier
  OWNER TO floreant;

-- Table: public.ticket_item_modifier_relation

-- DROP TABLE public.ticket_item_modifier_relation;

CREATE TABLE public.ticket_item_modifier_relation
(
  ticket_item_id integer NOT NULL,
  modifier_id integer NOT NULL,
  list_order integer NOT NULL,
  CONSTRAINT ticket_item_modifier_relation_pkey PRIMARY KEY (ticket_item_id, list_order),
  CONSTRAINT fk5d3f9acb6c108ef0 FOREIGN KEY (modifier_id)
      REFERENCES public.ticket_item_modifier (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk5d3f9acbdec6120a FOREIGN KEY (ticket_item_id)
      REFERENCES public.ticket_item (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.ticket_item_modifier_relation
  OWNER TO floreant;
-- Table: public.transactions

-- DROP TABLE public.transactions;

CREATE TABLE public.transactions
(
  id integer NOT NULL DEFAULT nextval('transactions_id_seq'::regclass),
  payment_type character varying(30) NOT NULL,
  global_id character varying(16),
  transaction_time timestamp without time zone,
  amount double precision,
  tips_amount double precision,
  tips_exceed_amount double precision,
  tender_amount double precision,
  transaction_type character varying(30) NOT NULL,
  custom_payment_name character varying(60),
  custom_payment_ref character varying(120),
  custom_payment_field_name character varying(60),
  payment_sub_type character varying(40) NOT NULL,
  captured boolean,
  voided boolean,
  authorizable boolean,
  card_holder_name character varying(60),
  card_number character varying(40),
  card_auth_code character varying(30),
  card_type character varying(20),
  card_transaction_id character varying(255),
  card_merchant_gateway character varying(60),
  card_reader character varying(30),
  card_aid character varying(120),
  card_arqc character varying(120),
  card_ext_data character varying(255),
  gift_cert_number character varying(64),
  gift_cert_face_value double precision,
  gift_cert_paid_amount double precision,
  gift_cert_cash_back_amount double precision,
  drawer_resetted boolean,
  note character varying(255),
  terminal_id integer,
  ticket_id integer,
  user_id integer,
  payout_reason_id integer,
  payout_recepient_id integer,
  CONSTRAINT transactions_pkey PRIMARY KEY (id),
  CONSTRAINT fkfe9871551df2d7f1 FOREIGN KEY (ticket_id)
      REFERENCES public.ticket (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fkfe9871552ad2d031 FOREIGN KEY (terminal_id)
      REFERENCES public.terminal (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fkfe9871553e20ad51 FOREIGN KEY (user_id)
      REFERENCES public.users (auto_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fkfe987155ca43b6 FOREIGN KEY (payout_recepient_id)
      REFERENCES public.payout_recepients (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fkfe987155fc697d9e FOREIGN KEY (payout_reason_id)
      REFERENCES public.payout_reasons (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT transactions_global_id_key UNIQUE (global_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.transactions
  OWNER TO floreant;

-- Index: public.idx_transactions_time

-- DROP INDEX public.idx_transactions_time;

CREATE INDEX idx_transactions_time
  ON public.transactions
  USING btree
  (transaction_time);

-- Index: public.idx_tx_term_user_time

-- DROP INDEX public.idx_tx_term_user_time;

CREATE INDEX idx_tx_term_user_time
  ON public.transactions
  USING btree
  (terminal_id, user_id, transaction_time);

-- Index: public.tran_drawer_resetted

-- DROP INDEX public.tran_drawer_resetted;

CREATE INDEX tran_drawer_resetted
  ON public.transactions
  USING btree
  (drawer_resetted);


-- Trigger: trg_selemti_tx_ai_forma_pago on public.transactions

-- DROP TRIGGER trg_selemti_tx_ai_forma_pago ON public.transactions;

CREATE TRIGGER trg_selemti_tx_ai_forma_pago
  AFTER INSERT
  ON public.transactions
  FOR EACH ROW
  EXECUTE PROCEDURE selemti.fn_tx_after_insert_forma_pago();

-- Table: public.void_reasons

-- DROP TABLE public.void_reasons;

CREATE TABLE public.void_reasons
(
  id integer NOT NULL DEFAULT nextval('void_reasons_id_seq'::regclass),
  reason_text character varying(255),
  CONSTRAINT void_reasons_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.void_reasons
  OWNER TO floreant;
-- Table: public.users

-- DROP TABLE public.users;

CREATE TABLE public.users
(
  auto_id integer NOT NULL DEFAULT nextval('users_auto_id_seq'::regclass),
  user_id integer,
  user_pass character varying(16) NOT NULL,
  first_name character varying(30),
  last_name character varying(30),
  ssn character varying(30),
  cost_per_hour double precision,
  clocked_in boolean,
  last_clock_in_time timestamp without time zone,
  last_clock_out_time timestamp without time zone,
  phone_no character varying(20),
  is_driver boolean,
  available_for_delivery boolean,
  active boolean,
  shift_id integer,
  currentterminal integer,
  n_user_type integer,
  CONSTRAINT users_pkey PRIMARY KEY (auto_id),
  CONSTRAINT fk4d495e87660a5e3 FOREIGN KEY (shift_id)
      REFERENCES public.shift (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk4d495e8897b1e39 FOREIGN KEY (n_user_type)
      REFERENCES public.user_type (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk4d495e8d9409968 FOREIGN KEY (currentterminal)
      REFERENCES public.terminal (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT users_user_id_key UNIQUE (user_id),
  CONSTRAINT users_user_pass_key UNIQUE (user_pass)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.users
  OWNER TO floreant;
