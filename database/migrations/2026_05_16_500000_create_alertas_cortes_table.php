<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
            DO $$ BEGIN
                CREATE TABLE selemti.alertas_cortes (
                    id              BIGSERIAL PRIMARY KEY,
                    postcorte_id    BIGINT,
                    sesion_id       BIGINT,
                    tipo            VARCHAR(50) NOT NULL DEFAULT 'REQUIERE_APROBACION',
                    destinatario_id BIGINT NOT NULL,
                    leida           BOOLEAN NOT NULL DEFAULT FALSE,
                    leida_en        TIMESTAMP,
                    creada_en       TIMESTAMP NOT NULL DEFAULT NOW()
                );
                CREATE INDEX alertas_cortes_destinatario_leida_idx
                    ON selemti.alertas_cortes (destinatario_id, leida);
            EXCEPTION WHEN duplicate_table THEN NULL;
            END $$;
        SQL);
    }

    public function down(): void
    {
        DB::connection('pgsql')->unprepared(
            'DROP TABLE IF EXISTS selemti.alertas_cortes;'
        );
    }
};
