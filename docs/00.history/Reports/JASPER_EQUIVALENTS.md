Jasper Equivalents (FloreantPOS) — Terrena Reports

- SQL source: `database/sql/reportes/script_sql_reportes_adicionales.sql`
- Views created:
  - `vw_ticket_base` (helper)
  - `vw_report_sales_detail`
  - `vw_report_sales_summary`
  - `vw_report_balance_detail`
  - `vw_report_sales_exceptions`
  - `vw_report_menu_usage`
  - `vw_report_journal_lines`, `vw_report_journal_payments`

Common filters
- `start` `end` (YYYY-MM-DD)
- `branch` (branch_key, case-insensitive)
- `terminal` (comma-separated terminal ids)

Web endpoints (Blade)
- `GET /reports/sales/detail` → `App\Http\Controllers\Reports\SalesDetailController@show`
- `GET /reports/sales/summary` → `App\Http\Controllers\Reports\SalesSummaryController@show`
- `GET /reports/sales/balance` → `App\Http\Controllers\Reports\SalesBalanceController@show`
- `GET /reports/sales/exceptions` → `App\Http\Controllers\Reports\SalesExceptionsController@show`
- `GET /reports/menu/usage` → `App\Http\Controllers\Reports\MenuUsageController@show`
- `GET /reports/sales/journal` → `App\Http\Controllers\Reports\SalesJournalController@show`

API endpoints (JSON)
- `GET /api/reports/sales/detail`
- `GET /api/reports/sales/summary`
- `GET /api/reports/sales/balance`
- `GET /api/reports/sales/exceptions`
- `GET /api/reports/menu/usage`
- `GET /api/reports/sales/journal`

Notes
- Timezone and search_path are ensured by `ConfiguresReportConnection`.
- Terminal filter uses view columns when present or ticket join via `ticket_id`.
- Only read operations; no data mutation.

