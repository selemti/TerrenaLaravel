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
        Schema::connection('pgsql')->create('selemti.cash_fund_movement_audit_log', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('movement_id'); // FK a cash_fund_movements
            $table->string('action', 50); // CREATED, UPDATED, DELETED, ATTACHMENT_ADDED, ATTACHMENT_REMOVED
            $table->string('field_changed', 100)->nullable(); // Campo que cambió
            $table->text('old_value')->nullable(); // Valor anterior
            $table->text('new_value')->nullable(); // Valor nuevo
            $table->text('observaciones')->nullable(); // Comentario del cambio
            $table->integer('changed_by_user_id'); // Quien hizo el cambio
            $table->timestamp('created_at')->useCurrent();

            // Índices
            $table->index('movement_id');
            $table->index('action');
            $table->index('changed_by_user_id');

            // Foreign keys
            $table->foreign('movement_id')
                ->references('id')
                ->on('selemti.cash_fund_movements')
                ->onDelete('cascade');

            $table->foreign('changed_by_user_id')
                ->references('id')
                ->on('selemti.users')
                ->onDelete('restrict');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.cash_fund_movement_audit_log');
    }
};
