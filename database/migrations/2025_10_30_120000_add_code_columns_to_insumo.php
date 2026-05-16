<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        $tableCheck = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='insumo' LIMIT 1"
        );
        if (! $tableCheck) {
            return;
        }

        // Verificar cuáles columnas ya existen
        $needsCodigo = ! $this->columnExists('codigo');
        $needsCategoria = ! $this->columnExists('categoria_codigo');
        $needsSubcategoria = ! $this->columnExists('subcategoria_codigo');
        $needsConsecutivo = ! $this->columnExists('consecutivo');
        $needsUniqueIndex = ! $this->indexExists('insumo_codigo_unique');
        $needsCatIndex = ! $this->indexExists('insumo_cat_sub_cons_idx');

        if (!$needsCodigo && !$needsCategoria && !$needsSubcategoria && !$needsConsecutivo && !$needsUniqueIndex && !$needsCatIndex) {
            return; // Todas las columnas e índices ya existen
        }

        Schema::table('insumo', function (Blueprint $table) use ($needsCodigo, $needsCategoria, $needsSubcategoria, $needsConsecutivo, $needsUniqueIndex, $needsCatIndex) {
            if ($needsCodigo) {
                $table->string('codigo', 20)->nullable();
            }
            if ($needsCategoria) {
                $table->string('categoria_codigo', 4)->nullable();
            }
            if ($needsSubcategoria) {
                $table->string('subcategoria_codigo', 6)->nullable();
            }
            if ($needsConsecutivo) {
                $table->unsignedInteger('consecutivo')->nullable();
            }

            // TODO: En producción esta tabla es selemti.insumo (esquema selemti).
            // TODO: En una migración futura vamos a forzar NOT NULL cuando ya hayamos poblado datos.

            if ($needsUniqueIndex) {
                $table->unique('codigo', 'insumo_codigo_unique');
            }

            if ($needsCatIndex) {
                $table->index(
                    ['categoria_codigo', 'subcategoria_codigo', 'consecutivo'],
                    'insumo_cat_sub_cons_idx'
                );
            }
        });
    }

    private function columnExists(string $column): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.columns WHERE table_schema = 'selemti' AND table_name = 'insumo' AND column_name = ? LIMIT 1",
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

    public function down(): void
    {
        Schema::table('insumo', function (Blueprint $table) {
            $table->dropUnique('insumo_codigo_unique');
            $table->dropIndex('insumo_cat_sub_cons_idx');

            $table->dropColumn([
                'codigo',
                'categoria_codigo',
                'subcategoria_codigo',
                'consecutivo',
            ]);
        });
    }
};
