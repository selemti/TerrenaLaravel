# Instrucciones de validación — Reportes de Ventas

## 1) Preparación

- Asegura timezone/search_path:
  - `SET TIME ZONE 'America/Mexico_City';`
  - `SET search_path TO public, selemti;`
- Limpia cachés de Laravel si cambiaste código:
  - `php artisan optimize:clear`

## 2) Crear vistas faltantes (si aplica)

- Ejecuta `COMANDOS_SQL_VISTAS.sql` (mismo folder) para crear:
  - `public.vw_report_menu_usage`
  - `public.vw_report_sales_exceptions` (fallback autosuficiente)
- Verifica existencia:
  - `SELECT to_regclass('public.vw_report_menu_usage'), to_regclass('public.vw_report_sales_exceptions');`

## 3) Validaciones por fecha (ej. 2025-10-24)

- Summary (neto, bruto, descuento):
  - `SELECT * FROM public.vw_report_sales_summary WHERE folio_date='2025-10-24';`
- Balance (total cobrado):
  - `SELECT * FROM public.vw_report_balance_detail WHERE folio_date='2025-10-24';`
- Esperado: `SUM(summary.bruto) ≈ SUM(balance.monto)`; `neto = bruto − descuento`.

- Journal:
  - `SELECT * FROM public.vw_report_journal_lines WHERE folio_date='2025-10-24' LIMIT 10;`
  - `SELECT * FROM public.vw_report_journal_payments WHERE folio_date='2025-10-24' LIMIT 10;`

- Uso de menú:
  - `SELECT * FROM public.vw_report_menu_usage WHERE folio_date='2025-10-24' ORDER BY neto DESC LIMIT 10;`

- Excepciones:
  - `SELECT error_code, COUNT(*) FROM public.vw_report_sales_exceptions WHERE folio_date='2025-10-24' GROUP BY 1 ORDER BY 2 DESC;`

## 4) Endpoints web/API

- Web:
  - `/reports/sales/detail|summary|balance|exceptions|journal` y `/reports/menu/usage`
- API:
  - `/api/reports/sales/detail|summary|balance|exceptions|journal`
  - `/api/reports/menu/usage`

Parámetros:
- `start`, `end` (YYYY-MM-DD)
- `branch` (una o varias coma-separadas, o multiselect en UI)
- `terminal` (ids coma-separados)

## 5) Mix de Ventas (pivot)

- Vista “Detalle de registros” ahora pivota por día/sucursal:
  - Columnas: Efectivo, Crédito, Débito, Otras, Venta neta
  - Separador por mes cuando el rango incluye varios meses
  - Multiselect de sucursales disponible

## 6) Resolución de errores comunes

- “Undefined table … vw_report_*”: crear vistas con `COMANDOS_SQL_VISTAS.sql`.
- PG 9.5 y ROUND: castear a `::numeric` antes de `ROUND(..., 2)`.
- Fallos por caché: `php artisan optimize:clear`.

## 7) Siguientes pasos

- Exportes PDF/Excel para todos los reportes (patrón listo).
- Ajustes finos si hay diferencias con FloreantPOS en fechas/sucursales específicas.

