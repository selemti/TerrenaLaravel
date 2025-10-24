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
        $schema = Schema::connection('pgsql');

        if ($schema->hasTable('selemti.recepcion_cab')) {
            $schema->table('selemti.recepcion_cab', function (Blueprint $table) use ($schema) {
                // Agregar almacen_id si no existe
                if (!$schema->hasColumn('selemti.recepcion_cab', 'almacen_id')) {
                    $table->string('almacen_id', 36)->nullable()->after('sucursal_id');
                    $table->index('almacen_id');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $schema = Schema::connection('pgsql');

        if ($schema->hasTable('selemti.recepcion_cab')) {
            $schema->table('selemti.recepcion_cab', function (Blueprint $table) use ($schema) {
                if ($schema->hasColumn('selemti.recepcion_cab', 'almacen_id')) {
                    $table->dropIndex(['almacen_id']);
                    $table->dropColumn('almacen_id');
                }
            });
        }
    }
};
