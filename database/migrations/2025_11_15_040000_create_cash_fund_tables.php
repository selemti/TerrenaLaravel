<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        if (! $schema->hasTable('caja_fondo')) {
            $schema->create('caja_fondo', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('sucursal_id');
                $table->date('fecha');
                $table->decimal('monto_inicial', 14, 2);
                $table->string('moneda', 10)->default('MXN');
                $table->string('estado', 24)->default('ABIERTO');
                $table->unsignedBigInteger('creado_por');
                $table->timestampTz('creado_en')->useCurrent();
                $table->timestampTz('actualizado_en')->nullable();
                $table->jsonb('meta')->nullable();

                $table->unique(['sucursal_id', 'fecha']);
                $table->index(['estado']);
            });
        }

        if (! $schema->hasTable('caja_fondo_usuario')) {
            $schema->create('caja_fondo_usuario', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('fondo_id');
                $table->unsignedBigInteger('user_id');
                $table->string('rol', 20);
                $table->timestampsTz();

                $table->index(['fondo_id']);
                $table->index(['user_id']);
            });
        }

        if (! $schema->hasTable('caja_fondo_mov')) {
            $schema->create('caja_fondo_mov', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('fondo_id');
                $table->timestampTz('fecha_hora')->useCurrent();
                $table->string('tipo', 20); // EGRESO/REINTEGRO/DEPOSITO
                $table->string('concepto');
                $table->unsignedBigInteger('proveedor_id')->nullable();
                $table->decimal('monto', 14, 2);
                $table->string('metodo', 20)->default('EFECTIVO');
                $table->boolean('requiere_comprobante')->default(false);
                $table->string('estatus', 24)->default('CAPTURADO');
                $table->unsignedBigInteger('creado_por');
                $table->unsignedBigInteger('aprobado_por')->nullable();
                $table->timestampTz('aprobado_en')->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index(['fondo_id']);
                $table->index(['estatus']);
            });
        }

        if (! $schema->hasTable('caja_fondo_adj')) {
            $schema->create('caja_fondo_adj', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('mov_id');
                $table->string('tipo', 20);
                $table->string('archivo_url');
                $table->text('observaciones')->nullable();
                $table->timestampsTz();

                $table->index(['mov_id']);
            });
        }

        if (! $schema->hasTable('caja_fondo_arqueo')) {
            $schema->create('caja_fondo_arqueo', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('fondo_id');
                $table->timestampTz('fecha_cierre')->useCurrent();
                $table->decimal('efectivo_contado', 14, 2);
                $table->decimal('diferencia', 14, 2)->default(0);
                $table->text('observaciones')->nullable();
                $table->unsignedBigInteger('cerrado_por');
                $table->timestampsTz();

                $table->index(['fondo_id']);
            });
        }
    }

    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        foreach (['caja_fondo_arqueo', 'caja_fondo_adj', 'caja_fondo_mov', 'caja_fondo_usuario', 'caja_fondo'] as $table) {
            if ($schema->hasTable($table)) {
                $schema->drop($table);
            }
        }
    }
};
