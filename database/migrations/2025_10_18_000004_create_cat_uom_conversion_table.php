<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (! Schema::hasTable('cat_uom_conversion')) {
            Schema::create('cat_uom_conversion', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->foreignId('origen_id')->constrained('cat_unidades')->cascadeOnDelete();
                $table->foreignId('destino_id')->constrained('cat_unidades')->cascadeOnDelete();
                $table->decimal('factor', 18, 6);
                $table->timestamps();

                $table->unique(['origen_id', 'destino_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('cat_uom_conversion');
    }
};
