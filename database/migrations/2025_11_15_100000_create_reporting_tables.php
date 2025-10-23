<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('pgsql')->create('selemti.report_definitions', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('category')->nullable();
            $table->jsonb('config');
            $table->boolean('is_system')->default(false);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestampsTz();
        });

        Schema::connection('pgsql')->create('selemti.report_runs', function (Blueprint $table): void {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('report_id');
            $table->unsignedBigInteger('requested_by')->nullable();
            $table->string('status', 20)->default('pending');
            $table->jsonb('filters')->nullable();
            $table->jsonb('result_meta')->nullable();
            $table->string('storage_path')->nullable();
            $table->timestampTz('queued_at')->nullable();
            $table->timestampTz('started_at')->nullable();
            $table->timestampTz('finished_at')->nullable();
            $table->timestampsTz();

            $table->foreign('report_id')
                ->references('id')
                ->on('selemti.report_definitions')
                ->onDelete('cascade');
            $table->index(['report_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.report_runs');
        Schema::connection('pgsql')->dropIfExists('selemti.report_definitions');
    }
};
