CREATE TABLE IF NOT EXISTS selemti.transfer_cab (
  id bigserial PRIMARY KEY,
  origen_almacen_id int NOT NULL,
  destino_almacen_id int NOT NULL,
  estado varchar(16) NOT NULL DEFAULT 'CREADA',
  creada_por int NOT NULL,
  despachada_por int,
  recibida_por int,
  guia varchar(64),
  created_at timestamp DEFAULT now()
);
CREATE TABLE IF NOT EXISTS selemti.transfer_det (
  id bigserial PRIMARY KEY,
  transfer_id bigint REFERENCES selemti.transfer_cab(id) ON DELETE CASCADE,
  item_id int NOT NULL,
  cantidad numeric(12,3) NOT NULL,
  cantidad_despachada numeric(12,3),
  cantidad_recibida numeric(12,3),
  created_at timestamp DEFAULT now()
);