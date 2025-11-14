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
        $schema = Schema::connection('pgsql');

        $needsEstado = ! $this->columnExists('estado');
        $needsPresentaciones = ! $this->columnExists('total_presentaciones');
        $needsCanonico = ! $this->columnExists('total_canonico');

        if (! $needsEstado && ! $needsPresentaciones && ! $needsCanonico) {
            return;
        }

        $schema->table('selemti.recepcion_cab', function (Blueprint $table) use ($needsEstado, $needsPresentaciones, $needsCanonico) {
            if ($needsEstado) {
                $table->string('estado')->nullable()->after('fecha_recepcion');
            }
            if ($needsPresentaciones) {
                $table->decimal('total_presentaciones', 15, 4)->nullable()->after('estado');
            }
            if ($needsCanonico) {
                $table->decimal('total_canonico', 15, 4)->nullable()->after($needsPresentaciones ? 'total_presentaciones' : 'estado');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        $columns = array_filter([
            $this->columnExists('estado') ? 'estado' : null,
            $this->columnExists('total_presentaciones') ? 'total_presentaciones' : null,
            $this->columnExists('total_canonico') ? 'total_canonico' : null,
        ]);

        if (empty($columns)) {
            return;
        }

        $schema->table('selemti.recepcion_cab', function (Blueprint $table) use ($columns) {
            $table->dropColumn($columns);
        });
    }

    protected function columnExists(string $column): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<'SQL'
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema IN ('selemti', 'public')
              AND table_name = 'recepcion_cab'
              AND column_name = ?
            LIMIT 1
            SQL,
            [$column]
        );

        return ! empty($result);
    }
};
