<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::connection('pgsql')->table('selemti.cash_funds', function (Blueprint $table) {
            $table->string('descripcion', 255)->nullable()->after('moneda')
                ->comment('Descripción o nombre del fondo para identificación rápida');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->table('selemti.cash_funds', function (Blueprint $table) {
            $table->dropColumn('descripcion');
        });
    }
};
