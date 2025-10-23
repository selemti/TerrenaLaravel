<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $schema = Schema::connection('pgsql');

        if (! $schema->hasTable('labor_roles')) {
            $schema->create('labor_roles', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('clave', 40)->unique();
                $table->string('nombre', 120);
                $table->decimal('rate_per_hour', 18, 6)->default(0);
                $table->boolean('activo')->default(true);
                $table->text('descripcion')->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('activo');
            });
        }

        if (! $schema->hasTable('recipe_labor_steps')) {
            $schema->create('recipe_labor_steps', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('recipe_id');
                $table->unsignedBigInteger('labor_role_id')->nullable();
                $table->string('nombre', 160);
                $table->decimal('duracion_minutos', 10, 3)->default(0);
                $table->decimal('costo_manual', 18, 6)->nullable();
                $table->unsignedInteger('orden')->default(0);
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('recipe_id');
                $table->index('labor_role_id');
            });
        }

        if (! $schema->hasTable('overhead_definitions')) {
            $schema->create('overhead_definitions', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('clave', 60)->unique();
                $table->string('nombre', 160);
                $table->string('tipo', 40)->default('fixed_per_batch');
                $table->decimal('tasa', 18, 6)->default(0);
                $table->boolean('activo')->default(true);
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->index('activo');
                $table->index('tipo');
            });
        }

        if (! $schema->hasTable('recipe_overhead_allocations')) {
            $schema->create('recipe_overhead_allocations', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('recipe_id');
                $table->unsignedBigInteger('overhead_id');
                $table->decimal('valor', 18, 6)->nullable();
                $table->jsonb('meta')->nullable();
                $table->timestampsTz();

                $table->unique(['recipe_id', 'overhead_id'], 'recipe_overhead_unique');
                $table->index('overhead_id');
            });
        }

        if (! $schema->hasTable('recipe_extended_cost_history')) {
            $schema->create('recipe_extended_cost_history', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('recipe_id');
                $table->timestampTz('snapshot_at')->useCurrent();
                $table->decimal('mp_batch_cost', 18, 6)->default(0);
                $table->decimal('labor_batch_cost', 18, 6)->default(0);
                $table->decimal('overhead_batch_cost', 18, 6)->default(0);
                $table->decimal('total_batch_cost', 18, 6)->default(0);
                $table->decimal('portion_cost', 18, 6)->default(0);
                $table->decimal('yield_portions', 18, 6)->default(0);
                $table->jsonb('breakdown')->nullable();
                $table->timestampsTz();

                $table->index(['recipe_id', 'snapshot_at'], 'recipe_extended_cost_hist_idx');
            });
        }
    }

    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        $schema->dropIfExists('recipe_extended_cost_history');
        $schema->dropIfExists('recipe_overhead_allocations');
        $schema->dropIfExists('overhead_definitions');
        $schema->dropIfExists('recipe_labor_steps');
        $schema->dropIfExists('labor_roles');
    }
};
