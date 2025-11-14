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
        if ($this->columnExists()) {
            return;
        }

        Schema::connection('pgsql')->table('selemti.recepcion_cab', function (Blueprint $table) {
            $table->date('fecha_recepcion')->nullable()->after('numero_recepcion');
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
            $table->dropColumn('fecha_recepcion');
        });
    }

    protected function columnExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<'SQL'
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema IN ('selemti', 'public')
              AND table_name = 'recepcion_cab'
              AND column_name = 'fecha_recepcion'
            LIMIT 1
            SQL
        );

        return ! empty($result);
    }
};
