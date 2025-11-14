
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! $this->tableExists()) {
            return;
        }

        $needsClave = ! $this->columnExists('clave');
        $needsNombre = ! $this->columnExists('nombre');
        $needsActivo = ! $this->columnExists('activo');
        $needsCreated = ! $this->columnExists('created_at');
        $needsUpdated = ! $this->columnExists('updated_at');

        if ($needsClave || $needsNombre || $needsActivo || $needsCreated || $needsUpdated) {
            Schema::connection('pgsql')->table('selemti.cat_unidades', function (Blueprint $table) use ($needsClave, $needsNombre, $needsActivo, $needsCreated, $needsUpdated) {
                if ($needsClave) {
                    $table->string('clave', 16)->nullable()->after('id');
                }

                if ($needsNombre) {
                    $table->string('nombre', 64)->nullable();
                }

                if ($needsActivo) {
                    $table->boolean('activo')->default(true);
                }

                if ($needsCreated && $needsUpdated) {
                    $table->timestamps();
                } elseif ($needsCreated) {
                    $table->timestamp('created_at')->nullable();
                } elseif ($needsUpdated) {
                    $table->timestamp('updated_at')->nullable();
                }
            });
        }

        if ($needsClave && $this->columnExists('codigo')) {
            DB::connection('pgsql')->statement('UPDATE selemti.cat_unidades SET clave = codigo WHERE clave IS NULL AND codigo IS NOT NULL');
        }

        if ($needsNombre) {
            if ($this->columnExists('descripcion')) {
                DB::connection('pgsql')->statement('UPDATE selemti.cat_unidades SET nombre = descripcion WHERE nombre IS NULL AND descripcion IS NOT NULL');
            } elseif ($this->columnExists('detalle')) {
                DB::connection('pgsql')->statement('UPDATE selemti.cat_unidades SET nombre = detalle WHERE nombre IS NULL AND detalle IS NOT NULL');
            }
        }

        if ($needsClave && ! $this->indexExists('cat_unidades_clave_unique')) {
            Schema::connection('pgsql')->table('selemti.cat_unidades', function (Blueprint $table) {
                $table->unique('clave');
            });
        }
    }

    public function down(): void
    {
        if (! $this->tableExists()) {
            return;
        }

        Schema::connection('pgsql')->table('selemti.cat_unidades', function (Blueprint $table) {
            if ($this->indexExists('cat_unidades_clave_unique')) {
                $table->dropUnique('cat_unidades_clave_unique');
            }

            foreach (['clave', 'nombre', 'activo'] as $column) {
                if ($this->columnExists($column)) {
                    $table->dropColumn($column);
                }
            }

            if ($this->columnExists('created_at') || $this->columnExists('updated_at')) {
                $table->dropTimestamps();
            }
        });
    }

    private function tableExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT to_regclass('selemti.cat_unidades') AS regclass"
        );

        return ! empty($result?->regclass);
    }

    private function columnExists(string $column): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            <<<'SQL'
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'selemti'
              AND table_name = 'cat_unidades'
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
