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

        Schema::connection('pgsql')->table('selemti.cash_funds', function (Blueprint $table) {
            $table->string('descripcion', 255)->nullable()->after('moneda')
                ->comment('Descripción o nombre del fondo para identificación rápida');
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

        Schema::connection('pgsql')->table('selemti.cash_funds', function (Blueprint $table) {
            if ($this->columnExists()) {
                $table->dropColumn('descripcion');
            }
        });
    }

    protected function columnExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<'SQL'
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'selemti'
              AND table_name = 'cash_funds'
              AND column_name = 'descripcion'
            LIMIT 1
            SQL
        );

        return ! empty($result);
    }
};
