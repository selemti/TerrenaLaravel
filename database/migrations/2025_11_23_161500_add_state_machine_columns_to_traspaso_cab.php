<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('selemti.traspaso_cab', function (Blueprint $table) {
            // Columns for state machine: BORRADOR → VALIDADA → POSTEADA
            $table->unsignedBigInteger('validada_por')->nullable();
            $table->timestamp('validada_at')->nullable();
            $table->unsignedBigInteger('posteada_por')->nullable();
            $table->timestamp('posteada_at')->nullable();
            
            // Add foreign key constraints
            $table->foreign('validada_por')->references('id')->on('users');
            $table->foreign('posteada_por')->references('id')->on('users');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('selemti.traspaso_cab', function (Blueprint $table) {
            $table->dropForeign(['validada_por']);
            $table->dropForeign(['posteada_por']);
            
            $table->dropColumn([
                'validada_por',
                'validada_at',
                'posteada_por',
                'posteada_at'
            ]);
        });
    }
};