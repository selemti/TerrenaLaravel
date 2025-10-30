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
        Schema::connection('pgsql')->table('selemti.inv_consumo_pos', function (Blueprint $table) {
            $table->boolean('requiere_reproceso')
                ->default(true)
                ->comment('Pendiente de reprocesar')
                ->index('inv_consumo_pos_requiere_reproceso_idx');
            $table->boolean('procesado')
                ->default(false)
                ->comment('Consumo confirmado')
                ->index('inv_consumo_pos_procesado_idx');
            $table->timestamp('fecha_proceso')
                ->nullable()
                ->comment('Momento del procesamiento');
        });

        Schema::connection('pgsql')->table('selemti.inv_consumo_pos_det', function (Blueprint $table) {
            $table->boolean('requiere_reproceso')
                ->default(true)
                ->index('inv_consumo_pos_det_requiere_reproceso_idx');
            $table->boolean('procesado')
                ->default(false)
                ->index('inv_consumo_pos_det_procesado_idx');
            $table->timestamp('fecha_proceso')
                ->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->table('selemti.inv_consumo_pos', function (Blueprint $table) {
            $table->dropIndex('inv_consumo_pos_requiere_reproceso_idx');
            $table->dropIndex('inv_consumo_pos_procesado_idx');
            $table->dropColumn(['requiere_reproceso', 'procesado', 'fecha_proceso']);
        });

        Schema::connection('pgsql')->table('selemti.inv_consumo_pos_det', function (Blueprint $table) {
            $table->dropIndex('inv_consumo_pos_det_requiere_reproceso_idx');
            $table->dropIndex('inv_consumo_pos_det_procesado_idx');
            $table->dropColumn(['requiere_reproceso', 'procesado', 'fecha_proceso']);
        });
    }
};
