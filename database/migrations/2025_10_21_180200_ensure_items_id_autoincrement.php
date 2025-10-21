<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades.DB;

return new class extends Migration {
    public function up(): void {
        DB::unprepared(<<<'SQL'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname='items_id_seq') THEN
        CREATE SEQUENCE selemti.items_id_seq START 1;
        PERFORM setval('selemti.items_id_seq', COALESCE((SELECT max(id) FROM selemti.items),0));
    END IF;
END$$;

ALTER TABLE selemti.items
    ALTER COLUMN id SET DEFAULT nextval('selemti.items_id_seq');
SQL);
    }
    public function down(): void {
        DB::unprepared("ALTER TABLE selemti.items ALTER COLUMN id DROP DEFAULT");
    }
};
