<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    protected string $connection = 'pgsql';

    public function up(): void
    {
        $schema = Schema::connection($this->connection);

        if (! $schema->hasTable('recepcion_cab')) {
            $schema->create('recepcion_cab', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('numero_recepcion', 40)->nullable()->unique();
                $table->unsignedBigInteger('proveedor_id');
                $table->string('sucursal_id', 36)->nullable();
                $table->string('almacen_id', 36)->nullable();
                $table->timestampTz('fecha_recepcion')->useCurrent();
                $table->string('estado', 24)->default('BORRADOR');
                $table->decimal('total_presentaciones', 16, 4)->default(0);
                $table->decimal('total_canonico', 18, 6)->default(0);
                $table->decimal('peso_total_kg', 14, 4)->nullable();
                $table->unsignedBigInteger('creado_por')->nullable();
                $table->unsignedBigInteger('verificado_por')->nullable();
                $table->unsignedBigInteger('aprobado_por')->nullable();
                $table->timestampTz('verificado_en')->nullable();
                $table->timestampTz('aprobado_en')->nullable();
                $table->text('notas')->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('proveedor_id');
                $table->index('sucursal_id');
                $table->index('almacen_id');
                $table->index('fecha_recepcion');
                $table->index('estado');
            });
        }

        if (! $schema->hasTable('inventory_batch')) {
            $schema->create('inventory_batch', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('item_id');
                $table->string('lote_proveedor', 120);
                $table->decimal('cantidad_original', 18, 6)->default(0);
                $table->decimal('cantidad_actual', 18, 6)->default(0);
                $table->string('uom_base', 20)->nullable();
                $table->date('caducidad')->nullable();
                $table->string('estado', 24)->default('ACTIVO');
                $table->decimal('temperatura_recepcion', 6, 2)->nullable();
                $table->string('documento_url')->nullable();
                $table->string('sucursal_id', 36)->nullable();
                $table->string('almacen_id', 36)->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('item_id');
                $table->index('lote_proveedor');
                $table->index('caducidad');
                $table->index('estado');
                $table->unique(['item_id', 'lote_proveedor', 'sucursal_id', 'almacen_id'], 'inventory_batch_item_lote_unique');
            });
        }

        if (! $schema->hasTable('recepcion_det')) {
            $schema->create('recepcion_det', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('recepcion_id');
                $table->unsignedBigInteger('item_id');
                $table->unsignedBigInteger('inventory_batch_id')->nullable();
                $table->string('lote_proveedor', 120)->nullable();
                $table->date('fecha_caducidad')->nullable();
                $table->decimal('qty_presentacion', 16, 4);
                $table->decimal('qty_recibida', 16, 4)->default(0);
                $table->decimal('pack_size', 16, 4)->default(1);
                $table->string('uom_compra', 20);
                $table->decimal('qty_canonica', 18, 6);
                $table->string('uom_base', 20);
                $table->decimal('cantidad_rechazada', 18, 6)->default(0);
                $table->decimal('precio_unit', 14, 4)->nullable();
                $table->decimal('temperatura_recepcion', 6, 2)->nullable();
                $table->string('certificado_calidad_url')->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('recepcion_id');
                $table->index('item_id');
                $table->index('inventory_batch_id');
            });
        }

        if (! $schema->hasTable('mov_inv')) {
            $schema->create('mov_inv', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('item_id');
                $table->unsignedBigInteger('inventory_batch_id')->nullable();
                $table->string('tipo', 24);
                $table->decimal('qty', 18, 6);
                $table->string('uom', 20);
                $table->string('sucursal_id', 36)->nullable();
                $table->string('sucursal_dest', 36)->nullable();
                $table->string('almacen_id', 36)->nullable();
                $table->string('ref_tipo', 40)->nullable();
                $table->unsignedBigInteger('ref_id')->nullable();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->timestampTz('ts')->useCurrent();
                $table->jsonb('meta')->nullable();
                $table->text('notas')->nullable();
                $table->timestampsTz();

                $table->index('item_id');
                $table->index('inventory_batch_id');
                $table->index('tipo');
                $table->index('sucursal_id');
                $table->index('sucursal_dest');
                $table->index('almacen_id');
                $table->index('ts');
            });
        }

        if (! $schema->hasTable('recepcion_adjuntos')) {
            $schema->create('recepcion_adjuntos', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('recepcion_id');
                $table->string('tipo', 20);
                $table->string('file_url');
                $table->text('notas')->nullable();
                $table->unsignedBigInteger('uploaded_by')->nullable();
                $table->timestampsTz();

                $table->index('recepcion_id');
            });
        }
    }

    public function down(): void
    {
        $schema = Schema::connection($this->connection);

        foreach (['recepcion_adjuntos', 'mov_inv', 'recepcion_det', 'inventory_batch', 'recepcion_cab'] as $table) {
            if ($schema->hasTable($table)) {
                $schema->drop($table);
            }
        }
    }
};
