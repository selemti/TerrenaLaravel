-- Solo staging. El trigger POS se difiere al final.
CREATE TABLE IF NOT EXISTS selemti.inv_consumo_pos (
  id bigserial PRIMARY KEY,
  ticket_id bigint NOT NULL,
  ticket_item_id bigint,
  sucursal_id int NOT NULL,
  terminal_id int NOT NULL,
  estado varchar(16) NOT NULL DEFAULT 'PENDIENTE',
  created_at timestamp DEFAULT now(),
  UNIQUE(ticket_id, ticket_item_id)
);
CREATE TABLE IF NOT EXISTS selemti.inv_consumo_pos_det (
  id bigserial PRIMARY KEY,
  consumo_id bigint REFERENCES selemti.inv_consumo_pos(id) ON DELETE CASCADE,
  mp_id int NOT NULL,
  uom_id int,
  cantidad numeric(12,4) NOT NULL,
  factor numeric(12,6) NOT NULL DEFAULT 1,
  origen varchar(16) NOT NULL
);