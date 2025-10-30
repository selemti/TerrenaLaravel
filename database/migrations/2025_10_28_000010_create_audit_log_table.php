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
        // TODO: asegurarse de que el esquema `selemti` exista antes de ejecutar esta migración.
        Schema::connection('pgsql')->create('selemti.audit_log', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->timestamp('timestamp')->useCurrent();
            $table->unsignedBigInteger('user_id');
            $table->string('accion', 100);
            $table->string('entidad', 50);
            $table->unsignedBigInteger('entidad_id');
            $table->text('motivo')->nullable();
            $table->text('evidencia_url')->nullable(); // TODO: hacer obligatorio cuando el frontend soporte captura de evidencia.
            $table->jsonb('payload_json')->nullable();

            $table->index(['entidad', 'entidad_id']);
            $table->index('user_id');
            $table->index('timestamp');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.audit_log');
    }
};
