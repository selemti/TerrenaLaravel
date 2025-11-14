<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        $needsFecha = ! $this->columnExists('fecha_requerida');
        $needsAlmacen = ! $this->columnExists('almacen_destino_id');
        $needsJustificacion = ! $this->columnExists('justificacion');
        $needsUrgente = ! $this->columnExists('urgente');
        $needsOrigen = ! $this->columnExists('origen_suggestion_id');

        if ($needsFecha || $needsAlmacen || $needsJustificacion || $needsUrgente || $needsOrigen) {
            $schema->table('selemti.purchase_requests', function (Blueprint $table) use (
                $needsFecha,
                $needsAlmacen,
                $needsJustificacion,
                $needsUrgente,
                $needsOrigen
            ) {
                if ($needsFecha) {
                    $table->date('fecha_requerida')->nullable()
                        ->comment('Fecha límite en que se necesita el material');
                }

                if ($needsAlmacen) {
                    $table->bigInteger('almacen_destino_id')->nullable()
                        ->comment('FK a selemti.cat_almacenes - Dónde se recibirá');
                }

                if ($needsJustificacion) {
                    $table->text('justificacion')->nullable()
                        ->comment('Por qué se solicita (ej: stock bajo, evento especial)');
                }

                if ($needsUrgente) {
                    $table->boolean('urgente')->default(false)
                        ->comment('Marca de urgencia operativa');
                }

                if ($needsOrigen) {
                    $table->bigInteger('origen_suggestion_id')->nullable()
                        ->comment('FK a purchase_suggestions - si fue generada automáticamente');
                }
            });
        }

        if ($needsAlmacen && ! $this->foreignExists('fk_preq_almacen_destino')) {
            $schema->table('selemti.purchase_requests', function (Blueprint $table) {
                $table->foreign('almacen_destino_id', 'fk_preq_almacen_destino')
                    ->references('id')
                    ->on('selemti.cat_almacenes')
                    ->onDelete('set null');
            });
        }

        if ($needsOrigen && ! $this->foreignExists('fk_preq_suggestion')) {
            $schema->table('selemti.purchase_requests', function (Blueprint $table) {
                $table->foreign('origen_suggestion_id', 'fk_preq_suggestion')
                    ->references('id')
                    ->on('selemti.purchase_suggestions')
                    ->onDelete('set null');
            });
        }

        if ($needsFecha && ! $this->indexExists('idx_preq_fecha_requerida')) {
            $schema->table('selemti.purchase_requests', function (Blueprint $table) {
                $table->index('fecha_requerida', 'idx_preq_fecha_requerida');
            });
        }

        if ($needsUrgente && ! $this->indexExists('idx_preq_urgente')) {
            $schema->table('selemti.purchase_requests', function (Blueprint $table) {
                $table->index('urgente', 'idx_preq_urgente');
            });
        }

        if ($this->columnExists('fecha_requerida')) {
            DB::statement("COMMENT ON COLUMN selemti.purchase_requests.fecha_requerida IS 'Fecha límite operativa'");
        }
        if ($this->columnExists('almacen_destino_id')) {
            DB::statement("COMMENT ON COLUMN selemti.purchase_requests.almacen_destino_id IS 'Almacén que recibirá el material'");
        }
    }

    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        if ($this->foreignExists('fk_preq_almacen_destino')) {
            $schema->table('selemti.purchase_requests', function (Blueprint $table) {
                $table->dropForeign('fk_preq_almacen_destino');
            });
        }

        if ($this->foreignExists('fk_preq_suggestion')) {
            $schema->table('selemti.purchase_requests', function (Blueprint $table) {
                $table->dropForeign('fk_preq_suggestion');
            });
        }

        foreach (['idx_preq_fecha_requerida', 'idx_preq_urgente'] as $index) {
            if ($this->indexExists($index)) {
                $schema->table('selemti.purchase_requests', function (Blueprint $table) use ($index) {
                    $table->dropIndex($index);
                });
            }
        }

        $columns = array_filter([
            $this->columnExists('fecha_requerida') ? 'fecha_requerida' : null,
            $this->columnExists('almacen_destino_id') ? 'almacen_destino_id' : null,
            $this->columnExists('justificacion') ? 'justificacion' : null,
            $this->columnExists('urgente') ? 'urgente' : null,
            $this->columnExists('origen_suggestion_id') ? 'origen_suggestion_id' : null,
        ]);

        if (! empty($columns)) {
            $schema->table('selemti.purchase_requests', function (Blueprint $table) use ($columns) {
                $table->dropColumn($columns);
            });
        }
    }

    protected function columnExists(string $column): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<'SQL'
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'selemti'
              AND table_name = 'purchase_requests'
              AND column_name = ?
            LIMIT 1
            SQL,
            [$column]
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

    protected function foreignExists(string $constraint): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            'SELECT 1 FROM pg_constraint WHERE conname = ? LIMIT 1',
            [$constraint]
        );

        return ! empty($result);
    }
};
