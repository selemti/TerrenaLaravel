<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('cash_funds', function (Blueprint $table) {
            $table->id();
            $table->integer('sucursal_id'); // FK a selemti.cat_sucursales (PostgreSQL)
            $table->date('fecha');
            $table->decimal('monto_inicial', 10, 2);
            $table->string('moneda', 3)->default('MXN');
            $table->enum('estado', ['ABIERTO', 'EN_REVISION', 'CERRADO'])->default('ABIERTO');

            // Responsable del fondo (quien lo maneja)
            $table->foreignId('responsable_user_id')
                ->constrained('users')
                ->onDelete('restrict');

            // Quien creó el registro
            $table->foreignId('created_by_user_id')
                ->constrained('users')
                ->onDelete('restrict');

            $table->timestamp('closed_at')->nullable();
            $table->timestamps();

            // Índices para búsquedas frecuentes
            $table->index('sucursal_id');
            $table->index('fecha');
            $table->index('estado');
            $table->index('responsable_user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cash_funds');
    }
};
