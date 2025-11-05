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
        Schema::connection('pgsql')->table('selemti.inv_consumo_pos', function (Blueprint $table) {
            if (! $this->columnExists('inv_consumo_pos', 'requiere_reproceso')) {
                $table->boolean('requiere_reproceso')
                    ->default(true)
                    ->comment('Pendiente de reprocesar')
                    ->index('inv_consumo_pos_requiere_reproceso_idx');
            }
            if (! $this->columnExists('inv_consumo_pos', 'procesado')) {
                $table->boolean('procesado')
                    ->default(false)
                    ->comment('Consumo confirmado')
                    ->index('inv_consumo_pos_procesado_idx');
            }
            if (! $this->columnExists('inv_consumo_pos', 'fecha_proceso')) {
                $table->timestamp('fecha_proceso')
                    ->nullable()
                    ->comment('Momento del procesamiento');
            }
            if (! $this->columnExists('inv_consumo_pos', 'revertido')) {
                $table->boolean('revertido')
                    ->default(false)
                    ->comment('Consumo revertido/anulado')
                    ->index('inv_consumo_pos_revertido_idx');
            }
        });

        Schema::connection('pgsql')->table('selemti.inv_consumo_pos_det', function (Blueprint $table) {
            if (! $this->columnExists('inv_consumo_pos_det', 'requiere_reproceso')) {
                $table->boolean('requiere_reproceso')
                    ->default(true)
                    ->index('inv_consumo_pos_det_requiere_reproceso_idx');
            }
            if (! $this->columnExists('inv_consumo_pos_det', 'procesado')) {
                $table->boolean('procesado')
                    ->default(false)
                    ->index('inv_consumo_pos_det_procesado_idx');
            }
            if (! $this->columnExists('inv_consumo_pos_det', 'fecha_proceso')) {
                $table->timestamp('fecha_proceso')
                    ->nullable();
            }
            if (! $this->columnExists('inv_consumo_pos_det', 'revertido')) {
                $table->boolean('revertido')
                    ->default(false)
                    ->index('inv_consumo_pos_det_revertido_idx');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->table('selemti.inv_consumo_pos', function (Blueprint $table) {
            if ($this->indexExists('inv_consumo_pos_revertido_idx')) {
                $table->dropIndex('inv_consumo_pos_revertido_idx');
            }
            if ($this->indexExists('inv_consumo_pos_requiere_reproceso_idx')) {
                $table->dropIndex('inv_consumo_pos_requiere_reproceso_idx');
            }
            if ($this->indexExists('inv_consumo_pos_procesado_idx')) {
                $table->dropIndex('inv_consumo_pos_procesado_idx');
            }

            $columns = array_filter([
                $this->columnExists('inv_consumo_pos', 'requiere_reproceso') ? 'requiere_reproceso' : null,
                $this->columnExists('inv_consumo_pos', 'procesado') ? 'procesado' : null,
                $this->columnExists('inv_consumo_pos', 'fecha_proceso') ? 'fecha_proceso' : null,
                $this->columnExists('inv_consumo_pos', 'revertido') ? 'revertido' : null,
            ]);

            if (!empty($columns)) {
                $table->dropColumn($columns);
            }
        });

        Schema::connection('pgsql')->table('selemti.inv_consumo_pos_det', function (Blueprint $table) {
            if ($this->indexExists('inv_consumo_pos_det_revertido_idx')) {
                $table->dropIndex('inv_consumo_pos_det_revertido_idx');
            }
            if ($this->indexExists('inv_consumo_pos_det_requiere_reproceso_idx')) {
                $table->dropIndex('inv_consumo_pos_det_requiere_reproceso_idx');
            }
            if ($this->indexExists('inv_consumo_pos_det_procesado_idx')) {
                $table->dropIndex('inv_consumo_pos_det_procesado_idx');
            }

            $columns = array_filter([
                $this->columnExists('inv_consumo_pos_det', 'requiere_reproceso') ? 'requiere_reproceso' : null,
                $this->columnExists('inv_consumo_pos_det', 'procesado') ? 'procesado' : null,
                $this->columnExists('inv_consumo_pos_det', 'fecha_proceso') ? 'fecha_proceso' : null,
                $this->columnExists('inv_consumo_pos_det', 'revertido') ? 'revertido' : null,
            ]);

            if (!empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }

    protected function columnExists(string $table, string $column): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<SQL
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'selemti'
              AND table_name = ?
              AND column_name = ?
            LIMIT 1
            SQL,
            [$table, $column]
        );

        return ! empty($result);
    }

    protected function indexExists(string $index): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM pg_indexes WHERE schemaname = 'selemti' AND indexname = ? LIMIT 1",
            [$index]
        );

        return ! empty($result);
    }
};
