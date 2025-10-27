<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Migration to add operational flags to the items table.
 *
 * @version 2.1
 * @author Gemini
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        $schema->table('selemti.items', function (Blueprint $table) {
            if (!Schema::hasColumn('selemti.items', 'es_producible')) {
                $table->boolean('es_producible')->default(false)->comment('Indicates if this item is produced internally (sub-recipe).');
            }
            if (!Schema::hasColumn('selemti.items', 'es_consumible_operativo')) {
                $table->boolean('es_consumible_operativo')->default(false)->comment('Identifies operational use materials (cleaning, gloves).');
            }
            if (!Schema::hasColumn('selemti.items', 'es_empaque_to_go')) {
                $table->boolean('es_empaque_to_go')->default(false)->comment('Marks items as to-go packaging.');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        $schema->table('selemti.items', function (Blueprint $table) {
            if (Schema::hasColumn('selemti.items', 'es_producible')) {
                $table->dropColumn('es_producible');
            }
            if (Schema::hasColumn('selemti.items', 'es_consumible_operativo')) {
                $table->dropColumn('es_consumible_operativo');
            }
            if (Schema::hasColumn('selemti.items', 'es_empaque_to_go')) {
                $table->dropColumn('es_empaque_to_go');
            }
        });
    }
};