CREATE TABLE IF NOT EXISTS selemti.sol_prod_cab (
  id bigserial PRIMARY KEY,
  sucursal_id int NOT NULL,
  fecha date NOT NULL DEFAULT current_date,
  estado varchar(16) NOT NULL DEFAULT 'SOLICITADA',
  solicitada_por int NOT NULL,
  autorizada_por int,
  observaciones text,
  created_at timestamp DEFAULT now()
);
CREATE TABLE IF NOT EXISTS selemti.sol_prod_det (
  id bigserial PRIMARY KEY,
  sol_id bigint REFERENCES selemti.sol_prod_cab(id) ON DELETE CASCADE,
  plu int NOT NULL,
  cantidad numeric(12,3) NOT NULL,
  cantidad_autorizada numeric(12,3),
  created_at timestamp DEFAULT now()
);
CREATE TABLE IF NOT EXISTS selemti.prod_cab (
  id bigserial PRIMARY KEY,
  sol_id bigint REFERENCES selemti.sol_prod_cab(id),
  fecha_programada date NOT NULL,
  estado varchar(16) NOT NULL DEFAULT 'PROGRAMADA',
  creada_por int NOT NULL,
  aprobada_por int,
  created_at timestamp DEFAULT now()
);
CREATE TABLE IF NOT EXISTS selemti.prod_det (
  id bigserial PRIMARY KEY,
  prod_id bigint REFERENCES selemti.prod_cab(id) ON DELETE CASCADE,
  sr_id int NOT NULL,
  cantidad numeric(12,3) NOT NULL,
  rendimiento numeric(12,3),
  created_at timestamp DEFAULT now()
);