<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->addColumnIfMissing('selemti.alert_rules', 'scope', function (Blueprint $table): void {
            $table->string('scope', 40)->default('global');
        });

        $this->addColumnIfMissing('selemti.alert_rules', 'threshold_numeric', function (Blueprint $table): void {
            $table->decimal('threshold_numeric', 14, 4)->nullable();
        });

        $this->addColumnIfMissing('selemti.alert_rules', 'threshold_percent', function (Blueprint $table): void {
            $table->decimal('threshold_percent', 7, 4)->nullable();
        });

        $this->addColumnIfMissing('selemti.alert_rules', 'notification_channels', function (Blueprint $table): void {
            $table->jsonb('notification_channels')->nullable();
        });

        $this->addColumnIfMissing('selemti.alert_events', 'assigned_to', function (Blueprint $table): void {
            $table->unsignedBigInteger('assigned_to')->nullable();
        });

        $this->addColumnIfMissing('selemti.alert_events', 'acknowledged_at', function (Blueprint $table): void {
            $table->timestampTz('acknowledged_at')->nullable();
        });

        $this->addColumnIfMissing('selemti.alert_events', 'resolution_notes', function (Blueprint $table): void {
            $table->text('resolution_notes')->nullable();
        });

        $this->addColumnIfMissing('selemti.alert_events', 'severity', function (Blueprint $table): void {
            $table->string('severity', 20)->default('medium');
        });
    }

    public function down(): void
    {
        $self = $this;

        Schema::connection('pgsql')->table('selemti.alert_events', function (Blueprint $table) use ($self): void {
            foreach (['assigned_to', 'acknowledged_at', 'resolution_notes', 'severity'] as $column) {
                if ($self->columnExists('selemti.alert_events', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::connection('pgsql')->table('selemti.alert_rules', function (Blueprint $table) use ($self): void {
            foreach (['scope', 'threshold_numeric', 'threshold_percent', 'notification_channels'] as $column) {
                if ($self->columnExists('selemti.alert_rules', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }

    private function addColumnIfMissing(string $table, string $column, callable $callback): void
    {
        if ($this->columnExists($table, $column)) {
            return;
        }

        Schema::connection('pgsql')->table($table, $callback);
    }

    private function columnExists(string $table, string $column): bool
    {
        [$schema, $name] = explode('.', $table, 2);

        $result = DB::selectOne(
            'SELECT 1 FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
            [$schema, $name, $column]
        );

        return $result !== null;
    }
};
