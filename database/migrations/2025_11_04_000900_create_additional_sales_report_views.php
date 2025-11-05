<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        $candidates = [
            base_path('BD/Noviembre/VentasReport/v9/script_sql_reportes_adicionales.sql'),
            base_path('database/sql/reportes/script_sql_reportes_adicionales.sql'),
        ];

        $path = null;
        foreach ($candidates as $p) {
            if (file_exists($p)) { $path = $p; break; }
        }

        if (!$path) {
            throw new RuntimeException('SQL script not found in expected locations.');
        }

        DB::unprepared(file_get_contents($path));
    }

    public function down(): void
    {
        // Drop created views in reverse order
        $drops = [
            'vw_report_journal_payments',
            'vw_report_journal_lines',
            'vw_report_menu_usage',
            'vw_report_sales_exceptions',
            'vw_report_balance_detail',
            'vw_report_sales_summary',
            'vw_report_sales_detail',
            'vw_ticket_base',
        ];

        foreach ($drops as $view) {
            DB::statement("DROP VIEW IF EXISTS {$view} CASCADE");
        }
    }
};
