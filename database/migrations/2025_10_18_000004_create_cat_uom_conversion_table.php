<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if ($this->tableExists()) {
            return;
        }

        Schema::connection('pgsql')->create('selemti.cat_uom_conversion', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('origen_id');
            $table->unsignedBigInteger('destino_id');
            $table->decimal('factor', 18, 6);
            $table->timestamps();

            $table->unique(['origen_id', 'destino_id'], 'uq_cat_uom_conversion_pair');

            $table->foreign('origen_id', 'fk_cat_uom_conv_origen')
                ->references('id')
                ->on('selemti.cat_unidades')
                ->cascadeOnDelete();

            $table->foreign('destino_id', 'fk_cat_uom_conv_destino')
                ->references('id')
                ->on('selemti.cat_unidades')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::connection('pgsql')->dropIfExists('selemti.cat_uom_conversion');
    }

    private function tableExists(): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT to_regclass('selemti.cat_uom_conversion') AS regclass"
        );

        return ! empty($result?->regclass);
    }
};
