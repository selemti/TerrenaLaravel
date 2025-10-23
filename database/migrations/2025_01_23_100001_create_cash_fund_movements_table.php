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
        Schema::create('cash_fund_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cash_fund_id')
                ->constrained('cash_funds')
                ->onDelete('cascade');

            $table->enum('tipo', ['EGRESO', 'REINTEGRO', 'DEPOSITO']);
            $table->text('concepto');
            $table->integer('proveedor_id')->nullable(); // FK a selemti.cat_proveedores (PostgreSQL)
            $table->decimal('monto', 10, 2);
            $table->enum('metodo', ['EFECTIVO', 'TRANSFER']);
            $table->enum('estatus', ['APROBADO', 'POR_APROBAR', 'RECHAZADO'])->default('APROBADO');
            $table->boolean('requiere_comprobante')->default(false);
            $table->boolean('tiene_comprobante')->default(false);
            $table->string('adjunto_path')->nullable();

            // Auditoría
            $table->foreignId('created_by_user_id')
                ->constrained('users')
                ->onDelete('restrict');

            $table->foreignId('approved_by_user_id')
                ->nullable()
                ->constrained('users')
                ->onDelete('set null');

            $table->timestamp('approved_at')->nullable();
            $table->timestamps();

            // Índices
            $table->index('cash_fund_id');
            $table->index('tipo');
            $table->index('estatus');
            $table->index('created_by_user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cash_fund_movements');
    }
};
