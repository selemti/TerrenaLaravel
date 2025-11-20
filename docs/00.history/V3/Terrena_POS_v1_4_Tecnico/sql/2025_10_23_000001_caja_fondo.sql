CREATE SCHEMA IF NOT EXISTS selemti;
CREATE TABLE IF NOT EXISTS selemti.caja_fondo (
  id bigserial PRIMARY KEY,
  sucursal_id int NOT NULL,
  fecha date NOT NULL,
  monto_inicial numeric(12,2) NOT NULL,
  moneda varchar(3) DEFAULT 'MXN',
  estado varchar(16) NOT NULL DEFAULT 'ABIERTO',
  creado_por int NOT NULL,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);
CREATE TABLE IF NOT EXISTS selemti.caja_fondo_usuario (
  fondo_id bigint REFERENCES selemti.caja_fondo(id) ON DELETE CASCADE,
  user_id int NOT NULL,
  rol varchar(16) NOT NULL,
  PRIMARY KEY (fondo_id, user_id)
);
CREATE TABLE IF NOT EXISTS selemti.caja_fondo_mov (
  id bigserial PRIMARY KEY,
  fondo_id bigint REFERENCES selemti.caja_fondo(id) ON DELETE CASCADE,
  fecha_hora timestamp NOT NULL DEFAULT now(),
  tipo varchar(16) NOT NULL,
  concepto text NOT NULL,
  proveedor_id int,
  monto numeric(12,2) NOT NULL,
  metodo varchar(16) NOT NULL DEFAULT 'EFECTIVO',
  requiere_comprobante boolean DEFAULT false,
  estatus varchar(16) NOT NULL DEFAULT 'CAPTURADO',
  creado_por int NOT NULL,
  aprobado_por int,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);
CREATE TABLE IF NOT EXISTS selemti.caja_fondo_adj (
  id bigserial PRIMARY KEY,
  mov_id bigint REFERENCES selemti.caja_fondo_mov(id) ON DELETE CASCADE,
  tipo varchar(16) NOT NULL,
  archivo_url text NOT NULL,
  observaciones text,
  created_at timestamp DEFAULT now()
);
CREATE TABLE IF NOT EXISTS selemti.caja_fondo_arqueo (
  id bigserial PRIMARY KEY,
  fondo_id bigint REFERENCES selemti.caja_fondo(id) ON DELETE CASCADE,
  fecha_cierre timestamp NOT NULL DEFAULT now(),
  efectivo_contado numeric(12,2) NOT NULL,
  diferencia numeric(12,2) NOT NULL,
  observaciones text,
  cerrado_por int NOT NULL
);