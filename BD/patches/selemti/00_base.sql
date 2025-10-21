-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
CREATE TYPE consumo_policy AS ENUM (
    'FEFO',
    'PEPS'
);


ALTER TYPE consumo_policy OWNER TO postgres;

CREATE TYPE lote_estado AS ENUM (
    'ACTIVO',
    'BLOQUEADO',
    'RECALL'
);


ALTER TYPE lote_estado OWNER TO postgres;

CREATE TYPE merma_clase AS ENUM (
    'MERMA',
    'DESPERDICIO'
);


ALTER TYPE merma_clase OWNER TO postgres;

CREATE TYPE merma_tipo AS ENUM (
    'PROCESO',
    'OPERATIVA'
);


ALTER TYPE merma_tipo OWNER TO postgres;

CREATE TYPE mov_tipo AS ENUM (
    'RECEPCION',
    'COMPRA',
    'VENTA',
    'CONSUMO_OP',
    'AJUSTE',
    'TRASPASO_IN',
    'TRASPASO_OUT',
    'ANULACION'
);


ALTER TYPE mov_tipo OWNER TO postgres;

CREATE TYPE op_estado AS ENUM (
    'ABIERTA',
    'EN_PROCESO',
    'CERRADA',
    'ANULADA'
);


ALTER TYPE op_estado OWNER TO postgres;

CREATE TYPE producto_tipo AS ENUM (
    'MATERIA_PRIMA',
    'ELABORADO',
    'ENVASADO'
);


ALTER TYPE producto_tipo OWNER TO postgres;

SET search_path = public, pg_catalog;

COMMIT;
