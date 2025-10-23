<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        if (! $schema->hasTable('inventory_counts')) {
            $schema->create('inventory_counts', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('folio', 40)->nullable()->unique();
                $table->string('sucursal_id', 36)->nullable();
                $table->string('almacen_id', 36)->nullable();
                $table->timestampTz('programado_para')->nullable();
                $table->timestampTz('iniciado_en')->nullable();
                $table->timestampTz('cerrado_en')->nullable();
                $table->string('estado', 24)->default('BORRADOR');
                $table->unsignedBigInteger('creado_por')->nullable();
                $table->unsignedBigInteger('cerrado_por')->nullable();
                $table->text('notas')->nullable();
                $table->decimal('total_items', 14, 4)->default(0);
                $table->decimal('total_variacion', 18, 6)->default(0);
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('estado');
                $table->index('sucursal_id');
                $table->index('almacen_id');
                $table->index('programado_para');
                $table->index('cerrado_en');
            });
        }

        if (! $schema->hasTable('inventory_count_lines')) {
            $schema->create('inventory_count_lines', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('inventory_count_id');
                $table->unsignedBigInteger('item_id');
                $table->unsignedBigInteger('inventory_batch_id')->nullable();
                $table->decimal('qty_teorica', 18, 6)->default(0);
                $table->decimal('qty_contada', 18, 6)->default(0);
                $table->decimal('qty_variacion', 18, 6)->default(0);
                $table->string('uom', 20);
                $table->string('motivo', 60)->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('inventory_count_id');
                $table->index('item_id');
                $table->index('inventory_batch_id');
            });
        }
    }

    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        foreach (['inventory_count_lines', 'inventory_counts'] as $table) {
            if ($schema->hasTable($table)) {
                $schema->drop($table);
            }
        }
    }
};
