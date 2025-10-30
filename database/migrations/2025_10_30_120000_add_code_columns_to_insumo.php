<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('insumo', function (Blueprint $table) {
            $table->string('codigo', 20)->nullable();
            $table->string('categoria_codigo', 4)->nullable();
            $table->string('subcategoria_codigo', 6)->nullable();
            $table->unsignedInteger('consecutivo')->nullable();

            // TODO: En producción esta tabla es selemti.insumo (esquema selemti).
            // TODO: En una migración futura vamos a forzar NOT NULL cuando ya hayamos poblado datos.

            $table->unique('codigo', 'insumo_codigo_unique');

            $table->index(
                ['categoria_codigo', 'subcategoria_codigo', 'consecutivo'],
                'insumo_cat_sub_cons_idx'
            );
        });
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
