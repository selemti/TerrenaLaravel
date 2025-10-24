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
        Schema::table('recepcion_cab', function (Blueprint $table) {
            $table->string('estado')->nullable()->after('fecha_recepcion');
            $table->decimal('total_presentaciones', 15, 4)->nullable()->after('estado');
            $table->decimal('total_canonico', 15, 4)->nullable()->after('total_presentaciones');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('recepcion_cab', function (Blueprint $table) {
            $table->dropColumn(['estado', 'total_presentaciones', 'total_canonico']);
        });
    }
};
