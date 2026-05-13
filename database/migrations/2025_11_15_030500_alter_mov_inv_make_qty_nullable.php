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

        DB::connection('pgsql')->statement("
            DO \$\$
            BEGIN
                BEGIN ALTER TABLE selemti.mov_inv ALTER COLUMN qty DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
                BEGIN ALTER TABLE selemti.mov_inv ALTER COLUMN uom DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
                BEGIN ALTER TABLE selemti.mov_inv ALTER COLUMN tipo DROP NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
            END
            \$\$
        ");
    }

    public function down(): void {}
};
