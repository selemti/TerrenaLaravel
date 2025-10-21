<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasTable('cat_almacenes')) {
            Schema::create('cat_almacenes', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('clave', 16)->unique();
                $table->string('nombre', 80);
                $table->foreignId('sucursal_id')->nullable()->constrained('cat_sucursales')->nullOnDelete();
                $table->boolean('activo')->default(true);
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('cat_almacenes');
    }
};
