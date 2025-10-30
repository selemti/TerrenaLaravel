<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('pgsql')->create('selemti.menu_engineering_snapshots', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('menu_item_id');
            $table->date('period_start');
            $table->date('period_end');
            $table->unsignedInteger('units_sold')->default(0);
            $table->decimal('net_sales', 14, 2)->default(0);
            $table->decimal('food_cost', 14, 2)->default(0);
            $table->decimal('contribution', 14, 2)->default(0);
            $table->decimal('avg_price', 12, 2)->default(0);
            $table->decimal('avg_cost', 12, 2)->default(0);
            $table->decimal('margin_pct', 6, 3)->default(0);
            $table->decimal('popularity_index', 6, 3)->default(0);
            $table->string('classification', 20)->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestampsTz();

            $table->foreign('menu_item_id')
                ->references('id')
                ->on('selemti.menu_items')
                ->onDelete('cascade');
            $table->unique(['menu_item_id', 'period_start', 'period_end']);
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.menu_engineering_snapshots');
    }
};
