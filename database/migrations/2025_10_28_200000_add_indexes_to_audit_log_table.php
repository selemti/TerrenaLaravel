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
        // Verificar si la tabla ya existe
        if (!Schema::hasTable('selemti.audit_log')) {
            // Crear tabla si no existe (aunque ya debería existir según análisis previo)
            Schema::create('selemti.audit_log', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->timestamp('timestamp')->nullable();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->string('accion')->nullable();
                $table->string('entidad')->nullable();
                $table->unsignedBigInteger('entidad_id')->nullable();
                $table->text('motivo')->nullable();
                $table->text('evidencia_url')->nullable();
                $table->jsonb('payload_json')->nullable();
                
                $table->index(['timestamp'], 'idx_audit_log_timestamp');
                $table->index(['user_id'], 'idx_audit_log_user_id');
                $table->index(['accion'], 'idx_audit_log_accion');
                $table->index(['entidad'], 'idx_audit_log_entidad');
                $table->index(['entidad_id'], 'idx_audit_log_entidad_id');
                $table->foreign('user_id')->references('id')->on('selemti.users')->onDelete('set null');
            });
        } else {
            // Asegurar que los índices existan
            Schema::table('selemti.audit_log', function (Blueprint $table) {
                // Verificar y crear índices si no existen
                if (!Schema::hasIndex('selemti.audit_log', 'idx_audit_log_timestamp')) {
                    $table->index(['timestamp'], 'idx_audit_log_timestamp');
                }
                
                if (!Schema::hasIndex('selemti.audit_log', 'idx_audit_log_user_id')) {
                    $table->index(['user_id'], 'idx_audit_log_user_id');
                }
                
                if (!Schema::hasIndex('selemti.audit_log', 'idx_audit_log_accion')) {
                    $table->index(['accion'], 'idx_audit_log_accion');
                }
                
                if (!Schema::hasIndex('selemti.audit_log', 'idx_audit_log_entidad')) {
                    $table->index(['entidad'], 'idx_audit_log_entidad');
                }
                
                if (!Schema::hasIndex('selemti.audit_log', 'idx_audit_log_entidad_id')) {
                    $table->index(['entidad_id'], 'idx_audit_log_entidad_id');
                }
                
                // Verificar constraint de foreign key
                $indexes = DB::select("
                    SELECT conname 
                    FROM pg_constraint 
                    WHERE conrelid = 'selemti.audit_log'::regclass 
                    AND contype = 'f' 
                    AND conname = 'audit_log_user_id_foreign'
                ");
                
                if (empty($indexes)) {
                    $table->foreign('user_id')->references('id')->on('selemti.users')->onDelete('set null');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('selemti.audit_log', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropIndex(['idx_audit_log_timestamp']);
            $table->dropIndex(['idx_audit_log_user_id']);
            $table->dropIndex(['idx_audit_log_accion']);
            $table->dropIndex(['idx_audit_log_entidad']);
            $table->dropIndex(['idx_audit_log_entidad_id']);
        });
    }
};