<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasTable('cat_unidades')) {
            Schema::create('cat_unidades', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('clave', 16);
                $table->string('nombre', 64);
                $table->boolean('activo')->default(true);
                $table->timestamps();
                $table->unique('clave');
            });
        } else {
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

            if ($needsNombre && Schema::hasColumn('cat_unidades', 'descripcion')) {
                DB::statement('UPDATE cat_unidades SET nombre = descripcion WHERE nombre IS NULL AND descripcion IS NOT NULL');
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('cat_unidades');
    }
};
