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
        if (! $this->tableExists('recepcion_cab') || $this->columnExists('almacen_id')) {
            return;
        }

        Schema::connection('pgsql')->table('selemti.recepcion_cab', function (Blueprint $table) {
            $table->string('almacen_id', 36)->nullable()->after('sucursal_id');
            $table->index('almacen_id', 'idx_recepcion_cab_almacen');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! $this->tableExists('recepcion_cab') || ! $this->columnExists('almacen_id')) {
            return;
        }

        Schema::connection('pgsql')->table('selemti.recepcion_cab', function (Blueprint $table) {
            if ($this->indexExists('idx_recepcion_cab_almacen')) {
                $table->dropIndex('idx_recepcion_cab_almacen');
            }
            $table->dropColumn('almacen_id');
        });
    }

    private function tableExists(string $table): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT to_regclass('selemti.' || ?) AS regclass",
            [$table]
        );

        return ! empty($result?->regclass);
    }

    private function columnExists(string $column): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<SQL
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'selemti'
              AND table_name = 'recepcion_cab'
              AND column_name = ?
            LIMIT 1
            SQL,
            [$column]
        );

        return ! empty($result);
    }

    private function indexExists(string $index): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM pg_indexes WHERE schemaname = 'selemti' AND indexname = ? LIMIT 1",
            [$index]
        );

        return ! empty($result);
    }
};
