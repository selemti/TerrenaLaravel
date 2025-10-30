<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Migration to add unit_cost to the inventory_batch table for batch costing.
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

        $schema->table('selemti.inventory_batch', function (Blueprint $table) {
            if (!Schema::hasColumn('selemti.inventory_batch', 'unit_cost')) {
                $table->decimal('unit_cost', 12, 4)->default(0.00)->comment('Costo unitario del lote para costeo por batch.');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        $schema->table('selemti.inventory_batch', function (Blueprint $table) {
            if (Schema::hasColumn('selemti.inventory_batch', 'unit_cost')) {
                $table->dropColumn('unit_cost');
            }
        });
    }
};
