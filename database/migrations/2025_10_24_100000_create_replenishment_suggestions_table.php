<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        if (! $schema->hasTable('replenishment_suggestions')) {
            $schema->create('replenishment_suggestions', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('folio', 40)->unique()->nullable()->comment('Folio único de la sugerencia');

                // Tipo y clasificación
                $table->string('tipo', 20)->comment('COMPRA | PRODUCCION');
                $table->string('prioridad', 20)->default('NORMAL')->comment('URGENTE | ALTA | NORMAL | BAJA');
                $table->string('origen', 40)->default('AUTO')->comment('AUTO | MANUAL | EVENTO_ESPECIAL');

                // Item y ubicación
                $table->string('item_id', 20)->comment('FK to items.id');
                $table->unsignedBigInteger('sucursal_id')->nullable();
                $table->unsignedBigInteger('almacen_id')->nullable();

                // Cantidades y análisis
                $table->decimal('stock_actual', 18, 6)->comment('Stock al momento de la sugerencia');
                $table->decimal('stock_min', 18, 6)->comment('Mínimo según política');
                $table->decimal('stock_max', 18, 6)->comment('Máximo según política');
                $table->decimal('qty_sugerida', 18, 6)->comment('Cantidad sugerida a pedir/producir');
                $table->decimal('qty_aprobada', 18, 6)->nullable()->comment('Cantidad ajustada por usuario');
                $table->string('uom', 20);

                // Análisis de consumo
                $table->decimal('consumo_promedio_diario', 18, 6)->nullable()->comment('Promedio últimos 7-30 días');
                $table->integer('dias_stock_restante')->nullable()->comment('Días de inventario al ritmo actual');
                $table->date('fecha_agotamiento_estimada')->nullable()->comment('Cuándo se acabaría el stock');

                // Estados y flujo
                $table->string('estado', 24)->default('PENDIENTE');
                // PENDIENTE -> REVISADA -> APROBADA -> CONVERTIDA
                // PENDIENTE -> REVISADA -> RECHAZADA
                // PENDIENTE -> CADUCADA (si pasa tiempo sin revisar)

                // Trazabilidad de conversión
                $table->unsignedBigInteger('purchase_request_id')->nullable();
                $table->unsignedBigInteger('production_order_id')->nullable();

                // Fechas y usuarios
                $table->timestampTz('sugerido_en')->useCurrent();
                $table->timestampTz('revisado_en')->nullable();
                $table->unsignedBigInteger('revisado_por')->nullable();
                $table->timestampTz('convertido_en')->nullable();
                $table->timestampTz('caduca_en')->nullable()->comment('Auto-rechazar si no se revisa antes de esta fecha');

                // Contexto y justificación
                $table->text('motivo')->nullable()->comment('Por qué se sugirió');
                $table->text('motivo_rechazo')->nullable()->comment('Por qué se rechazó');
                $table->text('notas')->nullable()->comment('Notas del usuario');
                $table->jsonb('meta')->nullable()->comment('Metadata: proveedor preferido, evento, etc.');

                $table->timestampsTz();

                // Índices para performance
                $table->index('tipo');
                $table->index('prioridad');
                $table->index('estado');
                $table->index(['item_id', 'sucursal_id']);
                $table->index('sugerido_en');
                $table->index('fecha_agotamiento_estimada');
                $table->index('revisado_por');
                $table->index('purchase_request_id');
                $table->index('production_order_id');
            });
        }

        // Vista para dashboard de gerente
        DB::connection('pgsql')->statement("
            CREATE OR REPLACE VIEW selemti.vw_replenishment_dashboard AS
            SELECT
                rs.*,
                i.item_code as item_codigo,
                i.nombre as item_nombre,
                s.nombre as sucursal_nombre,
                CASE
                    WHEN rs.fecha_agotamiento_estimada <= CURRENT_DATE THEN 'CRITICO'
                    WHEN rs.fecha_agotamiento_estimada <= CURRENT_DATE + INTERVAL '3 days' THEN 'URGENTE'
                    WHEN rs.fecha_agotamiento_estimada <= CURRENT_DATE + INTERVAL '7 days' THEN 'PROXIMO'
                    ELSE 'NORMAL'
                END as nivel_urgencia,
                CASE
                    WHEN rs.stock_actual <= 0 THEN 'SIN_STOCK'
                    WHEN rs.stock_actual < rs.stock_min THEN 'BAJO_MINIMO'
                    ELSE 'OK'
                END as estado_stock
            FROM selemti.replenishment_suggestions rs
            LEFT JOIN selemti.items i ON i.id = rs.item_id
            LEFT JOIN selemti.cat_sucursales s ON s.id = rs.sucursal_id
        ");
    }

    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        DB::connection('pgsql')->statement('DROP VIEW IF EXISTS selemti.vw_replenishment_dashboard');

        if ($schema->hasTable('replenishment_suggestions')) {
            $schema->drop('replenishment_suggestions');
        }
    }
};
