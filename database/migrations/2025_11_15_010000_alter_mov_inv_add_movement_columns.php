<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $exists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='mov_inv' LIMIT 1"
        );
        if (! $exists) {
            return;
        }

        // Add columns used by the Movement model that the original CREATE migration may be missing
        DB::connection('pgsql')->statement("
            DO \$\$
            BEGIN
                BEGIN ALTER TABLE selemti.mov_inv ADD COLUMN cantidad NUMERIC(18,6); EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.mov_inv ADD COLUMN qty_original NUMERIC(18,6); EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.mov_inv ADD COLUMN lote_id BIGINT; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.mov_inv ADD COLUMN usuario_id BIGINT; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.mov_inv ADD COLUMN uom_original_id BIGINT; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.mov_inv ADD COLUMN costo_unit NUMERIC(14,4); EXCEPTION WHEN duplicate_column THEN NULL; END;
            END
            \$\$
        ");
    }

    public function down(): void {}
};
