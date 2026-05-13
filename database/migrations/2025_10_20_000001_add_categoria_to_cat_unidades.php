<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->statement("
            DO \$\$
            BEGIN
                BEGIN
                    ALTER TABLE selemti.cat_unidades ADD COLUMN categoria VARCHAR(20) NULL;
                EXCEPTION WHEN duplicate_column THEN NULL;
                END;
            END
            \$\$
        ");
    }

    public function down(): void
    {
        DB::connection('pgsql')->statement('ALTER TABLE selemti.cat_unidades DROP COLUMN IF EXISTS categoria');
    }
};
