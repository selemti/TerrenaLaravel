<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void {
        DB::unprepared(<<<'SQL'
ALTER TABLE selemti.cat_proveedores
  ADD COLUMN IF NOT EXISTS razon_social      VARCHAR(200),
  ADD COLUMN IF NOT EXISTS rfc               VARCHAR(20),
  ADD COLUMN IF NOT EXISTS tipo_comprobante  VARCHAR(10),
  ADD COLUMN IF NOT EXISTS uso_cfdi          VARCHAR(10),
  ADD COLUMN IF NOT EXISTS metodo_pago       VARCHAR(10),
  ADD COLUMN IF NOT EXISTS forma_pago        VARCHAR(10),
  ADD COLUMN IF NOT EXISTS regimen_fiscal    VARCHAR(10),
  ADD COLUMN IF NOT EXISTS contacto_nombre   VARCHAR(150),
  ADD COLUMN IF NOT EXISTS contacto_email    VARCHAR(150),
  ADD COLUMN IF NOT EXISTS contacto_telefono VARCHAR(50),
  ADD COLUMN IF NOT EXISTS direccion         VARCHAR(255),
  ADD COLUMN IF NOT EXISTS ciudad           VARCHAR(120),
  ADD COLUMN IF NOT EXISTS estado           VARCHAR(120),
  ADD COLUMN IF NOT EXISTS pais              VARCHAR(120),
  ADD COLUMN IF NOT EXISTS cp                VARCHAR(12),
  ADD COLUMN IF NOT EXISTS notas            TEXT;
CREATE INDEX IF NOT EXISTS idx_prov_razon_social ON selemti.cat_proveedores(razon_social);
CREATE INDEX IF NOT EXISTS idx_prov_rfc ON selemti.cat_proveedores(rfc);
SQL);
    }
    public function down(): void {
        DB::unprepared(<<<'SQL'
DROP INDEX IF EXISTS selemti.idx_prov_razon_social;
DROP INDEX IF EXISTS selemti.idx_prov_rfc;
ALTER TABLE selemti.cat_proveedores
  DROP COLUMN IF EXISTS razon_social,
  DROP COLUMN IF EXISTS rfc,
  DROP COLUMN IF EXISTS tipo_comprobante,
  DROP COLUMN IF EXISTS uso_cfdi,
  DROP COLUMN IF EXISTS metodo_pago,
  DROP COLUMN IF EXISTS forma_pago,
  DROP COLUMN IF EXISTS regimen_fiscal,
  DROP COLUMN IF EXISTS contacto_nombre,
  DROP COLUMN IF EXISTS contacto_email,
  DROP COLUMN IF EXISTS contacto_telefono,
  DROP COLUMN IF EXISTS direccion,
  DROP COLUMN IF EXISTS ciudad,
  DROP COLUMN IF EXISTS estado,
  DROP COLUMN IF EXISTS pais,
  DROP COLUMN IF EXISTS cp,
  DROP COLUMN IF EXISTS notas;
SQL);
    }
};
