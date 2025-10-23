<?php

use Illuminate\\Database\\Migrations\\Migration;
use Illuminate\\Database\\Schema\\Blueprint;
use Illuminate\\Support\\Facades\\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        if (! $schema->hasTable('purchase_requests')) {
            $schema->create('purchase_requests', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('folio', 40)->nullable()->unique();
                $table->string('sucursal_id', 36)->nullable();
                $table->unsignedBigInteger('created_by');
                $table->unsignedBigInteger('requested_by')->nullable();
                $table->timestampTz('requested_at')->useCurrent();
                $table->string('estado', 24)->default('BORRADOR');
                $table->decimal('importe_estimado', 18, 6)->default(0);
                $table->text('notas')->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('sucursal_id');
                $table->index('estado');
                $table->index('requested_at');
            });
        }

        if (! $schema->hasTable('purchase_request_lines')) {
            $schema->create('purchase_request_lines', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('request_id');
                $table->unsignedBigInteger('item_id');
                $table->decimal('qty', 18, 6);
                $table->string('uom', 20);
                $table->date('fecha_requerida')->nullable();
                $table->unsignedBigInteger('preferred_vendor_id')->nullable();
                $table->decimal('last_price', 18, 6)->nullable();
                $table->string('estado', 24)->default('PENDIENTE');
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('request_id');
                $table->index('item_id');
                $table->index('preferred_vendor_id');
            });
        }

        if (! $schema->hasTable('purchase_vendor_quotes')) {
            $schema->create('purchase_vendor_quotes', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('request_id');
                $table->unsignedBigInteger('vendor_id');
                $table->string('folio_proveedor', 60)->nullable();
                $table->string('estado', 24)->default('RECIBIDA');
                $table->timestampTz('enviada_en')->useCurrent();
                $table->timestampTz('recibida_en')->nullable();
                $table->decimal('subtotal', 18, 6)->default(0);
                $table->decimal('descuento', 18, 6)->default(0);
                $table->decimal('impuestos', 18, 6)->default(0);
                $table->decimal('total', 18, 6)->default(0);
                $table->unsignedBigInteger('capturada_por')->nullable();
                $table->unsignedBigInteger('aprobada_por')->nullable();
                $table->timestampTz('aprobada_en')->nullable();
                $table->text('notas')->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index(['request_id', 'vendor_id'], 'purchase_vendor_quotes_request_vendor_idx');
                $table->index('estado');
            });
        }

        if (! $schema->hasTable('purchase_vendor_quote_lines')) {
            $schema->create('purchase_vendor_quote_lines', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('quote_id');
                $table->unsignedBigInteger('request_line_id');
                $table->unsignedBigInteger('item_id');
                $table->decimal('qty_oferta', 18, 6);
                $table->string('uom_oferta', 20);
                $table->decimal('precio_unitario', 18, 6);
                $table->decimal('pack_size', 18, 6)->default(1);
                $table->string('pack_uom', 20)->nullable();
                $table->decimal('monto_total', 18, 6);
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('quote_id');
                $table->index('request_line_id');
                $table->index('item_id');
            });
        }

        if (! $schema->hasTable('purchase_orders')) {
            $schema->create('purchase_orders', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('folio', 40)->nullable()->unique();
                $table->unsignedBigInteger('quote_id')->nullable();
                $table->unsignedBigInteger('vendor_id');
                $table->string('sucursal_id', 36)->nullable();
                $table->string('estado', 24)->default('BORRADOR');
                $table->date('fecha_promesa')->nullable();
                $table->decimal('subtotal', 18, 6)->default(0);
                $table->decimal('descuento', 18, 6)->default(0);
                $table->decimal('impuestos', 18, 6)->default(0);
                $table->decimal('total', 18, 6)->default(0);
                $table->unsignedBigInteger('creado_por');
                $table->unsignedBigInteger('aprobado_por')->nullable();
                $table->timestampTz('aprobado_en')->nullable();
                $table->text('notas')->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('vendor_id');
                $table->index('estado');
            });
        }

        if (! $schema->hasTable('purchase_order_lines')) {
            $schema->create('purchase_order_lines', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('order_id');
                $table->unsignedBigInteger('request_line_id')->nullable();
                $table->unsignedBigInteger('item_id');
                $table->decimal('qty', 18, 6);
                $table->string('uom', 20);
                $table->decimal('precio_unitario', 18, 6);
                $table->decimal('descuento', 18, 6)->default(0);
                $table->decimal('impuestos', 18, 6)->default(0);
                $table->decimal('total', 18, 6);
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('order_id');
                $table->index('item_id');
            });
        }

        if (! $schema->hasTable('purchase_documents')) {
            $schema->create('purchase_documents', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('request_id')->nullable();
                $table->unsignedBigInteger('quote_id')->nullable();
                $table->unsignedBigInteger('order_id')->nullable();
                $table->string('tipo', 30);
                $table->string('file_url');
                $table->unsignedBigInteger('uploaded_by')->nullable();
                $table->text('notas')->nullable();
                $table->timestampsTz();

                $table->index('request_id');
                $table->index('quote_id');
                $table->index('order_id');
            });
        }
    }

    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        foreach ([
            'purchase_documents',
            'purchase_order_lines',
            'purchase_orders',
            'purchase_vendor_quote_lines',
            'purchase_vendor_quotes',
            'purchase_request_lines',
            'purchase_requests',
        ] as $table) {
            if ($schema->hasTable($table)) {
                $schema->drop($table);
            }
        }
    }
};
