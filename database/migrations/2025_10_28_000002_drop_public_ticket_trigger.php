<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::connection('pgsql')->unprepared(<<<'SQL'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_ticket_inventory_consumption'
    ) THEN
        DROP TRIGGER trg_ticket_inventory_consumption ON public.ticket;
    END IF;
END;
$$;
SQL);
    }

    public function down(): void
    {
        // Política A: no se recrea el trigger automáticamente.
    }
};
