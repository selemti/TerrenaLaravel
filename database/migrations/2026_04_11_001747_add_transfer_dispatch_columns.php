<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // PG 9.5 does not support ADD COLUMN IF NOT EXISTS — use DO blocks instead
        DB::statement("
            DO \$\$
            BEGIN
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN despachada_por INTEGER; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN despachada_at TIMESTAMP; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN guia VARCHAR(100); EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN recibida_por INTEGER; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN recibida_at TIMESTAMP; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_det ADD COLUMN cantidad_despachada NUMERIC(14,4); EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_det ADD COLUMN cantidad_recibida NUMERIC(14,4); EXCEPTION WHEN duplicate_column THEN NULL; END;
            END
            \$\$
        ");
    }

    public function down(): void
    {
        DB::statement("
            ALTER TABLE selemti.traspaso_cab
            DROP COLUMN IF EXISTS despachada_por,
            DROP COLUMN IF EXISTS despachada_at,
            DROP COLUMN IF EXISTS guia,
            DROP COLUMN IF EXISTS recibida_por,
            DROP COLUMN IF EXISTS recibida_at
        ");

        DB::statement("
            ALTER TABLE selemti.traspaso_det
            DROP COLUMN IF EXISTS cantidad_despachada,
            DROP COLUMN IF EXISTS cantidad_recibida
        ");
    }
};
