DB — Diccionario detallado (selectas tablas Caja)

Fecha: 2025-10-17 01:48

Fuente
- Generado con scripts/db_table_details.php (solo lectura; search_path de sesión selemti, public).

# selemti.sesion_cajon

## Columnas
- id: bigint(64,0); nullable=no; default=nextval('sesion_cajon_id_seq'::regclass)
- sucursal: text; nullable=yes; default=null
- terminal_id: integer(32,0); nullable=no; default=null
- terminal_nombre: text; nullable=yes; default=null
- cajero_usuario_id: integer(32,0); nullable=no; default=null
- apertura_ts: timestamp with time zone; nullable=no; default=now()
- cierre_ts: timestamp with time zone; nullable=yes; default=null
- estatus: text; nullable=no; default='ACTIVA'::text
- opening_float: numeric(12,2); nullable=no; default=0
- closing_float: numeric(12,2); nullable=yes; default=null
- dah_evento_id: integer(32,0); nullable=yes; default=null
- skipped_precorte: boolean; nullable=no; default=false

## PK
- id

## FKs
- N/A

## Índices
- ix_sesion_cajon_cajero — CREATE INDEX ix_sesion_cajon_cajero ON sesion_cajon USING btree (cajero_usuario_id, apertura_ts)
- ix_sesion_cajon_terminal — CREATE INDEX ix_sesion_cajon_terminal ON sesion_cajon USING btree (terminal_id, apertura_ts)
- sesion_cajon_pkey (UNIQUE, PK) — CREATE UNIQUE INDEX sesion_cajon_pkey ON sesion_cajon USING btree (id)
- sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key (UNIQUE) — CREATE UNIQUE INDEX ... (terminal_id, cajero_usuario_id, apertura_ts)

# selemti.precorte

## Columnas
- id: bigint(64,0); nullable=no; default=nextval('precorte_id_seq'::regclass)
- sesion_id: bigint(64,0); nullable=no; default=null
- declarado_efectivo: numeric(12,2); nullable=no; default=0
- declarado_otros: numeric(12,2); nullable=no; default=0
- estatus: text; nullable=no; default='PENDIENTE'::text
- creado_en: timestamp with time zone; nullable=no; default=now()
- creado_por: integer(32,0); nullable=yes; default=null
- ip_cliente: inet; nullable=yes; default=null
- notas: text; nullable=yes; default=null

## PK
- id

## FKs
- sesion_id → selemti.sesion_cajon(id)

## Índices
- idx_precorte_sesion_id — CREATE INDEX ... (sesion_id)
- precorte_pkey (UNIQUE, PK) — CREATE UNIQUE INDEX ... (id)
- precorte_sesion_id_idx — CREATE INDEX ... (sesion_id)

# selemti.precorte_efectivo

## Columnas
- id: bigint(64,0); nullable=no; default=nextval('precorte_efectivo_id_seq'::regclass)
- precorte_id: bigint(64,0); nullable=no; default=null
- denominacion: numeric(12,2); nullable=no; default=null
- cantidad: integer(32,0); nullable=no; default=null
- subtotal: numeric(12,2); nullable=no; default=0

## PK
- id

## FKs
- precorte_id → selemti.precorte(id)

## Índices
- precorte_efectivo_pkey (UNIQUE, PK)

# selemti.precorte_otros

## Columnas
- id: bigint(64,0); nullable=no; default=nextval('precorte_otros_id_seq'::regclass)
- precorte_id: bigint(64,0); nullable=no; default=null
- tipo: text; nullable=no; default=null
- monto: numeric(12,2); nullable=no; default=0
- referencia: text; nullable=yes; default=null
- evidencia_url: text; nullable=yes; default=null
- notas: text; nullable=yes; default=null
- creado_en: timestamp with time zone; nullable=no; default=now()

## PK
- id

## FKs
- precorte_id → selemti.precorte(id)

## Índices
- ix_precorte_otros_precorte — CREATE INDEX ... (precorte_id)
- precorte_otros_pkey (UNIQUE, PK)

# selemti.postcorte

## Columnas
- id: bigint(64,0); nullable=no; default=nextval('postcorte_id_seq'::regclass)
- sesion_id: bigint(64,0); nullable=no; default=null
- sistema_efectivo_esperado: numeric(12,2); nullable=no; default=0
- declarado_efectivo: numeric(12,2); nullable=no; default=0
- diferencia_efectivo: numeric(12,2); nullable=no; default=0
- veredicto_efectivo: text; nullable=no; default='CUADRA'::text
- sistema_tarjetas: numeric(12,2); nullable=no; default=0
- declarado_tarjetas: numeric(12,2); nullable=no; default=0
- diferencia_tarjetas: numeric(12,2); nullable=no; default=0
- veredicto_tarjetas: text; nullable=no; default='CUADRA'::text
- creado_en: timestamp with time zone; nullable=no; default=now()
- creado_por: integer(32,0); nullable=yes; default=null
- notas: text; nullable=yes; default=null
- sistema_transferencias: numeric(12,2); nullable=no; default=0
- declarado_transferencias: numeric(12,2); nullable=no; default=0
- diferencia_transferencias: numeric(12,2); nullable=no; default=0
- veredicto_transferencias: text; nullable=no; default='CUADRA'::text
- validado: boolean; nullable=no; default=false
- validado_por: integer(32,0); nullable=yes; default=null
- validado_en: timestamp with time zone; nullable=yes; default=null

## PK
- id

## FKs
- sesion_id → selemti.sesion_cajon(id)

## Índices
- postcorte_pkey (UNIQUE, PK)
- uq_postcorte_sesion_id (UNIQUE) — (sesion_id)

# public.ticket

## Columnas
- id: integer; nullable=no; default=nextval('ticket_id_seq'::regclass)
- global_id: varchar(16); nullable=yes; default=null
- create_date: timestamp; nullable=yes; default=null
- closing_date: timestamp; nullable=yes; default=null
- active_date: timestamp; nullable=yes; default=null
- deliveery_date: timestamp; nullable=yes; default=null
- creation_hour: integer; nullable=yes; default=null
- paid: boolean; nullable=yes; default=null
- voided: boolean; nullable=yes; default=null
- void_reason: varchar(255); nullable=yes; default=null
- wasted/refunded/settled/drawer_resetted: boolean; nullable=yes; default=null
- sub_total/total_discount/total_tax/total_price/paid_amount/due_amount/advance_amount/adjustment_amount/service_charge/delivery_charge: double precision; nullable=yes; default=null
- number_of_guests: integer; nullable=yes; default=null
- status: varchar(30); nullable=yes; default=null
- bar_tab/is_tax_exempt/is_re_opened: boolean; nullable=yes; default=null
- customer_id/gratuity_id/shift_id/owner_id/driver_id/void_by_user: integer; nullable=yes; default=null
- delivery_address: varchar(120); nullable=yes; default=null
- customer_pickeup: boolean; nullable=yes; default=null
- delivery_extra_info: varchar(255); nullable=yes; default=null
- ticket_type: varchar(20); nullable=yes; default=null
- terminal_id: integer; nullable=yes; default=null
- folio_date: date; nullable=yes; default=null
- branch_key: text; nullable=yes; default=null
- daily_folio: integer; nullable=yes; default=null

## PK
- id

## FKs
- terminal_id → public.terminal(id)
- gratuity_id → public.gratuity(id)
- shift_id → public.shift(id)
- void_by_user/owner_id/driver_id → public.users(auto_id)

## Índices
- ticket_pkey (UNIQUE, PK)
- ticket_global_id_key (UNIQUE) — (global_id)
- ux_ticket_dailyfolio (UNIQUE) — (folio_date, branch_key, daily_folio) WHERE daily_folio IS NOT NULL
- ticketclosingdate — (closing_date)
- idx_ticket_close_term_owner — (closing_date, terminal_id, owner_id)
- creationhour/deliverydate/drawerresetted/ticketactivedate/ticketcreatedate/ticketpaid/ticketsettled/ticketvoided — índices simples de columna

Observaciones clave
- Faltante de índice FK: selemti.precorte_efectivo(precorte_id) → sugerido agregar.
- Ítems duplicados: dos índices sobre selemti.precorte(sesion_id) → mantener uno.
- Preflight: aprovechar índices de closing_date y compuesto; si hay latencia, considerar índice parcial (terminal_id, closing_date) WHERE closing_date IS NULL.

