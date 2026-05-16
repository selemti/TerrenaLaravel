<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('CREATE SCHEMA IF NOT EXISTS selemti');

        $schema = Schema::connection('pgsql');
        if ($this->tableExists('purchase_suggestions')) {
            return;
        }

        $schema->create('selemti.purchase_suggestions', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('folio', 20)->unique()->comment('PSC-2025-001234');

            $table->bigInteger('sucursal_id')->nullable();
            $table->bigInteger('almacen_id')->nullable();

            $table->string('estado', 20)->default('PENDIENTE')
                ->comment('PENDIENTE, REVISADA, APROBADA, CONVERTIDA, RECHAZADA');
            $table->string('prioridad', 20)->default('NORMAL')
                ->comment('URGENTE, ALTA, NORMAL, BAJA');
            $table->string('origen', 20)->default('AUTO')
                ->comment('AUTO, MANUAL, EVENTO_ESPECIAL');

            $table->integer('total_items')->default(0);
            $table->decimal('total_estimado', 18, 2)->default(0);

            $table->timestamp('sugerido_en')->useCurrent();
            $table->integer('sugerido_por_user_id')->nullable()
                ->comment('FK a selemti.users.id');
            $table->integer('revisado_por_user_id')->nullable()
                ->comment('FK a selemti.users.id');
            $table->timestamp('revisado_en')->nullable();
            $table->bigInteger('convertido_a_request_id')->nullable()
                ->comment('FK a selemti.purchase_requests.id');
            $table->timestamp('convertido_en')->nullable();

            $table->integer('dias_analisis')->default(7)
                ->comment('Días usados para calcular consumo promedio');
            $table->boolean('consumo_promedio_calculado')->default(true);
            $table->text('notas')->nullable();
            $table->jsonb('meta')->nullable();

            $table->timestamps();

            $table->foreign('sucursal_id', 'fk_psugg_sucursal')
                ->references('id')
                ->on('selemti.cat_sucursales')
                ->onDelete('set null');

            $table->foreign('almacen_id', 'fk_psugg_almacen')
                ->references('id')
                ->on('selemti.cat_almacenes')
                ->onDelete('set null');

            // FKs to pre-existing legacy tables omitted — added post-migration via ALTER IF those tables exist

            $table->index('estado', 'idx_psugg_estado');
            $table->index('prioridad', 'idx_psugg_prioridad');
            $table->index('sugerido_en', 'idx_psugg_fecha');
            $table->index(['sucursal_id', 'estado'], 'idx_psugg_sucursal_estado');
        });

        DB::statement("COMMENT ON TABLE selemti.purchase_suggestions IS 'Sugerencias automáticas de compra basadas en stock policies'");
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.purchase_suggestions');
    }

    private function tableExists(string $table): bool
    {
        // Compatible con PostgreSQL 9.5 (sin to_regclass)
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema IN ('selemti', 'public') AND table_name = ? LIMIT 1",
            [$table]
        );

        return ! empty($result);
    }
};
