<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! $this->tableExists('production_orders')) {
            Schema::connection('pgsql')->create('selemti.production_orders', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('folio', 40)->nullable()->unique();
                $table->unsignedBigInteger('recipe_id')->nullable();
                $table->unsignedBigInteger('item_id')->nullable();
                $table->decimal('qty_programada', 18, 6)->default(0);
                $table->decimal('qty_producida', 18, 6)->default(0);
                $table->decimal('qty_merma', 18, 6)->default(0);
                $table->string('uom_base', 20)->nullable();
                $table->string('sucursal_id', 36)->nullable();
                $table->string('almacen_id', 36)->nullable();
                $table->timestampTz('programado_para')->nullable();
                $table->timestampTz('iniciado_en')->nullable();
                $table->timestampTz('cerrado_en')->nullable();
                $table->string('estado', 24)->default('BORRADOR');
                $table->unsignedBigInteger('creado_por')->nullable();
                $table->unsignedBigInteger('aprobado_por')->nullable();
                $table->text('notas')->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('recipe_id');
                $table->index('item_id');
                $table->index('sucursal_id');
                $table->index('almacen_id');
                $table->index('estado');
                $table->index('programado_para');
            });
        }

        if (! $this->tableExists('production_order_inputs')) {
            Schema::connection('pgsql')->create('selemti.production_order_inputs', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('production_order_id');
                $table->unsignedBigInteger('item_id');
                $table->unsignedBigInteger('inventory_batch_id')->nullable();
                $table->decimal('qty', 18, 6);
                $table->string('uom', 20);
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('production_order_id');
                $table->index('item_id');
                $table->index('inventory_batch_id');
            });
        }

        if (! $this->tableExists('production_order_outputs')) {
            Schema::connection('pgsql')->create('selemti.production_order_outputs', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('production_order_id');
                $table->unsignedBigInteger('item_id');
                $table->unsignedBigInteger('inventory_batch_id')->nullable();
                $table->string('lote_producido', 120)->nullable();
                $table->date('fecha_caducidad')->nullable();
                $table->decimal('qty', 18, 6);
                $table->string('uom', 20);
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('production_order_id');
                $table->index('item_id');
                $table->index('inventory_batch_id');
            });
        }

        if (! $this->tableExists('inventory_wastes')) {
            Schema::connection('pgsql')->create('selemti.inventory_wastes', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('production_order_id')->nullable();
                $table->unsignedBigInteger('item_id');
                $table->unsignedBigInteger('inventory_batch_id')->nullable();
                $table->decimal('qty', 18, 6);
                $table->string('uom', 20);
                $table->string('motivo', 80)->nullable();
                $table->string('sucursal_id', 36)->nullable();
                $table->string('almacen_id', 36)->nullable();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->string('ref_tipo', 40)->nullable();
                $table->unsignedBigInteger('ref_id')->nullable();
                $table->timestampTz('registrado_en')->useCurrent();
                $table->jsonb('meta')->nullable();
                $table->text('notas')->nullable();
                $table->timestampsTz();

                $table->index('production_order_id');
                $table->index('item_id');
                $table->index('inventory_batch_id');
                $table->index('sucursal_id');
            });
        }
    }

    public function down(): void
    {
        foreach (['inventory_wastes', 'production_order_outputs', 'production_order_inputs', 'production_orders'] as $table) {
            if ($this->tableExists($table)) {
                Schema::connection('pgsql')->drop("selemti.{$table}");
            }
        }
    }

    private function tableExists(string $table): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT to_regclass('selemti.' || ?) AS regclass",
            [$table]
        );

        return ! empty($result?->regclass);
    }
};
