<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if ($this->tableExists()) {
            return;
        }

        Schema::connection('pgsql')->create('selemti.inv_stock_policy', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('item_id', 64);
            $table->unsignedBigInteger('sucursal_id');
            $table->decimal('min_qty', 18, 6)->default(0);
            $table->decimal('max_qty', 18, 6)->default(0);
            $table->decimal('reorder_qty', 18, 6)->default(0);
            $table->boolean('activo')->default(true);
            $table->timestamps();

            $table->unique(['item_id', 'sucursal_id'], 'inv_stock_policy_item_store_unique');
            // FK to selemti.items omitted: pre-existing legacy table, not created by migrations
            $table->foreign('sucursal_id', 'fk_inv_stock_policy_sucursal')
                ->references('id')
                ->on('selemti.cat_sucursales')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.inv_stock_policy');
    }

    private function tableExists(): bool
    {
        // Compatible con PostgreSQL 9.5 (sin to_regclass)
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema = 'selemti' AND table_name = 'inv_stock_policy' LIMIT 1"
        );

        return ! empty($result);
    }
};
