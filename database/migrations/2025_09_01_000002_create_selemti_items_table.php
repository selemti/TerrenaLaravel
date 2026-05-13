<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $exists = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='items' LIMIT 1"
        );
        if ($exists) {
            return;
        }

        Schema::connection('pgsql')->create('selemti.items', function (Blueprint $table) {
            $table->string('id', 50)->primary();
            $table->string('item_code', 32)->nullable()->unique();
            $table->string('nombre', 200);
            $table->text('descripcion')->nullable();
            $table->string('categoria_id', 30)->nullable();
            $table->unsignedBigInteger('category_id')->nullable();
            $table->string('unidad_medida', 16)->nullable();
            $table->unsignedBigInteger('unidad_medida_id')->nullable();
            $table->unsignedBigInteger('unidad_compra_id')->nullable();
            $table->unsignedBigInteger('unidad_salida_id')->nullable();
            $table->decimal('factor_conversion', 14, 6)->nullable();
            $table->decimal('factor_compra', 14, 6)->nullable();
            $table->boolean('perishable')->default(false);
            $table->decimal('costo_promedio', 14, 4)->nullable()->default(0);
            $table->boolean('activo')->default(true);
            $table->string('tipo', 30)->nullable();
            $table->boolean('es_producible')->default(false);
            $table->boolean('es_consumible_operativo')->default(false);
            $table->boolean('es_empaque_to_go')->default(false);
            $table->string('clave', 50)->nullable();
            $table->string('codigo', 50)->nullable();
            $table->decimal('temperatura_min', 8, 2)->nullable();
            $table->decimal('temperatura_max', 8, 2)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.items');
    }
};
