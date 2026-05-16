<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
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
        $exists = \Illuminate\Support\Facades\DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='traspaso_cab' LIMIT 1"
        );
        if (! $exists) {
            return;
        }

        DB::connection('pgsql')->statement("
            DO \$\$
            BEGIN
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN validada_por BIGINT NULL; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN validada_at TIMESTAMP NULL; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN posteada_por BIGINT NULL; EXCEPTION WHEN duplicate_column THEN NULL; END;
                BEGIN ALTER TABLE selemti.traspaso_cab ADD COLUMN posteada_at TIMESTAMP NULL; EXCEPTION WHEN duplicate_column THEN NULL; END;
            END
            \$\$
        ");
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