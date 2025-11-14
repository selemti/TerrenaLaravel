<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('insumo', function (Blueprint $table) {
            if (! Schema::hasColumn('insumo', 'codigo')) {
                $table->string('codigo', 20)->nullable();
            }
            if (! Schema::hasColumn('insumo', 'categoria_codigo')) {
                $table->string('categoria_codigo', 4)->nullable();
            }
            if (! Schema::hasColumn('insumo', 'subcategoria_codigo')) {
                $table->string('subcategoria_codigo', 6)->nullable();
            }
            if (! Schema::hasColumn('insumo', 'consecutivo')) {
                $table->unsignedInteger('consecutivo')->nullable();
            }
            if (! Schema::hasColumn('insumo', 'codigo_alterno')) {
                $table->string('codigo_alterno', 50)->nullable()->comment('Código alternativo para compatibilidad');
            }

            // TODO: En producción esta tabla es selemti.insumo (esquema selemti).
            // TODO: En una migración futura vamos a forzar NOT NULL cuando ya hayamos poblado datos.

            // Only add unique constraint if column exists and constraint doesn't exist
            try {
                DB::statement('ALTER TABLE insumo DROP CONSTRAINT IF EXISTS insumo_codigo_unique');
                if (Schema::hasColumn('insumo', 'codigo')) {
                    $table->unique('codigo', 'insumo_codigo_unique');
                }
            } catch (\Exception $e) {
                // Ignore if constraint already exists
            }

            // Only add index if it doesn't exist
            try {
                DB::statement('DROP INDEX IF EXISTS insumo_cat_sub_cons_idx');
                if (Schema::hasColumn('insumo', 'categoria_codigo') &&
                    Schema::hasColumn('insumo', 'subcategoria_codigo') &&
                    Schema::hasColumn('insumo', 'consecutivo')) {
                    $table->index(
                        ['categoria_codigo', 'subcategoria_codigo', 'consecutivo'],
                        'insumo_cat_sub_cons_idx'
                    );
                }
            } catch (\Exception $e) {
                // Ignore if index already exists
            }
        });
    }

    public function down(): void
    {
        Schema::table('insumo', function (Blueprint $table) {
            try {
                DB::statement('ALTER TABLE insumo DROP CONSTRAINT IF EXISTS insumo_codigo_unique');
            } catch (\Exception $e) {
                // Ignore
            }

            try {
                DB::statement('DROP INDEX IF EXISTS insumo_cat_sub_cons_idx');
            } catch (\Exception $e) {
                // Ignore
            }

            $columns = array_filter([
                Schema::hasColumn('insumo', 'codigo') ? 'codigo' : null,
                Schema::hasColumn('insumo', 'categoria_codigo') ? 'categoria_codigo' : null,
                Schema::hasColumn('insumo', 'subcategoria_codigo') ? 'subcategoria_codigo' : null,
                Schema::hasColumn('insumo', 'consecutivo') ? 'consecutivo' : null,
                Schema::hasColumn('insumo', 'codigo_alterno') ? 'codigo_alterno' : null,
            ]);

            if (! empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }
};
