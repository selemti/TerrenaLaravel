<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Tabla de log de reversas de consumo POS
     */
    public function up(): void
    {
        DB::connection('pgsql')->statement("
            CREATE TABLE IF NOT EXISTS selemti.pos_reverse_log (
                id BIGSERIAL PRIMARY KEY,
                ticket_id BIGINT NOT NULL,
                user_id BIGINT NOT NULL,
                reversed_at TIMESTAMP NOT NULL DEFAULT NOW(),
                motivo TEXT,
                meta JSONB,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            );
        ");

        // Índices
        DB::connection('pgsql')->statement("
            CREATE INDEX IF NOT EXISTS idx_pos_reverse_log_ticket_id
            ON selemti.pos_reverse_log(ticket_id);
        ");

        DB::connection('pgsql')->statement("
            CREATE INDEX IF NOT EXISTS idx_pos_reverse_log_user_id
            ON selemti.pos_reverse_log(user_id);
        ");

        DB::connection('pgsql')->statement("
            CREATE INDEX IF NOT EXISTS idx_pos_reverse_log_reversed_at
            ON selemti.pos_reverse_log(reversed_at);
        ");

        // Comentarios
        DB::connection('pgsql')->statement("
            COMMENT ON TABLE selemti.pos_reverse_log IS
            'Log de auditoría de reversas de consumo POS';
        ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::connection('pgsql')->statement('DROP TABLE IF EXISTS selemti.pos_reverse_log CASCADE;');
    }
};
