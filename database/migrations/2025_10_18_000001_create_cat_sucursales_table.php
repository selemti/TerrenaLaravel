<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if ($this->tableExists()) {
            return;
        }

        Schema::connection('pgsql')->create('selemti.cat_sucursales', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('clave', 16)->unique();
            $table->string('nombre', 120);
            $table->string('ubicacion', 160)->nullable();
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.cat_sucursales');
    }

    private function tableExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT to_regclass('selemti.cat_sucursales') AS regclass"
        );

        return ! empty($result?->regclass);
    }
};
