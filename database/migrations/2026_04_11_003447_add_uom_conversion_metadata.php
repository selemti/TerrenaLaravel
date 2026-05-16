<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $exists = \Illuminate\Support\Facades\DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='cat_uom_conversion' LIMIT 1"
        );
        if (! $exists) {
            return;
        }

        // PG 9.5 no soporta ADD COLUMN IF NOT EXISTS — usar DO blocks
        \Illuminate\Support\Facades\DB::statement("
            DO \$\$
            BEGIN
                BEGIN ALTER TABLE selemti.cat_uom_conversion ADD COLUMN is_exact BOOLEAN DEFAULT true; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.cat_uom_conversion ADD COLUMN scope VARCHAR(16) DEFAULT 'global'; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.cat_uom_conversion ADD COLUMN notes TEXT; EXCEPTION WHEN duplicate_column THEN NULL; END;
            END
            \$\$
        ");
    }

    public function down(): void
    {
        \Illuminate\Support\Facades\DB::statement("
            DO \$\$
            BEGIN
                BEGIN ALTER TABLE selemti.cat_uom_conversion DROP COLUMN is_exact; EXCEPTION WHEN undefined_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.cat_uom_conversion DROP COLUMN scope; EXCEPTION WHEN undefined_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.cat_uom_conversion DROP COLUMN notes; EXCEPTION WHEN undefined_column THEN NULL; END;
            END
            \$\$
        ");
    }
};
