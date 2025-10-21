<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasTable('inv_stock_policy')) {
            Schema::create('inv_stock_policy', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('item_id', 64);
                $table->foreignId('sucursal_id')->constrained('cat_sucursales')->cascadeOnDelete();
                $table->decimal('min_qty', 18, 6)->default(0);
                $table->decimal('max_qty', 18, 6)->default(0);
                $table->decimal('reorder_qty', 18, 6)->default(0);
                $table->boolean('activo')->default(true);
                $table->timestamps();

                $table->unique(['item_id', 'sucursal_id'], 'inv_stock_policy_item_store_unique');
                $table->foreign('item_id')
                    ->references('id')
                    ->on('items')
                    ->cascadeOnDelete();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('inv_stock_policy');
    }
};
