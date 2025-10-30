<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Migration to add reprocessing flags to the ticket_items table.
 *
 * @version 2.1
 * @author Gemini
 * @see /docs/Recetas/POS_REPROCESSING.md
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Per project context, the main schema is 'selemti' on the 'pgsql' connection.
        $schema = Schema::connection('pgsql');

        $schema->table('selemti.ticket_items', function (Blueprint $table) {
            if (!Schema::hasColumn('selemti.ticket_items', 'requiere_reproceso')) {
                $table->boolean('requiere_reproceso')->default(true)->comment('Indicates if the sale has not yet been assigned a recipe.');
            }
            if (!Schema::hasColumn('selemti.ticket_items', 'receta_procesada')) {
                $table->boolean('receta_procesada')->default(false)->comment('Indicates if the sale has been correctly reprocessed.');
            }
            if (!Schema::hasColumn('selemti.ticket_items', 'fecha_proceso')) {
                $table->timestamp('fecha_proceso')->nullable()->comment('Timestamp of when the sale was reprocessed.');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        $schema->table('selemti.ticket_items', function (Blueprint $table) {
            if (Schema::hasColumn('selemti.ticket_items', 'requiere_reproceso')) {
                $table->dropColumn('requiere_reproceso');
            }
            if (Schema::hasColumn('selemti.ticket_items', 'receta_procesada')) {
                $table->dropColumn('receta_procesada');
            }
            if (Schema::hasColumn('selemti.ticket_items', 'fecha_proceso')) {
                $table->dropColumn('fecha_proceso');
            }
        });
    }
};