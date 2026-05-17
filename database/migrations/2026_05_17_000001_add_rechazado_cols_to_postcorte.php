<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Columnas presentes en producción pero que faltan en local
        // rechazado_por y rechazado_en: se agregan al schema de postcorte
        DB::connection('pgsql')->unprepared('
            DO $body$
            BEGIN
                BEGIN
                    ALTER TABLE selemti.postcorte ADD COLUMN rechazado_por INTEGER;
                EXCEPTION WHEN duplicate_column THEN NULL;
                END;
                BEGIN
                    ALTER TABLE selemti.postcorte ADD COLUMN rechazado_en TIMESTAMPTZ;
                EXCEPTION WHEN duplicate_column THEN NULL;
                END;
            END
            $body$
        ');
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared('
            ALTER TABLE selemti.postcorte
                DROP COLUMN IF EXISTS rechazado_por,
                DROP COLUMN IF EXISTS rechazado_en
        ');
    }
};
