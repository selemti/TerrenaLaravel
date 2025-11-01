<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('pgsql')->create('report_favorites', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id');
            $table->string('report_key', 120);
            $table->jsonb('meta')->nullable();
            $table->timestampsTz();

            $table->unique(['user_id', 'report_key']);
            $table->index('report_key');
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('report_favorites');
    }
};
