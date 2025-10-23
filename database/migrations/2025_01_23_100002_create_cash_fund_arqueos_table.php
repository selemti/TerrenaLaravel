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
        Schema::create('cash_fund_arqueos', function (Blueprint $table) {
            $table->id();

            // Un fondo solo puede tener un arqueo
            $table->foreignId('cash_fund_id')
                ->unique()
                ->constrained('cash_funds')
                ->onDelete('cascade');

            $table->decimal('monto_esperado', 10, 2);
            $table->decimal('monto_contado', 10, 2);
            $table->decimal('diferencia', 10, 2);
            $table->text('observaciones')->nullable();

            // Quien realizó el arqueo
            $table->foreignId('created_by_user_id')
                ->constrained('users')
                ->onDelete('restrict');

            $table->timestamps();

            // Índices
            $table->index('cash_fund_id');
            $table->index('created_by_user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cash_fund_arqueos');
    }
};
