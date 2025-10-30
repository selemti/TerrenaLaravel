<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Tabla de log de reprocesos de consumo POS
     */
    public function up(): void
    {
        DB::connection('pgsql')->statement("
            CREATE TABLE IF NOT EXISTS selemti.pos_reprocess_log (
                id BIGSERIAL PRIMARY KEY,
                ticket_id BIGINT NOT NULL,
                user_id BIGINT NOT NULL,
                reprocessed_at TIMESTAMP NOT NULL DEFAULT NOW(),
                motivo TEXT,
                meta JSONB,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            );
        ");

        // Índices
        DB::connection('pgsql')->statement("
            CREATE INDEX IF NOT EXISTS idx_pos_reprocess_log_ticket_id
            ON selemti.pos_reprocess_log(ticket_id);
        ");

        DB::connection('pgsql')->statement("
            CREATE INDEX IF NOT EXISTS idx_pos_reprocess_log_user_id
            ON selemti.pos_reprocess_log(user_id);
        ");

        DB::connection('pgsql')->statement("
            CREATE INDEX IF NOT EXISTS idx_pos_reprocess_log_reprocessed_at
            ON selemti.pos_reprocess_log(reprocessed_at);
        ");

        // Comentarios
        DB::connection('pgsql')->statement("
            COMMENT ON TABLE selemti.pos_reprocess_log IS
            'Log de auditoría de reprocesos de consumo POS histórico';
        ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS selemti.pos_reprocess_log CASCADE;');
    }
};
