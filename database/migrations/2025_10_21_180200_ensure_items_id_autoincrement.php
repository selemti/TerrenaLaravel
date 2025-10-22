<?php

return new class extends \Illuminate\Database\Migrations\Migration {
    public function up(): void
    {
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
DECLARE
  v_dtype text;
  v_max   bigint;
BEGIN
  -- Detectar tipo de la columna id
  SELECT data_type
    INTO v_dtype
  FROM information_schema.columns
  WHERE table_schema='selemti'
    AND table_name='items'
    AND column_name='id';

  -- Sólo procedemos si es integer/bigint
  IF v_dtype IN ('bigint','integer') THEN

    -- Crear secuencia si no existe
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname='items_id_seq') THEN
      EXECUTE 'CREATE SEQUENCE selemti.items_id_seq START 1';
    END IF;

    -- Obtener el max(id) de forma segura
    SELECT max(id)::bigint INTO v_max FROM selemti.items;
    IF v_max IS NULL THEN
      v_max := 0;
    END IF;

    -- Ajustar la secuencia al máximo actual
    PERFORM setval('selemti.items_id_seq'::regclass, v_max, true);

    -- Poner default nextval() a la columna
    EXECUTE 'ALTER TABLE selemti.items
             ALTER COLUMN id SET DEFAULT nextval(''selemti.items_id_seq'')';
  END IF;
END$$;
SQL);
    }

    public function down(): void
    {
        // Quitamos el default si existía; dejamos la secuencia quieta
        \Illuminate\Support\Facades\DB::unprepared(<<<'SQL'
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='selemti' AND table_name='items' AND column_name='id'
  ) THEN
    EXECUTE 'ALTER TABLE selemti.items ALTER COLUMN id DROP DEFAULT';
  END IF;
END$$;
SQL);
    }
};
