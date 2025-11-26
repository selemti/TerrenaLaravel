<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! $this->tableExists()) {
            Schema::connection('pgsql')->create('selemti.audit_log', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->timestamp('timestamp')->nullable();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->string('accion')->nullable();
                $table->string('entidad')->nullable();
                $table->unsignedBigInteger('entidad_id')->nullable();
                $table->text('motivo')->nullable();
                $table->text('evidencia_url')->nullable();
                $table->jsonb('payload_json')->nullable();

                $table->index(['timestamp'], 'idx_audit_log_timestamp');
                $table->index(['user_id'], 'idx_audit_log_user_id');
                $table->index(['accion'], 'idx_audit_log_accion');
                $table->index(['entidad'], 'idx_audit_log_entidad');
                $table->index(['entidad_id'], 'idx_audit_log_entidad_id');
                $table->foreign('user_id')->references('id')->on('selemti.users')->onDelete('set null');
            });

            return;
        }

        $needsTimestamp = ! $this->indexExists('idx_audit_log_timestamp');
        $needsUser = ! $this->indexExists('idx_audit_log_user_id');
        $needsAccion = ! $this->indexExists('idx_audit_log_accion');
        $needsEntidad = ! $this->indexExists('idx_audit_log_entidad');
        $needsEntidadId = ! $this->indexExists('idx_audit_log_entidad_id');
        $needsForeign = ! $this->foreignExists('selemti_audit_log_user_id_foreign');

        if ($needsTimestamp || $needsUser || $needsAccion || $needsEntidad || $needsEntidadId || $needsForeign) {
            Schema::connection('pgsql')->table('selemti.audit_log', function (Blueprint $table) use (
                $needsTimestamp,
                $needsUser,
                $needsAccion,
                $needsEntidad,
                $needsEntidadId,
                $needsForeign
            ) {
                if ($needsTimestamp) {
                    $table->index(['timestamp'], 'idx_audit_log_timestamp');
                }

                if ($needsUser) {
                    $table->index(['user_id'], 'idx_audit_log_user_id');
                }

                if ($needsAccion) {
                    $table->index(['accion'], 'idx_audit_log_accion');
                }

                if ($needsEntidad) {
                    $table->index(['entidad'], 'idx_audit_log_entidad');
                }

                if ($needsEntidadId) {
                    $table->index(['entidad_id'], 'idx_audit_log_entidad_id');
                }

                if ($needsForeign) {
                    $table->foreign('user_id')->references('id')->on('selemti.users')->onDelete('set null');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! $this->tableExists()) {
            return;
        }

        $self = $this;

        Schema::connection('pgsql')->table('selemti.audit_log', function (Blueprint $table) use ($self) {
            if ($self->foreignExists('selemti_audit_log_user_id_foreign')) {
                $table->dropForeign('selemti_audit_log_user_id_foreign');
            }

            foreach ([
                'idx_audit_log_timestamp',
                'idx_audit_log_user_id',
                'idx_audit_log_accion',
                'idx_audit_log_entidad',
                'idx_audit_log_entidad_id',
            ] as $index) {
                if ($self->indexExists($index)) {
                    $table->dropIndex($index);
                }
            }
        });
    }

    protected function tableExists(): bool
    {
        // Compatible con PostgreSQL 9.5 (sin to_regclass)
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 FROM information_schema.tables WHERE table_schema = 'selemti' AND table_name = 'audit_log' LIMIT 1"
        );

        return ! empty($result);
    }

    protected function indexExists(string $indexName): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            "SELECT 1 AS exists FROM pg_indexes WHERE schemaname = 'selemti' AND indexname = ? LIMIT 1",
            [$indexName]
        );

        return ! empty($result);
    }

    protected function foreignExists(string $constraint): bool
    {
        $result = DB::connection('pgsql')->selectOne(
            'SELECT 1 FROM pg_constraint WHERE conname = ? LIMIT 1',
            [$constraint]
        );

        return ! empty($result);
    }
};
