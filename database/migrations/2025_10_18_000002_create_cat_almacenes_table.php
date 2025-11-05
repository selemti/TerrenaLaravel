<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if ($this->tableExists()) {
            return;
        }

        Schema::connection('pgsql')->create('selemti.cat_almacenes', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('clave', 16)->unique();
            $table->string('nombre', 80);
            $table->unsignedBigInteger('sucursal_id')->nullable();
            $table->boolean('activo')->default(true);
            $table->timestamps();

            $table->foreign('sucursal_id', 'fk_cat_almacenes_sucursal')
                ->references('id')
                ->on('selemti.cat_sucursales')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.cat_almacenes');
    }

    private function tableExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT to_regclass('selemti.cat_almacenes') AS regclass"
        );

        return ! empty($result?->regclass);
    }
};
