<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    protected function scriptPath(): string
    {
        $candidates = [
            base_path('docs/docs/BD/NoviembreDocsDocs/VentasReport/v9/script_sql_reportes_adicionales.sql'),
            base_path('database/sql/reportes/script_sql_reportes_adicionales.sql'),
        ];

        foreach ($candidates as $path) {
            if (file_exists($path)) {
                return $path;
            }
        }

        throw new RuntimeException('SQL script not found in expected locations.');
    }

    public function up(): void
    {
        DB::unprepared(file_get_contents($this->scriptPath()));
    }

    public function down(): void
    {
        // Reapply the script to keep the views defined; reverting to the previous
        // implementation is not supported because it underreported descuentos.
        DB::unprepared(file_get_contents($this->scriptPath()));
    }
};
