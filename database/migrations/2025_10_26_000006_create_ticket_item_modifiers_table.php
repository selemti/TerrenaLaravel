<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Creates the ticket_item_modifiers table to log modifiers for each sold item.
 *
 * @version 2.1
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if ($this->tableExists('ticket_item_modifiers')) {
            return;
        }

        Schema::connection('pgsql')->create('selemti.ticket_item_modifiers', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('ticket_id')->index('ticket_item_modifiers_ticket_id_idx');
            $table->unsignedBigInteger('ticket_item_id')->index('ticket_item_modifiers_ticket_item_id_idx');
            $table->unsignedBigInteger('sucursal_id')->nullable();
            $table->unsignedBigInteger('terminal_id')->nullable();
            $table->boolean('procesado')->default(false);
            $table->timestamp('fecha_proceso')->nullable();
            $table->string('pos_code')->nullable()->comment('Código/modificador POS (opcional).');
            $table->unsignedBigInteger('recipe_version_id')->nullable()->comment('Versión de receta aplicada al modificador.');
            $table->decimal('precio_extra', 12, 4)->default(0)->comment('Sobrecargo aplicado por el POS.');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.ticket_item_modifiers');
    }

    private function tableExists(string $table): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT to_regclass('selemti.' || ?) AS regclass",
            [$table]
        );

        return ! empty($result?->regclass);
    }
};
