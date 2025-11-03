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
        Schema::connection('pgsql')->table('selemti.cat_sucursales', function (Blueprint $table) {
            $table->string('pos_location', 64)->nullable()->after('ubicacion');
            $table->index('pos_location');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->table('selemti.cat_sucursales', function (Blueprint $table) {
            $table->dropIndex(['pos_location']);
            $table->dropColumn('pos_location');
        });
    }
};
