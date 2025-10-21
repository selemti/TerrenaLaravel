<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasTable('cat_unidades')) {
            return;
        }

        $needsClave = ! Schema::hasColumn('cat_unidades', 'clave');
        $needsNombre = ! Schema::hasColumn('cat_unidades', 'nombre');
        $needsActivo = ! Schema::hasColumn('cat_unidades', 'activo');
        $needsTimestamps = ! Schema::hasColumn('cat_unidades', 'created_at') || ! Schema::hasColumn('cat_unidades', 'updated_at');

        if ($needsClave || $needsNombre || $needsActivo || $needsTimestamps) {
            Schema::table('cat_unidades', function (Blueprint $table) use ($needsClave, $needsNombre, $needsActivo, $needsTimestamps) {
                if ($needsClave) {
                    $table->string('clave', 16)->nullable()->after('id');
                }

                if ($needsNombre) {
                    $table->string('nombre', 64)->nullable();
                }

                if ($needsActivo) {
                    $table->boolean('activo')->default(true);
                }

                if ($needsTimestamps) {
                    $table->timestamps();
                }
            });
        }

        if ($needsClave && Schema::hasColumn('cat_unidades', 'codigo')) {
            DB::statement('UPDATE cat_unidades SET clave = codigo WHERE clave IS NULL AND codigo IS NOT NULL');
        }

        if ($needsNombre) {
            if (Schema::hasColumn('cat_unidades', 'descripcion')) {
                DB::statement('UPDATE cat_unidades SET nombre = descripcion WHERE nombre IS NULL AND descripcion IS NOT NULL');
            } elseif (Schema::hasColumn('cat_unidades', 'detalle')) {
                DB::statement('UPDATE cat_unidades SET nombre = detalle WHERE nombre IS NULL AND detalle IS NOT NULL');
            }
        }

        if ($needsClave) {
            Schema::table('cat_unidades', function (Blueprint $table) {
                $table->unique('clave');
            });
        }
    }

    public function down(): void
    {
        if (! Schema::hasTable('cat_unidades')) {
            return;
        }

        Schema::table('cat_unidades', function (Blueprint $table) {
            if (Schema::hasColumn('cat_unidades', 'clave')) {
                $table->dropUnique(['clave']);
                $table->dropColumn('clave');
            }

            if (Schema::hasColumn('cat_unidades', 'nombre')) {
                $table->dropColumn('nombre');
            }

            if (Schema::hasColumn('cat_unidades', 'activo')) {
                $table->dropColumn('activo');
            }

            if (Schema::hasColumn('cat_unidades', 'created_at')) {
                $table->dropTimestamps();
            }
        });
    }
};

