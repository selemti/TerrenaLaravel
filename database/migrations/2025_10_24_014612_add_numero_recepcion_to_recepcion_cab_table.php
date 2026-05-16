<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! $this->tableExists() || $this->columnExists()) {
            return;
        }

        Schema::connection('pgsql')->table('selemti.recepcion_cab', function (Blueprint $table) {
            $table->string('numero_recepcion')->nullable()->after('id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! $this->columnExists()) {
            return;
        }

        Schema::connection('pgsql')->table('selemti.recepcion_cab', function (Blueprint $table) {
            $table->dropColumn('numero_recepcion');
        });
    }

    protected function tableExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='recepcion_cab' LIMIT 1"
        );
        return ! empty($result);
    }

    protected function columnExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<'SQL'
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema IN ('selemti', 'public')
              AND table_name = 'recepcion_cab'
              AND column_name = 'numero_recepcion'
            LIMIT 1
            SQL
        );

        return ! empty($result);
    }
};
