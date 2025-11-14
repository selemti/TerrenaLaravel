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

        $rolesTable = $tableNames['roles'];

        Schema::table($rolesTable, function (Blueprint $table) use ($rolesTable) {
            if (! Schema::hasColumn($rolesTable, 'display_name')) {
                $table->string('display_name')->nullable()->after('guard_name');
            }
            if (! Schema::hasColumn($rolesTable, 'description')) {
                $table->text('description')->nullable()->after('display_name');
            }
            if (! Schema::hasColumn($rolesTable, 'color')) {
                $table->string('color', 7)->nullable()->after('description');
            }
        });
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

        $rolesTable = $tableNames['roles'];

        Schema::table($rolesTable, function (Blueprint $table) use ($rolesTable) {
            $columns = array_filter([
                Schema::hasColumn($rolesTable, 'display_name') ? 'display_name' : null,
                Schema::hasColumn($rolesTable, 'description') ? 'description' : null,
                Schema::hasColumn($rolesTable, 'color') ? 'color' : null,
            ]);

            if (! empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }
};
