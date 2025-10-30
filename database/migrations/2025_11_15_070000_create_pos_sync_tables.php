<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('pgsql')->create('selemti.pos_sync_batches', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->string('source_system', 50);
            $table->string('status', 20)->default('pending');
            $table->timestampTz('started_at')->nullable();
            $table->timestampTz('finished_at')->nullable();
            $table->unsignedInteger('rows_processed')->default(0);
            $table->unsignedInteger('rows_successful')->default(0);
            $table->unsignedInteger('rows_failed')->default(0);
            $table->jsonb('metadata')->nullable();
            $table->jsonb('errors')->nullable();
            $table->timestampsTz();
        });

        Schema::connection('pgsql')->create('selemti.pos_sync_logs', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('batch_id');
            $table->string('external_id', 120)->nullable();
            $table->string('action', 50);
            $table->string('status', 20);
            $table->jsonb('payload')->nullable();
            $table->text('message')->nullable();
            $table->timestampTz('created_at')->default(DB::raw('CURRENT_TIMESTAMP'));

            $table->foreign('batch_id')
                ->references('id')
                ->on('selemti.pos_sync_batches')
                ->onDelete('cascade');
            $table->index(['batch_id', 'status']);
            $table->index(['external_id']);
        });

        Schema::connection('pgsql')->create('selemti.menu_items', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('recipe_id')->nullable();
            $table->string('plu', 80)->unique();
            $table->string('name');
            $table->string('category')->nullable();
            $table->boolean('active')->default(true);
            $table->jsonb('metadata')->nullable();
            $table->timestampsTz();
        });

        Schema::connection('pgsql')->create('selemti.menu_item_sync_map', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('menu_item_id');
            $table->string('pos_identifier', 120);
            $table->string('channel', 40)->default('pos');
            $table->jsonb('metadata')->nullable();
            $table->timestampsTz();

            $table->foreign('menu_item_id')
                ->references('id')
                ->on('selemti.menu_items')
                ->onDelete('cascade');
            $table->unique(['pos_identifier', 'channel']);
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.menu_item_sync_map');
        Schema::connection('pgsql')->dropIfExists('selemti.menu_items');
        Schema::connection('pgsql')->dropIfExists('selemti.pos_sync_logs');
        Schema::connection('pgsql')->dropIfExists('selemti.pos_sync_batches');
    }
};
