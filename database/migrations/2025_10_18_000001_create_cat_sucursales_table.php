<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasTable('cat_sucursales')) {
            Schema::create('cat_sucursales', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('clave', 16)->unique();
                $table->string('nombre', 120);
                $table->string('ubicacion', 160)->nullable();
                $table->boolean('activo')->default(true);
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('cat_sucursales');
    }
};
