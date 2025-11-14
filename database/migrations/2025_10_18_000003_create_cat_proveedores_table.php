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

        Schema::connection('pgsql')->create('selemti.cat_proveedores', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('rfc', 20)->unique();
            $table->string('nombre', 120);
            $table->string('telefono', 30)->nullable();
            $table->string('email', 120)->nullable();
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.cat_proveedores');
    }

    private function tableExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT to_regclass('selemti.cat_proveedores') AS regclass"
        );

        return ! empty($result?->regclass);
    }
};
