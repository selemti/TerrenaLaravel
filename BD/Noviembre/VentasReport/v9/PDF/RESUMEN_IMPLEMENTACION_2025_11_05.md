# Resumen de implementación — Reportes de Ventas (V9)

Fecha: 2025-11-05
Entorno: Laravel 12 + PostgreSQL 9.5 (FloreantPOS)

## Alcance principal

- Replicados reportes tipo Jasper (FloreantPOS) en Terrena (solo lectura):
  - Detalle de ventas (vw_report_sales_detail)
  - Resumen de ventas (vw_report_sales_summary)
  - Balance por forma de pago (vw_report_balance_detail)
  - Excepciones (vw_report_sales_exceptions) — con fallback autosuficiente
  - Uso de menú (vw_report_menu_usage)
  - Journal (vw_report_journal_lines, vw_report_journal_payments)

## SQL (vistas creadas/ajustadas)

- Compatibles con PG 9.5 (ROUND sobre ::numeric, no double precision).
- ticket.service_charge (singular) y propinas desde gratuity(amount, paid, refunded).
- ticket_item usa item_price y discount (no unit_price, discount_amount).
- total_discount: tomado de ticket.total_discount (existe) o derivado desde líneas.

Referencias:
- `BD/Noviembre/VentasReport/v9/script_sql_reportes_adicionales.sql`
- `database/sql/reportes/script_sql_reportes_adicionales.sql`
- Bloques rápidos para crear vistas faltantes: `BD/Noviembre/VentasReport/v9/PDF/COMANDOS_SQL_VISTAS.sql`

## Endpoints (solo lectura)

- WEB (Blade)
  - `/reports/sales/detail` — Detalle
  - `/reports/sales/summary` — Resumen
  - `/reports/sales/balance` — Balance por forma de pago
  - `/reports/sales/exceptions` — Excepciones
  - `/reports/menu/usage` — Uso de menú
  - `/reports/sales/journal` y alias `/reports/journal` — Journal

- API (JSON)
  - `/api/reports/sales/detail|summary|balance|exceptions|journal`
  - `/api/reports/menu/usage`

Parámetros: `start`, `end` (YYYY-MM-DD), `branch` (una o varias coma-separadas o multiselect), `terminal` (coma-separado).

## Controladores y vistas (archivos clave)

- Controladores:
  - `app/Http/Controllers/Reports/SalesDetailController.php`
  - `app/Http/Controllers/Reports/SalesSummaryController.php` (incluye `exportPdf()` de ejemplo)
  - `app/Http/Controllers/Reports/SalesBalanceController.php`
  - `app/Http/Controllers/Reports/SalesExceptionsController.php` (fallback si falta la vista)
  - `app/Http/Controllers/Reports/MenuUsageController.php`
  - `app/Http/Controllers/Reports/SalesJournalController.php`

- Blades:
  - `resources/views/reports/sales/detail.blade.php`
  - `resources/views/reports/sales/summary.blade.php`
  - `resources/views/reports/sales/balance.blade.php`
  - `resources/views/reports/sales/exceptions.blade.php`
  - `resources/views/reports/sales/journal.blade.php`
  - `resources/views/reports/menu/usage.blade.php`

- Sidebar (menú): `resources/views/layouts/terrena.blade.php` — sección “Reportes”.

## Optimización en Mix de Ventas

- Vista pivotada por día/sucursal con columnas: Efectivo, Crédito, Débito, Otras, Venta neta.
- Separador mensual en rangos largos.
- Filtro multiselect de sucursales (branch[]).
- Archivos:
  - `app/Http/Controllers/Reports/SalesMixController.php`
  - `resources/views/reports/sales/mix.blade.php`

## Utilidades

- Comando Artisan solo lectura: `db:select` (solo SELECT/WITH; bindings JSON y `--first`).
- Trait de conexión reportes: timezone y search_path correctos.

## Validaciones ejecutadas / esperadas

- Consistencia (ejemplo 2025-10-24): summary.bruto ≈ balance.total (sumas por método), neto = bruto − descuento.
- Journal líneas/pagos con datos correctos.
- Excepciones: versión autosuficiente si no existen `vw_diag_*`.

## Errores comunes y solución

- “no existe la relación … vw_report_sales_exceptions/vw_report_menu_usage”: crear vistas con `COMANDOS_SQL_VISTAS.sql`.
- En PG 9.5, usar `ROUND(<expr>::numeric,2)`.
- Si persiste caché de rutas/config: `php artisan optimize:clear`.

## Próximos pasos sugeridos

- Añadir exportes PDF/Excel al resto de reportes (ya hay helper PDF y patrón Excel).
- Extender pivot a otros reportes si aplica.
- Si hay diferencias con FloreantPOS en fechas específicas, contrastar reglas (REFUND/VOID_TRANS, voided, propinas/servicio) y ajustar umbrales de “descuentos altos”.

