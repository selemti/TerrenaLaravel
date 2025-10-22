<?php

return new class extends \Illuminate\Database\Migrations\Migration {
    public function up(): void
    {
        // === COLUMNS (compatibles con PG antiguo) ===
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='razon_social'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN razon_social VARCHAR(200);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='rfc'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN rfc VARCHAR(20);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='tipo_comprobante'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN tipo_comprobante VARCHAR(10);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='uso_cfdi'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN uso_cfdi VARCHAR(10);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='metodo_pago'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN metodo_pago VARCHAR(10);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='forma_pago'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN forma_pago VARCHAR(10);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='regimen_fiscal'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN regimen_fiscal VARCHAR(10);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='contacto_nombre'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN contacto_nombre VARCHAR(150);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='contacto_email'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN contacto_email VARCHAR(150);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='contacto_telefono'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN contacto_telefono VARCHAR(50);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='direccion'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN direccion VARCHAR(255);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='ciudad'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN ciudad VARCHAR(120);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='estado'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN estado VARCHAR(120);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='pais'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN pais VARCHAR(120);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='cp'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN cp VARCHAR(12);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='notas'
) THEN
  ALTER TABLE selemti.cat_proveedores ADD COLUMN notas TEXT;
END IF;
END$$;
SQL);

        // === INDEXES ===
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='idx_prov_razon_social'
) THEN
  CREATE INDEX idx_prov_razon_social ON selemti.cat_proveedores(razon_social);
END IF;
END$$;
SQL);

        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
IF NOT EXISTS (
  SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='idx_prov_rfc'
) THEN
  CREATE INDEX idx_prov_rfc ON selemti.cat_proveedores(rfc);
END IF;
END$$;
SQL);
    }

    public function down(): void
    {
        // Indexes (con chequeo)
        \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.idx_prov_razon_social");
        \Illuminate\Support\Facades\DB::unprepared("DROP INDEX IF EXISTS selemti.idx_prov_rfc");

        // Columns (con chequeo por compatibilidad)
        foreach ([
            'razon_social','rfc','tipo_comprobante','uso_cfdi','metodo_pago','forma_pago',
            'regimen_fiscal','contacto_nombre','contacto_email','contacto_telefono',
            'direccion','ciudad','estado','pais','cp','notas'
        ] as $col) {
            \Illuminate\Support\Facades\DB::unprepared("
DO $$
BEGIN
IF EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='selemti' AND table_name='cat_proveedores' AND column_name='{$col}'
) THEN
  ALTER TABLE selemti.cat_proveedores DROP COLUMN {$col};
END IF;
END$$;");
        }
    }
};
