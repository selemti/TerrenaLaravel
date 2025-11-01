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
        $tableNames = config('permission.table_names');

        if (empty($tableNames)) {
            throw new \Exception('Error: config/permission.php not found and defaults could not be merged.');
        }

        // Verificar si la foreign key ya existe (soporta prefijo generado por Postgres)
        $existingConstraint = \Illuminate\Support\Facades\DB::connection('pgsql')->selectOne("
            SELECT conname
            FROM pg_constraint
            WHERE conrelid = 'selemti.audit_log'::regclass
              AND contype = 'f'
              AND conname IN ('audit_log_user_id_foreign', 'selemti_audit_log_user_id_foreign')
            LIMIT 1
        ");

        if (!$existingConstraint) {
            Schema::connection('pgsql')->table('selemti.audit_log', function (Blueprint $table) {
                $table->foreign('user_id')
                    ->references('id')
                    ->on('selemti.users')
                    ->onDelete('set null');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $tableNames = config('permission.table_names');

        if (empty($tableNames)) {
            throw new \Exception('Error: config/permission.php not found and defaults could not be merged.');
        }

        // Verificar si la foreign key existe antes de intentar eliminarla
        $existingConstraint = \Illuminate\Support\Facades\DB::connection('pgsql')->selectOne("
            SELECT conname
            FROM pg_constraint
            WHERE conrelid = 'selemti.audit_log'::regclass
              AND contype = 'f'
              AND conname IN ('audit_log_user_id_foreign', 'selemti_audit_log_user_id_foreign')
            LIMIT 1
        ");

        if ($existingConstraint) {
            $constraintName = $existingConstraint->conname;

            Schema::connection('pgsql')->table('selemti.audit_log', function (Blueprint $table) use ($constraintName) {
                $table->dropForeign($constraintName);
            });
        }
    }
};