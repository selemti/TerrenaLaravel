<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Creates the ticket_item_modifiers table to log modifiers for each sold item.
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
        $schema = Schema::connection('pgsql');

        if (!$schema->hasTable('selemti.ticket_item_modifiers')) {
            $schema->create('selemti.ticket_item_modifiers', function (Blueprint $table) {
                // This table records every modifier chosen for a specific item in a ticket.
                // It is crucial for accurately costing each sale, deducting inventory for add-ons
                // (like extra protein, sauces, to-go packaging), and enabling the retroactive
                // reprocessing of historical sales.
                $table->bigIncrements('id');
                $table->unsignedBigInteger('ticket_item_id')->index()->comment('The ticket line item this modifier belongs to.');
                $table->string('pos_code')->index()->comment('Code/ID of the modifier from the POS.');
                $table->unsignedBigInteger('recipe_version_id')->nullable()->comment('The recipe version representing this modifier for inventory consumption.');
                $table->decimal('precio_extra', 12, 4)->default(0)->comment('Upcharge applied by the POS for this modifier.');

                // Reprocessing flags, similar to ticket_items, to ensure modifiers are
                // processed even if their recipe is mapped after the sale.
                $table->boolean('requiere_reproceso')->default(true)->index()->comment('Indicates this modifier has not yet been processed for inventory consumption.');
                $table->boolean('procesado')->default(false)->index()->comment('True when inventory has been consumed for this modifier.');
                $table->timestamp('fecha_proceso')->nullable()->comment('Timestamp of when inventory was consumed.');

                $table->timestamps();

                // Foreign key constraints (commented out for schema flexibility)
                // $table->foreign('ticket_item_id')->references('id')->on('selemti.ticket_items')->onDelete('cascade');
                // $table->foreign('recipe_version_id')->references('id')->on('selemti.recipe_versions')->onDelete('set null');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.ticket_item_modifiers');
    }
};
