<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Creates the pos_map table to link POS codes with internal recipes.
 *
 * @version 2.1
 * @author Gemini
 * @see /docs/Recetas/POS_MAPPING.md
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        if (!$schema->hasTable('selemti.pos_map')) {
            $schema->create('selemti.pos_map', function (Blueprint $table) {
                // This table is the bridge between the Point of Sale (POS) and the internal
                // inventory and recipe management system. It translates a POS code (PLU, SKU)
                // into a specific, versioned recipe to ensure accurate inventory consumption and costing.
                $table->bigIncrements('id');
                $table->string('pos_code')->index()->comment('Code or identifier from the POS for this product/modifier.');
                $table->unsignedBigInteger('menu_item_id')->nullable()->comment('Logical reference to the internal menu item (e.g., menu_items.id).');
                $table->unsignedBigInteger('recipe_version_id')->nullable()->comment('Specific recipe version to be used for consumption calculation.');

                // POS modifiers (like extra protein, specific sauce, or to-go packaging)
                // are also mapped here by setting is_modifier to true.
                $table->boolean('is_modifier')->default(false)->index()->comment('If true, this record represents a POS modifier.');

                // Multiple pos_map entries can point to the same recipe_version_id. For example,
                // different POS codes (e.g., "CHILAQUILES_DINE_IN", "CHILAQUILES_TOGO") might
                // use the same base recipe.
                $table->boolean('is_active')->default(true)->index()->comment('Allows deactivating a mapping without deleting it.');
                $table->timestamps();
                $table->timestamp('deactivated_at')->nullable()->comment('Timestamp of when this mapping was deactivated.');

                // Foreign key constraints (commented out for schema flexibility)
                // $table->foreign('menu_item_id')->references('id')->on('selemti.menu_items')->onDelete('set null');
                // $table->foreign('recipe_version_id')->references('id')->on('selemti.recipe_versions')->onDelete('set null');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.pos_map');
    }
};